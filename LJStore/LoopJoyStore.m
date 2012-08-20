//
//  Store.m
//  Store
//
//  Created by Tennyson Hinds on 8/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoopJoyStore.h"
#import "LJNetworkService.h"
#import "JSONKit.h"
#import "LJItem.h"
#import "LJStorePopUpView.h"
#import "TPCompiledResources.h"
#import "PayPal.h"

@interface LoopJoyStore()
    @property(nonatomic,retain) NSMutableDictionary *items;
@end

@implementation LoopJoyStore


@synthesize items;

#pragma mark - Singleton
static LoopJoyStore *_sharedInstance = nil;

+ (LoopJoyStore *)sharedInstance
{
    if (!_sharedInstance)
        _sharedInstance = [[LoopJoyStore alloc] init];
    
    return _sharedInstance;
}

+(void)initWithDevID:(NSString *)devID forEnv:(LJEnvironmentType)envType{
    [[self sharedInstance] initializeWithDevID:devID forEnv:envType];
    [PayPal initializeWithAppID:@"APP-09B355920Y2948247" forEnvironment:ENV_LIVE];
}

-(void)initializeWithDevID:(NSString *)devID forEnv:(LJEnvironmentType)envType
{   
    _developerID = devID;
    _currentEnv = envType;
    _deviceType = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? LJ_DEVICE_TYPE_IPAD : ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) ? LJ_DEVICE_TYPE_IPHONE_RETINA : LJ_DEVICE_TYPE_IPHONE;
    
    
    LJNetworkService *networkService = [[LJNetworkService alloc] initWithAddress:@"http://50.16.220.58/items" withRequestType:URLRequestGET delegate:self];
    
    NSString *initializeStr = [NSString stringWithFormat:@"{\"devID\":\"%@\",\"envType\":\"%@\"}",_developerID,_currentEnv];  
    [networkService setBody:initializeStr];
    [networkService execute];
}

-(UIButton *)getLJButtonForItem:(int)itemID withButtonType:(LJButtonType)buttonType{
    UIButton *purchaseButton = [self getBareButton:buttonType];
    [purchaseButton addTarget:self action:@selector(showModal:) forControlEvents:UIControlEventTouchUpInside];
    purchaseButton.tag = itemID;
    return purchaseButton;
}

-(UIButton *)getLJButtonForItem:(int)itemID withButtonType:(LJButtonType)buttonType andAction:(SEL)select{
    UIButton *purchaseButton = [self getBareButton:buttonType];
    [purchaseButton addTarget:self action:@selector(select) forControlEvents:UIControlEventTouchUpInside];
    purchaseButton.tag = itemID;
    return purchaseButton;
}

-(UIButton *)getLJButtonForItemCarousel:(NSArray *)itemIDs withButtonType:(LJButtonType)buttonType{
    return [[UIButton alloc] init];
}

-(NSString *)getMerchantName{
    return _merchantName;
}

-(UIAlertView *)getLJAlertForItem:(int)itemID withTitle:(NSString *)title andMessage:(NSString *)message{
    UIAlertView *ljAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Check it Out!" otherButtonTitles:nil];
    ljAlert.tag = itemID;
    return ljAlert;
}

-(void)showModal:(UIButton *)sender{
    [self showModalForItem:sender.tag];
}

-(void)showModalForItem:(int)itemID{
    LJItem *storeItem = [items objectForKey:[[NSString alloc] initWithFormat:@"%i",itemID]];
    LJStorePopUpView *popUpStore = [[LJStorePopUpView alloc] initWithItem:storeItem forOrientation:_currentOrientation];
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    popUpStore.alpha = 0.0;
    [mainWindow insertSubview:popUpStore aboveSubview:mainWindow];
    [UIView animateWithDuration:0.2 animations:^{ popUpStore.alpha = 1.0; } completion:^(BOOL finished) {}];
}

