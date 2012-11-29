//
//  LJStorePopUpView.m
//  SudokuRivals
//
//  Created by Tennyson Hinds on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "LJStorePopUpView.h"
#import "TPCompiledResources.h"
#import "GANTracker.h"
#import "UIDevice+IdentifierAddition.h"
#import "LJAFLJSONRequestOperation.h"
#import "LJSONKit.h"
#import "PayPal.h"



@implementation LJStorePopUpView


-(id)initWithItem:(LJItem *)item forOrientation:(LJModalOrientation)orientation{
    _item = item;
    _developerID = [[LoopJoyStore sharedInstance] getDeveloperID];
    _orientation = orientation;
    _cancelPos = [[LoopJoyStore sharedInstance] getCancelButtonPos];
    _appID = [[LoopJoyStore sharedInstance] getEnvType] == LJ_ENV_LIVE ? @"APP-09B355920Y2948247" : @"APP-80W284485P519543T";
    _isRetina = [[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0);
    _receivedData = [[NSMutableData alloc] init];
    _pendingCheckout = FALSE;
    _confirmAttempted = FALSE;
    _LJ_BASE_URL = [[LoopJoyStore sharedInstance] getEnvType] == LJ_ENV_LIVE ? @"http://loopjoy.com" : @"http://dev.loopjoy.com";
    
    [[PayPal getPayPalInst] fetchDeviceReferenceTokenWithAppID:_appID 
                                                forEnvironment:[[LoopJoyStore sharedInstance] getEnvType] == LJ_ENV_LIVE ? ENV_LIVE : ENV_SANDBOX 
                                                  withDelegate:self];

    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //if (orientation == LJ_MODAL_HORIZONTAL){} else {}
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat xCenter;
        UILabel *topTextLabel;
        UIImage *backgroundImage;
        
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            backgroundImage = TPGetCompiledImage(@"background_ipad.png");
            formView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - backgroundImage.size.width)/2,120,backgroundImage.size.width,backgroundImage.size.height)];
            formView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
            formView.alpha = 1;
            
            _webView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            CGAffineTransform transform;
            
            switch(_orientation){
                case LJ_MODAL_HORIZONTAL:
                    transform = CGAffineTransformMakeRotation(3.14159/2);
                    break;
                case LJ_MODAL_HORIZONTAL_INVERSE:
                    transform = CGAffineTransformMakeRotation(-3.14159/2);
                    break;
                case LJ_MODAL_VERTICAL:
                    transform = CGAffineTransformMakeRotation(0);
                    break;
                case LJ_MODAL_VERTICAL_INVERSE:
                    transform = CGAffineTransformMakeRotation(3.14159);
                    break;
                    
            }
            
            _webView.transform = transform;
            _webView.frame = [[UIScreen mainScreen] bounds];

            
            _webView.delegate = self;
            
            
            xCenter = formView.frame.size.width/2;
            
            
            
            //Show error message if we are unable to load an item.
            if(_item == nil){
                
                UIFont *errorTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold," size:30];
                NSString *errorText = @"No connectivity. \n Please try again later.";
                CGSize textSize = [errorText sizeWithFont:errorTextFont constrainedToSize:CGSizeMake(420, 240) lineBreakMode:UILineBreakModeWordWrap];
                UILabel *errorTextLabel;
                errorTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - textSize.width/2,formView.frame.size.height/2 - textSize.height/2, textSize.width,textSize.height)];
                errorTextLabel.text = errorText;
                errorTextLabel.numberOfLines = 0;
                errorTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                errorTextLabel.textColor = [UIColor blackColor];
                errorTextLabel.font = errorTextFont;
                errorTextLabel.textAlignment = UITextAlignmentCenter;
                errorTextLabel.backgroundColor = [UIColor clearColor];
                [formView addSubview:errorTextLabel];
            }
            
            else {
                //backgroundImage = _item.product_background_image != nil ? _item.product_background_image : [[LoopJoyStore sharedInstance] getDefaultBG];

                //Modal Top Text
                NSString *topText = _item.product_display_text;
                UIFont *topTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
                CGSize textSize = [topText sizeWithFont:topTextFont constrainedToSize:CGSizeMake(580, 80) lineBreakMode:UILineBreakModeWordWrap];
                topTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - textSize.width/2, 30, textSize.width,textSize.height)];
                topTextLabel.text = topText;
                topTextLabel.numberOfLines = 0;
                topTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                topTextLabel.textColor = [UIColor colorWithRed:.16 green:.16 blue:.16 alpha:1];
                topTextLabel.font = topTextFont;
                topTextLabel.textAlignment = UITextAlignmentCenter;
                topTextLabel.backgroundColor = [UIColor clearColor];
                [formView addSubview:topTextLabel];
                
                
                //Modal Image
                UIImageView *modalImageView = [self resizeImage:_item.product_image forWidth:360 andHeight:450];
                CGRect imageFrame = modalImageView.frame;
                imageFrame.origin.x = xCenter - modalImageView.frame.size.width/2;
                imageFrame.origin.y = (formView.frame.size.height - topTextLabel.frame.size.height - modalImageView.frame.size.height - 40)/2;
                modalImageView.frame = imageFrame;
                modalImageView.alpha = 1;
                [formView addSubview:modalImageView];

                
                //Modal Price Label
                //Modal Top Text
                NSString *priceText = [NSString stringWithFormat:@"       $%@",_item.product_price];
                UIFont *priceTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
                UIImage *priceTextBG = TPGetCompiledImage(@"ipad_item_price_tag.png");
                UILabel *priceTagLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageFrame.origin.x + imageFrame.size.width + 10,imageFrame.origin.y + imageFrame.size.height /2,priceTextBG.size.width,priceTextBG.size.height)];
                priceTagLabel.text = priceText;
                priceTagLabel.numberOfLines = 1;
                priceTagLabel.lineBreakMode = UILineBreakModeClip;
                priceTagLabel.textColor = [UIColor colorWithRed:.16 green:.16 blue:.16 alpha:1];
                priceTagLabel.font = priceTextFont;
                priceTagLabel.textAlignment = UITextAlignmentCenter;
                priceTagLabel.backgroundColor = [UIColor colorWithPatternImage:priceTextBG];
                [priceTagLabel setTransform:CGAffineTransformMakeRotation(-.324)];
                [formView addSubview:priceTagLabel];
                
                //Paypal Initialization and Button Placement
                UIButton *button = [[PayPal getPayPalInst] getPayButtonWithTarget:self andAction:@selector(startPaypalCheckout) andButtonType:BUTTON_278x43];
                CGRect frame = button.frame;
                frame.origin.x = round((formView.frame.size.width - button.frame.size.width) / 2.);
                frame.origin.y = (modalImageView.frame.size.height + modalImageView.frame.origin.y) + (formView.frame.size.height - (modalImageView.frame.size.height + modalImageView.frame.origin.y))/2 - frame.size.height/2 -10; //
                button.frame = frame;
                [formView addSubview:button];
                
                //Terms Of Service Label
                UILabel *tosTextLabel;
                NSString *tosText = @"By clicking the button below I agree to the Terms of Sale";
                UIFont *tosTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10];
                CGSize tosTextSize = [tosText sizeWithFont:tosTextFont constrainedToSize:CGSizeMake(160,140) lineBreakMode:UILineBreakModeWordWrap];
                tosTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - (tosTextSize.width/2), button.frame.origin.y - tosTextSize.height - 10, tosTextSize.width,tosTextSize.height)];
                tosTextLabel.text = tosText;
                tosTextLabel.numberOfLines = 0;
                tosTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                tosTextLabel.textColor = [UIColor colorWithRed:.40 green:.40 blue:.40 alpha:1];
                tosTextLabel.font = tosTextFont;
                tosTextLabel.textAlignment = UITextAlignmentCenter;
                tosTextLabel.backgroundColor = [UIColor clearColor];
                
                UILabel *underLineLabel = [[UILabel alloc] initWithFrame:CGRectMake(tosTextLabel.frame.origin.x + (tosTextLabel.frame.size.width/2) - 2, tosTextLabel.frame.origin.y + tosTextLabel.frame.size.height - 2,70, 1)];
                underLineLabel.backgroundColor = [UIColor colorWithRed:.40 green:.40 blue:.40 alpha:1];
                [tosTextLabel addSubview:underLineLabel];
                
                UIButton *tosButton = [UIButton buttonWithType:UIButtonTypeCustom];
                tosButton.frame = tosTextLabel.frame;
                [tosButton addTarget:self action:@selector(getTermsOfService) forControlEvents:UIControlEventTouchUpInside];
                [tosButton setBackgroundColor:[UIColor clearColor]];

                [formView addSubview:tosButton];
                [formView addSubview:tosTextLabel];
                [formView addSubview:underLineLabel];

             
            }
        }
        else {
            
            backgroundImage = TPGetCompiledImage(@"background_iphone.png");
            formView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - backgroundImage.size.width)/2,(frame.size.height - backgroundImage.size.height)/2,backgroundImage.size.width,backgroundImage.size.height)];
            formView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
            formView.alpha = 1;
            

            _webView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            _webView.delegate = self;
            xCenter = formView.frame.size.width/2;
            
            if(_item == nil){
                UIFont *errorTextFont = [UIFont fontWithName:@"Helvetica" size:22];
                NSString *errorText = @"Sorry, Unable to connect to the LoopJoy Store at this time.\n Please try again later.";
                CGSize textSize = [errorText sizeWithFont:errorTextFont constrainedToSize:CGSizeMake(240, 180) lineBreakMode:UILineBreakModeWordWrap];
                UILabel *errorTextLabel;
                errorTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - textSize.width/2,formView.frame.size.height/2 - textSize.height/2, textSize.width,textSize.height)];
                errorTextLabel.text = errorText;
                errorTextLabel.numberOfLines = 0;
                errorTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                errorTextLabel.textColor = [UIColor whiteColor];
                errorTextLabel.font = errorTextFont;
                errorTextLabel.textAlignment = UITextAlignmentCenter;
                errorTextLabel.backgroundColor = [UIColor clearColor];
                [formView addSubview:errorTextLabel];
            }
            
            else{
                //backgroundImage = _item.product_background_image != nil ? _item.product_background_image : [[LoopJoyStore sharedInstance] getDefaultBG];
                
                //Modal Top Text
                NSString *topText = _item.product_display_text;
                UIFont *topTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
                CGSize textSize = [topText sizeWithFont:topTextFont constrainedToSize:CGSizeMake(280, 25) lineBreakMode:UILineBreakModeWordWrap];
                topTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - textSize.width/2, 12, textSize.width,textSize.height)];
                topTextLabel.text = topText;
                topTextLabel.numberOfLines = 0;
                topTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                topTextLabel.textColor = [UIColor colorWithRed:.16 green:.16 blue:.16 alpha:1];
                topTextLabel.font = topTextFont;
                topTextLabel.textAlignment = UITextAlignmentCenter;
                topTextLabel.backgroundColor = [UIColor clearColor];
                [formView addSubview:topTextLabel];
                
                
                //Modal Image
                UIImageView *modalImageView = [self resizeImage:_item.product_image forWidth:165 andHeight:170];
                CGRect imageFrame = modalImageView.frame;
                imageFrame.origin.x = xCenter - modalImageView.frame.size.width/2;
                imageFrame.origin.y = (formView.frame.size.height - topTextLabel.frame.size.height - modalImageView.frame.size.height - 40)/2;
                modalImageView.frame = imageFrame;
                modalImageView.alpha = 1;
                [formView addSubview:modalImageView];
                
                //Modal Price Label
                //Modal Top Text
                NSString *priceText = [NSString stringWithFormat:@"      $%@",_item.product_price];
                UIFont *priceTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12];
                UIImage *priceTextBG = TPGetCompiledImage(@"iphone_item_price_tag.png");
                UILabel *priceTagLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageFrame.origin.x + imageFrame.size.width + 2,imageFrame.origin.y + imageFrame.size.height /2,priceTextBG.size.width,priceTextBG.size.height)];
                priceTagLabel.text = priceText;
                priceTagLabel.numberOfLines = 1;
                priceTagLabel.lineBreakMode = UILineBreakModeClip;
                priceTagLabel.textColor = [UIColor colorWithRed:.16 green:.16 blue:.16 alpha:1];
                priceTagLabel.font = priceTextFont;
                priceTagLabel.textAlignment = UITextAlignmentCenter;
                priceTagLabel.backgroundColor = [UIColor colorWithPatternImage:priceTextBG];
                [priceTagLabel setTransform:CGAffineTransformMakeRotation(-.324)];
                [formView addSubview:priceTagLabel];
                
                //Paypal Button Placement
                UIButton *button = [[PayPal getPayPalInst] getPayButtonWithTarget:self andAction:@selector(startPaypalCheckout) andButtonType:BUTTON_118x24];
                CGRect frame = button.frame;
                frame.origin.x = round((formView.frame.size.width - button.frame.size.width) / 2.);
                frame.origin.y = (modalImageView.frame.size.height + modalImageView.frame.origin.y) + (formView.frame.size.height - (modalImageView.frame.size.height + modalImageView.frame.origin.y))/2 - frame.size.height/2 - 5;
                button.frame = frame;
                [formView addSubview:button];
                
                //Terms Of Service Label
                UILabel *tosTextLabel;
                NSString *tosText = @"By clicking the button below I agree to the Terms of Sale";
                UIFont *tosTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:8];
                CGSize tosTextSize = [tosText sizeWithFont:tosTextFont constrainedToSize:CGSizeMake(136,24) lineBreakMode:UILineBreakModeWordWrap];
                tosTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - (tosTextSize.width/2), button.frame.origin.y - tosTextSize.height - 10, tosTextSize.width,tosTextSize.height)];
                tosTextLabel.text = tosText;
                tosTextLabel.numberOfLines = 0;
                tosTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                tosTextLabel.textColor = [UIColor colorWithRed:.40 green:.40 blue:.40 alpha:1];
                tosTextLabel.font = tosTextFont;
                tosTextLabel.textAlignment = UITextAlignmentCenter;
                tosTextLabel.backgroundColor = [UIColor clearColor];
                
                UILabel *underLineLabel = [[UILabel alloc] initWithFrame:CGRectMake(tosTextLabel.frame.origin.x + (tosTextLabel.frame.size.width/2) - 2, tosTextLabel.frame.origin.y + tosTextLabel.frame.size.height - 2,52, 1)];
                underLineLabel.backgroundColor = [UIColor colorWithRed:.40 green:.40 blue:.40 alpha:1];
                [tosTextLabel addSubview:underLineLabel];
                
                UIButton *tosButton = [UIButton buttonWithType:UIButtonTypeCustom];
                tosButton.frame = tosTextLabel.frame;
                [tosButton addTarget:self action:@selector(getTermsOfService) forControlEvents:UIControlEventTouchUpInside];
                [tosButton setBackgroundColor:[UIColor clearColor]];
                
                [formView addSubview:tosButton];
                [formView addSubview:tosTextLabel];
                [formView addSubview:underLineLabel];

                
            }
        }
        
        _activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        _activityIndicator.center = CGPointMake(xCenter, formView.frame.size.height/2.0);
        _activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [_activityIndicator setColor:[UIColor blackColor]];
        
        //CancelView
        UIButton *cancelButton = [self cancelButtonForPosition:_cancelPos withConfirmation:FALSE];
        [formView addSubview:cancelButton];
        
        CGAffineTransform transform;
        
        switch(_orientation){
            case LJ_MODAL_HORIZONTAL:
                transform = CGAffineTransformMakeRotation(3.14159/2);
                break;
            case LJ_MODAL_HORIZONTAL_INVERSE:
                transform = CGAffineTransformMakeRotation(-3.14159/2);
                break;
            case LJ_MODAL_VERTICAL:
                transform = CGAffineTransformMakeRotation(0);
                break;
            case LJ_MODAL_VERTICAL_INVERSE:
                transform = CGAffineTransformMakeRotation(3.14159);
                break;
                
        }
        
        formView.transform = transform;
        
        [self addSubview:formView];
    }
    return self;
}

