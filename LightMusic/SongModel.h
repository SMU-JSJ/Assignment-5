//
//  SongModel.h
//  LightMusic
//
//  Created by ch484-mac7 on 3/29/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SongModel : NSObject

+ (SongModel*) sharedInstance;

@property (strong, nonatomic) NSArray *relaxSongs;
@property (strong, nonatomic) NSArray *partySongs;
@property (strong, nonatomic) NSArray *gameSongs;
@property (strong, nonatomic) NSDictionary *songTimes;
@property (strong, nonatomic) NSDictionary *songArtists;

@end
