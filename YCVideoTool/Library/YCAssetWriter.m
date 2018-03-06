//
//  YCVideoWriter.m
//  YCMediaDemo
//  Created by lyc on 2018/2/1.
//  git : xxxxxxxx
//  Copyright © 2018年 lyc. All rights reserved.
//

#import "YCAssetWriter.h"
#import "YCSettings.h"


@interface YCAssetWriter()

@property(nonatomic,strong) AVAssetWriter                   *assetWriter;
@property(nonatomic,strong) AVAssetWriterInput              *videoWriterInput;
@property(nonatomic,strong) AVAssetWriterInput              *audioWriterInput;
@property(nonatomic)        dispatch_queue_t                audioQueue;


@property(nonatomic,strong) AVAssetWriterInputPixelBufferAdaptor  *writerAdaptor;

@end



@implementation YCAssetWriter


-(BOOL)initializeAVWriterInput:(CMSampleBufferRef)buffer isVideo:(BOOL)isVideo;
{
    if (isVideo)
    {
        [self initializeVideoWriterInput:buffer];
    }else
    {
        [self initializeAudioWriterInput:buffer];
    }
    
    [self initializeAssetWriter];
    
    return self.writerInit;
}


#pragma mark - create writer input .
-(void)initializeVideoWriterInput:(CMSampleBufferRef)buffer
{
    if (buffer == nil || _videoWriterInput != nil) return;
    
    CVImageBufferRef cvBuffer = CMSampleBufferGetImageBuffer(buffer);
    size_t width  = CVPixelBufferGetWidth(cvBuffer);
    size_t height = CVPixelBufferGetHeight(cvBuffer);
    
    CMFormatDescriptionRef formatDescription   = CMSampleBufferGetFormatDescription(buffer);
    NSMutableDictionary *compressionProperties = [NSMutableDictionary new];
    
    [compressionProperties setObject:@(width * height * 2) forKey:AVVideoAverageBitRateKey];
    [compressionProperties setObject:@NO forKey:AVVideoAllowFrameReorderingKey];
    [compressionProperties setObject:@30 forKey:AVVideoExpectedSourceFrameRateKey];
    NSDictionary *videoSettings = @{
                                    AVVideoCodecKey : AVVideoCodecTypeH264,
                                    AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                    AVVideoWidthKey : @(width),
                                    AVVideoHeightKey: @(height),
                                    AVVideoCompressionPropertiesKey : compressionProperties
                                    };
    
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                           outputSettings:videoSettings
                                                         sourceFormatHint:formatDescription];
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    
    
    
}


#pragma mark - Init audio input with captureSessionPreset and sampleBuffer firstly .
-(void)initializeAudioWriterInput:(CMSampleBufferRef)buffer
{
    if (buffer == nil || _audioWriterInput != nil) return;
    
    YCSettings *settings = [YCSettings shareInstance];
    
    NSInteger bitrate  = settings.bitrate;
    NSInteger channels = settings.channels;
    float sampleRate   = settings.sampleRate;
    
    AVCaptureSessionPreset sessionPreset = settings.captureSessionPreset;
    
    if ([[settings capturePresetHighSource] containsObject:sessionPreset])
    {
        bitrate  = kYCSettingBitrateHigh;
        channels = kYCSettingChannelsDouble;
    } else if ([[settings capturePresetMediumSource] containsObject:sessionPreset])
    {
        bitrate  = kYCSettingBitrateMedium;
        channels = kYCSettingChannelsDouble;
    } else if ([[settings capturePresetLowSource] containsObject:sessionPreset])
    {
        bitrate  = kYCSettingBitrateLow;
        channels = kYCSettingChannelsSingle;
    }
    
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(buffer);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);

    if (basicDescription != NULL && basicDescription->mSampleRate != 0)
    {
        sampleRate = basicDescription->mSampleRate;
    }

    /*
     if (basicDescription != NULL && basicDescription->mChannelsPerFrame != 0)
     {
            channels = basicDescription->mChannelsPerFrame;
     }
    */
    
    NSDictionary *audioSettings = @{
                                    AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                    AVEncoderBitRateKey : @(bitrate),
                                    AVNumberOfChannelsKey : @(channels),
                                    AVSampleRateKey : @(sampleRate)
                                    };
    
    _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                           outputSettings:audioSettings
                                                         sourceFormatHint:formatDescription];
    _audioWriterInput.expectsMediaDataInRealTime = YES;
    
}

