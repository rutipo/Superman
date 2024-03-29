// LJAFURLConnectionOperation.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LJAFURLConnectionOperation.h"
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#endif

typedef enum {
    LJAFOperationPausedState      = -1,
    LJAFOperationReadyState       = 1,
    LJAFOperationExecutingState   = 2,
    LJAFOperationFinishedState    = 3,
} _AFOperationState;

typedef signed short LJAFOperationState;

#if __IPHONE_OS_VERSION_MIN_REQUIRED
typedef UIBackgroundTaskIdentifier LJAFBackgroundTaskIdentifier;
#else
typedef id LJAFBackgroundTaskIdentifier;
#endif

static NSString * const kAFNetworkingLockName = @"com.alamofire.networking.operation.lock";

NSString * const LJAFNetworkingErrorDomain = @"LJAFNetworkingErrorDomain";
NSString * const LJAFNetworkingOperationFailingURLRequestErrorKey = @"LJAFNetworkingOperationFailingURLRequestErrorKey";
NSString * const LJAFNetworkingOperationFailingURLResponseErrorKey = @"LJAFNetworkingOperationFailingURLResponseErrorKey";

NSString * const LJAFNetworkingOperationDidStartNotification = @"com.alamofire.networking.operation.start";
NSString * const LJAFNetworkingOperationDidFinishNotification = @"com.alamofire.networking.operation.finish";

typedef void (^LJAFURLConnectionOperationProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
typedef BOOL (^LJAFURLConnectionOperationAuthenticationAgainstProtectionSpaceBlock)(NSURLConnection *connection, NSURLProtectionSpace *protectionSpace);
typedef void (^LJAFURLConnectionOperationAuthenticationChallengeBlock)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge);
typedef NSCachedURLResponse * (^LJAFURLConnectionOperationCacheResponseBlock)(NSURLConnection *connection, NSCachedURLResponse *cachedResponse);
typedef NSURLRequest * (^LJAFURLConnectionOperationRedirectResponseBlock)(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse);

static inline NSString * LJAFKeyPathFromOperationState(LJAFOperationState state) {
    switch (state) {
        case LJAFOperationReadyState:
            return @"isReady";
        case LJAFOperationExecutingState:
            return @"isExecuting";
        case LJAFOperationFinishedState:
            return @"isFinished";
        case LJAFOperationPausedState:
            return @"isPaused";
        default:
            return @"state";
    }
}

static inline BOOL LJAFStateTransitionIsValid(LJAFOperationState fromState, LJAFOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case LJAFOperationReadyState:
            switch (toState) {
                case LJAFOperationPausedState:
                case LJAFOperationExecutingState:
                    return YES;
                case LJAFOperationFinishedState:
                    return isCancelled;
                default:
                    return NO;
            }
        case LJAFOperationExecutingState:
            switch (toState) {
                case LJAFOperationPausedState:
                case LJAFOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case LJAFOperationFinishedState:
            return NO;
        case LJAFOperationPausedState:
            return toState == LJAFOperationReadyState;
        default:
            return YES;
    }
}

@interface LJAFURLConnectionOperation ()
@property (readwrite, nonatomic, assign) LJAFOperationState state;
@property (readwrite, nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@property (readwrite, nonatomic, strong) NSURLConnection *connection;
@property (readwrite, nonatomic, strong) NSURLRequest *request;
@property (readwrite, nonatomic, strong) NSURLResponse *response;
@property (readwrite, nonatomic, strong) NSError *error;
@property (readwrite, nonatomic, strong) NSData *responseData;
@property (readwrite, nonatomic, copy) NSString *responseString;
@property (readwrite, nonatomic, assign) long long totalBytesRead;
@property (readwrite, nonatomic, assign) LJAFBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (readwrite, nonatomic, copy) LJAFURLConnectionOperationProgressBlock uploadProgress;
@property (readwrite, nonatomic, copy) LJAFURLConnectionOperationProgressBlock downloadProgress;
@property (readwrite, nonatomic, copy) LJAFURLConnectionOperationAuthenticationAgainstProtectionSpaceBlock authenticationAgainstProtectionSpace;
@property (readwrite, nonatomic, copy) LJAFURLConnectionOperationAuthenticationChallengeBlock authenticationChallenge;
@property (readwrite, nonatomic, copy) LJAFURLConnectionOperationCacheResponseBlock cacheResponse;
@property (readwrite, nonatomic, copy) LJAFURLConnectionOperationRedirectResponseBlock redirectResponse;

- (void)operationDidStart;
- (void)finish;
- (void)cancelConnection;
@end

@implementation LJAFURLConnectionOperation
@synthesize state = _state;
@synthesize cancelled = _cancelled;
@synthesize connection = _connection;
@synthesize runLoopModes = _runLoopModes;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize responseData = _responseData;
@synthesize responseString = _responseString;
@synthesize totalBytesRead = _totalBytesRead;
@dynamic inputStream;
@synthesize outputStream = _outputStream;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;
@synthesize uploadProgress = _uploadProgress;
@synthesize downloadProgress = _downloadProgress;
@synthesize authenticationAgainstProtectionSpace = _authenticationAgainstProtectionSpace;
@synthesize authenticationChallenge = _authenticationChallenge;
@synthesize cacheResponse = _cacheResponse;
@synthesize redirectResponse = _redirectResponse;
@synthesize lock = _lock;

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    do {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    } while (YES);
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = kAFNetworkingLockName;
    
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    self.request = urlRequest;
    
    self.outputStream = [NSOutputStream outputStreamToMemory];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    for (NSString *runLoopMode in self.runLoopModes) {
        [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
    }
    
    self.state = LJAFOperationReadyState;
	
    return self;
}

- (void)dealloc {
    if (_outputStream) {
        [_outputStream close];
        _outputStream = nil;
    }

#if __IPHONE_OS_VERSION_MIN_REQUIRED
    if (_backgroundTaskIdentifier) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
#endif
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, state: %@, cancelled: %@ request: %@, response: %@>", NSStringFromClass([self class]), self, LJAFKeyPathFromOperationState(self.state), ([self isCancelled] ? @"YES" : @"NO"), self.request, self.response];
}

- (void)setCompletionBlock:(void (^)(void))block {
    [self.lock lock];
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __unsafe_unretained id _blockSelf = self;
        [super setCompletionBlock:^ {
            block();
            [_blockSelf setCompletionBlock:nil];
        }];
    }
    [self.lock unlock];
}

