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
#import "GANTracker.h"
#import "UIDevice+IdentifierAddition.h"

@interface LoopJoyStore()
    @property(nonatomic,retain) NSMutableDictionary *items;
@end

@implementation LoopJoyStore


@synthesize items;

#pragma mark - Singleton
static LoopJoyStore *_sharedInstance = nil;
static NSString* const kAnalyticsAccountId = @"UA-34240472-1";

+ (LoopJoyStore *)sharedInstance
{
    if (!_sharedInstance)
        _sharedInstance = [[LoopJoyStore alloc] init];
    
    return _sharedInstance;
}

+(void)initWithAPIKey:(NSString *)apiKey forEnv:(LJEnvironmentType)envType{
    [[self sharedInstance] initializeWithAPIKey:apiKey forEnv:envType];
    [PayPal initializeWithAppID:@"APP-09B355920Y2948247" forEnvironment:ENV_LIVE];
    [[GANTracker sharedTracker] startTrackerWithAccountID:kAnalyticsAccountId dispatchPeriod:10 delegate:nil];
}

-(void)initializeWithAPIKey:(NSString *)apiKey forEnv:(LJEnvironmentType)envType
{   
    _apiKey = apiKey;
    _currentEnv = envType;
    _developerID = @"N/A";
    _deviceType = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? LJ_DEVICE_TYPE_IPAD : ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) ? LJ_DEVICE_TYPE_IPHONE_RETINA : LJ_DEVICE_TYPE_IPHONE;
    
    NSError *error;
    NSString *logString = [[NSString alloc] initWithFormat:@"Initialize LJSTore with apiKey: %@, for device ID: %@, and device type: %@",apiKey,[[UIDevice currentDevice] uniqueDeviceIdentifier],[[UIDevice currentDevice] model]];
    
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Initialize" action:logString label:_developerID value:99 withError:&error]) {
        //NSLog(@"error in trackEvent initialize");
    }

    LJNetworkService *networkService = [[LJNetworkService alloc] initWithAddress:@"http://50.16.220.58/developer/items.json" 
                                                                 withRequestType:URLRequestPOST 
                                                                        delegate:self];
    
    NSString *initializeStr = [NSString stringWithFormat:@"{\"api_key\":\"%@\",\"envType\":\"%@\"}",_apiKey,_currentEnv];  
    [networkService setBody:initializeStr];
    [networkService execute];
}

-(UIButton *)getLJButtonForItem:(int)itemID withButtonType:(LJButtonType)buttonType{
    UIButton *purchaseButton = [self getBareButton:buttonType];
    [purchaseButton addTarget:self action:@selectort(showModal:) forControlEvents:UIControlEventTouchUpInside];
    purchaseButton.tag = itemID;
    
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Get Button" action:[[NSString alloc] initWithFormat:@"Get Button For Item #%d",itemID] label:_developerID value:0 withError:&error]) {
        //NSLog(@"error in trackEvent");
    }
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

-(NSString *)getDeveloperID{
    return _developerID;
}

-(UIAlertView *)getLJAlertForItem:(int)itemID withTitle:(NSString *)title andMessage:(NSString *)message isCancelable:(BOOL)cancelable{
    UIAlertView *ljAlert;
    
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Get Alert" action:[[NSString alloc] initWithFormat:@"Get Alert For Item #%d",itemID] label:_developerID value:cancelable ? 1 : 0 withError:&error]) {
        //NSLog(@"error in trackEvent");
    }
    
    if(cancelable){
        ljAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Check it Out!",nil];
    }
    else{
        ljAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Check it Out!" otherButtonTitles:nil];
    }
    
    ljAlert.tag = itemID;
    return ljAlert;
}

-(void)showModal:(UIButton *)sender{
    [self showModalForItem:sender.tag];
}

-(void)showModalForItem:(int)itemID{
    
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Show Modal" action:[[NSString alloc] initWithFormat:@"Modal Shown For Item #%d",itemID] label:_developerID value:0 withError:&error]) {
        //NSLog(@"error in trackEvent");
    }
    
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
        frame.size = CGSizeMake(99,150);
        frame.origin.x = 640;
        frame.origin.y = 860;
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
        case LJ_BUTTON_IPAD_YELLOW_NO_LINE:
            buttonTypeName = @"lj_buy_now_yellow_no_line_ipad.png";
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
        [self showModalForItem:alertView.tag];
    }
    else {
        NSError *error;
        if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Show Alert" action:[[NSString alloc] initWithFormat:@"Modal Exited For Item #%d",alertView.tag] label:_developerID value:0 withError:&error]) {
            //NSLog(@"error in trackEvent");
        }
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    //NSLog(@"did fail in here: %@",[error localizedDescription]);
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
    _developerID = [results objectForKey:@"developerID"];
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    //NSLog(@"did receive response ");
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //NSLog(@"did finish loading");
}


@end