-(UIButton *)cancelButtonForPosition:(LJCancelButtonPosition)position withConfirmation:(BOOL)confirm{
    int xPos;
    int yPos;
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cancelButton setTitle:@"X" forState:UIControlStateNormal];
    cancelButton.layer.borderColor = [UIColor clearColor].CGColor;
    cancelButton.backgroundColor = [UIColor colorWithRed:.70 green:.70 blue:.70 alpha:1];
    cancelButton.layer.borderWidth = 0.5f;
    cancelButton.layer.cornerRadius = 10.0f;
    if(confirm){[cancelButton addTarget:self action:@selector(cancelWithConfirm) forControlEvents:UIControlEventTouchUpInside];}
    else{[cancelButton addTarget:self action:@selector(cancelWithoutConfirm) forControlEvents:UIControlEventTouchUpInside];}
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        if(position == LJ_CANCEL_BUTTON_POS_TOP_RIGHT){xPos = formView.frame.size.width - 60; yPos = 22;}
        else if(position == LJ_CANCEL_BUTTON_POS_TOP_LEFT){xPos = 32; yPos = 22;}
        else{xPos = formView.frame.size.width - 60; yPos = formView.frame.size.height - 65;}
        cancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22];
        cancelButton.frame = CGRectMake(xPos,yPos,33,33);
    }
    else{
        if(position == LJ_CANCEL_BUTTON_POS_TOP_RIGHT){xPos = formView.frame.size.width - 37; yPos = 9;}
        else if(position == LJ_CANCEL_BUTTON_POS_TOP_LEFT){xPos = 8; yPos = 9;}
        else{xPos = formView.frame.size.width - 37; yPos = formView.frame.size.height - 15;}
        [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [cancelButton setTitle:@"X" forState:UIControlStateNormal];
        cancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10];
        cancelButton.frame = CGRectMake(xPos,yPos,25,25);
    }
    return cancelButton;
}

