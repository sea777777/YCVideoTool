//
//  YCVideoWriter.h
//  YCMediaDemo
//
//  Created by lyc on 2018/2/1.
//  Copyright © 2018年 lyc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface YCAssetWriter : NSObject


@property(nonatomic,strong) NSURL *filePath;


-(BOOL)initializeAVWriterInput:(CMSampleBufferRef)buffer isVideo:(BOOL)isVideo;

-(void)writeVideo:(CMSampleBufferRef)buffer completeHandler:(void(^)(BOOL isSuccess))handler;
-(void)writeAudio:(CMSampleBufferRef)buffer completeHandler:(void(^)(BOOL isSuccess))handler;

-(void)stopWriting:(CMTime)time completeHandler:(void(^)(void))handler;

-(BOOL)videoWriterInit;
-(BOOL)audioWriterInit;
-(BOOL)writerInit;

@end

