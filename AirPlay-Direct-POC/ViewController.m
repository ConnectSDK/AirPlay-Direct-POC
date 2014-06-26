//
//  ViewController.m
//  AirPlay-Direct-POC
//
//  Created by Jeremy White on 6/24/14.
//  AirPlay-Direct-POC by LG Electronics
//
//  To the extent possible under law, the person who associated CC0 with
//  this sample app has waived all copyright and related or neighboring rights
//  to the sample app.
//
//  You should have received a copy of the CC0 legalcode along with this
//  work. If not, see http://creativecommons.org/publicdomain/zero/1.0/.
//

#import "ViewController.h"

#import <ConnectSDK/ConnectSDK.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "MPAudioDeviceController.h"


@class MPAudioDeviceController;

typedef enum {
    ConnectivityStateDisconnected,
    ConnectivityStateTransitioning,
    ConnectivityStateConnected,
    ConnectivityStateBeamed
} ConnectivityState;

@interface ViewController () <DevicePickerDelegate, ConnectableDeviceDelegate>

@property (nonatomic) ConnectivityState state;
@property (nonatomic) ConnectableDevice *device;
@property (nonatomic) LaunchSession *launchSession;
@property (nonatomic) id<MediaControl> mediaControl;
@property (nonatomic, strong) MPMoviePlayerController *audioPlayer;
@property (nonatomic) AVPlayer *videoPlayer;
@property (nonatomic) MPAudioDeviceController *audioDeviceController;

@property (nonatomic) NSURL *audioURL;
@property (nonatomic) NSURL *audioIconURL;
@property (nonatomic) NSURL *videoURL;
@property (nonatomic) NSURL *videoIconURL;

- (void) disconnectFromDevice:(ConnectableDevice *)device;

@end

@implementation ViewController
{
    void(^_connectionCompletionBlock)(ConnectableDevice *device);
}

@synthesize state = _state;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioURL = [NSURL URLWithString:@"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/audio.mp3"];
    self.audioIconURL = [NSURL URLWithString:@"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/audioIcon.jpg"];
    self.videoURL = [NSURL URLWithString:@"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/video.mp4"];
    self.videoIconURL = [NSURL URLWithString:@"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/videoIcon.jpg"];
    
    self.state = ConnectivityStateDisconnected;
    
    [[[DiscoveryManager sharedManager] devicePicker] setDelegate:self];
}

#pragma mark - UI state management

- (ConnectivityState)state
{
    return _state;
}

- (void)setState:(ConnectivityState)state
{
    self.beamAudioButton.enabled = state != ConnectivityStateTransitioning;
    self.beamVideoButton.enabled = state != ConnectivityStateTransitioning;
    
    self.playButton.enabled = state == ConnectivityStateBeamed;
    self.pauseButton.enabled = state == ConnectivityStateBeamed;
    self.closeButton.enabled = state == ConnectivityStateBeamed;
    
    _state = state;
}

#pragma mark - UIButton actions

- (void)beamAudio:(id)sender
{
    [self cleanUpIfNecessary];
    
    self.state = ConnectivityStateTransitioning;
    
    [[[DiscoveryManager sharedManager] devicePicker] showPicker:sender];
    
    __weak ViewController *weakSelf = self;
    
    _connectionCompletionBlock = ^(ConnectableDevice *device)
    {
        if (!device || !weakSelf)
            return;
        
        ViewController *strongSelf = weakSelf;
        strongSelf.device = device;
        strongSelf.state = ConnectivityStateConnected;
        
        [strongSelf playAudio];
    };
}

- (void)beamVideo:(id)sender
{
    [self cleanUpIfNecessary];
    
    self.state = ConnectivityStateTransitioning;
    
    [[[DiscoveryManager sharedManager] devicePicker] showPicker:sender];
    
    __weak ViewController *weakSelf = self;
    
    _connectionCompletionBlock = ^(ConnectableDevice *device)
    {
        if (!device || !weakSelf)
            return;
        
        ViewController *strongSelf = weakSelf;
        strongSelf.device = device;
        strongSelf.state = ConnectivityStateConnected;
        
        [strongSelf playVideo];
    };
}

