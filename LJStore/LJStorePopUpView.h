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

@interface LJStorePopUpView : UIView <PayPalPaymentDelegate, LJTouchUIViewDelegate>{
    LJItem *_item;
    UIImage *_itemImage;
    NSString *_topText;
    
    NSMutableArray *pickerChoices;
    NSString *declaredOptionChoice;

    UIActionSheet *actionSheet;
    
    UIView *formView;
    LJTouchUIView *touchView;
    UIButton *sizeButton;
}
-(id)initWithItem:(LJItem *)item forOrientation:(LJModalOrientation)orientation;
@end