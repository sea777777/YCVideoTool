//
//  YCSessionManager.h
//  YCMediaDemo
//  Created by lyc on 2018/1/7.
//  git : xxxxxxxx
//  Copyright © 2018年 lyc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "YCSettings.h"

@class YCSessionManager;
@protocol YCSessionManagerDelegate<NSObject>

-(void)didRecordingProgress:(YCSessionManager*)sessionManager progress:(float)progress;

@end


@interface YCSessionManager : NSObject


/************************ settings ***********************/
/**
 CaptureSessionPreset for captureSession , default is AVCaptureSessionPresetHigh .
 */
@property(nonatomic,strong)  AVCaptureSessionPreset captureSessionPreset;

/**
 Set the video portrait when init , default is AVCaptureVideoOrientationPortrait .
 */
@property(nonatomic,assign)  AVCaptureVideoOrientation videoOrientation;

/**
 Need to adjust the orientation of the video automatically ? default is NO.
 */
@property(nonatomic,assign)  BOOL autoAdaptOrientation;

/**
 Default is 15s .
 */
@property(nonatomic,assign)  float maxRecordTime;
/************************ settings ***********************/



/**
 The path of the recorded video .
 */
@property(nonatomic,strong,readonly) NSURL *videoPath;

@property(nonatomic,strong,readonly) AVCaptureVideoDataOutput *videoOutput;

@property(nonatomic,strong,readonly) AVCaptureVideoPreviewLayer *previewLayer;

@property(nonatomic,weak) id<YCSessionManagerDelegate> delegate;


-(void)startSession;

/**
 Start write data to the disk .
*/
-(void)startRecording;

-(void)pauseRecordingWithHandler:(void (^)(void))completion;

-(void)stopRecordingWithHandler:(void(^)(void))completion;

/**
 Return the deleted chunk time .
 */
-(float)deleteLastChunk;

@end
