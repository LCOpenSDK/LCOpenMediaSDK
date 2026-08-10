//
//  LCBaseDownloadInfo.h
//  LCMediaComponents
//
//  Created by lei on 2025/8/6.
//

#import <Foundation/Foundation.h>
#import "LCMediaServerParameter.h"
#import "LCBindDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCBaseDownloadInfo : NSObject

@property(nonatomic, nullable, copy)NSString *pid; //产品ID

@property(nonatomic, copy)NSString *did;   //设备序列号

@property(nonatomic, assign)NSInteger cid;  //通道号

@property(nonatomic, assign)NSInteger index; //下载唯一标志符,区分下载任务

@property(nonatomic, copy)NSString *userName; //用户名

@property(nonatomic, copy)NSString *passWord; //设备密码

@property(nonatomic, copy)NSString *encryptKey; //加密秘钥（自定义加密秘钥）

@property(nonatomic, assign)NSInteger encryptMode; //加密模式:(0:不加密; 1:设备序列号或自定义密码加密; 3:三码合一设备加密模式; 5:0xC5加密)

@property(nonatomic, assign)BOOL isTls; //是否TLS加密

@property(nonatomic, assign)BOOL isQuic; ////是否走quic协议

// 码流地址：用于MQTT获取拉流地址
@property (nonatomic, copy, nullable)NSString *streamUrlV4;

@property(nonatomic, strong, nullable)LCBindDeviceInfo *bindDevice; //绑定设备信息

@end

NS_ASSUME_NONNULL_END
