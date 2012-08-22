//
//  LJStorePopUpView.m
//  SudokuRivals
//
//  Created by Tennyson Hinds on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LJStorePopUpView.h"
#import "PayPal.h"
#import "PayPalPayment.h"
#import "LJNetworkService.h"
#import "TPCompiledResources.h"
#import "GANTracker.h"

@implementation LJStorePopUpView


-(id)initWithItem:(LJItem *)item forOrientation:(LJModalOrientation)orientation{
    _item = item;
    _developerID = [[LoopJoyStore sharedInstance] getDeveloperID];
    _orientation = orientation;
    _isRetina = [[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0);

    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //if (orientation == LJ_MODAL_HORIZONTAL){}
    //else {}
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        CGFloat xCenter;
        UILabel *topTextLabel;
        
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            UIImage *backgroundImage = TPGetCompiledImage(@"ipad_500x500_background.png");
            formView = [[UIView alloc] initWithFrame:CGRectMake(145,155,backgroundImage.size.height,backgroundImage.size.width)];
            formView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
            formView.alpha = 1;
            
            touchView = [[LJTouchUIView alloc ] initWithFrame:formView.frame];
            [touchView setDelegate:self];
            
            xCenter = formView.frame.size.width/2;
            
            if(_item == nil){
                UIFont *errorTextFont = [UIFont fontWithName:@"Helvetica" size:30];
                NSString *errorText = @"No connectivity. \n Please try again later.";
                CGSize textSize = [errorText sizeWithFont:errorTextFont constrainedToSize:CGSizeMake(420, 240) lineBreakMode:UILineBreakModeWordWrap];
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
            else {
                //Modal Top Text
                NSString *topText = _item.product_display_text;
                UIFont *topTextFont = [UIFont fontWithName:@"Helvetica" size:30];
                CGSize textSize = [topText sizeWithFont:topTextFont constrainedToSize:CGSizeMake(420, 80) lineBreakMode:UILineBreakModeWordWrap];
                topTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - textSize.width/2, 15, textSize.width,textSize.height)];
                topTextLabel.text = topText;
                topTextLabel.numberOfLines = 0;
                topTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                topTextLabel.textColor = [UIColor whiteColor];
                topTextLabel.font = topTextFont;
                topTextLabel.textAlignment = UITextAlignmentCenter;
                topTextLabel.backgroundColor = [UIColor clearColor];
                [formView addSubview:topTextLabel];
                
                //Modal Image
                UIImage *modalImage = _item.product_image;
                UIView *modalImageView = [[UIView alloc] initWithFrame:CGRectMake(xCenter - modalImage.size.width/2,topTextLabel.frame.origin.y + topTextLabel.frame.size.height + 20,modalImage.size.width,modalImage.size.height)];
                modalImageView.backgroundColor = [UIColor colorWithPatternImage:modalImage];
                modalImageView.alpha = 1;
                [formView addSubview:modalImageView];
                
                
                //Paypal Initialization and Button Placement
                [PayPal initializeWithAppID:@"APP-09B355920Y2948247" forEnvironment:ENV_LIVE];
                [PayPal getPayPalInst].shippingEnabled = true;
                UIButton *button = [[PayPal getPayPalInst] getPayButtonWithTarget:self andAction:@selector(payWithPayPal:) andButtonType:BUTTON_278x43];
                
                
                CGRect frame = button.frame;
                frame.origin.x = round((formView.frame.size.width - button.frame.size.width) / 2.);
                frame.origin.y = (modalImageView.frame.size.height + modalImageView.frame.origin.y) + (formView.frame.size.height - (modalImageView.frame.size.height + modalImageView.frame.origin.y))/2 - frame.size.height/2 -10; //
                button.frame = frame;
                [formView addSubview:button];
                
                //TOS Button
                UIButton *tosButton = [[UIButton alloc] initWithFrame:CGRectMake(xCenter - 100, modalImageView.frame.size.height + modalImageView.frame.origin.y + (modalImageView.frame.size.height + modalImageView.frame.origin.y - button.frame.origin.y)/2 + 20, 200,20)];
                tosButton.backgroundColor = [UIColor colorWithPatternImage:TPGetCompiledImage(@"LJ_tos_ipad.png")];
                [tosButton addTarget:self action:@selector(getTermsOfService) forControlEvents:UIControlEventTouchUpInside];
                [formView addSubview:tosButton];
                
                //Powered By Image
                UIImageView *poweredBy = [[UIImageView alloc] initWithImage:TPGetCompiledImage(@"LJ_loopjoyGift_ipad.png")];
                poweredBy.frame = CGRectMake(25, formView.frame.size.height - 35, 229,26);
                poweredBy.alpha = .6;
                [formView addSubview:poweredBy];
                
            }
        }
        else {

            UIImage *backgroundImage = _isRetina ? TPGetCompiledImage(@"iphone_modal_background_retina.png") : TPGetCompiledImage(@"iphone_modal_background.png");
            //NSLog(@"background image size height and width: %f , %f",backgroundImage.size.height,backgroundImage.size.width); 
            formView = [[UIView alloc] initWithFrame:CGRectMake((self.frame.size.width - backgroundImage.size.width)/2,(self.frame.size.height - backgroundImage.size.height)/2,backgroundImage.size.width,backgroundImage.size.height)];
            //NSLog(@"formView.x, formView.y: %f %f",formView.frame.origin.x,formView.frame.origin.y);
            //NSLog(@"formView.width, formView.height: %f %f",formView.frame.size.width,formView.frame.size.height);
            
            formView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
            formView.alpha = 1;
            
            touchView = [[LJTouchUIView alloc ] initWithFrame:formView.frame];
            [touchView setDelegate:self];
            
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
                UIImage *modalImage = _item.product_image;
                UIImageView *modalImageView = [[UIImageView alloc] initWithImage:modalImage];
                modalImageView.frame = CGRectMake(xCenter - 180/2,topTextLabel.frame.origin.y + topTextLabel.frame.size.height + 14,180,200);
                modalImageView.alpha = 1;
                [formView addSubview:modalImageView];
                
                
                //Paypal Button Placement
                [PayPal getPayPalInst].shippingEnabled = true;
                UIButton *button = [[PayPal getPayPalInst] getPayButtonWithTarget:self andAction:@selector(payWithPayPal:) andButtonType:BUTTON_194x37];
                
                
                CGRect frame = button.frame;
                frame.origin.x = round((formView.frame.size.width - button.frame.size.width) / 2.);
                frame.origin.y = (modalImageView.frame.size.height + modalImageView.frame.origin.y) + (formView.frame.size.height - (modalImageView.frame.size.height + modalImageView.frame.origin.y))/2 - frame.size.height/2 - 5;
                button.frame = frame;
                [formView addSubview:button];
                    
                //TOS Button
                UIButton *tosButton = [[UIButton alloc] initWithFrame:CGRectMake(xCenter - 65, modalImageView.frame.size.height + modalImageView.frame.origin.y + (modalImageView.frame.size.height + modalImageView.frame.origin.y - button.frame.origin.y)/2 + 16, 130,13)];
                tosButton.backgroundColor = [UIColor colorWithPatternImage:TPGetCompiledImage(@"LJ_tos_iphone.png")];
                [tosButton addTarget:self action:@selector(getTermsOfService) forControlEvents:UIControlEventTouchUpInside];
                [formView addSubview:tosButton];
                    
                //Powered By Image
                UIImageView *poweredBy = [[UIImageView alloc] initWithImage:TPGetCompiledImage(@"LJ_loopjoyGift_iphone.png")];
                poweredBy.frame = CGRectMake(10, formView.frame.size.height - 24, 103,12);
                poweredBy.alpha = .8;
                [formView addSubview:poweredBy];
                
            }
        }
        
        
        [self addSubview:touchView];
        [self addSubview:formView];
        
    }
    return self;
}

