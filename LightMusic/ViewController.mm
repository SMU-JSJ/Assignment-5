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
#import "RingBuffer.h"

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

@property (strong, nonatomic) NSArray* descriptionArray;

@property (nonatomic) MusicMode mode;

@end

@implementation ViewController

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

- (void)setMode:(MusicMode)mode {
    _mode = mode;
    [self updateMode];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateMode {
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
}

- (IBAction)relaxButtonClicked:(UIButton *)sender {
    self.mode = RELAX;
}

- (IBAction)relaxLabelClicked:(UIButton *)sender {
    self.mode = RELAX;
}

- (IBAction)partyButtonClicked:(UIButton *)sender {
    self.mode = PARTY;
}

- (IBAction)partyLabelClicked:(UIButton *)sender {
    self.mode = PARTY;
}

- (IBAction)gameButtonClicked:(UIButton *)sender {
    self.mode = GAME;
}

- (IBAction)gameLabelClicked:(UIButton *)sender {
    self.mode = GAME;
}

- (IBAction)playPauseButtonClicked:(UIButton *)sender {
}

@end
