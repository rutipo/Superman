//
//  LJStorePopUpView.m
//  SudokuRivals
//
//  Created by Tennyson Hinds on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LJStorePopUpView.h"
#import "TPCompiledResources.h"
#import "GANTracker.h"
#import "UIDevice+IdentifierAddition.h"
#import "AFJSONRequestOperation.h"
#import "JSONKit.h"
#import "PayPal.h"



@implementation LJStorePopUpView

@synthesize checkoutRequest;
@synthesize reviewRequest;
@synthesize confirmRequest;
@synthesize setupRequest;
@synthesize reviewAFRequest;


-(id)initWithItem:(LJItem *)item forOrientation:(LJModalOrientation)orientation{
    _item = item;
    _developerID = [[LoopJoyStore sharedInstance] getDeveloperID];
    _orientation = orientation;
    _appID = [[LoopJoyStore sharedInstance] getEnvType] == LJ_ENV_LIVE ? @"APP-09B355920Y2948247" : @"APP-80W284485P519543T";
    _isRetina = [[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0);
    _receivedData = [[NSMutableData alloc] init];
    
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
            
            touchView = [[LJTouchUIView alloc] initWithFrame:formView.frame];
            [touchView setDelegate:self];
            
            _webView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            _webView.delegate = self;
            
            xCenter = formView.frame.size.width/2;
            
            
            
            //Show error message if we are unable to load an item.
            if(_item == nil){
                UIFont *errorTextFont = [UIFont fontWithName:@"Helvetica" size:30];
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
                UIFont *topTextFont = [UIFont fontWithName:@"Helvetica" size:30];
                CGSize textSize = [topText sizeWithFont:topTextFont constrainedToSize:CGSizeMake(420, 80) lineBreakMode:UILineBreakModeWordWrap];
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
                UIImageView *modalImageView = [[UIImageView alloc] initWithImage:_item.product_image];
                CGFloat imageWidth = modalImageView.image.size.width > 360 ? 360 : modalImageView.image.size.width;
                CGFloat imageHeight = modalImageView.image.size.height > 450 ? 450 : modalImageView.image.size.height;
                CGRect imageFrame = modalImageView.frame;
                imageFrame.origin.x = xCenter - imageWidth/2;
                imageFrame.origin.y = topTextLabel.frame.origin.y + topTextLabel.frame.size.height + 20;
                imageFrame.size.width = imageWidth;
                imageFrame.size.height = imageHeight;
                modalImageView.frame = imageFrame;

                modalImageView.alpha = 1;
                [formView addSubview:modalImageView];
                
                
               
                //Paypal Initialization and Button Placement
                UIButton *button = [[PayPal getPayPalInst] getPayButtonWithTarget:self andAction:@selector(startPaypalCheckout) andButtonType:BUTTON_278x43];
                CGRect frame = button.frame;
                frame.origin.x = round((formView.frame.size.width - button.frame.size.width) / 2.);
                frame.origin.y = (modalImageView.frame.size.height + modalImageView.frame.origin.y) + (formView.frame.size.height - (modalImageView.frame.size.height + modalImageView.frame.origin.y))/2 - frame.size.height/2 -10; //
                button.frame = frame;
                //[formView addSubview:button];
                
             
            }
        }
        else {
            
            backgroundImage = TPGetCompiledImage(@"background_iphone.png");
            formView = [[UIImageView alloc] initWithFrame:CGRectMake((frame.size.width - backgroundImage.size.width)/2,(frame.size.height - backgroundImage.size.height)/2,backgroundImage.size.width,backgroundImage.size.height)];
            formView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
            formView.alpha = 1;
            
            touchView = [[LJTouchUIView alloc ] initWithFrame:formView.frame];
            [touchView setDelegate:self];
            
            _webView = [[UIWebView alloc] initWithFrame:formView.frame];
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
                UIFont *topTextFont = [UIFont fontWithName:@"Helvetica" size:24];
                CGSize textSize = [topText sizeWithFont:topTextFont constrainedToSize:CGSizeMake(240, 60) lineBreakMode:UILineBreakModeWordWrap];
                topTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - textSize.width/2, 12, textSize.width,textSize.height)];
                topTextLabel.text = topText;
                topTextLabel.numberOfLines = 0;
                topTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                topTextLabel.textColor = [UIColor whiteColor];
                topTextLabel.font = topTextFont;
                topTextLabel.textAlignment = UITextAlignmentCenter;
                topTextLabel.backgroundColor = [UIColor clearColor];
                [formView addSubview:topTextLabel];
                
                
                //Modal Image
                UIImageView *modalImageView = [[UIImageView alloc] initWithImage:_item.product_image];
                modalImageView.frame = CGRectMake(xCenter - 180/2,topTextLabel.frame.origin.y + topTextLabel.frame.size.height + 14,140,140);
                modalImageView.alpha = 1;
                [formView addSubview:modalImageView];
                
                
                //Paypal Button Placement
                UIButton *button = [[PayPal getPayPalInst] getPayButtonWithTarget:self andAction:@selector(startPaypalCheckout) andButtonType:BUTTON_152x33];
                CGRect frame = button.frame;
                frame.origin.x = round((formView.frame.size.width - button.frame.size.width) / 2.);
                frame.origin.y = (modalImageView.frame.size.height + modalImageView.frame.origin.y) + (formView.frame.size.height - (modalImageView.frame.size.height + modalImageView.frame.origin.y))/2 - frame.size.height/2 - 5;
                frame.size = CGSizeMake(152,33);
                button.frame = frame;
                //[formView addSubview:button];
                
            }
        }
        [self addSubview:touchView];
        [self addSubview:formView];
    }
    return self;
}



