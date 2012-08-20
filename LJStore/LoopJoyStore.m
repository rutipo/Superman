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
}

-(void)initializeWithDevID:(NSString *)devID forEnv:(LJEnvironmentType)envType
{   
    _developerID = devID;
    _currentEnv = envType;
    
    LJNetworkService *networkService = [[LJNetworkService alloc] initWithAddress:@"http://50.16.220.58/items" withRequestType:URLRequestGET delegate:self];
    
    NSString *initializeStr = [NSString stringWithFormat:@"{\"devID\":\"%@\",\"envType\":\"%@\"}",_developerID,_currentEnv];  
    [networkService setBody:initializeStr];
    [networkService execute];
}

-(UIButton *)getLJButtonForItem:(int)itemID withButtonType:(LJButtonType)buttonType{
    UIButton *purchaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *buttonTypeName = [self getItemString:buttonType];
    [purchaseButton setBackgroundImage:TPGetCompiledImage(buttonTypeName) forState:UIControlStateNormal];
    [purchaseButton addTarget:self action:@selector(showModal:) forControlEvents:UIControlEventTouchUpInside];
    purchaseButton.tag = itemID;
    return purchaseButton;
}

-(UIButton *)getLJButtonForItem:(int)itemID withButtonType:(LJButtonType)buttonType andAction:(SEL)select{
    UIButton *purchaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *buttonTypeName = [self getItemString:buttonType];
    [purchaseButton setBackgroundImage:TPGetCompiledImage(buttonTypeName) forState:UIControlStateNormal];
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

-(UIWindow *)getLJWindow{
    return _window;
}

-(void)showModal:(UIButton *)sender{
    NSString *itemID = [NSString stringWithFormat:@"%d", sender.tag];
    NSLog(@"Sender tag: %@",itemID);
    LJItem *storeItem = [items objectForKey:@"17"];
    NSLog(@"display text %@",storeItem.product_display_text);
    NSLog(@"devID %@",_developerID);
    NSLog(@"Test of name2: %d", [items count]);
    LJStorePopUpView *popUpStore = [[LJStorePopUpView alloc] initWithItem:storeItem forOrientation:_currentOrientation];
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    popUpStore.alpha = 0.0;
    [mainWindow insertSubview:popUpStore aboveSubview:mainWindow];
    [UIView animateWithDuration:0.2 animations:^{ popUpStore.alpha = 1.0; } completion:^(BOOL finished) {}];
    
    //[popUpStore.window makeKeyAndVisible];
}

-(void)showModalForItem:(NSString *)itemID{
    LJItem *storeItem = [items objectForKey:itemID];
    LJStorePopUpView *popUpStore = [[LJStorePopUpView alloc] initWithItem:storeItem forOrientation:_currentOrientation];
    [[[UIApplication sharedApplication] keyWindow] addSubview:popUpStore];
    
}

-(NSString *)getItemString:(LJButtonType)buttonType{
    NSString *buttonTypeName;
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
            buttonTypeName = @"lj_buy_now_blue_ipone.png";
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
    return buttonTypeName;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"did fail in here: %@",[error localizedDescription]);
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSLog(@"did recieve data");
    //String comes in as Base64 encoding.
    //Translate string to UTF8
    //After translation parse using json
    //Take image that is passed as json and convert it to ui image. 
    //Setup item array as different json classes.
    
    
    //NSString *tempString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]; //Takes data sent as base64 and makes and ascii string of it
    //NSString *jsonString = [NSData base64Decode:tempString]; //Decodes ASCII String under base64 and returns it as UTF8 (unicode) encoded string
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *results = [jsonString objectFromJSONString]; //Parses the UTF8 String as JSON 
    items = [[NSMutableDictionary alloc] init];
    
    //Results is a JSON Object (an object of an array items => [item1:stuff,item2:stuff]
    //itemArray is the Array [item1:{stuff:1,morestuff:2},item2:{stuff:1,morestuff:2}]
    //item in itemArray iterates through the different items and grabs the primatives by their type
    
    NSArray *itemArray = [results objectForKey:@"items"]; //Loops through the array, high level json wrapper should be named items
    NSLog(@"count on array %d",[itemArray count]);
    for (NSDictionary *item in itemArray){
        LJItem *itemObj = [[LJItem alloc] init];
        itemObj.product_price = [item objectForKey:@"price"];
        itemObj.product_sku = [item objectForKey:@"sku"]; 
        itemObj.product_name = [item objectForKey:@"name"];
        itemObj.product_desc = [item objectForKey:@"desc"];
        itemObj.product_options = [item objectForKey:@"options"];
        itemObj.product_display_text = [item objectForKey:@"display_text"];
        NSLog(@"item name: %@",itemObj.product_name);
        NSLog(@"item sku: %@",itemObj.product_sku);
        NSLog(@"item price: %@",itemObj.product_price);
        NSLog(@"item desc: %@",itemObj.product_desc);
        NSLog(@"item options: %@",itemObj.product_options);
        NSLog(@"item display_text: %@",itemObj.product_display_text);

        NSURL *url = [NSURL URLWithString:[item objectForKey:@"image_url"]];
        itemObj.product_image = [UIImage imageWithData: [NSData dataWithContentsOfURL:url]];
        NSLog(@"obj id: %@",[item objectForKey:@"id"]);
        [items setObject:itemObj forKey:[[item objectForKey:@"id"] stringValue]];
    }
    _merchantName = [results objectForKey:@"merchantName"];
    NSLog(@"Test of name: %d", [items count]);
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"did receive response ");
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"did finish loading");
}


@end
