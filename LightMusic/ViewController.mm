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
#import "SongModel.h"
#import <MediaPlayer/MediaPlayer.h>

#import "BLE.h"
#import "AppDelegate.h"

#define kBufferLength 4096

@interface ViewController ()

@property (strong, nonatomic) SongModel* songModel;

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
@property (weak, nonatomic) IBOutlet UIButton *connectDisconnectButton;

@property (strong, nonatomic) Novocaine *audioManager;
@property (nonatomic) float *audioData;

@property (strong, nonatomic, readonly) BLE* bleShield;

@property (strong, nonatomic) NSTimer *songTimeDecrementer;

@property (strong, nonatomic) NSArray *descriptionArray;

@property (nonatomic) MusicMode mode;
@property (nonatomic) BOOL playing;
@property (nonatomic) ConnectedState connected;
@property (nonatomic) int songIndex;
@property (nonatomic) NSInteger secondsLeftInCurrentSong;

@end


@implementation ViewController

AudioFileReader *fileReader;

// Lazily instantiate

- (SongModel*) songModel {
    if(!_songModel)
        _songModel = [SongModel sharedInstance];
    
    return _songModel;
}

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

- (NSArray*)descriptionArray {
    if (!_descriptionArray) {
        _descriptionArray = [NSArray arrayWithObjects:
            @"Music gets quieter and more mellow as the room gets darker.",
            @"Music gets louder as the party gets darker, and the green light blinks faster.",
            @"Lights are off, the music plays. Lights on, the music stops and you freeze!",
            nil];
    }
    
    return _descriptionArray;
}

- (BLE*)bleShield {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.bleShield;
}

- (void)setMode:(MusicMode)mode {
    _mode = mode;
    [self updateMode];
    [self setAudioOutput];
}

- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    if (playing) {
        [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"]
                              forState:UIControlStateNormal];
        [fileReader play];
        if (![self.audioManager playing])
            [self.audioManager play];
        [self createTimer];
    } else {
        [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"]
                              forState:UIControlStateNormal];
        [fileReader pause];
        if ([self.audioManager playing])
            [self.audioManager pause];
        [self.songTimeDecrementer invalidate];
    }
}

- (void)setConnected:(ConnectedState)connected {
    _connected = connected;
    if (connected == DISCONNECTED) {
        [self.connectDisconnectButton setImage:[UIImage imageNamed:@"disconnected.png"]
                                      forState:UIControlStateNormal];
    } else if (connected == CONNECTING) {
        [self.connectDisconnectButton setImage:[UIImage imageNamed:@"connecting.png"]
                              forState:UIControlStateNormal];
        
        [self scanForDevices];
    } else if (connected == CONNECTED) {
        [self.connectDisconnectButton setImage:[UIImage imageNamed:@"connected.png"]
                              forState:UIControlStateNormal];
    }
}

- (void)setSongIndex:(int)songIndex {
    if (self.mode == RELAX) {
        songIndex = songIndex % [self.songModel.relaxSongs count];
    } else if (self.mode == PARTY) {
        songIndex = songIndex % [self.songModel.partySongs count];
    } else if (self.mode == GAME) {
        songIndex = songIndex % [self.songModel.gameSongs count];
    }
    _songIndex = songIndex;
}

- (void)setSecondsLeftInCurrentSong:(NSInteger)secondsLeftInCurrentSong {
    _secondsLeftInCurrentSong = secondsLeftInCurrentSong;
    if (secondsLeftInCurrentSong == 0) {
        self.songIndex = self.songIndex + 1;
        [self setAudioOutput];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OnBLEDidConnect:) name:@"BLEDidConnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OnBLEDidDisconnect:) name:@"BLEDidDisconnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (OnBLEDidReceiveData:) name:@"BLEReceievedData" object:nil];
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
    
    [self.songTimeDecrementer invalidate];
    
    // call function to disconnect BLE
}

