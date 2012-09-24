//
//  LJStorePopUpView.h
//  SudokuRivals
//
//  Created by Tennyson Hinds on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "PayPal.h"
#import "LJTouchView.h"
#import "LJItem.h"
#import "LoopJoyStore.h"
#import "AFJSONRequestOperation.h"

@interface LJStorePopUpView : UIView <LJTouchUIViewDelegate, UIWebViewDelegate, DeviceReferenceTokenDelegate>{
    NSString *_developerID;
    LJModalOrientation _orientation;
    BOOL _isRetina;
    
    LJItem *_item;
    UIImage *_itemImage;
    NSString *_topText;
    
    NSMutableArray *pickerChoices;
    NSString *declaredOptionChoice;

    UIActionSheet *actionSheet;
    
    UIView *formView;
    UIWebView *_webView;
    LJTouchUIView *touchView;
    UIButton *sizeButton;
    
    NSMutableData *_receivedData;
    
    NSString *_cancelURL;
    NSString *_returnURL;
    NSString *_confirmURL;
    
    NSString *_appID;
    NSString *_deviceReferenceToken;
    NSString *_checkoutURL;
    NSString *_checkoutToken;
    NSString *_payerID;
}
@property(nonatomic,retain) NSMutableURLRequest *setupRequest;
@property(nonatomic,retain) NSMutableURLRequest *reviewRequest;
@property(nonatomic,retain) NSMutableURLRequest *checkoutRequest;
@property(nonatomic,retain) NSMutableURLRequest *confirmRequest;
@property(nonatomic,retain) AFJSONRequestOperation *reviewAFRequest;


-(id)initWithItem:(LJItem *)item forOrientation:(LJModalOrientation)orientation;
@end