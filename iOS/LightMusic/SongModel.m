//  Team JSJ - Jordan Kayse, Jessica Yeh, Story Zanetti
//  SongModel.m
//  LightMusic
//
//  Created by ch484-mac7 on 3/29/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import "SongModel.h"

@implementation SongModel

// Instantiates for the shared instance of the Song Model class
+ (SongModel*) sharedInstance {
    static SongModel* _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[SongModel alloc] init];
    });
    
    return _sharedInstance;
}

- (NSArray*)relaxSongs {
    if (!_relaxSongs) {
        _relaxSongs = [NSArray arrayWithObjects:@"Sweet Caroline", @"Keep Holding On", @"Seasons of Love", nil];
    }
    
    return _relaxSongs;
}

- (NSArray*)partySongs {
    if (!_partySongs) {
        _partySongs = [NSArray arrayWithObjects:@"All About That Bass", @"Uptown Funk", @"Jump", nil];
    }
    
    return _partySongs;
}

- (NSArray*)gameSongs {
    if (!_gameSongs) {
        _gameSongs = [NSArray arrayWithObjects:@"Freeze Frame", nil];
    }
    
    return _gameSongs;
}

- (NSDictionary*)songArtists {
    if (!_songArtists) {
        _songArtists = @{
                         @"Jump" : @"The Glee Cast", @"Uptown Funk" : @"The Glee Cast",
                         @"All About That Bass" : @"The Glee Cast", @"Sweet Caroline" : @"The Glee Cast",
                         @"Keep Holding On" : @"The Glee Cast", @"Seasons of Love" : @"The Glee Cast",
                         @"Freeze Frame" : @"The J. Geils Band"
                         };
    }
    
    return _songArtists;
}

- (NSDictionary*)songTimes {
    if (!_songTimes) {
        _songTimes = @{
                       @"Jump" : @236, @"Uptown Funk" : @262,
                       @"All About That Bass" : @189, @"Sweet Caroline" : @119,
                       @"Keep Holding On" : @245, @"Seasons of Love" : @185,
                       @"Freeze Frame" : @237
                       };
    }
    
    return _songTimes;
}

@end
