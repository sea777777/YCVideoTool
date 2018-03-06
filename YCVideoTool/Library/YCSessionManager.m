//
//  YCSessionManager.m
//  YCMediaDemo
//  Created by lyc on 2018/1/7.
//  git : xxxxxxxx
//  Copyright © 2018年 lyc. All rights reserved.
//

#import "YCSessionManager.h"
#import "YCSessionManager+DeviceUtils.h"
#import "YCAssetWriter.h"
#import "YCVideoChunk.h"


@interface YCSessionManager()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{

}


@property(nonatomic,strong) AVCaptureSession                *captureSession;
@property(nonatomic,strong) AVCaptureAudioDataOutput        *audioOutput;
@property(nonatomic,strong) AVCaptureDeviceInput            *videoInput;
@property(nonatomic,strong) YCAssetWriter                   *assetWriter;

@property(nonatomic,assign) CMTime                          startTime;
@property(nonatomic,assign) CMTime                          lastTime;
@property(nonatomic,assign) CMTime                          totalPauseTime;
@property(nonatomic,assign) CMTime                          currentChunkStartTime;

@property(nonatomic,strong) NSMutableArray<YCVideoChunk*>   *chunks;
@property(nonatomic,strong) dispatch_queue_t                sessionQueue;
@property(nonatomic,assign) BOOL                            isRecording;
@property(nonatomic,assign) BOOL                            isPaused;


@end



@implementation YCSessionManager

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.chunks = [NSMutableArray new];
        self.totalPauseTime = kCMTimeZero;
        self.currentChunkStartTime = kCMTimeInvalid;
        [self initSettings];
        [self initCaptureSession];
        [self initSessionQueue];
        [self initPreviewLayer];
        [self initVideoOutput];
        [self initAudioOutput];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveDeviceOrientationNotication:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];

    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)initSettings
{
    self.videoOrientation     = [YCSettings shareInstance].videoOrientation;
    self.captureSessionPreset = [YCSettings shareInstance].captureSessionPreset;
    self.maxRecordTime        = [YCSettings shareInstance].maxRecordTime;
}


-(void)initCaptureSession
{
    if (_captureSession == nil)
    {
        _captureSession = [AVCaptureSession new];
        _captureSession.automaticallyConfiguresApplicationAudioSession = YES;
    }
}

-(void)initSessionQueue
{
    if (_sessionQueue == nil)
    {
        _sessionQueue = dispatch_queue_create("lyc.YCVideoTools", DISPATCH_QUEUE_SERIAL);
    }
}


-(void)initPreviewLayer
{
    if (_previewLayer == nil)
    {
        _previewLayer = [AVCaptureVideoPreviewLayer new];
        _previewLayer.session = _captureSession;
    }
}


