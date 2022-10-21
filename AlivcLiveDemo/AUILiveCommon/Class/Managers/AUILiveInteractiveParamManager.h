//
//  AUILiveInteractiveParamManager.h
//  AlivcLivePusherDemo
//
//  Created by ISS013602000846 on 2022/8/31.
//  Copyright © 2022 TripleL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AUILiveSDKHeader.h"

typedef NS_ENUM(NSInteger, AUILiveInteractiveURLConfigType) {
    AUILiveInteractiveURLConfigTypeLinkMic = 0, // 连麦互动
    AUILiveInteractiveURLConfigTypePK,          // PK互动
};

NS_ASSUME_NONNULL_BEGIN

@interface AUILiveInteractiveParamManager : NSObject

/**
 分辨率
 * 默认 : AlivcLivePushResolution540P
 */
@property (nonatomic, assign) AlivcLivePushResolution resolution;

/**
 视频编码模式
 * 默认 : AlivcLivePushVideoEncoderModeHard
 */
@property (nonatomic, assign) AlivcLivePushVideoEncoderMode videoEncoderMode;

/**
 音频编码模式
 * 默认 : AlivcLivePushAudioEncoderModeHard
 */
@property (nonatomic, assign) AlivcLivePushAudioEncoderMode audioEncoderMode;

+ (instancetype)manager;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