-(void)setupPayPalCheckout{

    //On Success Block
    void (^success)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON);
    success = ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
        NSDictionary *results = [NSDictionary dictionaryWithDictionary:JSON];
        NSDictionary *purchaseParams = [results objectForKey:@"purchase_params"];
        _cancelURL = [purchaseParams objectForKey:@"cancel_return_url"];
        _returnURL = [purchaseParams objectForKey:@"return_url"];
        _checkoutToken = [results objectForKey:@"token"]; 
        NSLog(@"Cancel URL: %@",_cancelURL);
        NSLog(@"Return URL: %@",_returnURL);
        NSLog(@"Checkout Token: %@",_checkoutToken);
        _checkoutURL = [NSString stringWithFormat:@"%@&drt=%@",[results objectForKey:@"redirect_url"],_deviceReferenceToken];
        NSLog(@"Checkout URL: %@",_checkoutURL);
    };
    
    //On Failure Block
    void (^failure)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON);
    failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        NSLog(@"|| Loopjoy || : Connection did fail with error: %@",[error localizedDescription]);
    };
    
    
    AFJSONRequestOperation *jsonRequest = [AFJSONRequestOperation JSONRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://localhost:3000/paypal/checkout?item_id=%@&UUID=%@&env_type=%@",_item.product_id,[[UIDevice currentDevice] uniqueDeviceIdentifier],[[LoopJoyStore sharedInstance] getEnvType] == LJ_ENV_LIVE ? @"LJ_ENV_LIVE" : @"LJ_ENV_BETA"]]] success:success failure:failure];
    [jsonRequest start];
    
}

-(void)startPaypalCheckout{
    NSLog(@"Checkout URL: %@",_checkoutURL);
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_checkoutURL]]];
    [self addSubview:_webView];
}