-(void)payWithPayPal:(id)sender{
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Modal View" action:[[NSString alloc] initWithFormat:@"Paypal Checkout Started For Item #%@",_item.product_id] label:@"" value:0 withError:&error]) {
        //NSLog(@"error in trackEvent");
    }
    [formView removeFromSuperview];
    [self removeFromSuperview];
    formView = nil;
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.recipient = @"ruti@loopjoy.com";
    payment.merchantName = [[LoopJoyStore sharedInstance] getMerchantName];
    payment.subTotal = [[NSDecimalNumber alloc] initWithDouble:[_item.product_price doubleValue]];
    payment.paymentCurrency = @"USD";
    [[PayPal getPayPalInst] checkoutWithPayment:payment];
}

-(void)getTermsOfService{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://loopjoy.com"]];
}

#pragma mark Touch Delegate Implementation

- (void) uiViewTouched:(BOOL)wasInside
{
    if( wasInside ){
    }
    else{
        NSError *error;
        if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Modal View" action:[[NSString alloc] initWithFormat:@"Modal View Dismissed By User For Item #%@",_item.product_id] label:_developerID value:0 withError:&error]) {
            //NSLog(@"error in trackEvent");
        }
        [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0.0; } completion:^(BOOL finished) {[self removeFromSuperview];}];
        formView = nil;
    }
}

- (void)paymentSuccessWithKey:(NSString *)payKey andStatus:(PayPalPaymentStatus)paymentStatus{
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ PayPal" action:[[NSString alloc] initWithFormat:@"Paypal Completed For Item #%@",_item.product_id] label:_developerID value:0 withError:&error]) {
        //NSLog(@"error in trackEvent");
    }}
- (void)paymentFailedWithCorrelationID:(NSString *)correlationID{}
- (void)paymentCanceled{
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ PayPal" action:[[NSString alloc] initWithFormat:@"Paypal Checkout Cenceled For Item #%@",_item.product_id] label:_developerID value:0 withError:&error]) {
        //NSLog(@"error in trackEvent");
    }}
- (void)paymentLibraryExit{}

@end