-(void)initVideoOutput
{
    if(_videoOutput == nil)
    {
        _videoOutput = [AVCaptureVideoDataOutput new];
        _videoOutput.alwaysDiscardsLateVideoFrames = NO;
        [_videoOutput setSampleBufferDelegate:self queue:_sessionQueue];
        
        [_videoOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation = AVCaptureVideoOrientationPortrait;

        
    }
}

-(void)initAudioOutput
{
    if (_audioOutput == nil)
    {
        _audioOutput = [AVCaptureAudioDataOutput new];
        [_audioOutput setSampleBufferDelegate:self queue:_sessionQueue];
    }
}


-(void)configSession
{
    [_captureSession beginConfiguration];
    
    if ([_captureSession canSetSessionPreset:_captureSessionPreset])
    {
        [_captureSession setSessionPreset:_captureSessionPreset];
    }
   
    NSError *error = nil;

    //add video input
    AVCaptureDevice *captureDevice = [self preferrdCaptureDevice:AVCaptureDeviceTypeBuiltInWideAngleCamera position:AVCaptureDevicePositionBack];
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!_videoInput)
    {
        NSLog(@" create videoDeviceInput failure.  error : %@",error);
        [_captureSession commitConfiguration];
        return;
    }
    
    if (![_captureSession.inputs containsObject:_videoInput] && [_captureSession canAddInput:_videoInput])
    {
        [_captureSession addInput:_videoInput];
    }else
    {
        NSLog(@"captureSession can't add videoDeviceInput");
        [_captureSession commitConfiguration];
        return;
    }
    
    // add audio input
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!audioDeviceInput )
    {
        NSLog(@"create audio device input failure . error:%@",error );
    }
    
    if (![_captureSession.inputs containsObject:audioDeviceInput] && [_captureSession canAddInput:audioDeviceInput])
    {
        [_captureSession addInput:audioDeviceInput];
    }else
    {
        NSLog(@"capturesession can't add audioInput . " );
    }
    
    
    //add video output
    if (![_captureSession.outputs containsObject:_videoOutput] && [_captureSession canAddOutput:_videoOutput])
    {
        
        [_captureSession addOutput:_videoOutput];
    }else
    {
        NSLog(@"capturesession can't add videooutput . ");
        [_captureSession commitConfiguration];
        return;
    }
    
    //add audio output
    if (![_captureSession.outputs containsObject:_audioOutput] && [_captureSession canAddOutput:_audioOutput])
    {
        [_captureSession addOutput:_audioOutput];
    }else
    {
        NSLog(@"capturesession can't add audiooutput . ");
        [_captureSession commitConfiguration];
        return;
    }
    
    [_captureSession commitConfiguration];
    
}



-(void)startSession
{
    dispatch_async(_sessionQueue, ^
    {
        [self configSession];
        [self.captureSession startRunning];
        [self changeVideoOrientation:_videoOrientation];
    });
}

-(void)startRecording
{
    _isRecording = YES;
}

-(void)pauseRecordingWithHandler:(void (^)(void))completion
{
    _isRecording = NO;
    _isPaused = YES;
    YCVideoChunk *chunk = [[YCVideoChunk alloc]initWithFilePath:self.assetWriter.filePath];
    chunk.startTime = self.currentChunkStartTime;
    chunk.endTime = self.lastTime;
    [_chunks addObject:chunk];
    _currentChunkStartTime = kCMTimeInvalid;
    
    dispatch_async(_sessionQueue, ^
    {
        [self.assetWriter stopWriting:_lastTime completeHandler:^
        {
            _assetWriter = nil;
            if (completion)
            {
                completion();
            }
        }];
    });
}

-(void)stopRecordingWithHandler:(void (^)(void))completion
{
    _isRecording = NO;
    
    dispatch_async(_sessionQueue, ^
    {
        [self mergeChunks:^(AVMutableComposition *compositon)
         {
             AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:compositon presetName:AVAssetExportPresetHighestQuality];
             exportSession.shouldOptimizeForNetworkUse = YES;
             NSURL *fileUrl = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"video.mp4"];
             [[NSFileManager defaultManager]removeItemAtURL:fileUrl error:nil];
             exportSession.outputFileType = AVFileTypeMPEG4;
             exportSession.outputURL = fileUrl;
             self.videoPath = fileUrl;
             [exportSession exportAsynchronouslyWithCompletionHandler:^{
                 if (completion)
                 {
                     completion();
                 }
             }];
         }];
    });
}