-(UIButton *)getBareButton:(LJButtonType)buttonType{
    NSString *buttonTypeName;
    UIButton *bareButton = [UIButton buttonWithType:UIButtonTypeCustom];

    
    if(_deviceType == LJ_DEVICE_TYPE_IPAD){
        CGRect frame = bareButton.frame;
        frame.size = CGSizeMake(99,136);
        frame.origin.x = 660;
        frame.origin.y = 880;
        bareButton.frame = frame;
    }
    else{
        int scale = _deviceType = LJ_DEVICE_TYPE_IPHONE ? 1 : 2;
        CGRect frame = bareButton.frame;
        frame.size = CGSizeMake(60 * scale, 82 * scale);
        frame.origin.x = 240 * scale;
        frame.origin.y = 340 * scale;
        bareButton.frame = frame;
    }
    
    switch (buttonType) {
        case LJ_BUTTON_IPAD_BLACK:
            buttonTypeName = @"lj_buy_now_black_ipad.png";
            break;
        case LJ_BUTTON_IPAD_RED:
            buttonTypeName = @"lj_buy_now_red_ipad.png";
            break;
        case LJ_BUTTON_IPAD_BLUE:
            buttonTypeName = @"lj_buy_now_blue_ipad.png";
            break;
        case LJ_BUTTON_IPAD_YELLOW:
            buttonTypeName = @"lj_buy_now_yellow_ipad.png";
            break;
        case LJ_BUTTON_IPAD_GREEN:
            buttonTypeName = @"lj_buy_now_black_ipad.png";
            break;
        case LJ_BUTTON_IPHONE_BLACK:
            buttonTypeName = @"lj_buy_now_black_iphone.png";
            break;
        case LJ_BUTTON_IPHONE_RED:
            buttonTypeName = @"lj_buy_now_red_iphone.png";
            break;
        case LJ_BUTTON_IPHONE_BLUE:
            buttonTypeName = @"lj_buy_now_blue_iphone.png";
            break;
        case LJ_BUTTON_IPHONE_YELLOW:
            buttonTypeName = @"lj_buy_now_yellow_iphone.png";
            break;
        case LJ_BUTTON_IPHONE_GREEN:
            buttonTypeName = @"lj_buy_now_green_iphone.png";
            break;
        default:
            buttonTypeName = @"lj_buy_now_black_iphone.png";
            break;
    }
    [bareButton setBackgroundImage:TPGetCompiledImage(buttonTypeName) forState:UIControlStateNormal];
    return bareButton;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Check it Out!"])
    {
    }
    [self showModalForItem:alertView.tag];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"did fail in here: %@",[error localizedDescription]);
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    items = [[NSMutableDictionary alloc] init];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *results = [jsonString objectFromJSONString]; //Parses the UTF8 String as JSON 
    
    
    //Results is a JSON Object (an object of an array items => [item1:stuff,item2:stuff]
    //itemArray is the Array [item1:{stuff:1,morestuff:2},item2:{stuff:1,morestuff:2}]
    //item in itemArray iterates through the different items and grabs the primatives by their type
    
    NSArray *itemArray = [results objectForKey:@"items"]; //Loops through the array, high level json wrapper should be named items
    for (NSDictionary *item in itemArray){
        LJItem *itemObj = [[LJItem alloc] init];
        itemObj.product_price = [item objectForKey:@"price"];
        itemObj.product_sku = [item objectForKey:@"sku"]; 
        itemObj.product_name = [item objectForKey:@"name"];
        itemObj.product_desc = [item objectForKey:@"desc"];
        itemObj.product_options = [item objectForKey:@"options"];
        itemObj.product_display_text = [item objectForKey:@"display_text"];
        itemObj.product_id = [item objectForKey:@"id"];

        NSURL *url = [NSURL URLWithString:[item objectForKey:@"image_url"]];
        itemObj.product_image = [UIImage imageWithData: [NSData dataWithContentsOfURL:url]];
        [items setObject:itemObj forKey:[[item objectForKey:@"id"] stringValue]];
    }
    _merchantName = [results objectForKey:@"merchantName"];
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"did receive response ");
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"did finish loading");
}


@end