-(void)getTermsOfService{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://loopjoy.com/TermsOfSale"]];
}

-(UIImageView *)resizeImage:(UIImage *)image forWidth:(int)widthMax andHeight:(int) heightMax {
    float wRatio;
    float hRatio;
    UIImageView *modalImageView = [[UIImageView alloc] initWithImage:image];
    
    if (image.size.width >= image.size.height)
    {
        if (image.size.width <= widthMax && image.size.height <= heightMax)
            return modalImageView;  // no resizing required
        wRatio = widthMax / image.size.width;
        hRatio = heightMax / image.size.height;
    }
    else
    {
        if (image.size.height <= heightMax && image.size.width <= widthMax)
            return modalImageView; // no resizing required
        wRatio = widthMax / image.size.width;
        hRatio = heightMax / image.size.height;
    }
    
    // hRatio and wRatio now have the scaling factors for height and width.
    // You want the smallest of the two to ensure that the resulting image
    // fits in the desired frame and maintains the aspect ratio.
    float resizeRatio = MIN(wRatio, hRatio);
    
    CGRect imageFrame = modalImageView.frame;
    imageFrame.size.width = image.size.width * resizeRatio;
    imageFrame.size.height = image.size.height * resizeRatio;
    modalImageView.frame = imageFrame;

    return modalImageView;    
}


                                                           

