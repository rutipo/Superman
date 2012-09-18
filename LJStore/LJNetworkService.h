//
//  LJNetworkDelegate.h
//  SudokuRivals
//
//  Created by Tennyson Hinds on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    URLRequestPOST = 1,
    URLRequestPUT = 2,
    URLRequestGET = 3,
    URLRequestDELETE = 4,
} URLRequestType;

@interface LJNetworkService : NSObject{
    NSString *_address;
    NSString *_requestString;
    NSURLConnection *_connection;
    NSMutableURLRequest *_request;
    
    NSMutableDictionary *_params;
    NSMutableDictionary *_headers;
    
    id _theDelegate;
    
    CFArrayRef certs;
}
- (id)initWithAddress:(NSString *)address withRequestType:(URLRequestType)requestType delegate:(id<NSURLConnectionDelegate>)theDelegate;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)setBody:(NSString *)body;
- (void)buildRequest;
- (void)execute;
@end
