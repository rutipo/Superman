//
//  LJStorePopUpView.h
//  SudokuRivals
//
//  Created by Tennyson Hinds on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "PayPal.h"
#import "LJItem.h"
#import "LoopJoyStore.h"
#import "LJAFJSONRequestOperation.h"

@interface LJStorePopUpView : UIView <UIWebViewDelegate, UIAlertViewDelegate, DeviceReferenceTokenDelegate>{
    NSString *_developerID;
    NSString *_LJ_BASE_URL;
    LJModalOrientation _orientation;
    LJCancelButtonPosition _cancelPos;
    BOOL _isRetina;

    
    LJItem *_item;
    UIImage *_itemImage;
    NSString *_topText;
    
    NSMutableArray *pickerChoices;
    NSString *declaredOptionChoice;

    UIActionSheet *actionSheet;
    
    UIView *formView;
    UIWebView *_webView;
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
    
    UIActivityIndicatorView *_activityIndicator;
    BOOL _pendingCheckout;
    BOOL _confirmAttempted;
    
}


-(id)initWithItem:(LJItem *)item forOrientation:(LJModalOrientation)orientation;
@end