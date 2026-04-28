//
//  LCNewPlayBackRouter.m
//  LCNewPlayBackModule
//
//  Created by lei on 2022/10/9.
//

#import "LCNewPlayBackRouter.h"
#import <LCBaseModule/LCModule.h>
#import "LCNewVideotapeListViewController.h"
#import "LCNewVideotapePlayerViewController.h"
#import "LCNewDeviceVideotapePlayManager.h"
#import "LCAICloudEventListViewController.h"
#import "LCAIFrameSelectEventListViewController.h"
#import <LCNetworkModule/LCCloudVideotapeInfo.h>

static NSString * const pbVideotapeListRouter = @"LCNewPlayBackRouter_VideotapeListRouter";
static NSString * const pbVideotapePlayer = @"LCNewPlayBackRouter_VideotapePlayer";
static NSString * const pbAICloudEventList = @"LCNewPlayBackRouter_AICloudEventList";
static NSString * const pbAIFrameSelectEventList = @"LCNewPlayBackRouter_AIFrameSelectEventList";

@interface LCNewPlayBackRouter()<LCModuleProtocol>

@end

@implementation LCNewPlayBackRouter

- (void)moduleInit {
    //录像列表
    [self registerVideotapeList];
    //录像播放
    [self registerVideotapePlayer];
    // AI 智见云存储：AI 每日快看
    [self registerAICloudEventList];
    // 每日帧选（独立页面，aiInsight）
    [self registerAIFrameSelectEventList];
}

-(void)registerVideotapeList {
    [LCRouter registerURLPattern:pbVideotapeListRouter toObjectHandler:^id(NSDictionary *routerParameters) {
        NSDictionary *userInfo = routerParameters[LCRouterParameterUserInfo];
        NSNumber *type = (NSNumber *)userInfo[@"type"];
        
        LCNewVideotapeListViewController *videotapeListVC = [[LCNewVideotapeListViewController alloc] init];
        videotapeListVC.defaultType = [type integerValue];
        return videotapeListVC;
    }];
}

-(void)registerVideotapePlayer {
    [LCRouter registerURLPattern:pbVideotapePlayer toObjectHandler:^id(NSDictionary *routerParameters) {
        NSDictionary *userInfo = routerParameters[LCRouterParameterUserInfo];
        NSString *cloudVideoJson = (NSString *)userInfo[@"cloudVideoJson"];
        NSString *subCloudVideoJson = (NSString *)userInfo[@"subCloudVideoJson"];
        NSString *selectedChannelId = (NSString *)userInfo[@"selectedChannelId"];
        NSString *localVideoJson = (NSString *)userInfo[@"localVideoJson"];
        NSNumber *type = (NSNumber *)userInfo[@"type"];
        
        if (cloudVideoJson != nil) {
            LCCloudVideotapeInfo *cloudInfo = [LCCloudVideotapeInfo jsonToObject:cloudVideoJson];
            if (cloudInfo != nil) {
                [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo = cloudInfo;
            }
        }
        
        if (subCloudVideoJson != nil) {
            LCCloudVideotapeInfo *cloudInfo = [LCCloudVideotapeInfo jsonToObject:subCloudVideoJson];
            if (cloudInfo != nil) {
                [LCNewDeviceVideotapePlayManager shareInstance].subCloudVideotapeInfo = cloudInfo;
            }
        }
        
        if (localVideoJson != nil) {
            LCLocalVideotapeInfo *localInfo = [LCLocalVideotapeInfo jsonToObject:localVideoJson];
            if (localInfo != nil) {
                [LCNewDeviceVideotapePlayManager shareInstance].localVideotapeInfo = localInfo;
            }
        }
        
        LCNewVideotapePlayerViewController *videotapePlayerVC = [[LCNewVideotapePlayerViewController alloc] init];
        if (selectedChannelId != nil) {
            [LCNewDeviceVideotapePlayManager shareInstance].displayChannelID = selectedChannelId;
        }
        videotapePlayerVC.type = [type integerValue];
        [LCNewDeviceVideotapePlayManager shareInstance].type = [type integerValue];
        return videotapePlayerVC;
    }];
}

- (void)registerAICloudEventList {
    [LCRouter registerURLPattern:pbAICloudEventList toObjectHandler:^id(__unused NSDictionary *routerParameters) {
        return [[LCAICloudEventListViewController alloc] init];
    }];
}

- (void)registerAIFrameSelectEventList {
    [LCRouter registerURLPattern:pbAIFrameSelectEventList toObjectHandler:^id(__unused NSDictionary *routerParameters) {
        return [[LCAIFrameSelectEventListViewController alloc] init];
    }];
}

@end
