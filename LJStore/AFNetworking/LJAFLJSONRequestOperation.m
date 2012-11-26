// LJAFLJSONRequestOperation.m
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

#import "LJAFLJSONRequestOperation.h"

static dispatch_queue_t af_json_request_operation_processing_queue;
static dispatch_queue_t json_request_operation_processing_queue() {
    if (af_json_request_operation_processing_queue == NULL) {
        af_json_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.json-request.processing", 0);
    }
    
    return af_json_request_operation_processing_queue;
}

@interface LJAFLJSONRequestOperation ()
@property (readwrite, nonatomic) id responseLJSON;
@property (readwrite, nonatomic) NSError *LJSONError;
@end

@implementation LJAFLJSONRequestOperation
@synthesize responseLJSON = _responseLJSON;
@synthesize LJSONError = _LJSONError;

+ (LJAFLJSONRequestOperation *)LJSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id LJSON))success 
                                                    failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id LJSON))failure
{
    LJAFLJSONRequestOperation *requestOperation = [[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(LJAFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(LJAFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(LJAFLJSONRequestOperation *)operation responseLJSON]);
        }
    }];
    
    return requestOperation;
}


- (id)responseLJSON {
    if (!_responseLJSON && [self.responseData length] > 0 && [self isFinished] && !self.LJSONError) {
        NSError *error = nil;

        if ([self.responseData length] == 0) {
            self.responseLJSON = nil;
        } else {
            self.responseLJSON = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&error];
        }
        
        self.LJSONError = error;
    }
    
    return _responseLJSON;
}

- (NSError *)error {
    if (_LJSONError) {
        return _LJSONError;
    } else {
        return [super error];
    }
}

#pragma mark - LJAFHTTPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[[request URL] pathExtension] isEqualToString:@"json"] || [super canProcessRequest:request];
}

- (void)setCompletionBlockWithSuccess:(void (^)(LJAFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(LJAFHTTPRequestOperation *operation, NSError *error))failure
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
   self.completionBlock = ^ {
        if ([self isCancelled]) {
            return;
        }
        
        if (self.error) {
            if (failure) {
                dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                    failure(self, self.error);
                });
            }
        } else {
            dispatch_async(json_request_operation_processing_queue(), ^{
                id LJSON = self.responseLJSON;
                
                if (self.LJSONError) {
                    if (failure) {
                        dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                            failure(self, self.error);
                        });
                    }
                } else {
                    if (success) {
                        dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                            success(self, LJSON);
                        });
                    }                    
                }
            });
        }
    };
#pragma clang diagnostic pop
}

@end