-(float)deleteLastChunk
{
    if (_chunks.count>=2)
    {
        YCVideoChunk *lastSecendChunk = _chunks[_chunks.count-2];
        YCVideoChunk *lastChunk = _chunks.lastObject;
        _totalPauseTime = CMTimeSubtract(_totalPauseTime,CMTimeSubtract(lastChunk.startTime, lastSecendChunk.endTime));
        _lastTime = lastSecendChunk.endTime;
        [[NSFileManager defaultManager] removeItemAtURL:lastChunk.path error:nil];
        [_chunks removeLastObject];
        return CMTimeGetSeconds(lastChunk.duringTime);
    }else
    {
        _totalPauseTime = kCMTimeZero;
        _startTime = kCMTimeInvalid;
        _lastTime = kCMTimeZero;
        _isPaused = NO;
        YCVideoChunk *lastChunk = _chunks.lastObject;
        if (lastChunk != nil)
        {
            [[NSFileManager defaultManager] removeItemAtURL:lastChunk.path error:nil];
            [_chunks removeLastObject];
        }
        return 0.f;
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate and AVCaptureAudioDataOutputSampleBufferDelegate -
-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!_isRecording) return;
    
    // Init audio and video writerinput .
    if (![self.assetWriter initializeAVWriterInput:sampleBuffer isVideo:(output == _videoOutput)]) return;
    
    float bufferSeconds = [self calculateTime:sampleBuffer];
    
    if (_delegate && [_delegate respondsToSelector:@selector(didRecordingProgress:progress:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [_delegate didRecordingProgress:self progress:bufferSeconds/_maxRecordTime];
        });
    }
    
    if (output == _videoOutput)
    {
        [self handleVideoOutput:output buffer:sampleBuffer connection:connection];
    }else if (output == _audioOutput)
    {
        [self handleAudioOutput:output buffer:sampleBuffer connection:connection];
    }

}


-(void)handleVideoOutput:(AVCaptureOutput *)output buffer:(CMSampleBufferRef)buffer connection:(AVCaptureConnection *)connection
{
    [self.assetWriter writeVideo:buffer completeHandler:^(BOOL isSuccess) {

    }];
}

-(void)handleAudioOutput:(AVCaptureOutput *)output buffer:(CMSampleBufferRef)buffer connection:(AVCaptureConnection *)connection
{
    [self.assetWriter writeAudio:buffer completeHandler:^(BOOL isSuccess) {

    }];
}


#pragma mark - UIDeviceOrientationDidChangeNotification -
-(void)didReceiveDeviceOrientationNotication:(NSNotificationCenter*)notification
{
    if (_autoAdaptOrientation == NO) return;
    
    dispatch_async(_sessionQueue, ^
    {
        [self changeVideoOrientation:[self currentDeviceOrientation]];
    });
}

-(void)setVideoPath:(NSURL *)videoPath
{
    if (_videoPath != videoPath)
    {
        _videoPath = videoPath;
    }
}


#pragma mark - update settings -
-(void)setCaptureSessionPreset:(AVCaptureSessionPreset)captureSessionPreset
{
    _captureSessionPreset = captureSessionPreset;
    [YCSettings shareInstance].captureSessionPreset = captureSessionPreset;
}

-(void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    _videoOrientation = videoOrientation;
    [YCSettings shareInstance].videoOrientation = videoOrientation;
}

-(void)setAutoAdaptOrientation:(BOOL)autoAdaptOrientation
{
    _autoAdaptOrientation = autoAdaptOrientation;
    [YCSettings shareInstance].autoAdaptOrientation = autoAdaptOrientation;
}

-(void)setMaxRecordTime:(float)maxRecordTime
{
    _maxRecordTime = maxRecordTime;
    [YCSettings shareInstance].maxRecordTime = maxRecordTime;
}


-(YCAssetWriter *)assetWriter
{
    if (_assetWriter == nil)
    {
        _assetWriter = [YCAssetWriter new];
        _assetWriter.filePath = [self nextTempURL];
        [[NSFileManager defaultManager] removeItemAtURL:_assetWriter.filePath error:nil];
    }
    return _assetWriter;
}

-(NSURL*)nextTempURL
{
    NSString *name = [NSString stringWithFormat:@"temp_video_%ld.mp4",(_chunks.count+1)];
    return [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:name];
}