- (NSInputStream *)inputStream {
    return self.request.HTTPBodyStream;
}

- (void)setInputStream:(NSInputStream *)inputStream {
    [self willChangeValueForKey:@"inputStream"];
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    mutableRequest.HTTPBodyStream = inputStream;
    self.request = mutableRequest;
    [self didChangeValueForKey:@"inputStream"];
}

- (void)setOutputStream:(NSOutputStream *)outputStream {
    if (outputStream == _outputStream) {
        return;
    }
    
    [self willChangeValueForKey:@"outputStream"];
    
    if (_outputStream) {
        [_outputStream close];
    }
    _outputStream = outputStream;
    [self didChangeValueForKey:@"outputStream"];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    [self.lock lock];
    if (!self.backgroundTaskIdentifier) {    
        UIApplication *application = [UIApplication sharedApplication];
        self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
            if (handler) {
                handler();
            }
            
            [self cancel];
            
            [application endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
    [self.lock unlock];
}
#endif

- (void)setUploadProgressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    self.uploadProgress = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

- (void)setAuthenticationAgainstProtectionSpaceBlock:(BOOL (^)(NSURLConnection *, NSURLProtectionSpace *))block {
    self.authenticationAgainstProtectionSpace = block;
}

- (void)setAuthenticationChallengeBlock:(void (^)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge))block {
    self.authenticationChallenge = block;
}

- (void)setCacheResponseBlock:(NSCachedURLResponse * (^)(NSURLConnection *connection, NSCachedURLResponse *cachedResponse))block {
    self.cacheResponse = block;
}

- (void)setRedirectResponseBlock:(NSURLRequest * (^)(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse))block {
    self.redirectResponse = block;
}

- (void)setState:(LJAFOperationState)state {
    [self.lock lock];
    if (LJAFStateTransitionIsValid(self.state, state, [self isCancelled])) {
        NSString *oldStateKey = LJAFKeyPathFromOperationState(self.state);
        NSString *newStateKey = LJAFKeyPathFromOperationState(state);
        
        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
        
        switch (state) {
            case LJAFOperationExecutingState:
                [[NSNotificationCenter defaultCenter] postNotificationName:LJAFNetworkingOperationDidStartNotification object:self];
                break;
            case LJAFOperationFinishedState:
                [[NSNotificationCenter defaultCenter] postNotificationName:LJAFNetworkingOperationDidFinishNotification object:self];
                break;
            default:
                break;
        }
    }
    [self.lock unlock];
}

- (NSString *)responseString {
    [self.lock lock];
    if (!_responseString && self.response && self.responseData) {
        NSStringEncoding textEncoding = NSUTF8StringEncoding;
        if (self.response.textEncodingName) {
            textEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)self.response.textEncodingName));
        }
        
        self.responseString = [[NSString alloc] initWithData:self.responseData encoding:textEncoding];
    }
    [self.lock unlock];
    
    return _responseString;
}

- (void)pause {
    if ([self isPaused] || [self isFinished] || [self isCancelled]) {
        return;
    }
    
    [self.lock lock];
    
    if ([self isExecuting]) {
        [self.connection performSelector:@selector(cancel) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
        [[NSNotificationCenter defaultCenter] postNotificationName:LJAFNetworkingOperationDidFinishNotification object:self];
    }
    
    self.state = LJAFOperationPausedState;

    [self.lock unlock];
}

- (BOOL)isPaused {
    return self.state == LJAFOperationPausedState;
}

- (void)resume {
    if (![self isPaused]) {
        return;
    }
    
    [self.lock lock];
    self.state = LJAFOperationReadyState;
    
    [self start];
    [self.lock unlock];
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == LJAFOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == LJAFOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == LJAFOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    [self.lock lock];
    if ([self isReady]) {
        self.state = LJAFOperationExecutingState;
        
        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)operationDidStart {
    [self.lock lock];
    if ([self isCancelled]) {
        [self finish];
    } else {
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }
        
        [self.connection start];  
    }
    [self.lock unlock];
}

- (void)finish {
    self.state = LJAFOperationFinishedState;
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = YES;
        [super cancel];
        [self didChangeValueForKey:@"isCancelled"];

        // Cancel the connection on the thread it runs on to prevent race conditions 
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)cancelConnection {
    if (self.connection) {
        [self.connection cancel];
        
        // Manually send this delegate message since `[self.connection cancel]` causes the connection to never send another message to its delegate
        NSDictionary *userInfo = nil;
        if ([self.request URL]) {
            userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
        }
        [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo]];
    }
}