-(void)initializeAssetWriter
{
    if (_assetWriter != nil || !self.audioWriterInit || !self.videoWriterInit ) return ;
    
    NSError *error = nil;
    
    AVMutableMetadataItem *creationDateItem = [AVMutableMetadataItem new];
    creationDateItem.keySpace = AVMetadataKeySpaceCommon;
    creationDateItem.key = AVMetadataCommonKeyCreationDate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *zhLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    [dateFormatter setLocale:zhLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZZZZZ"];
    creationDateItem.value = [dateFormatter stringFromDate:[NSDate date]];
    
    AVMutableMetadataItem *softwareItem = [AVMutableMetadataItem new];
    softwareItem.keySpace = AVMetadataKeySpaceCommon;
    softwareItem.key = AVMetadataCommonKeySoftware;
    softwareItem.value = @"YCVideoTool";
    
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:_filePath fileType:AVFileTypeMPEG4 error:&error];
    self.assetWriter.metadata = @[softwareItem, creationDateItem];

    if (error != nil)
    {
        NSLog(@"init asset writer error : %@ ",error.localizedDescription);
        return ;
    }
    
    if ([self.assetWriter canAddInput:_videoWriterInput])
    {
        [self.assetWriter addInput:_videoWriterInput];
    }else
    {
        NSLog(@"add video writer input error");
    }
    
    
    if ([self.assetWriter canAddInput:_audioWriterInput])
    {
        [self.assetWriter addInput:_audioWriterInput];
    }else
    {
        NSLog(@"add audio writer input error");
    }
    
    self.assetWriter.shouldOptimizeForNetworkUse = YES;
    
}


-(BOOL)videoWriterInit
{
    return _videoWriterInput != nil;
}

-(BOOL)audioWriterInit
{
    return _audioWriterInput != nil;
}

-(BOOL)writerInit
{
    return _assetWriter != nil;
}


-(void)writeVideo:(CMSampleBufferRef)buffer completeHandler:(void (^)(BOOL))handler
{
    BOOL isSuccess = NO;
    
    if (CMSampleBufferDataIsReady(buffer))
    {
        if (_assetWriter.status == AVAssetWriterStatusUnknown)
        {
            [_assetWriter startWriting];
            CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(buffer);
            [_assetWriter startSessionAtSourceTime:timestamp];
        }
        
        if (_assetWriter.status == AVAssetWriterStatusFailed)
        {
            NSLog(@"writer video error : %@", _assetWriter.error.localizedDescription);
            isSuccess = NO;
            
        }
        
        if (_assetWriter.status == AVAssetWriterStatusWriting && [_videoWriterInput isReadyForMoreMediaData])
        {
            isSuccess = [_videoWriterInput appendSampleBuffer:buffer];
        }
    }else
    {
        NSLog(@"video writer is not ready .");
    }
    
    if (handler)
    {
        handler(isSuccess);
    }
}

-(void)writeAudio:(CMSampleBufferRef)buffer completeHandler:(void(^)(BOOL isSuccess))handler
{
    BOOL isSuccess = NO;
    
    if (CMSampleBufferDataIsReady(buffer))
    {
        if (_assetWriter.status == AVAssetWriterStatusUnknown)
        {
            [_assetWriter startWriting];
            CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(buffer);
            [_assetWriter startSessionAtSourceTime:timestamp];
        }
        
        if (_assetWriter.status == AVAssetWriterStatusFailed)
        {
            NSLog(@"writer audio error : %@", _assetWriter.error.localizedDescription);
            isSuccess = NO;
        }
        
        if (_assetWriter.status == AVAssetWriterStatusWriting && [_audioWriterInput isReadyForMoreMediaData])
        {
            isSuccess = [_audioWriterInput appendSampleBuffer:buffer];
        }
    }else
    {
        NSLog(@"audio writer is not ready .");
    }
    
    if (handler)
    {
        handler(isSuccess);
    }
}



-(void)stopWriting:(CMTime)time completeHandler:(void(^)(void))handler
{
    if (_assetWriter.status != AVAssetWriterStatusWriting)
    {
        if (handler)
        {
            handler();
        }
        return;
    }
    
    [_assetWriter endSessionAtSourceTime:time];
    [_assetWriter finishWritingWithCompletionHandler:^
     {
         if (handler)
         {
             handler();
         }
     }];
}


-(dispatch_queue_t)audioQueue
{
    if (_audioQueue == nil)
    {
        _audioQueue = dispatch_queue_create("lyc.YCVideoTool.Audio", nil);
    }
    return _audioQueue;
}
@end
