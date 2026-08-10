//
//  LCDevPlayInfo.h
//  LCMediaComponents
//
//  Created by lei on 2026/3/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCDevPlayInfo : NSObject<NSCopying>

/// 对应片段子设备序列号
@property(nonatomic, copy)NSString *did;

/// 对应片段子设备通道号
@property(nonatomic, assign)NSInteger cid;

/// 对应片段开始播放时间,格式:yyyyMMddHHmmss
@property(nonatomic, copy)NSString *startTime;

/// 对应片段结束播放时间,格式:yyyyMMddHHmmss
@property(nonatomic, copy)NSString *endTime;

/// 转换成playInfo字符串,格式:sn/channel/yyyyMMddHHmmss-yyyyMMddHHmmss
- (NSString *)playInfoString;

@end

NS_ASSUME_NONNULL_END
