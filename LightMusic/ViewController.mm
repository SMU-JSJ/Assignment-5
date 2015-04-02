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

- (SongModel*)songModel {
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
    self.playing = self.playing;
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

- (void)setPlaying:(BOOL)playing {
    
    _playing = playing;
    
    if (playing) {
        if (self.mode == GAME && self.connected == CONNECTED) {
            [self.playPauseButton setImage:[UIImage imageNamed:@"pause_disabled.png"]
                                  forState:UIControlStateNormal];
            [self.playPauseButton setEnabled:NO];
        } else {
            [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"]
                                  forState:UIControlStateNormal];
            [self.playPauseButton setEnabled:YES];
        }
        
        [fileReader play];
        if (![self.audioManager playing])
            [self.audioManager play];
        [self createTimer];
    } else {
        if (self.mode == GAME && self.connected == CONNECTED) {
            [self.playPauseButton setImage:[UIImage imageNamed:@"play_disabled.png"]
                                  forState:UIControlStateNormal];
            [self.playPauseButton setEnabled:NO];
        } else {
            [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"]
                                  forState:UIControlStateNormal];
            [self.playPauseButton setEnabled:YES];
        }
        
        [fileReader pause];
        if ([self.audioManager playing])
            [self.audioManager pause];
        [self.songTimeDecrementer invalidate];
    }
    
    if (self.connected == CONNECTED) {
        [self sendDataToArduino];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.volumeSlider.value = 1.0;
    
    [self setAudioOutput];
    [self createTimer];
    
    self.playing = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.audioManager pause]; // just pause the playing
    // audio manager is a singleton class, so we do not need to
    // tear it down, in case some other controller may want to use it
    
    _audioManager = nil;
    
    [self.songTimeDecrementer invalidate];
    
    // call function to disconnect BLE
}


- (void)sendDataToArduino {
    int LEDcode;
    
    // Concactenates the LED color codes and mode code together
    // The byte is for the red LED, second byte is for the
    // green LED, and last byte is for the mode
    // 0x11 - red on,    0x10 - red off
    // 0x21 - green on,  0x20 - green off
    // 0x00 - not party, 0x01 - party
    if (self.playing) {
        if (self.mode != PARTY) {
            LEDcode = 0x102100;
        } else {
            LEDcode = 0x102101;
        }
    } else {
        if (self.mode != PARTY) {
            LEDcode = 0x112000;
        } else {
            LEDcode = 0x112001;
        }
    }
    
    NSData *data = [NSData dataWithBytes: &LEDcode length: sizeof(LEDcode)];
    
    [self.bleShield write:data];
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

- (void)dealloc {
    free(self.audioData);
    self.audioManager = nil;
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
    [self togglePlayPause];
}

- (void)togglePlayPause {
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
// Parse the received data from NSNotification
-(void) OnBLEDidReceiveData:(NSNotification *)notification
{
    NSMutableData* d = [[notification userInfo] objectForKey:@"data"];
    const uint8_t *bytes = (const uint8_t *)[d bytes];
    
    uint8_t B0 = bytes[0], B3 = bytes[3], B1 = 0, P1 = 0, P2 = 0, L1 = 0, L2 = 0;
    
    // If the first byte is 0A and the fourth byte is 0B
    //   You  will receive button data, potentiometer data, and light sensor data
    //   (9 bytes total)
    //   B0: 0A - indicating that the button values are next
    //   B1 and B2: value of the button
    //   B3: 0B - indicating that the potentiometer values are next
    //   B4 and B5: value of the potentiometer
    //   B6: 0B - indicating that the light sensor values are next
    //   B7 and B8: value of the light sensor
    // If the first byte is 0A and the fourth byte is 0C
    //   You  will receive button data and light sensor data
    //   (9 bytes total)
    //   B0: 0A - indicating that the button values are next
    //   B1 and B2: value of the button
    //   B3: 0B - indicating that the light sensor values are next
    //   B4 and B5: value of the light sensor
    // If the first byte will be 0B
    //   You will receive potentiometer data and light sensor data
    //   (6 bytes total)
    //   B0: 0B - indicating that the potentiometer values are next
    //   B1 and B2: value of the potentiometer
    //   B3: 0B - indicating that the light sensor values are next
    //   B4 and B5: value of the light sensor
    // Otherwise, the first byte will be 0C
    //   You will receive light sensor data
    //   (3 bytes total)
    //   B0: 0B - indicating that the light values are next
    //   B1 and B2: value of the light
    if (B0 == 10 && B3 == 11) {
        // There are 9 bytes
        B1 = bytes[1], P1 = bytes[4], P2 = bytes[5], L1 = bytes[7], L2 = bytes[8];
    } else if (B0 == 10 && B3 == 12) {
        // There are 6 bytes
        B1 = bytes[1], L1 = bytes[4], L2 = bytes[5];
    } else if (B0 == 11) {
        // There are 6 bytes
        P1 = bytes[1], P2 = bytes[2], L1 = bytes[4], L2 = bytes[5];
    } else {
        // Ther are 3 bytes
        L1 = bytes[1], L2 = bytes[2];
    }
    
    // Button: if B1 is 1, toggle play/pause
    if (B0 == 10 && B1 == 1) {
        [self togglePlayPause];
    }
    
    // Potentiometer
    if (B0 == 11 || B3 == 11) {
        int potentiometer = (P1 << 8) + P2;
        float volumeValue = (float)potentiometer/1023.0;
        if(volumeValue >= self.volumeSlider.value + 0.1 ||
           volumeValue <= self.volumeSlider.value - 0.1) {
            MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
            musicPlayer.volume = volumeValue;
            self.volumeSlider.value = volumeValue;
        }
    }
    
    // Light sensor
    if (self.mode == GAME) {
        int light = (L1 << 8) + L2;
        if (light >= 900) {
            self.playing = NO;
        } else {
            self.playing = YES;
        }
    }
}

// we disconnected, stop running
- (void) OnBLEDidDisconnect:(NSNotification *)notification {
    self.connected = DISCONNECTED;
    self.playing = self.playing;
}

-(void) OnBLEDidConnect:(NSNotification *)notification {
    self.connected = CONNECTED;
    self.playing = self.playing;
}

@end
