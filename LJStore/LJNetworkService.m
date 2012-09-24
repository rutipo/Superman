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
- (id)initWithAddress:(NSString *)address withRequestType:(URLRequestType)requestType delegate:(id<NSURLConnectionDelegate>)theDelegate{
    self = [super init];
    if (self){

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
        
        
        _address = [[NSString alloc] initWithString:address];
        _request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:address]];
        _theDelegate = theDelegate;
        
        switch(requestType){
            case URLRequestPOST:		
                [_request setHTTPMethod:@"POST"];
                break;
            case URLRequestPUT:
                break;
            case URLRequestGET:
                [_request setHTTPMethod:@"GET"];
                break;
            case URLRequestDELETE:
                break;
        }
        
        _params = [[NSMutableDictionary alloc] init];
        _headers = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}
- (void)addParam:(NSString *)name value:(NSString *)value{
    [_params setObject:value forKey:name];
}
- (void)addHeader:(NSString *)name value:(NSString *)value{
    [_headers setObject:value forKey:name];
}

- (void)setBody:(NSString *)body{
    _requestString = [[NSString alloc] initWithString:body];
    NSLog(@"request string: %@",_requestString);
    [_request setHTTPBody:[_requestString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)buildRequest{
    NSString *body = [[NSString alloc] init];
    for(NSString *key in _params) {
        NSString *value = [_params objectForKey:key];
        body = [NSString stringWithFormat:@"%@%@%@",key,@"&",value];
    }
}
- (void)execute{
    [_request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    //[_request setValue:[NSString stringWithFormat:@"%d",[_requestString length]] forHTTPHeaderField:@"Content-length"];
    [_request setHTTPBody:[_requestString dataUsingEncoding:NSUTF8StringEncoding]];
    _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
    
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [_theDelegate connection:connection didReceiveData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [_theDelegate connection:connection didFailWithError:error];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [_theDelegate connectionDidFinishLoading:connection];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [_theDelegate connection:connection didReceiveResponse:response];
}


//Challenge Authorization

- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSString * challenge = [protectionSpace authenticationMethod];
    NSLog(@"canAuthenticateAgainstProtectionSpace challenge %@ isServerTrust=%d", challenge, [challenge isEqualToString:NSURLAuthenticationMethodServerTrust]);
    if ([challenge isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return YES;
    }
    
    return NO;
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

