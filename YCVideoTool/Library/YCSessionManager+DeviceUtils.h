//
//  YCSessionManager+DeviceUtils.h
//  YCMediaDemo
//  Created by lyc on 2018/1/13.
//  git : xxxxxxxx
//  Copyright © 2018年 lyc. All rights reserved.
//

#import "YCSessionManager.h"

@interface YCSessionManager (DeviceUtils)


/**
 * If get the capture device that is not expected , return the nearest capture device .
 */
-(AVCaptureDevice*)preferrdCaptureDevice:(AVCaptureDeviceType)deviceType position:(AVCaptureDevicePosition)position;

/**
 * Return actual device orientation .
 */
-(AVCaptureVideoOrientation)currentDeviceOrientation;


-(void)changeVideoOrientation:(AVCaptureVideoOrientation)videoOrientation;

-(CMSampleBufferRef)adjustBuffer:(CMSampleBufferRef)sample withTimeOffset:(CMTime)offset andDuration:(CMTime)duration;

@end
