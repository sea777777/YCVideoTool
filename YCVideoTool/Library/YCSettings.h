//
//  YCSettings.h
//  YCMediaDemo
//
//  Created by lyc on 2018/2/3.
//  Copyright © 2018年 lyc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kYCSettingBitrateLow 64000
#define kYCSettingBitrateMedium (64000 * 2)
#define kYCSettingBitrateHigh (64000 * 5)
#define kYCSettingChannelsSingle 1
#define kYCSettingChannelsDouble 2     //
#define kYCSettingSampleRate 44100     //44.1k
#define kYCSettingMaxRecordTime 15.0


@interface YCSettings : NSObject

+(instancetype)shareInstance;

@property(nonatomic,strong)  AVCaptureSessionPreset captureSessionPreset;

@property(nonatomic,assign)  BOOL autoAdaptOrientation;

@property(nonatomic,assign)  AVCaptureVideoOrientation videoOrientation;

@property(nonatomic,assign)  float maxRecordTime;

/***************** audio settings *****************/
@property(nonatomic,assign)  NSInteger bitrate;
@property(nonatomic,assign)  NSInteger channels;
@property(nonatomic,assign)  float sampleRate;
/***************** audio settings *****************/


-(NSArray*)capturePresetHighSource;

-(NSArray*)capturePresetMediumSource;

-(NSArray*)capturePresetLowSource;

    
@end
