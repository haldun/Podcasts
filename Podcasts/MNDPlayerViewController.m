//
//  MNDPlayerViewController.m
//  Podcasts
//
//  Created by Haldun Bayhantopcu on 24/10/13.
//  Copyright (c) 2013 monoid. All rights reserved.
//

@import AVFoundation;

#import "MNDPlayerViewController.h"
#import "MNDPodcast.h"

@interface MNDPlayerViewController () <AVAudioPlayerDelegate>

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation MNDPlayerViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = self.podcast.title;
  [[AVAudioSession sharedInstance] setDelegate:self];
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

- (AVAudioPlayer *)audioPlayer
{
  if (!_audioPlayer) {
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:self.podcast.localUrl] error:&error];
    if (error) {
      BLog(@"error: %@", error);
    }
  }
  return _audioPlayer;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (IBAction)playButtonTapped:(id)sender
{
  [self.audioPlayer play];
}

@end
