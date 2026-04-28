//
//  LCRecordThumbsDownloadInfo.h
//  LCMediaComponents
//
//  Created by lei on 2025/8/6.
//

#import <UIKit/UIKit.h>
#import "LCBaseDownloadInfo.h"
#import "LCMediaServerParameter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCRecordThumbsDownloadInfo : LCBaseDownloadInfo

@property(nonatomic, assign)NSInteger index; //下载唯一标志符,区分下载任务

@property(nonatomic, copy)NSString *startTime; //开始时间

@property(nonatomic, copy)NSString *endTime; //结束时间

@property(nonatomic, copy)NSString *userName; //用户名

@property(nonatomic, copy)NSString *passWord; //设备密码

@property(nonatomic, assign)NSInteger encryptMode; //加密模式:(0:不加密; 1:设备序列号或自定义密码加密; 3:三码合一设备加密模式)

@property(nonatomic, copy)NSString *encryptKey; //加密秘钥

@property(nonatomic, assign)BOOL isTls; //是否TLS加密

@property(nonatomic, assign)NSInteger fileType; //文件类型:不传或者1：视频流； 2：关键I帧流 3：图片JPEG流(封装dhav头尾) 4：手动截图图片流

@property(nonatomic, strong, nullable)LCMediaServerParameter *serverParam; //长链接地址

@end

NS_ASSUME_NONNULL_END
