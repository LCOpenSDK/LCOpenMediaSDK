//
//  LCCondensedRecordInterface.h
//  LCNetworkModule
//
//  开放平台影集
//  - /openapi/getCondensedRecords
//  - /openapi/queryCondensedRecordBitmap
//

#import <Foundation/Foundation.h>
#import "LCCloudVideotapeInfo.h"

@class LCError;

NS_ASSUME_NONNULL_BEGIN

@interface LCCondensedRecordInterface : NSObject

/// packageType：aiCloudRecord（AI每日快看）、aiInsight（每日帧选）
+ (void)queryCondensedRecordBitmapWithToken:(NSString *)token
                                   deviceId:(NSString *)deviceId
                                  channelId:(NSString *)channelId
                                  productId:(NSString *)productId
                                  beginDay:(NSString *)beginDayYYYYMMDD
                                    endDay:(NSString *)endDayYYYYMMDD
                               packageType:(NSString *)packageType
                                     success:(void (^)(NSString *bitmap))success
                                     failure:(void (^)(LCError *error))failure;

+ (void)getCondensedRecordsWithToken:(NSString *)token
                            deviceId:(NSString *)deviceId
                           channelId:(NSString *)channelId
                           productId:(NSString *)productId
                           beginTime:(NSString *)beginTimeFull
                             endTime:(NSString *)endTimeFull
                            recordId:(NSString *)recordId
                           packageType:(NSString *)packageType
                                 count:(NSInteger)count
                                 success:(void (^)(NSArray<LCCloudVideotapeInfo *> *records))success
                                 failure:(void (^)(LCError *error))failure;

@end

NS_ASSUME_NONNULL_END
