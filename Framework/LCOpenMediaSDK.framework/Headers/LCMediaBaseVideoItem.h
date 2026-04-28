//
//  LCMediaBaseVideoItem.h
//  LCOpenMediaSDK
//
//  Created by lei on 2025/9/9.
//

#import "LCBaseVideoItem.h"
#import "LCBindDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCMediaBaseVideoItem : LCBaseVideoItem

@property (nonatomic, assign) NSInteger streamHandler; // 拉流句柄

@property (nonatomic, assign) NSInteger playport; // 播放port句柄

//是否展示辅助帧
@property (nonatomic, assign) BOOL isSupportBoundingBox;

@property(nonatomic, assign)BOOL isMixStream; //是否走混流

@end

NS_ASSUME_NONNULL_END