- (void)play:(id)sender
{
    if ([self.device serviceWithName:@"AirPlay"])
    {
        [self playThroughAirPlay];
        return;
    }
    
    if (!self.mediaControl)
        return;
    
    [self.mediaControl playWithSuccess:nil failure:nil];
}

- (void)pause:(id)sender
{
    if ([self.device serviceWithName:@"AirPlay"])
    {
        [self pauseThroughAirPlay];
        return;
    }
    
    if (!self.mediaControl)
        return;
    
    [self.mediaControl pauseWithSuccess:nil failure:nil];
}

- (void)close:(id)sender
{
    [self cleanUpIfNecessary];
}

#pragma mark - Helper methods

- (void) playAudio
{
    if ([self.device serviceWithName:@"AirPlay"])
    {
        [self playAudioThroughAirPlay];
        return;
    }
    NSString *title = @"The Song That Doesn't End";
    NSString *description = @"Lamb Chop's Play Along";
    NSString *mimeType = @"audio/mp3";
    
    [self.device.mediaPlayer playMedia:self.audioURL iconURL:self.audioIconURL title:title description:description mimeType:mimeType shouldLoop:NO success:^(LaunchSession *launchSession, id<MediaControl> mediaControl)
     {
         self.launchSession = launchSession;
         self.mediaControl = mediaControl;
         self.state = ConnectivityStateBeamed;
     } failure:^(NSError *error)
     {
         [self cleanUpIfNecessary];
     }];
}

- (void) playVideo
{
    if ([self.device serviceWithName:@"AirPlay"])
    {
        [self playVideoThroughAirPlay];
        return;
    }
    
    NSString *title = @"Sintel Trailer";
    NSString *description = @"Blender Open Movie Project";
    NSString *mimeType = @"video/mp4";
    
    [self.device.mediaPlayer playMedia:self.videoURL iconURL:self.videoIconURL title:title description:description mimeType:mimeType shouldLoop:NO success:^(LaunchSession *launchSession, id<MediaControl> mediaControl)
     {
         self.launchSession = launchSession;
         self.mediaControl = mediaControl;
         self.state = ConnectivityStateBeamed;
     } failure:^(NSError *error)
     {
         [self cleanUpIfNecessary];
     }];
}

#pragma mark - ConnectableDevice management methods

- (void) cleanUpIfNecessary
{
    self.state = ConnectivityStateTransitioning;
    
    if ([self.device serviceWithName:@"AirPlay"])
    {
        [self closeThroughAirPlay];
        [self setState:ConnectivityStateDisconnected];
    } else
    {
        __weak ViewController *weakSelf = self;
        __weak ConnectableDevice *weakDevice = self.device;
        
        void (^closeCompletionBlock)(void) = ^{
            if (!weakSelf)
                return;
            
            ViewController *strongSelf = weakSelf;
            ConnectableDevice *strongDevice = weakDevice;
            
            [strongSelf disconnectFromDevice:strongDevice];
        };
        
        if (self.launchSession)
        {
            [self.launchSession closeWithSuccess:^(id responseObject) {
                closeCompletionBlock();
            } failure:^(NSError *error) {
                closeCompletionBlock();
            }];
        } else
        {
            closeCompletionBlock();
        }
    }
    
    self.launchSession = nil;
    self.mediaControl = nil;
    
    if (self.device)
        self.device.delegate = nil;
    
    self.device = nil;
}

- (void) disconnectFromDevice:(ConnectableDevice *)device
{
    if (!device)
        return;
    
    device.delegate = nil;
    [device disconnect];
    
    [self setState:ConnectivityStateDisconnected];
}

#pragma mark - DevicePickerDelegate methods