-(float)calculateTime:(CMSampleBufferRef)sampleBuffer
{
    CMTime currentTime  = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CMTime duringTime   = CMSampleBufferGetDuration(sampleBuffer);
    self.startTime      = CMTIME_IS_INVALID(self.startTime) ? currentTime : self.startTime;
   
    self.totalPauseTime = self.isPaused ? CMTimeAdd(CMTimeSubtract(currentTime,_lastTime),self.totalPauseTime):self.totalPauseTime;
    self.isPaused = NO;
    self.lastTime = duringTime.value>0?CMTimeAdd(currentTime,duringTime):CMTimeAdd(currentTime, _videoInput.device.activeVideoMinFrameDuration);
    self.currentChunkStartTime = CMTIME_IS_INVALID(self.currentChunkStartTime) ? currentTime : self.currentChunkStartTime;
    
    return CMTimeGetSeconds(CMTimeSubtract(CMTimeSubtract(_lastTime, _startTime),self.totalPauseTime));
}

-(void)mergeChunks:(void(^)(AVMutableComposition*))completeHandler
{
    dispatch_async(_sessionQueue, ^
    {
        AVMutableCompositionTrack *audioTrack = nil;
        AVMutableCompositionTrack *videoTrack = nil;
        AVMutableComposition *composition = [AVMutableComposition new];

        CMTime currentTime = composition.duration;
        for (YCVideoChunk *chunk in _chunks) {
            AVAsset *asset = chunk.asset;
            
            NSArray *audioAssetTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            NSArray *videoAssetTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            
            CMTime maxBounds = kCMTimeInvalid;
            
            CMTime videoTime = currentTime;
            for (AVAssetTrack *videoAssetTrack in videoAssetTracks) {
                if (videoTrack == nil) {
                    NSArray *videoTracks = [composition tracksWithMediaType:AVMediaTypeVideo];
                    
                    if (videoTracks.count > 0) {
                        videoTrack = [videoTracks firstObject];
                    } else {
                        videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                        videoTrack.preferredTransform = videoAssetTrack.preferredTransform;
                    }
                }
                
                videoTime = [self _appendTrack:videoAssetTrack toCompositionTrack:videoTrack atTime:videoTime withBounds:maxBounds];
                maxBounds = videoTime;
            }
            
            CMTime audioTime = currentTime;
            for (AVAssetTrack *audioAssetTrack in audioAssetTracks) {
                if (audioTrack == nil) {
                    NSArray *audioTracks = [composition tracksWithMediaType:AVMediaTypeAudio];
                    
                    if (audioTracks.count > 0) {
                        audioTrack = [audioTracks firstObject];
                    } else {
                        audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                    }
                }
                
                audioTime = [self _appendTrack:audioAssetTrack toCompositionTrack:audioTrack atTime:audioTime withBounds:maxBounds];
            }
            
            currentTime = composition.duration;
            
        }
        
        if (completeHandler)
        {
            completeHandler(composition);
        }
    });

}


- (CMTime)_appendTrack:(AVAssetTrack *)track toCompositionTrack:(AVMutableCompositionTrack *)compositionTrack atTime:(CMTime)time withBounds:(CMTime)bounds {
    CMTimeRange timeRange = track.timeRange;
    time = CMTimeAdd(time, timeRange.start);
    
    if (CMTIME_IS_VALID(bounds)) {
        CMTime currentBounds = CMTimeAdd(time, timeRange.duration);
        
        if (CMTIME_COMPARE_INLINE(currentBounds, >, bounds)) {
            timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(timeRange.duration, CMTimeSubtract(currentBounds, bounds)));
        }
    }
    
    if (CMTIME_COMPARE_INLINE(timeRange.duration, >, kCMTimeZero)) {
        NSError *error = nil;
        [compositionTrack insertTimeRange:timeRange ofTrack:track atTime:time error:&error];
        
        if (error != nil) {
            NSLog(@"error  %@", error);
        }
        return CMTimeAdd(time, timeRange.duration);
    }
    
    return time;
}
@end

