//
//  LCOpenMediaNetManager.h
//  Categories
//
//  Created by lei on 2025/6/16.
//

#import <Foundation/Foundation.h>
#import "LCMediaNetProtocol.h"

@class LCOpenMediaDevice;
@class LCOpenPlayTokenModel;

NS_ASSUME_NONNULL_BEGIN

@interface LCOpenMediaNetManager : NSObject<LCMediaNetProtocol>

+ (instancetype)shareInstance;

/// 实时预览 / 对讲：按能力集设置 device.isEncrypt、streamInfo.type、streamInfo.encrypt；国标 GB28181 固定 type=RTSV1、encrypt=0
+ (void)applyRealStreamAbilityFieldsToDevice:(LCOpenMediaDevice *)device
                              playTokenModel:(LCOpenPlayTokenModel *)playTokenModel
                                   isNVRLink:(BOOL)isNVRLink;

/// 卡录像：按能力集设置 device.isEncrypt、streamInfo.type、streamInfo.encrypt；国标 GB28181 固定 type=PBSV1、encrypt=0
+ (void)applyRecordStreamAbilityFieldsToDevice:(LCOpenMediaDevice *)device
                                playTokenModel:(LCOpenPlayTokenModel *)playTokenModel
                                     isNVRLink:(BOOL)isNVRLink;

/// 对讲：TSV1/TSV2 → type=TSV1、encrypt=2（公共部分同 HSEncrypt/TCM/std_newChip）；国标 GB28181 固定 type=RTSV1、encrypt=0
+ (void)applyTalkStreamAbilityFieldsToDevice:(LCOpenMediaDevice *)device
                              playTokenModel:(LCOpenPlayTokenModel *)playTokenModel
                                   isNVRLink:(BOOL)isNVRLink;

@end

NS_ASSUME_NONNULL_END
