//
//  ViewController.h
//  LightMusic
//
//  Created by ch484-mac7 on 3/29/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

typedef enum musicMode {
    RELAX,
    PARTY,
    GAME
} MusicMode;

typedef enum connectedState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED
} ConnectedState;

@end

