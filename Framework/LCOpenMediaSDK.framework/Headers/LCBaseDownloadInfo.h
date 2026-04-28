//
//  LCBaseDownloadInfo.h
//  LCMediaComponents
//
//  Created by lei on 2025/8/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCBaseDownloadInfo : NSObject

@property(nonatomic, nullable, copy)NSString *pid; //产品ID

@property(nonatomic, copy)NSString *did;   //设备序列号

@property(nonatomic, assign)NSInteger cid;  //通道号

@end

NS_ASSUME_NONNULL_END
