//
//  LJItem.h
//  Store
//  Created by Tennyson Hinds on 8/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LJItem : NSObject
@property (nonatomic, retain) NSString *product_price;
@property (nonatomic, retain) NSString *product_sku;
@property (nonatomic, retain) NSString *product_name;
@property (nonatomic, retain) NSString *product_type;
@property (nonatomic, retain) NSString *product_desc;
@property (nonatomic, retain) NSString *product_options;
@property (nonatomic, retain) NSString *product_display_text;
@property (nonatomic, retain) NSString *product_id;
@property (nonatomic, retain) UIImage *product_image;
@property (nonatomic, retain) UIImage *product_background_image;


@end
