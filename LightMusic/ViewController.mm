//
//  ViewController.m
//  LightMusic
//
//  Created by ch484-mac7 on 3/29/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import "ViewController.h"
#import "Novocaine.h"
#import "AudioFileReader.h"
#import <MediaPlayer/MediaPlayer.h>

#define kBufferLength 4096

@interface ViewController ()


@property (weak, nonatomic) IBOutlet UIButton *relaxButton;
@property (weak, nonatomic) IBOutlet UIButton *relaxLabel;
@property (weak, nonatomic) IBOutlet UIButton *partyButton;
@property (weak, nonatomic) IBOutlet UIButton *partyLabel;
@property (weak, nonatomic) IBOutlet UIButton *gameButton;
@property (weak, nonatomic) IBOutlet UIButton *gameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

@property (strong, nonatomic) Novocaine *audioManager;
@property (nonatomic) float *audioData;

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSArray *descriptionArray;
@property (strong, nonatomic) NSArray *relaxSongs;
@property (strong, nonatomic) NSArray *partySongs;
@property (strong, nonatomic) NSArray *gameSongs;
@property (strong, nonatomic) NSDictionary *songTimes;
@property (strong, nonatomic) NSDictionary *songArtists;

@property (nonatomic) MusicMode mode;
@property (nonatomic) BOOL playing;
@property (nonatomic) int songIndex;

@end

@implementation ViewController

AudioFileReader *fileReader;

// Lazily instantiate