#pragma mark - NSURLConnectionDelegate

- (BOOL)connection:(NSURLConnection *)connection 
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
#ifdef _AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return YES;
    }
#endif
    
    if (self.authenticationAgainstProtectionSpace) {
        return self.authenticationAgainstProtectionSpace(connection, protectionSpace);
    } else if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] || [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)connection:(NSURLConnection *)connection 
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge 
{
#ifdef _AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        return;
    }
#endif
    
    if (self.authenticationChallenge) {
        self.authenticationChallenge(connection, challenge);
    } else {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = nil;
            
            NSString *username = (__bridge_transfer NSString *)CFURLCopyUserName((__bridge CFURLRef)[self.request URL]);
            NSString *password = (__bridge_transfer NSString *)CFURLCopyPassword((__bridge CFURLRef)[self.request URL]);
            
            if (username && password) {
                credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
            } else if (username) {
                credential = [[[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:[challenge protectionSpace]] objectForKey:username];
            } else {
                credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[challenge protectionSpace]];
            }
            
            if (credential) {
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        } else {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    if (self.redirectResponse) {
        return self.redirectResponse(connection, request, redirectResponse);
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
   didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten 
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.uploadProgress(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        });
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
didReceiveResponse:(NSURLResponse *)response 
{
    self.response = response;
    
    [self.outputStream open];
}

- (void)connection:(NSURLConnection *)__unused connection 
    didReceiveData:(NSData *)data
{
    self.totalBytesRead += [data length];
    
    if ([self.outputStream hasSpaceAvailable]) {
        const uint8_t *dataBuffer = (uint8_t *) [data bytes];
        [self.outputStream write:&dataBuffer[0] maxLength:[data length]];
    }
    
    if (self.downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadProgress([data length], self.totalBytesRead, self.response.expectedContentLength);
        });
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)__unused connection {
    self.responseData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [self.outputStream close];
    
    [self finish];

    self.connection = nil;
}

- (void)connection:(NSURLConnection *)__unused connection 
  didFailWithError:(NSError *)error 
{    
    self.error = error;
    
    [self.outputStream close];
    
    [self finish];

    self.connection = nil;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection 
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    if (self.cacheResponse) {
        return self.cacheResponse(connection, cachedResponse);
    } else {
        if ([self isCancelled]) {
            return nil;
        }
        
        return cachedResponse; 
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSURLRequest *request = [aDecoder decodeObjectForKey:@"request"];
    
    self = [self initWithRequest:request];
    if (!self) {
        return nil;
    }

    self.state = [aDecoder decodeIntegerForKey:@"state"];
    self.cancelled = [aDecoder decodeBoolForKey:@"isCancelled"];
    self.response = [aDecoder decodeObjectForKey:@"response"];
    self.error = [aDecoder decodeObjectForKey:@"error"];
    self.responseData = [aDecoder decodeObjectForKey:@"responseData"];
    self.totalBytesRead = [[aDecoder decodeObjectForKey:@"totalBytesRead"] longLongValue];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self pause];
    
    [aCoder encodeObject:self.request forKey:@"request"];

    switch (self.state) {
        case LJAFOperationExecutingState:
        case LJAFOperationPausedState:
            [aCoder encodeInteger:LJAFOperationReadyState forKey:@"state"];
            break;
        default:
            [aCoder encodeInteger:self.state forKey:@"state"];
            break;
    }
    
    [aCoder encodeBool:[self isCancelled] forKey:@"isCancelled"];
    [aCoder encodeObject:self.response forKey:@"response"];
    [aCoder encodeObject:self.error forKey:@"error"];
    [aCoder encodeObject:self.responseData forKey:@"responseData"];
    [aCoder encodeObject:[NSNumber numberWithLongLong:self.totalBytesRead] forKey:@"totalBytesRead"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    LJAFURLConnectionOperation *operation = [[[self class] allocWithZone:zone] initWithRequest:self.request];
            
    operation.uploadProgress = self.uploadProgress;
    operation.downloadProgress = self.downloadProgress;
    operation.authenticationAgainstProtectionSpace = self.authenticationAgainstProtectionSpace;
    operation.authenticationChallenge = self.authenticationChallenge;
    operation.cacheResponse = self.cacheResponse;
    operation.redirectResponse = self.redirectResponse;

    return operation;
}

@end
