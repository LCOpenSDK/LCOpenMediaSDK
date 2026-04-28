//
//  LCCloudExtraInfo.h
//  LCMediaComponents
//
//  Created by lei on 2026/3/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCCloudExtraInfo : NSObject

@property(nonatomic, strong)NSArray<NSString *> *pswArray; //密码组

@property(nonatomic, assign)NSInteger businessType; //业务类型: 1-降本影集

@property(nonatomic, assign)BOOL preciseSeek; //YES：精准seek  NO：非精准seek（与以前效果一致）;默认NO

//下载优化参数
@property(nonatomic, copy)NSString *uid;
@property(nonatomic, copy)NSString *ak;
@property(nonatomic, copy)NSString *expireTime;
@property(nonatomic, copy)NSString *fileToken;
@property(nonatomic, copy)NSString *m3uPath;
@property(nonatomic, copy)NSString *regionId;
@property(nonatomic, copy)NSString *streamAddr;  //下载文件的地址

/// 参数模型转换成json
-(NSString *)toJsonString;

@end

NS_ASSUME_NONNULL_END
