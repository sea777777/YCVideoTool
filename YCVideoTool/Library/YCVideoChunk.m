//
//  YCVideoChunk.m
//  YCMediaDemo
//  Created by lyc on 2018/2/20.
//  git : xxxxxxxx
//  Copyright © 2018年 lyc. All rights reserved.
//

#import "YCVideoChunk.h"

@implementation YCVideoChunk


-(instancetype)initWithFilePath:(NSURL*)path
{
    self = [super init];
    if (self) {
        _path = path;
    }
    return self;
}

-(AVAsset *)asset
{
    if (_asset == nil)
    {
        _asset = [AVAsset assetWithURL:_path];
    }
    return _asset;
}

-(CMTime)duringTime
{
    return CMTimeSubtract(self.endTime,self.startTime);
}

@end