-(void)setupPayPalCheckout{

    //On Success Block
    void (^success)(NSURLRequest *request, NSHTTPURLResponse *response, id LJSON);
    success = ^(NSURLRequest *request, NSHTTPURLResponse *response, id LJSON){
        NSDictionary *results = [NSDictionary dictionaryWithDictionary:LJSON];
        NSDictionary *purchaseParams = [results objectForKey:@"purchase_params"];
        _cancelURL = [purchaseParams objectForKey:@"cancel_return_url"];
        _returnURL = [purchaseParams objectForKey:@"return_url"];
        _checkoutToken = [results objectForKey:@"token"]; 
        _checkoutURL = [NSString stringWithFormat:@"%@&drt=%@",[results objectForKey:@"redirect_url"],_deviceReferenceToken];
        if(_pendingCheckout == true){
            [self startPaypalCheckout];
        }
        
    };
    
    //On Failure Block
    void (^failure)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id LJSON);
    failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id LJSON){
        NSLog(@"|| Loopjoy || : Connection did fail with error: %@",[error localizedDescription]);
    };
    
    
    LJAFLJSONRequestOperation *jsonRequest = [LJAFLJSONRequestOperation LJSONRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@/paypal/checkout?item_id=%@&UUID=%@&env_type=%@",_LJ_BASE_URL,_item.product_id,[[UIDevice currentDevice] uniqueDeviceIdentifier],[[LoopJoyStore sharedInstance] getEnvType] == LJ_ENV_LIVE ? @"LJ_ENV_LIVE" : @"LJ_ENV_SANDBOX"]]] success:success failure:failure];
    [jsonRequest start];
    
}

