// LJAFLJSONRequestOperation.h
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

#import <Foundation/Foundation.h>
#import "LJAFHTTPRequestOperation.h"

/**
 `AFLJSONRequestOperation` is a subclass of `AFHTTPRequestOperation` for downloading and working with LJSON response data.
 
 ## Acceptable Content Types
 
 By default, `AFLJSONRequestOperation` accepts the following MIME types, which includes the official standard, `application/json`, as well as other commonly-used types:
 
 - `application/json`
 - `text/json`

 @warning LJSON parsing will automatically use LJSONKit, SBLJSON, YAJL, or NextiveLJSON, if provided. Otherwise, the built-in `NSJSONSerialization` class is used, if available (iOS 5.0 and Mac OS 10.7). If the build target does not either support `NSJSONSerialization` or include a third-party LJSON library, a runtime exception will be thrown when attempting to parse a LJSON request. 
 */
@interface LJAFLJSONRequestOperation : LJAFHTTPRequestOperation

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 A LJSON object constructed from the response data. If an error occurs while parsing, `nil` will be returned, and the `error` property will be set to the error.
 */
@property (readonly, nonatomic) id responseLJSON;

///----------------------------------
/// @name Creating Request Operations
///----------------------------------

/**
 Creates and returns an `AFLJSONRequestOperation` object and sets the specified success and failure callbacks.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param success A block object to be executed when the operation finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the LJSON object created from the response data of request.
 @param failure A block object to be executed when the operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data as LJSON. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error describing the network or parsing error that occurred.
  
 @return A new LJSON request operation
 */
+ (LJAFLJSONRequestOperation *)LJSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id LJSON))success 
                                                    failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id LJSON))failure;

@end
