//
//  LCRecordThumbsDownloadInfo.h
//  LCMediaComponents
//
//  Created by lei on 2025/8/6.
//

#import <UIKit/UIKit.h>
#import "LCBaseDownloadInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCRecordThumbsDownloadInfo : LCBaseDownloadInfo

@property(nonatomic, copy)NSString *startTime; //开始时间

@property(nonatomic, copy)NSString *endTime; //结束时间

@property(nonatomic, assign)NSInteger fileType; //文件类型:不传或者1：视频流； 2：关键I帧流 3：图片JPEG流(封装dhav头尾) 4：手动截图图片流

@end

NS_ASSUME_NONNULL_END
