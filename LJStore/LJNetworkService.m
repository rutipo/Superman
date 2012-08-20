//
//  LJNetworkDelegate.m
//  SudokuRivals
//
//  Created by Tennyson Hinds on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LJNetworkService.h"
#import "LJStorePopUpView.h"

@implementation LJNetworkService
- (id)initWithAddress:(NSString *)_address withRequestType:(URLRequestType)requestType delegate:(id<NSURLConnectionDelegate>)theDelegate{
    if (self = [super init]){
//        
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"crt" ofType:@"der"]; //change the path to our certificate here
//        assert(path);
//        NSData *data = [NSData dataWithContentsOfFile:path];
//        assert(data);
//        
//        /* Set up the array of certs we will authenticate against and create cred */
//        SecCertificateRef rootcert = SecCertificateCreateWithData(NULL, CFBridgingRetain(data));
//        const void *array[1] = { rootcert };
//        certs = CFArrayCreate(NULL, array, 1, &kCFTypeArrayCallBacks);
//        CFRelease(rootcert);    // for completeness, really does not matter 
        
        
        address = _address;
        request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:address]];
        thisDelegate = theDelegate;
        
        switch(requestType){
            case URLRequestPOST:		
                [request setHTTPMethod:@"POST"];
                break;
            case URLRequestPUT:
                break;
            case URLRequestGET:
                [request setHTTPMethod:@"GET"];
                break;
            case URLRequestDELETE:
                break;
        }
        
        params = [[NSMutableDictionary alloc] init];
        headers = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}
- (void)addParam:(NSString *)name value:(NSString *)value{
    [params setObject:value forKey:name];
}
- (void)addHeader:(NSString *)name value:(NSString *)value{
    [headers setObject:value forKey:name];
}

- (void)setBody:(NSString *)body{
    requestString = body;
    NSLog(@"request string: %@",requestString);
    [request setHTTPBody:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)buildRequest{
    NSString *body = [[NSString alloc] init];
    for(NSString *key in params) {
        NSString *value = [params objectForKey:key];
        body = [NSString stringWithFormat:@"%@%@%@",key,@"&",value];
    }
}
- (void)execute{
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:[NSString stringWithFormat:@"%d",[requestString length]] forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"Executing NSURL REQUEST");
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://50.16.220.58/items.json"]
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:60.0];
    connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
}

- (void)connection:(NSURLConnection *)sendingConnection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"Did receive response)");
    [thisDelegate connection:sendingConnection didReceiveResponse:response];
}
- (void)sendInfo:(NSString  *)data{}
- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSString * challenge = [protectionSpace authenticationMethod];
    NSLog(@"canAuthenticateAgainstProtectionSpace challenge %@ isServerTrust=%d", challenge, [challenge isEqualToString:NSURLAuthenticationMethodServerTrust]);
    if ([challenge isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return YES;
    }
    
    return NO;
}

-(void)connection:(NSURLConnection *)sendingConnection didReceiveData:(NSData *)data{
    NSLog(@"didRecieveDataInParent");
    NSLog(@"data %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    [thisDelegate connection:sendingConnection didReceiveData:data];
}
/* Look to see if we can handle the challenge */
- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"didReceiveAuthenticationChallenge %@ FAILURES=%d", [[challenge protectionSpace] authenticationMethod], (int)[challenge previousFailureCount]);
    
    /* Setup */
    NSURLProtectionSpace *protectionSpace   = [challenge protectionSpace];
    assert(protectionSpace);
    SecTrustRef trust                       = [protectionSpace serverTrust];
    assert(trust);
    CFRetain(trust);  // Make sure this thing stays around until we're done with it
    NSURLCredential *credential             = [NSURLCredential credentialForTrust:trust];
    
    
    /* Build up the trust anchor using our root cert */    
    
    int err;
    
    SecTrustResultType trustResult = 0;
    
    err = SecTrustSetAnchorCertificates(trust, certs);
    if (err == noErr) {
        err = SecTrustEvaluate(trust,&trustResult);
    }
    CFRelease(trust);  // OK, now we're done with it
    
    BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultConfirm) || (trustResult == kSecTrustResultUnspecified));
    
    // Return based on whether we decided to trust or not
    if (trusted) {
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    } else {
        NSLog(@"Trust evaluation failed for service root certificate");
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

@end

