//
//  Store.m
//  Store
//
//  Created by Tennyson Hinds on 8/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoopJoyStore.h"
#import "LJNetworkService.h"
#import "LJSONKit.h"
#import "LJItem.h"
#import "LJStorePopUpView.h"
#import "TPCompiledResources.h"
#import "PayPal.h"
#import "GANTracker.h"
#import "UIDevice+IdentifierAddition.h"
#import "LJAFImageRequestOperation.h"
#import "UIImageView+LJAFNetworking.h"
#import "LJAFHTTPClient.h"


@interface LoopJoyStore(){
    id<LoopJoyStoreDelegate> delegate;
    NSMutableData *recievedData;
}

@property (nonatomic, retain) NSMutableDictionary *items;
@property (nonatomic, retain) id<LoopJoyStoreDelegate> delegate;
@end

@implementation LoopJoyStore


@synthesize items;
@synthesize delegate;
@synthesize _LJ_BASE_URL;

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
}

+(void)initWithAPIKey:(NSString *)apiKey forEnv:(LJEnvironmentType)envType withTarget:(const id<LoopJoyStoreDelegate>)target{
    [[self sharedInstance] initializeWithAPIKey:apiKey forEnv:envType withTarget:target];
}

-(void)initializeWithAPIKey:(NSString *)apiKey forEnv:(LJEnvironmentType)envType withTarget:(const id<LoopJoyStoreDelegate>)target{
    delegate = target;
    [self initializeWithAPIKey:apiKey forEnv:envType];
}

-(void)initializeWithAPIKey:(NSString *)apiKey forEnv:(LJEnvironmentType)envType
{   
    [[GANTracker sharedTracker] startTrackerWithAccountID:kAnalyticsAccountId dispatchPeriod:10 delegate:nil];
    
    _apiKey = [[NSString alloc] initWithString:apiKey];
    _currentEnv = envType;
    _cancelButtonPosition = LJ_CANCEL_BUTTON_POS_TOP_RIGHT;
    _developerID = @"N/A";
    _deviceType = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? LJ_DEVICE_TYPE_IPAD : LJ_DEVICE_TYPE_IPHONE;//([[UIScreen //mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) ? LJ_DEVICE_TYPE_IPHONE_RETINA : LJ_DEVICE_TYPE_IPHONE;
    recievedData = [[NSMutableData alloc] init];
    _LJ_BASE_URL = @"http://loopjoy.com";
    
    //Paypal Initialization -- Depending on environmet
    if(_currentEnv == LJ_ENV_LIVE){
        //[PayPal initializeWithAppID:@"APP-09B355920Y2948247" forEnvironment:ENV_LIVE];
    }
    else{
        //[PayPal initializeWithAppID:@"APP-80W284485P519543T" forEnvironment:ENV_SANDBOX];
    }
    
    NSError *error;
    NSString *logString = [[NSString alloc] initWithFormat:@"Initialize LJStore with apiKey: %@, for device ID: %@, and device type: %@",apiKey,[[UIDevice currentDevice] uniqueDeviceIdentifier],[[UIDevice currentDevice] model]];
    
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Initialize" action:logString label:_developerID value:99 withError:&error]) {
        NSLog(@"error in trackEvent initialize");
    }
    
    

    LJNetworkService *networkService = [[LJNetworkService alloc] initWithAddress:[NSString stringWithFormat:@"%@/developer/items.json",_LJ_BASE_URL] 
                                                                 withRequestType:URLRequestPOST 
                                                                        delegate:self];
    
    NSString *initializeStr = [[NSString alloc] initWithFormat:@"{\"api_key\":\"%@\",\"envType\":\"%@\",\"deviceType\":\"%@\"}",apiKey,envType == LJ_ENV_LIVE ? @"env_live" : @"env_sandbox",[self formatTypeToString:_deviceType]];  
    [networkService setBody:initializeStr];
    [networkService execute];
}

-(UIButton *)getLJButtonForItem:(int)itemID withButtonType:(LJButtonType)buttonType{
    UIButton *purchaseButton = [self getBareButton:buttonType];

    
    [purchaseButton addTarget:self action:@selector(showModal:) forControlEvents:UIControlEventTouchUpInside];
    purchaseButton.tag = itemID;
    
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Get Button" action:[[NSString alloc] initWithFormat:@"Get Button For Item #%d",itemID] label:_developerID value:0 withError:&error]) {
        NSLog(@"error in trackEvent");
    }
    return purchaseButton;
}

