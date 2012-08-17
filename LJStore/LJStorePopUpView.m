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

@implementation LJStorePopUpView


-(id)initWithItem:(LJItem *)item forOrientation:(LJModalOrientation)orientation{
    _item = item;
    if (orientation == LJ_MODAL_HORIZONTAL){
        return [self initWithFrame:CGRectMake(1, 1, 1, 1)];
    }
    else{
        return [self initWithFrame:CGRectMake(1, 1, 1, 1)];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        CGFloat xCenter;
        UILabel *topTextLabel;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            UIImage *backgroundImage = TPGetComipledImage(@"ipad_500x500_background.png");
            formView = [[UIView alloc] initWithFrame:CGRectMake(145,155,backgroundImage.size.height,backgroundImage.size.width)];
            formView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
            formView.alpha = 1;
            
            touchView = [[LJTouchUIView alloc ] initWithFrame:CGRectMake(145,155,backgroundImage.size.height,backgroundImage.size.width)];
            [touchView setDelegate:self];
            
            xCenter = formView.frame.size.width/2;
            
            //Modal Top Text
            NSString *topText = _item.product_display_text;
            UIFont *topTextFont = [UIFont fontWithName:@"Gotham-Black" size:30];
            CGSize textSize = [topText sizeWithFont:topTextFont constrainedToSize:CGSizeMake(420, 80) lineBreakMode:UILineBreakModeWordWrap];
            topTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(xCenter - textSize.width/2, 25, textSize.width,textSize.height)];
            topTextLabel.text = topText;
            topTextLabel.numberOfLines = 0;
            topTextLabel.lineBreakMode = UILineBreakModeWordWrap;
            topTextLabel.textColor = [UIColor whiteColor];
            topTextLabel.font = [UIFont fontWithName:@"Gotham-Black" size:30];
            topTextLabel.textAlignment = UITextAlignmentCenter;
            topTextLabel.backgroundColor = [UIColor clearColor];
            [formView addSubview:topTextLabel];
            
            //Modal Image
            UIImage *modalImage = _item.product_image;
            UIView *modalImageView = [[UIView alloc] initWithFrame:CGRectMake(xCenter - modalImage.size.width/2,topTextLabel.frame.origin.y + topTextLabel.frame.size.height + 30,modalImage.size.width,modalImage.size.height)];
            modalImageView.backgroundColor = [UIColor colorWithPatternImage:modalImage];
            modalImageView.alpha = 1;
            [formView addSubview:modalImageView];

            
            //Paypal Initialization and Button Placement
            [PayPal initializeWithAppID:@"APP-09B355920Y2948247" forEnvironment:ENV_LIVE];
            [PayPal getPayPalInst].shippingEnabled = true;
            UIButton *button = [[PayPal getPayPalInst] getPayButtonWithTarget:self andAction:@selector(payWithPayPal) andButtonType:BUTTON_278x43];
            
            CGRect frame = button.frame;
            frame.origin.x = round((formView.frame.size.width - button.frame.size.width) / 2.);
            frame.origin.y = (modalImageView.frame.size.height + modalImageView.frame.origin.y) + (formView.frame.size.height - (modalImageView.frame.size.height + modalImageView.frame.origin.y))/2 - frame.size.height/2 ; //
            button.frame = frame;
            [formView addSubview:button];
            
        }
        else {
            //iphoneCode goes here.
        }
        
        
        [self addSubview:touchView];
        [self addSubview:formView];
        
    }
    return self;
}

-(void)payWithPayPal{
    [formView removeFromSuperview];
    [self removeFromSuperview];
    formView = nil;
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.subTotal = [NSDecimalNumber decimalNumberWithDecimal:[_item.product_price decimalValue]];
    payment.recipient = @"ruti@loopjoy.com";
    payment.merchantName = [[LoopJoyStore sharedInstance] getMerchantName];
    payment.paymentCurrency = @"USD";
    [[PayPal getPayPalInst] checkoutWithPayment:payment];
}

#pragma mark Touch Delegate Implementation

- (void) uiViewTouched:(BOOL)wasInside
{
    if( wasInside ){
    }
    else{
        [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0.0; } completion:^(BOOL finished) {[self removeFromSuperview];}];
        formView = nil;
    }
}

- (void)paymentSuccessWithKey:(NSString *)payKey andStatus:(PayPalPaymentStatus)paymentStatus{}
- (void)paymentFailedWithCorrelationID:(NSString *)correlationID{}
- (void)paymentCanceled{}
- (void)paymentLibraryExit{}

@end