- (Novocaine*)audioManager {
    if (!_audioManager) {
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

- (float*)audioData {
    if (!_audioData) {
        _audioData = (float*)calloc(kBufferLength, sizeof(float));
    }
    return _audioData;
}

- (NSArray *)descriptionArray {
    if (!_descriptionArray) {
        _descriptionArray = [NSArray arrayWithObjects:
            @"Music gets quieter and more mellow as the room gets darker.",
            @"Music gets louder as the party gets darker, and the green light blinks faster.",
            @"Lights are off, the music plays. Lights on, the music stops and you freeze!",
            nil];
    }
    
    return _descriptionArray;
}

- (NSArray *)relaxSongs {
    if (!_relaxSongs) {
        _relaxSongs = [NSArray arrayWithObjects:@"Sweet Caroline", @"Keep Holding On", @"Seasons Of Love", nil];
    }
    
    return _relaxSongs;
}

- (NSArray *)partySongs {
    if (!_partySongs) {
        _partySongs = [NSArray arrayWithObjects:@"All About That Bass", @"Uptown Funk", @"Jump", nil];
    }
    
    return _partySongs;
}

- (NSArray *)gameSongs {
    if (!_gameSongs) {
        _gameSongs = [NSArray arrayWithObjects:@"Freeze Frame", nil];
    }
    
    return _gameSongs;
}

- (NSDictionary *)songArtists {
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

- (NSDictionary *)songTimes {
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

- (void)setMode:(MusicMode)mode {
    _mode = mode;
    [self updateMode];
    [self setAudioOutput];
    [self createTimer];
}

- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    if (playing) {
        [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"]
                              forState:UIControlStateNormal];
        [fileReader play];
        if (![self.audioManager playing])
            [self.audioManager play];
    } else {
        [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"]
                              forState:UIControlStateNormal];
        [fileReader pause];
        if ([self.audioManager playing])
            [self.audioManager pause];
    }
}

- (void)setSongIndex:(int)songIndex {
    if (self.mode == RELAX) {
        songIndex = songIndex % [self.relaxSongs count];
    } else if (self.mode == PARTY) {
        songIndex = songIndex % [self.partySongs count];
    } else if (self.mode == GAME) {
        songIndex = songIndex % [self.gameSongs count];
    }
    
    _songIndex = songIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.volumeSlider.value = 1.0;
    
    [self setAudioOutput];
    [self createTimer];
    
    self.playing = YES;
    // handle what happens if the view gets loaded again
//    if(![self.audioManager playing])
//        [self.audioManager play];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.audioManager pause]; // just pause the playing
    // audio manager is a singleton class, so we do not need to
    // tear it down, in case some other controller may want to use it
    
    _audioManager = nil;
    
    [self.timer invalidate];
}

- (void)createTimer {
    NSLog(@"create timer");
    
    if ([self.timer isValid]) {
        NSLog(@"invalidate timer");
        [self.timer invalidate];
    }
    
    NSString* songName = [self getSongAtIndex:self.songIndex];
    NSNumber* timerNum = (NSNumber *)[self.songTimes valueForKey:songName];
    NSInteger timerInt = [timerNum integerValue];
    
    NSLog(@"%ld", timerInt);
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timerInt
                                                  target:self
                                                selector:@selector(setAudioOutput)
                                                userInfo:nil
                                                 repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    self.songIndex = self.songIndex + 1;
}

- (void)setAudioOutput {
    NSString* songName = [self getSongAtIndex:self.songIndex];
    self.songTitleLabel.text = songName;
    self.artistLabel.text = (NSString *)[self.songArtists valueForKey:songName];
    
    NSLog(@"Song index = %d\nSong name = %@", self.songIndex, songName);
    // load samples from an mp3 file and set them to output to the speakers!!
    NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:songName
                                                  withExtension:@"mp3"];
    
    fileReader = [[AudioFileReader alloc]
                  initWithAudioFileURL: inputFileURL
                  samplingRate: self.audioManager.samplingRate
                  numChannels: self.audioManager.numOutputChannels];
    
    
    //[fileReader play];
    fileReader.currentTime = 0.0;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         // this loads new samples from the file reader object and saves them into the output speaker buffers
         [fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
         
     }];
}

- (NSString *)getSongAtIndex:(int)songIndex {
    if (self.mode == RELAX) {
        return self.relaxSongs[songIndex];
    } else if (self.mode == PARTY) {
        return self.partySongs[songIndex];
    } else {
        return self.gameSongs[songIndex];
    }
}

- (void)updateMode {
    self.songIndex = 0;
    
    UIImage *image1, *image2, *image3;
    UIColor *color1, *color2, *color3;
    
    image1 = [UIImage imageNamed:@"relax_grey.png"];
    image2 = [UIImage imageNamed:@"party_grey.png"];
    image3 = [UIImage imageNamed:@"game_grey.png"];
    
    color1 = [UIColor darkGrayColor];
    color2 = [UIColor darkGrayColor];
    color3 = [UIColor darkGrayColor];
    
    if (self.mode == RELAX) {
        image1 = [UIImage imageNamed:@"relax_blue.png"];
        color1 = [UIColor blueColor];
    } else if (self.mode == PARTY) {
        image2 = [UIImage imageNamed:@"party_blue.png"];
        color2 = [UIColor blueColor];
    } else if (self.mode == GAME) {
        image3 = [UIImage imageNamed:@"game_blue.png"];
        color3 = [UIColor blueColor];
    }
    
    self.descriptionLabel.text = self.descriptionArray[self.mode];
    
    // Set image and color for the relax button and label
    [self.relaxButton setImage:image1 forState:UIControlStateNormal];
    [self.relaxLabel setTitleColor:color1
                 forState:UIControlStateNormal];
    
    // Set image and color for the party button and label
    [self.partyButton setImage:image2 forState:UIControlStateNormal];
    [self.partyLabel setTitleColor:color2
                          forState:UIControlStateNormal];
    
    // Set image and color for the game button label
    [self.gameButton setImage:image3 forState:UIControlStateNormal];
    [self.gameLabel setTitleColor:color3
                         forState:UIControlStateNormal];
}

- (IBAction)volumeSliderChanged:(UISlider *)sender {
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    musicPlayer.volume = sender.value;
}

- (IBAction)relaxClicked:(UIButton *)sender {
    self.mode = RELAX;
}

- (IBAction)partyClicked:(UIButton *)sender {
    self.mode = PARTY;
}

- (IBAction)gameClicked:(UIButton *)sender {
    self.mode = GAME;
}

- (IBAction)playPauseButtonClicked:(UIButton *)sender {
    if (self.playing) {
        self.playing = NO;
    } else {
        self.playing = YES;
    }
}

@end