-(UIButton *)getLJButtonForItem:(int)itemID withButtonType:(LJButtonType)buttonType andAction:(NSValue *)value{
    UIButton *purchaseButton = [self getBareButton:buttonType];
    
    SEL select;
    
    // Guard against buffer overflow
    if (strcmp([value objCType], @encode(SEL)) == 0) {
        [value getValue:&select];
    }
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

-(LJDeviceType)getDeviceType{
    return _deviceType;
}

-(LJEnvironmentType)getEnvType{
    return _currentEnv;
}

-(LJCancelButtonPosition)getCancelButtonPos{
    return _cancelButtonPosition;
}

-(UIImage *)getDefaultBG{
    return _defaultBackgroundImage;
}

-(UIImage *)getImageForItem:(int)itemID{
    LJItem *storeItem = [items objectForKey:[[NSString alloc] initWithFormat:@"%i",itemID]];
    return storeItem.product_image;
}

-(NSString *)getDisplayTextForItem:(int)itemID{
    LJItem *storeItem = [items objectForKey:[[NSString alloc] initWithFormat:@"%i",itemID]];
    return storeItem.product_display_text;
}

-(NSString *)getSecondaryTextForItem:(int)itemID{
    LJItem *storeItem = [items objectForKey:[[NSString alloc] initWithFormat:@"%i",itemID]];
    return storeItem.description;
}

-(UIAlertView *)getLJAlertForItem:(int)itemID withTitle:(NSString *)title andMessage:(NSString *)message isCancelable:(BOOL)cancelable{
    UIAlertView *ljAlert;
    
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:@"IOS LJ Get Alert" action:[[NSString alloc] initWithFormat:@"Get Alert For Item #%d",itemID] label:_developerID value:cancelable ? 1 : 0 withError:&error]) {
        NSLog(@"error in trackEvent");
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
        NSLog(@"error in trackEvent");
    }
    
    LJItem *storeItem = [items objectForKey:[[NSString alloc] initWithFormat:@"%i",itemID]];
    LJStorePopUpView *popUpStore = [[LJStorePopUpView alloc] initWithItem:storeItem forOrientation:_currentOrientation];
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    popUpStore.alpha = 0.0;
    [mainWindow insertSubview:popUpStore aboveSubview:mainWindow];
    [UIView animateWithDuration:0.2 animations:^{ popUpStore.alpha = 1.0; } completion:^(BOOL finished) {}];
}

-(void)setCancelButtonPostion:(LJCancelButtonPosition)position{
    _cancelButtonPosition = position;
}

-(UIButton *)getBareButton:(LJButtonType)buttonType{
    NSString *buttonTypeName;
    _deviceType = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? LJ_DEVICE_TYPE_IPAD : LJ_DEVICE_TYPE_IPHONE;
    UIButton *bareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if(_deviceType == LJ_DEVICE_TYPE_IPAD){
        CGRect frame = bareButton.frame;
        frame.size = CGSizeMake(99,136);
        frame.origin.x = 645;
        frame.origin.y = 840;
        bareButton.frame = frame;
    }
    else if(_deviceType == LJ_DEVICE_TYPE_IPHONE){
        CGRect frame = bareButton.frame;
        frame.size = CGSizeMake(60,82);
        frame.origin.x = 240;
        frame.origin.y = 360;
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

- (NSString*)formatTypeToString:(LJDeviceType)deviceType {
    NSString *result = nil;
    
    switch(deviceType) {
        case LJ_DEVICE_TYPE_IPAD:
            result = @"IPAD";
            break;
        case LJ_DEVICE_TYPE_IPHONE:
            result = @"IPHONE";
            break;
        case LJ_DEVICE_TYPE_IPHONE_RETINA:
            result = @"IPHONE_RETINA";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
    
    return result;
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
            NSLog(@"error in trackEvent");
        }
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"|| Loopjoy || : Connection did fail with error: %@",[error localizedDescription]);
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [recievedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"|| Loopjoy || : Did receive server response ");
}

-(void)connectionDidFinishLoading:(NSURLConnection *)theConnection{
    NSLog(@"|| Loopjoy || : Did finish loading items");
    LJAFHTTPClient *requestClient = [LJAFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://loopjoy.com/"]];
    
    items = [[NSMutableDictionary alloc] init];
    NSMutableArray *requestArray = [[NSMutableArray alloc] init];
    NSString *jsonString = [[NSString alloc] initWithData:recievedData encoding:NSUTF8StringEncoding];
    NSDictionary *results = [jsonString objectFromLJSONString]; //Parses the UTF8 String as LJSON 
    
    //Results is a LJSON Object (an object of an array items => [item1:stuff,item2:stuff]
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
        
        if ([item objectForKey:@"custom_background_url"]){
            
            //[itemObj.product_background_image setImageWithURL:[NSURL URLWithString:[results objectForKey:@"custom_background_url"]]];
        }
        
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[item objectForKey:@"image_url"]]];
        LJAFImageRequestOperation *imageRequest = [LJAFImageRequestOperation imageRequestOperationWithRequest:urlRequest 
                                                    success:^(UIImage *image){ itemObj.product_image = image;}];
        [requestArray insertObject:imageRequest atIndex:0];
        [items setObject:itemObj forKey:[[item objectForKey:@"id"] stringValue]];
    }
    [requestClient enqueueBatchOfHTTPRequestOperations:requestArray progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations){} completionBlock:^(NSArray *operations){
        if ([delegate respondsToSelector:@selector(loadComplete)]){
            [delegate loadComplete];
        }
    }];
    
    _merchantName = [results objectForKey:@"merchantName"];
    _developerID = [results objectForKey:@"developerID"];
    

    //[_defaultBackgroundImage setImageWithURL:[NSURL URLWithString:[results objectForKey:@"background_image_url"]]];

    [self logItems];
}

-(void)logItems{
    NSLog(@"|| LoopJoy || : Available Items");
    
    for(id key in items) {
        LJItem *item = [items objectForKey:key];
        NSLog(@"=====================");
        NSLog(@"product id: %@",item.product_id);
        NSLog(@"product name: %@",item.product_name);
        NSLog(@"product display text: %@",item.product_display_text);
        NSLog(@"product desc: %@",item.product_desc);
        NSLog(@"product price: %@",item.product_price);
    }
    
    NSLog(@"=====================");
}

@end
