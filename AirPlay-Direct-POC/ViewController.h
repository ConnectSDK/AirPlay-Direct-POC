//
//  ViewController.h
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

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *beamAudioButton;
@property (weak, nonatomic) IBOutlet UIButton *beamVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

- (IBAction)beamAudio:(id)sender;
- (IBAction)beamVideo:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)close:(id)sender;

@end
