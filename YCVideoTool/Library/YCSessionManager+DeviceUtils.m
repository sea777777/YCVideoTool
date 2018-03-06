//
//  YCSessionManager+DeviceUtils.m
//  YCMediaDemo
//  Created by lyc on 2018/1/13.
//  git : xxxxxxxx
//  Copyright © 2018年 lyc. All rights reserved.
//

#import "YCSessionManager+DeviceUtils.h"



@implementation YCSessionManager (DeviceUtils)


-(AVCaptureDevice*)preferrdCaptureDevice:(AVCaptureDeviceType)deviceType position:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *preferredCaptureDevice = nil;
    AVCaptureDeviceDiscoverySession *deviceSession = nil;
    deviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[deviceType] mediaType:AVMediaTypeVideo position:position];
    
    for (AVCaptureDevice *device in  deviceSession.devices)
    {
        if (device.position == position && device.deviceType == deviceType)
        {
            preferredCaptureDevice = device; break;
        }
    }
    
    //if not exist, only position
    if (!preferredCaptureDevice)
    {
        for (AVCaptureDevice *device in  deviceSession.devices)
        {
            if (device.position == position)
            {
                preferredCaptureDevice = device; break;
            }
        }
    }
    
    //if not exist, only type
    if (!preferredCaptureDevice)
    {
        for (AVCaptureDevice *device in  deviceSession.devices)
        {
            if (device.deviceType == deviceType)
            {
                preferredCaptureDevice = device; break;
            }
        }
    }
    
    if (!preferredCaptureDevice && deviceSession.devices.count>0)
    {
        preferredCaptureDevice = deviceSession.devices[0];
    }
    
    return preferredCaptureDevice;
}


-(AVCaptureVideoOrientation)currentDeviceOrientation
{
    AVCaptureVideoOrientation currentOrientation = self.videoOrientation;
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    switch (deviceOrientation)
    {
        case UIDeviceOrientationLandscapeRight:
            currentOrientation = AVCaptureVideoOrientationLandscapeLeft ;
            break;
        case UIDeviceOrientationLandscapeLeft:
            currentOrientation = AVCaptureVideoOrientationLandscapeRight ;
            break;
        case UIDeviceOrientationPortrait:
            currentOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            currentOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }
    return currentOrientation;
}


-(void)changeVideoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection isVideoOrientationSupported])
    {
        connection.videoOrientation = videoOrientation;
    }
}

- (CMSampleBufferRef)adjustBuffer:(CMSampleBufferRef)sample withTimeOffset:(CMTime)offset andDuration:(CMTime)duration {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo *pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
        pInfo[i].duration = duration;
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

@end
