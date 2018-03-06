//
//  YCSettings.m
//  YCMediaDemo
//  Created by lyc on 2018/2/3.
//  git : xxxxxxxx
//  Copyright © 2018年 lyc. All rights reserved.
//

#import "YCSettings.h"

@implementation YCSettings


+(instancetype)shareInstance
{
    static YCSettings *settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [YCSettings new];
    });
    return settings;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _captureSessionPreset = AVCaptureSessionPresetHigh;
        _videoOrientation = AVCaptureVideoOrientationPortrait;
        _bitrate = kYCSettingBitrateHigh;
        _channels = kYCSettingChannelsDouble;
        _sampleRate = kYCSettingSampleRate;
        _maxRecordTime = kYCSettingMaxRecordTime;
    }
    return self;
}


-(NSArray*)capturePresetHighSource
{

    return [NSArray arrayWithObjects:AVCaptureSessionPresetHigh,
                                     AVCaptureSessionPreset3840x2160,
                                     AVCaptureSessionPresetiFrame1280x720,
                                     AVCaptureSessionPreset1920x1080,
                                     AVCaptureSessionPreset1280x720, nil];
}

-(NSArray*)capturePresetMediumSource
{
    
    return [NSArray arrayWithObjects:AVCaptureSessionPresetMedium,
            AVCaptureSessionPresetiFrame960x540,
            AVCaptureSessionPreset640x480, nil];
}

-(NSArray*)capturePresetLowSource
{
    
    return [NSArray arrayWithObjects:AVCaptureSessionPresetLow,
                                     AVCaptureSessionPreset352x288, nil];
}

@end
