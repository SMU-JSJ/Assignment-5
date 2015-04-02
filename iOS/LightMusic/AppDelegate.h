//
//  AppDelegate.h
//  Light Music
//
//  Created by Cheong on 15/8/12.
//  Copyright (c) 2012 RedBear Lab., All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,BLEDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BLE* bleShield;


@end
