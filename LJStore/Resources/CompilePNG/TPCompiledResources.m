//
//  TPCompiledResources.m
//
//  Created by Michael Tyson on 13/05/2012.
//  Copyright (c) 2012 A Tasty Pixel. All rights reserved.
//

#import "TPCompiledResources.h"

/*{%IMAGEDATA START%}*/
/*{%IMAGEDATA END%}*/

UIImage *TPGetCompiledImage(NSString* name) {
    /*{%LOAD_TEMPLATE%}
     if ( [name isEqualToString:@"ORIGINAL_FILENAME"] ) {
     static UIImage *_SANITISED_FILENAME_image = nil;
     if ( _SANITISED_FILENAME_image ) return _SANITISED_FILENAME_image;
     
     if ( [[UIScreen mainScreen] scale] == 2.0 ) {
     _SANITISED_FILENAME_image = [[UIImage alloc] initWithCGImage:
     [[UIImage imageWithData:[NSData dataWithBytesNoCopy:SANITISED_2X_FILENAME 
     length:SANITISED_2X_FILENAME_len freeWhenDone:NO]] CGImage] 
     scale:2.0 
     orientation:UIImageOrientationUp];
     } else {
     _SANITISED_FILENAME_image = [[UIImage alloc] initWithData:[NSData dataWithBytesNoCopy:SANITISED_FILENAME 
     length:SANITISED_FILENAME_len freeWhenDone:NO]];
     }
     
     return _SANITISED_FILENAME_image;
     }
     {%LOAD_TEMPLATE END%}*/
    
    /*{%IMAGELOADERS START%}*/
    /*{%IMAGELOADERS END%}*/
    return nil;
}