-(void)startPaypalCheckout{
    [formView addSubview:_activityIndicator];
    [_activityIndicator startAnimating];
    
    if(_checkoutURL == (id) [NSNull null] || [_checkoutURL length] == 0){
        _pendingCheckout = TRUE;
    }
    else{
        NSError *error;
        if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Paypal" action:[[NSString alloc] initWithFormat:@"Paypal Checkout Started By User For Item #%@",_item.product_id] label:_developerID value:0 withError:&error]) {
            NSLog(@"error in trackEvent");
        }
        _pendingCheckout = FALSE;
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_checkoutURL]]];
        _webView.backgroundColor = [UIColor clearColor];
        _webView.opaque = NO;
        [self addSubview:_webView];
    }
}


-(void)reviewPayPalCheckout{
    
    //On Success Block
    void (^successBlock)(NSURLRequest *request, NSHTTPURLResponse *response, id LJSON);
    successBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, id LJSON){
        [[formView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        NSDictionary *orderDetails = [NSDictionary dictionaryWithDictionary:LJSON];
        NSDictionary *address = [orderDetails objectForKey:@"shipping_address"];
        NSDictionary *gatewayDetails = [orderDetails objectForKey:@"gateway_details"];
        
        //Gateway Details
        _payerID = [gatewayDetails objectForKey:@"payer_id"];
        _checkoutToken = [gatewayDetails objectForKey:@"token"];
        
        
        //Order Details
        NSString *email = [orderDetails objectForKey:@"email"];
        NSString *subtotal = [NSString stringWithFormat:@"Subtotal: %@",[orderDetails objectForKey:@"subtotal"]];
        NSString *shipping = [NSString stringWithFormat:@"Shipping: %@",[orderDetails objectForKey:@"shipping"]];
        NSString *total = [NSString stringWithFormat:@"Total: %@",[orderDetails objectForKey:@"total"]];
        
        //Address Details
        NSString *name = [address objectForKey:@"name"];
        NSString *company = [address objectForKey:@"company"];
        NSString *address1 = [address objectForKey:@"address1"];
        NSString *address2 = [address objectForKey:@"address2"];
        NSString *address3 = [NSString stringWithFormat:@"%@, %@ %@ %@",[address objectForKey:@"city"],[address objectForKey:@"state"],[address objectForKey:@"country"], [address objectForKey:@"zip"]];
        
        //Buyer Details
        NSString *phone = [address objectForKey:@"phone"];
        
        
        //Setup Information Arrays
        NSArray *addressArray = [NSArray arrayWithObjects:name,company,address1,address2,address3, nil];
        NSArray *orderArray = [NSArray arrayWithObjects:subtotal,shipping,total,nil];
        NSArray *buyerArray = [NSArray arrayWithObjects:name,email,phone,nil];

        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            //Order Confirmation Header
            UIFont *textFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
            NSString *textString = @"Order Confirmation";
            CGSize textSize = [textString sizeWithFont:textFont constrainedToSize:CGSizeMake(460, 180) lineBreakMode:UILineBreakModeWordWrap];
            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(formView.frame.size.width/2 - textSize.width/2,30, textSize.width,textSize.height)];
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.text = textString;
            textLabel.font = textFont;
            [formView addSubview:textLabel];
            
            
            int labelSpacer = 100;
            //Shipping Address Header
            textFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, labelSpacer, 300, 25)];
            textLabel.text = @"Shipping Address: ";
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.font = textFont;
            [formView addSubview:textLabel];
            labelSpacer += 22;
            
            //Shipping Information
            for (id string in addressArray){
                if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
                textLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,labelSpacer, 340, 25)];
                textLabel.text = [NSString stringWithString:string];
                textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
                textLabel.numberOfLines = 0;
                textLabel.lineBreakMode = UILineBreakModeWordWrap;
                textLabel.textColor = [UIColor blackColor];
                textLabel.textAlignment = UITextAlignmentLeft;
                textLabel.backgroundColor = [UIColor clearColor];
                labelSpacer += 18;
                [formView addSubview:textLabel];
                }
            }
            labelSpacer += 22;
            
            //Buyer Information Header
            textFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, labelSpacer, 340, 25)];
            textLabel.text = @"Buyer Information: ";
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.font = textFont;
            [formView addSubview:textLabel];
            labelSpacer += 22;
            

            for (id string in buyerArray){
                if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
                    textLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,labelSpacer, 340, 25)];
                    textLabel.text = [NSString stringWithString:string];
                    textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
                    textLabel.numberOfLines = 0;
                    textLabel.lineBreakMode = UILineBreakModeTailTruncation;
                    textLabel.textColor = [UIColor blackColor];
                    textLabel.textAlignment = UITextAlignmentLeft;
                    textLabel.backgroundColor = [UIColor clearColor];
                    labelSpacer += 18;
                    [formView addSubview:textLabel];
                }
            }
            labelSpacer += 25;
            
            //Checkout Information Header
            textFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, labelSpacer, 340, 25)];
            textLabel.text = @"Invoice: ";
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.font = textFont;
            [formView addSubview:textLabel];
            labelSpacer += 22;
            
            for (id string in orderArray){
                if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
                    textLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,labelSpacer, 340, 25)];
                    textLabel.text = [NSString stringWithString:string];
                    textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
                    textLabel.numberOfLines = 0;
                    textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    textLabel.textColor = [UIColor blackColor];
                    textLabel.textAlignment = UITextAlignmentLeft;
                    textLabel.backgroundColor = [UIColor clearColor];
                    labelSpacer += 22;
                    [formView addSubview:textLabel];
                }
            }
            
            UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [confirmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
            confirmButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
            confirmButton.backgroundColor = [UIColor colorWithRed:.16 green:.41 blue:.64 alpha:1];
            confirmButton.layer.borderColor = [UIColor blackColor].CGColor;
            confirmButton.layer.borderWidth = 0.5f;
            confirmButton.layer.cornerRadius = 10.0f;
            confirmButton.frame = CGRectMake(formView.frame.size.width/2 - 125,580,250,60);
            [confirmButton addTarget:self action:@selector(confirmPayPalCheckout) forControlEvents:UIControlEventTouchUpInside];
            [formView addSubview:confirmButton];
            
            UIImageView *modalImageView = [self resizeImage:_item.product_image forWidth:210 andHeight:320];
            CGRect imageFrame = modalImageView.frame;
            imageFrame.origin.x = 400;
            imageFrame.origin.y = 100;
            modalImageView.frame = imageFrame;
            modalImageView.alpha = 1;
            [formView addSubview:modalImageView];
        }
        else{
            //Order Confirmation Header
            UIFont *textFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
            NSString *textString = @"Order Confirmation";
            CGSize textSize = [textString sizeWithFont:textFont constrainedToSize:CGSizeMake(260, 56) lineBreakMode:UILineBreakModeWordWrap];
            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(formView.frame.size.width/2 - textSize.width/2,20, textSize.width,textSize.height)];
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.text = textString;
            textLabel.font = textFont;
            [formView addSubview:textLabel];
            
            
            int labelSpacer = 50;
            //Shipping Address Header
            textFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, labelSpacer, 280, 20)];
            textLabel.text = @"Shipping Address: ";
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.font = textFont;
            [formView addSubview:textLabel];
            labelSpacer += 16;
            
            //Shipping Information
            for (id string in addressArray){
                if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
                    textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30,labelSpacer, 280, 20)];
                    textLabel.text = [NSString stringWithString:string];
                    textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
                    textLabel.numberOfLines = 0;
                    textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    textLabel.textColor = [UIColor blackColor];
                    textLabel.textAlignment = UITextAlignmentLeft;
                    textLabel.backgroundColor = [UIColor clearColor];
                    labelSpacer += 12;
                    [formView addSubview:textLabel];
                }
            }
            labelSpacer += 16;
            
            //Buyer Information Header
            textFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, labelSpacer, 280, 20)];
            textLabel.text = @"Buyer Information: ";
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.font = textFont;
            [formView addSubview:textLabel];
            labelSpacer += 16;
            
            
            for (id string in buyerArray){
                if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
                    textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30,labelSpacer, 280, 20)];
                    textLabel.text = [NSString stringWithString:string];
                    textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
                    textLabel.numberOfLines = 0;
                    textLabel.lineBreakMode = UILineBreakModeTailTruncation;
                    textLabel.textColor = [UIColor blackColor];
                    textLabel.textAlignment = UITextAlignmentLeft;
                    textLabel.backgroundColor = [UIColor clearColor];
                    labelSpacer += 12;
                    [formView addSubview:textLabel];
                }
            }
            labelSpacer += 16;
            
            //Checkout Information Header
            textFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, labelSpacer, 280, 20)];
            textLabel.text = @"Invoice: ";
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.font = textFont;
            [formView addSubview:textLabel];
            labelSpacer += 16;
            
            for (id string in orderArray){
                if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
                    textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30,labelSpacer, 280, 20)];
                    textLabel.text = [NSString stringWithString:string];
                    textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
                    textLabel.numberOfLines = 0;
                    textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    textLabel.textColor = [UIColor blackColor];
                    textLabel.textAlignment = UITextAlignmentLeft;
                    textLabel.backgroundColor = [UIColor clearColor];
                    labelSpacer += 12;
                    [formView addSubview:textLabel];
                }
            }
            
            UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [confirmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
            confirmButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
            confirmButton.backgroundColor = [UIColor colorWithRed:.16 green:.41 blue:.64 alpha:1];
            confirmButton.layer.borderColor = [UIColor blackColor].CGColor;
            confirmButton.layer.borderWidth = 0.0f;
            confirmButton.layer.cornerRadius = 6.0f;
            confirmButton.frame = CGRectMake(formView.frame.size.width/2 - 62,250,125,25);
            [confirmButton addTarget:self action:@selector(confirmPayPalCheckout) forControlEvents:UIControlEventTouchUpInside];
            [formView addSubview:confirmButton];
            

            
        }
        //CancelView 
        UIButton *cancelButton = [self cancelButtonForPosition:_cancelPos withConfirmation:TRUE];
        [formView addSubview:cancelButton];
        
        CGAffineTransform transform;
        
        switch(_orientation){
            case LJ_MODAL_HORIZONTAL:
                transform = CGAffineTransformMakeRotation(3.14159/2);
                break;
            case LJ_MODAL_HORIZONTAL_INVERSE:
                transform = CGAffineTransformMakeRotation(-3.14159/2);
                break;
            case LJ_MODAL_VERTICAL:
                transform = CGAffineTransformMakeRotation(0);
                break;
            case LJ_MODAL_VERTICAL_INVERSE:
                transform = CGAffineTransformMakeRotation(3.14159);
                break;
                
        }
        
        formView.transform = transform;
        
        [self addSubview:formView];
        [_webView removeFromSuperview];
        
        //Setup view Here and push view
        
        
    };

    //On Failure Block
    void (^failureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id LJSON);
    failureBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id LJSON){
        //NSLog(@"|| Loopjoy || : Connection did fail with error: %@",[error localizedDescription]);
    };

   LJAFLJSONRequestOperation *reviewAFRequest = [LJAFLJSONRequestOperation LJSONRequestOperationWithRequest:[[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/paypal/review?item_id=%@&token=%@",_LJ_BASE_URL,_item.product_id,_checkoutToken]]] success:successBlock failure:failureBlock];

    [reviewAFRequest start];
}


//This will get attached to confirm button 
-(void)confirmPayPalCheckout{
    
    [formView addSubview:_activityIndicator];
    [_activityIndicator startAnimating];
    
    
    //On Success Block
    void (^success)(NSURLRequest *request, NSHTTPURLResponse *response, id LJSON);
    success = ^(NSURLRequest *request, NSHTTPURLResponse *response, id LJSON){
        NSDictionary *orderApproval = [NSDictionary dictionaryWithDictionary:LJSON];
        NSString *orderSuccess = [orderApproval objectForKey:@"success"];
        NSString *orderMessage = [orderApproval objectForKey:@"message"];
        NSLog(@"Order Success: %@",orderSuccess);
                
        //Setup view Here and push view
        
        NSString *confText;
        confText = orderMessage;
        
        [[formView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        UILabel *confLabel = [[UILabel alloc] init];
        confLabel.text = confText;
        confLabel.numberOfLines = 0;
        confLabel.lineBreakMode = UILineBreakModeClip;
        confLabel.textColor = [UIColor colorWithRed:.16 green:.16 blue:.16 alpha:1];
        confLabel.textAlignment = UITextAlignmentCenter;
        confLabel.backgroundColor = [UIColor clearColor];
        
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            UIFont *confTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:28];
            CGSize confTextSize = [confText sizeWithFont:confTextFont constrainedToSize:CGSizeMake(570, 290) lineBreakMode:UILineBreakModeWordWrap];
            confLabel.font = confTextFont;
            confLabel.frame = CGRectMake((formView.frame.size.width - confTextSize.width)/2,220,440,290);
        }
        else{
            UIFont *confTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
            confLabel.font = confTextFont;
            CGSize confTextSize = [confText sizeWithFont:confTextFont constrainedToSize:CGSizeMake(280, 180) lineBreakMode:UILineBreakModeWordWrap];
            confLabel.frame = CGRectMake((formView.frame.size.width - confTextSize.width)/2,100,280,180);
        }
        
        
            
        UIButton *cancelButton = [self cancelButtonForPosition:_cancelPos withConfirmation:FALSE];
        [formView addSubview:confLabel];
        [formView addSubview:cancelButton];
        
        [_webView removeFromSuperview];
        [_activityIndicator stopAnimating];
        [_activityIndicator removeFromSuperview];
    };
    
    //On Failure Block
    void (^failure)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id LJSON);
    failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id LJSON){
        NSLog(@"|| Loopjoy || : Connection did fail with error: %@",[error localizedDescription]);
    };
    if(!_confirmAttempted){
        _confirmAttempted = TRUE;
    LJAFLJSONRequestOperation *jsonRequest = [LJAFLJSONRequestOperation LJSONRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/paypal/purchase?token=%@&payer_id=%@&item_id=%@",_LJ_BASE_URL,_checkoutToken,_payerID,_item.product_id]]] success:success failure:failure];
    [jsonRequest start];
    }
    else{}
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    [_activityIndicator stopAnimating];
    [_activityIndicator removeFromSuperview];
    UIButton *closeWebView = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [closeWebView addTarget:self action:@selector(closeWebView) forControlEvents:UIControlEventTouchUpInside];
    [closeWebView setTitle:@"Return To App" forState:UIControlStateNormal];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        closeWebView.frame = CGRectMake(_webView.frame.size.width - 162,_webView.frame.size.height - 37, 160.0, 35.0);
    }else{
        closeWebView.frame = CGRectMake(_webView.frame.size.width - 122,_webView.frame.size.height - 22,120,22);
    }
    [_webView addSubview:closeWebView];
    
    if(formView){
    [[formView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [formView removeFromSuperview];
    _webView.backgroundColor = [UIColor blackColor];
    _webView.opaque = YES;
    [_activityIndicator stopAnimating];
    [_activityIndicator removeFromSuperview];
    }
}

-(void)closeWebView{
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ PayPal" action:[[NSString alloc] initWithFormat:@"PayPal view dismissed by User For Item #%@",_item.product_id] label:_developerID value:0 withError:&error]) {
        NSLog(@"error in trackEvent");
    }
    [_webView removeFromSuperview];
    [_activityIndicator removeFromSuperview];
    _webView = nil;
    [self removeFromSuperview];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
	NSString *urlString = [[request.URL absoluteString] lowercaseString];
    
	if (urlString.length > 0) {
		//The PayPal server may add the default port to the URL. This will break our string comparisons. Remove.
		if ([request.URL.port intValue] == 80) {
			urlString = [urlString stringByReplacingOccurrencesOfString:@":80" withString:@""];
		}
		
		if ([urlString rangeOfString:[_cancelURL lowercaseString]].location != NSNotFound) {
			//Destroy WebView and replace earlier views
            [[formView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [_webView removeFromSuperview];
            _webView = nil;
            [self removeFromSuperview];
			return FALSE;
		}
		if ([urlString rangeOfString:[_returnURL lowercaseString]].location != NSNotFound) {
            [self reviewPayPalCheckout];
			return FALSE;
		}
	}
	return TRUE;
}

-(void)dealloc{
    _webView.delegate = nil;
}

- (void)receivedDeviceReferenceToken:(NSString *)token {
	_deviceReferenceToken = token;
    [self setupPayPalCheckout];
}

- (void)couldNotFetchDeviceReferenceToken {
	NSLog(@"DEVICE REFERENCE TOKEN ERROR: %@", [PayPal getPayPalInst].errorMessage);
	_deviceReferenceToken = @"";
    
	[self setupPayPalCheckout];
}

- (void)cancelWithoutConfirm{

        NSError *error;
        if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Modal View" action:[[NSString alloc] initWithFormat:@"Modal View Dismissed By User For Item #%@",_item.product_id] label:_developerID value:0 withError:&error]) {
            NSLog(@"error in trackEvent");
        }
        [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0.0; } completion:^(BOOL finished) {[self removeFromSuperview];}];
}

- (void)cancelWithConfirm{
        UIAlertView *cancelAlert = [[UIAlertView alloc] initWithTitle:@"Leaving?" message:@"Are you sure you want to leave the LoopJoy store?" delegate:self cancelButtonTitle:@"Yes, Cancel" otherButtonTitles:@"No, Stay",nil];
        [cancelAlert show];  
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Yes, Cancel"])
    {
        NSError *error;
        if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Modal View" action:[[NSString alloc] initWithFormat:@"Modal View Dismissed By User For Item #%@",_item.product_id] label:_developerID value:0 withError:&error]) {
            NSLog(@"error in trackEvent");
        }
        [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0.0; } completion:^(BOOL finished) {[self removeFromSuperview];}]; 
    }
    else {}
}




#pragma mark Touch Delegate Implementation
@end
