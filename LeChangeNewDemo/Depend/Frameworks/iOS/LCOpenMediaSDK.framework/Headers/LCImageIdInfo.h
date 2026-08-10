//
//  LCImageIdInfo.h
//  LCMediaComponents
//
//  Created by lei on 2026/2/6.
//

#import <Foundation/Foundation.h>
#import "LCVideoPlayerDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCImageIdInfo : NSObject

@property(nonatomic, copy)NSString *imageId; //图片id

@property(nonatomic, assign)LCDevImageType imageType; //图片类型

@end

NS_ASSUME_NONNULL_END
