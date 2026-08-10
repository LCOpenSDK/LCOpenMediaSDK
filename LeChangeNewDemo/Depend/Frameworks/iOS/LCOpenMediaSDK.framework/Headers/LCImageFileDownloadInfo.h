//
//  LCImageFileDownloadInfo.h
//  LCMediaComponents
//
//  Created by lei on 2026/2/3.
//

#import <Foundation/Foundation.h>
#import "LCBaseDownloadInfo.h"
#import "LCMediaServerParameter.h"
#import "LCImageIdInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCImageFileDownloadInfo : LCBaseDownloadInfo

@property(nonatomic, strong)NSArray<LCImageIdInfo *> *imageIds; //下载id数组

@property(nonatomic, assign)CGFloat speed; //下载速度（不传默认：1.0）

@end

NS_ASSUME_NONNULL_END