-(void)reviewPayPalCheckout{
    
    


    
    //On Success Block
    void (^successBlock)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON);
    successBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
        [[formView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        NSDictionary *orderDetails = [NSDictionary dictionaryWithDictionary:JSON];
        NSDictionary *address = [orderDetails objectForKey:@"shipping_address"];
        NSDictionary *gatewayDetails = [orderDetails objectForKey:@"gateway_details"];
        
        //Gateway Details
        _payerID = [gatewayDetails objectForKey:@"payer_id"];
        _checkoutToken = [gatewayDetails objectForKey:@"token"];
        
        //Order Details
        NSString *email = [orderDetails objectForKey:@"email"];
        NSString *subtotal = [NSString stringWithFormat:@"Subtotal %@: ",[orderDetails objectForKey:@"subtotal"]];
        NSString *shipping = [NSString stringWithFormat:@"Shipping %@: ",[orderDetails objectForKey:@"shipping"]];
        NSString *total = [NSString stringWithFormat:@"Total %@: ",[orderDetails objectForKey:@"total"]];
        
        //Address Details
        NSString *name = [address objectForKey:@"name"];
        NSString *company = [address objectForKey:@"company"];
        NSString *address1 = [address objectForKey:@"address1"];
        NSString *address2 = [address objectForKey:@"address2"];
        NSString *address3 = [NSString stringWithFormat:@"%@, %@ %@ %@",[address objectForKey:@"city"],[address objectForKey:@"state"],[address objectForKey:@"country"], [address objectForKey:@"zip"]];
        
        //Buyer Details
        NSString *nameString = [NSString stringWithFormat:@"Name: %@",name];
        NSString *emailString = [NSString stringWithFormat:@"Email: %@",email];
        NSString *phoneString;
        if(!([address objectForKey:@"phone"]==(id) [NSNull null] || [[address objectForKey:@"phone"] length]==0 || [address objectForKey:@"phone"]==@"")){
            phoneString = [NSString stringWithFormat:@"Phone: %@", [address objectForKey:@"phone"]];
        }
        
        //Setup Information Arrays
        NSArray *addressArray = [NSArray arrayWithObjects:name,company,address1,address2,address3, nil];
        NSArray *orderArray = [NSArray arrayWithObjects:email,subtotal,shipping,total,nil];
        NSArray *buyerArray = [NSArray arrayWithObjects:nameString,emailString,phoneString,nil];

        //Order Confirmation Header
        UIFont *textFont = [UIFont fontWithName:@"Helvetica" size:24];
        NSString *textString = @"Order Confirmation";
        CGSize textSize = [textString sizeWithFont:textFont constrainedToSize:CGSizeMake(240, 180) lineBreakMode:UILineBreakModeWordWrap];
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(formView.frame.size.width/2 - textSize.width/2,20, textSize.width,textSize.height)];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.text = textString;
        textLabel.font = textFont;
        [formView addSubview:textLabel];
        
        
        //Shipping Address Header
        textFont = [UIFont fontWithName:@"Helvetica" size:20];
        textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 60, 300, 25)];
        textLabel.text = @"Shipping Address: ";
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = textFont;
        [formView addSubview:textLabel];
        
        //Shipping Information
        int labelSpacer = 20;
        for (id string in addressArray){
            if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30,65 + labelSpacer, 300, 25)];
            textLabel.text = [NSString stringWithString:string];
            textLabel.numberOfLines = 0;
            textLabel.lineBreakMode = UILineBreakModeWordWrap;
            textLabel.textColor = [UIColor blackColor];
            textLabel.textAlignment = UITextAlignmentLeft;
            textLabel.backgroundColor = [UIColor clearColor];
            labelSpacer += 20;
            [formView addSubview:textLabel];
            }
        }
        labelSpacer += 40;
        
        //Buyer Information Header
        textFont = [UIFont fontWithName:@"Helvetica" size:20];
        textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 60, 300, 25)];
        textLabel.text = @"Buyer Information: ";
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = textFont;
        [formView addSubview:textLabel];
        

        for (id string in buyerArray){
            if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
                textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30,65 + labelSpacer, 300, 25)];
                textLabel.text = [NSString stringWithString:string];
                textLabel.numberOfLines = 0;
                textLabel.lineBreakMode = UILineBreakModeWordWrap;
                textLabel.textColor = [UIColor blackColor];
                textLabel.textAlignment = UITextAlignmentLeft;
                textLabel.backgroundColor = [UIColor clearColor];
                labelSpacer += 20;
                [formView addSubview:textLabel];
            }
        }
        labelSpacer += 40;
        
        //Checkout Information Header
        textFont = [UIFont fontWithName:@"Helvetica" size:20];
        textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 60, 300, 25)];
        textLabel.text = @"Invoice: ";
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = textFont;
        [formView addSubview:textLabel];
        
        
        for (id string in orderArray){
            if(!(string==(id) [NSNull null] || [string length]==0 || string==@"")){
                textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30,65 + labelSpacer, 300, 25)];
                textLabel.text = [NSString stringWithString:string];
                textLabel.numberOfLines = 0;
                textLabel.lineBreakMode = UILineBreakModeWordWrap;
                textLabel.textColor = [UIColor blackColor];
                textLabel.textAlignment = UITextAlignmentLeft;
                textLabel.backgroundColor = [UIColor clearColor];
                labelSpacer += 20;
                [formView addSubview:textLabel];
            }
        }
        
        
        
        [_webView removeFromSuperview];
        
        //Setup view Here and push view
        
        
    };

    //On Failure Block
    void (^failureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON);
    failureBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        //NSLog(@"|| Loopjoy || : Connection did fail with error: %@",[error localizedDescription]);
    };

   reviewAFRequest = [AFJSONRequestOperation JSONRequestOperationWithRequest:[[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://localhost:3000/paypal/review?item_id=%@&token=%@",_item.product_id,_checkoutToken]]] success:successBlock failure:failureBlock];

    [reviewAFRequest start];
    NSLog(@"No Crash");
}


//This will get attached to confirm button 
-(void)confirmPayPalCheckout{
    confirmRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:3000/paypal/purchase"]];
    [confirmRequest setHTTPBody:[NSString stringWithFormat:@"{\"payer_id\":\"%@\",\"token\":\"%@\"}",_payerID,_checkoutToken]];
    [confirmRequest setHTTPMethod:@"POST"];
    [confirmRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    //On Success Block
    void (^success)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON);
    success = ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
        NSDictionary *orderApproval = [NSDictionary dictionaryWithDictionary:JSON];
        NSString *orderSuccess = [orderApproval objectForKey:@"success"];
        
        [[formView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_webView removeFromSuperview];
        
        //Setup view Here and push view
        if(orderSuccess == @"YES"){} else{}
    };
    
    //On Failure Block
    void (^failure)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON);
    failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        NSLog(@"|| Loopjoy || : Connection did fail with error: %@",[error localizedDescription]);
    };
    
    
    AFJSONRequestOperation *jsonRequest = [AFJSONRequestOperation JSONRequestOperationWithRequest:confirmRequest success:success failure:failure];
    [jsonRequest start];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
	NSString *urlString = [[request.URL absoluteString] lowercaseString];
    
	if (urlString.length > 0) {
		//The PayPal server may add the default port to the URL. This will break our string comparisons. Remove.
		if ([request.URL.port intValue] == 80) {
			urlString = [urlString stringByReplacingOccurrencesOfString:@":80" withString:@""];
		}
		
		if ([urlString rangeOfString:[_cancelURL lowercaseString]].location != NSNotFound) {
            NSLog(@"Cancel");
			//Destroy WebView and replace earlier views
            [_webView removeFromSuperview];
            _webView = nil;
            //[self addSubview:touchView];
            //[self addSubview:formView];
			return FALSE;
		}
		if ([urlString rangeOfString:[_returnURL lowercaseString]].location != NSNotFound) {
            NSLog(@"Return");
            [self reviewPayPalCheckout];
			return FALSE;
		}
	}
	return TRUE;
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


#pragma mark Touch Delegate Implementation

- (void) uiViewTouched:(BOOL)wasInside
{
    if( wasInside ){
    }
    else{
        NSError *error;
        if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Modal View" action:[[NSString alloc] initWithFormat:@"Modal View Dismissed By User For Item #%@",_item.product_id] label:_developerID value:0 withError:&error]) {
            NSLog(@"error in trackEvent");
        }
        [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0.0; } completion:^(BOOL finished) {[self removeFromSuperview];}];
        formView = nil;
    }
}

@end