- (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device
{
    if ([device serviceWithName:@"AirPlay"])
    {
        _connectionCompletionBlock(device);
    } else
    {
        if ([device hasCapabilities:@[kMediaPlayerPlayAudio, kMediaPlayerPlayVideo, kMediaControlPlay, kMediaControlPause]])
        {
            self.device = device;
            device.delegate = self;
            [device connect];
        }
    }
}

- (void)devicePicker:(DevicePicker *)picker didCancelWithError:(NSError *)error
{
    if (error)
        self.state = ConnectivityStateDisconnected;
}

#pragma mark - ConnectableDeviceDelegate methods

- (void)connectableDeviceReady:(ConnectableDevice *)device
{
    if (device != self.device)
        return;
    
    self.state = ConnectivityStateConnected;
    
    if (_connectionCompletionBlock)
        _connectionCompletionBlock(self.device);
}

- (void)connectableDevice:(ConnectableDevice *)device capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed
{
    if (device != self.device)
        return;
    
    if (![device hasCapabilities:@[kMediaPlayerPlayAudio, kMediaPlayerPlayVideo, kMediaControlPlay, kMediaControlPause]])
        [self cleanUpIfNecessary];
}

- (void)connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error { }

#pragma mark - AirPlay direct methods

- (void) playAudioThroughAirPlay
{
    [self setAvRouteForDevice:self.device];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    self.audioPlayer = [[MPMoviePlayerController alloc] initWithContentURL:self.audioURL];
    self.audioPlayer.allowsAirPlay = NO;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
    self.state = ConnectivityStateBeamed;
}

- (void) playVideoThroughAirPlay
{
    [self setAvRouteForDevice:self.device];
    
    self.videoPlayer = [AVPlayer playerWithURL:self.videoURL];
    [self.videoPlayer play];
    
    self.state = ConnectivityStateBeamed;
}

- (void) playThroughAirPlay
{
    if (self.audioPlayer)
        [self.audioPlayer play];
    else if (self.videoPlayer)
        [self.videoPlayer play];
}

- (void) pauseThroughAirPlay
{
    if (self.audioPlayer)
        [self.audioPlayer pause];
    else if (self.videoPlayer)
        [self.videoPlayer pause];
}

- (void) closeThroughAirPlay
{
    self.audioPlayer = nil;
    self.videoPlayer = nil;
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
    
    [self.audioDeviceController pickHandsetRoute];
}

- (void)setAvRouteForDevice:(ConnectableDevice *)device
{
    if (!self.audioDeviceController)
    {
        self.audioDeviceController = [[MPAudioDeviceController alloc] init];
        self.audioDeviceController.routeDiscoveryEnabled = YES;
    }
    
    // credit: Justin DeWind
    // source: http://spin.atomicobject.com/2012/04/23/ios-mirroring-and-programmatic-airplay-selection/
    [self.audioDeviceController determinePickableRoutesWithCompletionHandler:^(NSInteger value)
    {
        NSMutableArray *routes = [NSMutableArray array];
        [self.audioDeviceController clearCachedRoutes];
        
        NSUInteger index = 0;
        while (true)
        {
            NSDictionary *route = [self.audioDeviceController routeDescriptionAtIndex:index];
            if (route)
            {
                [routes addObject:route];
                index++;
            } else
            {
                NSLog(@"%@", routes);
                break;
            }
        }
        
        NSString *airPlayUUID = [device serviceWithName:@"AirPlay"].serviceDescription.UUID;
        
        if (!airPlayUUID)
            return;
        
        __block BOOL foundDevice = NO;
        
        [routes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            if ([[obj objectForKey:@"RouteUID"] hasPrefix:airPlayUUID])
            {
                if ([[obj objectForKey:@"RouteSupportsAirPlayAudio"] boolValue])
                {
                    NSDictionary *info = [obj objectForKey:@"AirPlayPortExtendedInfo"];
                    if ([[info objectForKey:@"uid"] hasSuffix:@"-airplay"])
                    {
                        [self.audioDeviceController pickRouteAtIndex:idx];
                        foundDevice = YES;
                        *stop = YES;
                    }
                }
            }
        }];
        
        if (!foundDevice)
            [self cleanUpIfNecessary];
    }];
}

@end
