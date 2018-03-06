//
//  YCVideoChunk.h
//  YCMediaDemo
//
//  Created by LYC on 2018/2/20.
//  Copyright © 2018年 lyc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface YCVideoChunk : NSObject


@property(nonatomic,strong,readonly) NSURL *path;

@property(nonatomic,strong) AVAsset *asset;

@property(nonatomic,assign) CMTime startTime;

@property(nonatomic,assign) CMTime endTime;

@property(nonatomic,assign) CMTime duringTime;

-(instancetype)initWithFilePath:(NSURL*)path;



@end