- (void)scanForDevices {
    // disconnect from any peripherals
    if (self.bleShield.activePeripheral)
        if(self.bleShield.activePeripheral.isConnected)
        {
            [[self.bleShield CM] cancelPeripheralConnection:[self.bleShield activePeripheral]];
            return;
        }
    
    // set peripheral to nil
    if (self.bleShield.peripherals)
        self.bleShield.peripherals = nil;
    
    //start search for peripherals with a timeout of 3 seconds
    // this is an asunchronous call and will return before search is complete
    [self.bleShield findBLEPeripherals:3];
    
    // after three seconds, try to connect to first peripheral
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0
                                     target:self
                                   selector:@selector(didFinishScanning:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)didFinishScanning:(NSTimer*)timer {
    CBPeripheral* aPeripheral;
    NSString* perName;
    
    for (int i = 0; i < [self.bleShield.peripherals count]; i++) {
        aPeripheral = [self.bleShield.peripherals objectAtIndex:i];
        perName = aPeripheral.name;
        
        if ([perName isEqualToString:@"JSJ"]) {
            [self.bleShield connectPeripheral:aPeripheral];
            return;
        }
    }
    
    self.connected = DISCONNECTED;
}

- (void)createTimer {
    if ([self.songTimeDecrementer isValid]) {
        [self.songTimeDecrementer invalidate];
    }
    
    self.songTimeDecrementer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(decrementSecondsLeftInCurrentSong)
                                                userInfo:nil
                                                 repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:self.songTimeDecrementer forMode:NSRunLoopCommonModes];
}

// Decrements the number of seconds left in the current song playing
- (void)decrementSecondsLeftInCurrentSong {
    self.secondsLeftInCurrentSong--;
}

- (void)setAudioOutput {
    // Get the current song name and the length of the song
    NSString* songName = [self getSongAtIndex:self.songIndex];
    NSNumber* timerNum = (NSNumber *)[self.songModel.songTimes valueForKey:songName];
    self.secondsLeftInCurrentSong = [timerNum integerValue];
    
    self.songTitleLabel.text = songName;
    self.artistLabel.text = (NSString *)[self.songModel.songArtists valueForKey:songName];
    
    NSLog(@"Song index = %d\nSong name = %@", self.songIndex, songName);
    // load samples from an mp3 file and set them to output to the speakers!!
    NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:songName
                                                  withExtension:@"mp3"];
    
    fileReader = [[AudioFileReader alloc]
                  initWithAudioFileURL: inputFileURL
                  samplingRate: self.audioManager.samplingRate
                  numChannels: self.audioManager.numOutputChannels];
    
    fileReader.currentTime = 0.0;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         // this loads new samples from the file reader object and saves them into the output speaker buffers
         [fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
         
     }];
}

- (NSString *)getSongAtIndex:(int)songIndex {
    if (self.mode == RELAX) {
        return self.songModel.relaxSongs[songIndex];
    } else if (self.mode == PARTY) {
        return self.songModel.partySongs[songIndex];
    } else {
        return self.songModel.gameSongs[songIndex];
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


- (IBAction)connectDisconnectButtonClicked:(UIButton *)sender {
    if (self.connected) {
        if(self.bleShield.activePeripheral.isConnected)
        {
            [[self.bleShield CM] cancelPeripheralConnection:[self.bleShield activePeripheral]];
        }
    } else {
        self.connected = CONNECTING;
    }
}

#pragma mark - BLEdelegate protocol methods
// NEW FUNCTION EXAMPLE: parse the received data from NSNotification
-(void) OnBLEDidReceiveData:(NSNotification *)notification
{
    NSData* d = [[notification userInfo] objectForKey:@"data"];
    NSLog(@"%@", [d description]);
    //    NSUInteger decodedInteger;
    //    [d getBytes:&decodedInteger length:sizeof(decodedInteger)];
    //    NSLog(@"Data: %lu", (unsigned long)decodedInteger);
    
    //NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    //self.label.text = s;
    //NSLog(@"%@", s);
}

// NEW FUNCTION: we disconnected, stop running
- (void) OnBLEDidDisconnect:(NSNotification *)notification {
    // disconnect
    self.connected = DISCONNECTED;
}

//CHANGE 7: create function called from "BLEDidConnect" notification (you can change the function below)
// in this function, update a label on the UI to have the name of the active peripheral
// you might be interested in the following method:
// NSString *deviceName =[notification.userInfo objectForKey:@"deviceName"];
// now just wait to send or receive
-(void) OnBLEDidConnect:(NSNotification *)notification {
    self.connected = CONNECTED;
}

#pragma mark - UI operations storyboard
- (IBAction)BLEShieldSend:(id)sender {
    
    //Note: this function only needs a name change, the BLE writing does not change
    NSString *s;
    NSData *d;
    
//    if (self.textField.text.length > 16)
//        s = [self.textField.text substringToIndex:16];
//    else
//        s = self.textField.text;
    
    s = [NSString stringWithFormat:@"%@\r\n", s];
    d = [s dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.bleShield write:d];
}


@end
