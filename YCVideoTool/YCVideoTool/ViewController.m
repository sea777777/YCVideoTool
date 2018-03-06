//
//  ViewController.m
//  YCMediaDemo
//
//  Created by lyc on 2018/1/7.
//  Copyright © 2018年 lyc. All rights reserved.
//

#import "ViewController.h"
#import "YCSessionManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "YCSessionManager+DeviceUtils.h"




#define SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)



@interface ViewController ()<UIGestureRecognizerDelegate,YCSessionManagerDelegate>

@property (strong, nonatomic) YCSessionManager *sessionManager;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) MPMoviePlayerViewController * moviePlayerVC;
@property (strong, nonatomic) CAShapeLayer *shapeLayer;
@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sessionManager = [YCSessionManager new];
    self.sessionManager.autoAdaptOrientation = NO;
    self.sessionManager.delegate = self;
    self.sessionManager.maxRecordTime = 15;
    [self.sessionManager startSession];
    
    _previewLayer = self.sessionManager.previewLayer;
    _previewLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    
    [self resetBtns];
    [self initProgressView];

}

-(void)resetBtns
{
    _deleteBtn.backgroundColor = [UIColor whiteColor];
    _deleteBtn.layer.cornerRadius = 25;
    _OKBtn.backgroundColor = [UIColor whiteColor];
    _OKBtn.layer.cornerRadius = 25;
    _recordBtnBackgroundView.layer.cornerRadius = 44;
    [self.view bringSubviewToFront:_recordBtn];
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point=[[touches anyObject] locationInView:self.view];
    CALayer *layer=[self.view.layer hitTest:point];
    if (layer==_recordBtn.layer)
    {
        [self.sessionManager startRecording];
    }
}


- (IBAction)OKButtonClick:(UIButton *)sender
{
    [self.sessionManager stopRecordingWithHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.moviePlayerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:self.sessionManager.videoPath];
            [[self.moviePlayerVC moviePlayer] prepareToPlay];
            [self presentMoviePlayerViewControllerAnimated:self.moviePlayerVC];
            [[self.moviePlayerVC moviePlayer] play];
        });
    }];
}

- (IBAction)deleteButtonClick:(UIButton *)sender
{
    float deletedTime = [self.sessionManager deleteLastChunk];
    float progress = 0.f;
    if (deletedTime != 0)
    {
        progress = _progressBar.progress - deletedTime/self.sessionManager.maxRecordTime;
    }
    _progressBar.progress = progress;
    [self drawProgress:progress];

}



-(void)didRecordingProgress:(YCSessionManager *)sessionManager progress:(float)progress
{
    [_progressBar setProgress:progress];
    [self drawProgress:progress];
}


-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point=[[touches anyObject] locationInView:self.view];
    CALayer *layer=[self.view.layer hitTest:point];
    if (layer==_recordBtn.layer)
    {
        [self.sessionManager pauseRecordingWithHandler:nil];
        
    }
}


-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


-(void)drawProgress:(float)progress
{
    _shapeLayer.strokeEnd = progress;
}
-(void)initProgressView
{
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(2, 2, 84, 84)];
    
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.strokeColor = [UIColor greenColor].CGColor;
    _shapeLayer.fillColor   = [UIColor clearColor].CGColor;
    _shapeLayer.lineJoin    = kCALineJoinRound;
    _shapeLayer.lineCap     = kCALineCapRound;
    _shapeLayer.path        = path.CGPath;
    _shapeLayer.strokeStart = 0;
    _shapeLayer.strokeEnd   = 0;
    _shapeLayer.lineWidth   = 4;
    
    [_recordBtnBackgroundView.layer addSublayer:_shapeLayer];
    _recordBtnBackgroundView.layer.transform = CATransform3DRotate(CATransform3DIdentity, -M_PI/2, 0, 0, 1);
}


@end

