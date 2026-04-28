#import "LCAIFrameSelectRecordPluginPresenter.h"
#import "LCNewDeviceVideotapePlayManager.h"
#import <LCBaseModule/LCProgressHUD.h>
#import <LCMediaBaseModule/PHAsset+Lechange.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import <UIKit/UIKit.h>

@implementation LCAIFrameSelectRecordPluginPresenter

- (void)onPlaySuccess:(LCBaseVideoItem *)videoItem {
    (void)videoItem;
    if ([LCNewDeviceVideotapePlayManager shareInstance].isSoundOn) {
        [self.recordPlugin playAudioWithIsCallback:YES];
    } else {
        [self.recordPlugin stopAudioWithIsCallback:YES];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [LCProgressHUD hideAllHuds:[UIApplication sharedApplication].keyWindow];
        if (self.onBizState) {
            self.onBizState(LCAICloudQuickLookBizSceneNone, nil);
        }
        if (self.onRefresh) {
            self.onRefresh();
        }
    });
}

- (void)onPlayLoading:(LCBaseVideoItem *)videoItem {
    (void)videoItem;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onBizState) {
            if (self.expectFirstSDKLoading) {
                self.expectFirstSDKLoading = NO;
                self.onBizState(LCAICloudQuickLookBizSceneFirstLoading, nil);
            } else {
                self.onBizState(LCAICloudQuickLookBizSceneLoading, nil);
            }
        }
        if (self.onRefresh) {
            self.onRefresh();
        }
    });
}

- (void)onPlayPaused:(LCBaseVideoItem *)videoItem {
    (void)videoItem;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onBizState) {
            self.onBizState(LCAICloudQuickLookBizScenePlay, nil);
        }
        if (self.onRefresh) {
            self.onRefresh();
        }
    });
}

- (void)onPlayStop:(LCBaseVideoItem *)videoItem saveLastFrame:(BOOL)saveLastFrame {
    (void)videoItem;
    (void)saveLastFrame;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onRefresh) {
            self.onRefresh();
        }
    });
}

- (void)onPlayFinished:(LCBaseVideoItem *)videoItem {
    (void)videoItem;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onBizState) {
            self.onBizState(LCAICloudQuickLookBizSceneReplay, nil);
        }
        if (self.onRefresh) {
            self.onRefresh();
        }
    });
}

- (void)onRecordStart:(LCBaseVideoItem *)videoItem {
    (void)videoItem;
}

- (void)onPlayFailureWithVideoError:(NSString *)videoError type:(NSString *)type videoItem:(LCBaseVideoItem *)videoItem {
    (void)type;
    (void)videoItem;
    dispatch_async(dispatch_get_main_queue(), ^{
        [LCProgressHUD hideAllHuds:[UIApplication sharedApplication].keyWindow];
        NSString *msg = videoError.length ? videoError : @"play error";
        if (self.onBizState) {
            self.onBizState(LCAICloudQuickLookBizSceneRetry, msg);
        }
        if (self.onRefresh) {
            self.onRefresh();
        }
    });
}

- (void)onStreamInfoWithVideoError:(NSString *)videoError type:(NSString *)type streamInfo:(NSString *)streamInfo videoItem:(LCBaseVideoItem *)videoItem {
    (void)videoError;
    (void)type;
    (void)streamInfo;
    (void)videoItem;
}

- (void)onReceiveDataWithByteRate:(NSInteger)byte videoItem:(LCBaseVideoItem *)videoItem {
    (void)byte;
    (void)videoItem;
}

- (void)onPlayerTime:(NSTimeInterval)playTime videoItem:(LCBaseVideoItem *)videoItem {
    (void)videoItem;
    if (self.onPlayTime) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onPlayTime(playTime);
        });
    }
}

- (void)onPlaySpeedChange:(CGFloat)speed videoItem:(LCBaseVideoItem *)videoItem {
    (void)speed;
    (void)videoItem;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onRefresh) {
            self.onRefresh();
        }
    });
}

- (void)onAssistFrameInfoWithJsonDic:(NSDictionary<NSString *, id> *)jsonDic {
    (void)jsonDic;
}

- (void)onEZoomChanged:(CGFloat)scale with:(LCBaseVideoItem *)videoItem {
    (void)scale;
    (void)videoItem;
}

- (void)onSoundChanged:(BOOL)isAudioOpen {
    (void)isAudioOpen;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onRefresh) {
            self.onRefresh();
        }
    });
}

- (void)onSnapPicFail {
    dispatch_async(dispatch_get_main_queue(), ^{
        [LCProgressHUD showMsg:@"ai_insight_snapshot_failed".lcMedia_T];
    });
}

- (void)onSnapPicSuccessWithPaths:(NSDictionary<NSNumber *, NSString *> *)paths {
    NSArray *values = [paths allValues];
    for (NSString *path in values) {
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        NSURL *imgURL = [NSURL fileURLWithPath:path];
        [PHAsset saveImageToCameraRoll:image url:imgURL success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [LCProgressHUD showMsg:@"livepreview_localization_success".lcMedia_T];
            });
        } failure:^(NSError *error) {
            (void)error;
            dispatch_async(dispatch_get_main_queue(), ^{
                [LCProgressHUD showMsg:@"livepreview_localization_fail".lcMedia_T];
            });
        }];
    }
}

- (void)onRecordFail {
    dispatch_async(dispatch_get_main_queue(), ^{
        [LCProgressHUD showMsg:@"ai_insight_record_failed".lcMedia_T];
    });
}

- (void)onRecordFinish:(LCBaseVideoItem *)videoItem paths:(NSDictionary<NSNumber *, NSString *> *)paths {
    (void)videoItem;
    NSArray *pathArr = [paths allValues];
    for (NSString *path in pathArr) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSURL *davURL = [NSURL fileURLWithPath:path];
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                [PHAsset saveVideoAtURL:davURL success:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [LCProgressHUD showMsg:@"livepreview_localization_success".lcMedia_T];
                    });
                } failure:^(NSError *error) {
                    (void)error;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [LCProgressHUD showMsg:@"livepreview_localization_fail".lcMedia_T];
                    });
                }];
            } else {
                [LCProgressHUD showMsg:@"livepreview_localization_fail".lcMedia_T];
            }
        });
    }
}

- (void)processPan:(CGFloat)dx dy:(CGFloat)dy channelId:(NSInteger)channelId {
    (void)dx;
    (void)dy;
    (void)channelId;
}

- (void)processPanBegin:(NSInteger)channelId {
    (void)channelId;
}

- (void)processPanEnd:(NSInteger)channelId {
    (void)channelId;
}

- (UIView *)viewForStateLayer:(LCOpenMediaRecordPlugin *)plugin {
    (void)plugin;
    return nil;
}

- (UIView *)viewForToolLayer:(LCOpenMediaRecordPlugin *)plugin {
    (void)plugin;
    return nil;
}

- (NSString *)configFilePathWithCid:(NSInteger)cid fileType:(enum LCFilePathType)fileType {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths firstObject];
    NSString *myDirectory = [libraryDirectory stringByAppendingPathComponent:@"lechange"];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:myDirectory isDirectory:&isDir]) {
        [fm createDirectoryAtPath:myDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyyMMddHHmmss";
    NSString *strDate = [df stringFromDate:[NSDate date]];
    if (fileType == LCFilePathTypeSnapShot) {
        NSString *picDir = [myDirectory stringByAppendingPathComponent:@"picture"];
        if (![fm fileExistsAtPath:picDir isDirectory:&isDir]) {
            [fm createDirectoryAtPath:picDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        return [[picDir stringByAppendingPathComponent:strDate] stringByAppendingFormat:@"_%ld.jpg", (long)cid];
    }
    if (fileType == LCFilePathTypeRecord) {
        NSString *vidDir = [myDirectory stringByAppendingPathComponent:@"video"];
        if (![fm fileExistsAtPath:vidDir isDirectory:&isDir]) {
            [fm createDirectoryAtPath:vidDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        return [[vidDir stringByAppendingPathComponent:strDate] stringByAppendingFormat:@"_video_record_%ld.mp4", (long)cid];
    }
    return @"";
}

- (UIColor *)recordPlugin:(LCOpenMediaRecordPlugin *)plugin littleWindowBorderColor:(id)littleWindowBorderColor {
    (void)plugin;
    (void)littleWindowBorderColor;
    return [UIColor darkGrayColor];
}

- (void)recordPlugin:(LCOpenMediaRecordPlugin *)plugin changed:(LCScreenMode)screenMode littleWindow:(NSInteger)channelId {
    (void)plugin;
    (void)screenMode;
    (void)channelId;
}

- (void)recordPlugin:(LCOpenMediaRecordPlugin *)plugin subWindow:(LCCastQuadrant)location {
    (void)plugin;
    (void)location;
}

- (UIView *)recordPlugin:(LCOpenMediaRecordPlugin *)plugin bgViewWith:(NSInteger)channelId {
    (void)plugin;
    (void)channelId;
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    v.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    return v;
}

- (LCMediaDoubleCameraSpaceConfig *)videoWindowSpaceConfig:(LCOpenMediaRecordPlugin *)plugin {
    (void)plugin;
    return nil;
}

- (LCMediaDoubleCamWindowConfig *)recordPlugin:(LCOpenMediaRecordPlugin *)livePlugin windowConfigWith:(NSInteger)channelId {
    (void)livePlugin;
    (void)channelId;
    return nil;
}

- (void)onSingleClick:(UITapGestureRecognizer *)gesture cid:(NSInteger)cid {
    (void)gesture;
    (void)cid;
}

- (void)onDoubleClick:(UITapGestureRecognizer *)gesture cid:(NSInteger)cid {
    (void)gesture;
    (void)cid;
}

- (void)onLeftSwipe:(UISwipeGestureRecognizer *)gesture cid:(NSInteger)cid {
    (void)gesture;
    (void)cid;
}

- (void)onRightSwipe:(UISwipeGestureRecognizer *)gesture cid:(NSInteger)cid {
    (void)gesture;
    (void)cid;
}

- (void)onUpSwipe:(UISwipeGestureRecognizer *)gesture cid:(NSInteger)cid {
    (void)gesture;
    (void)cid;
}

- (void)onDownSwipe:(UISwipeGestureRecognizer *)gesture cid:(NSInteger)cid {
    (void)gesture;
    (void)cid;
}

- (void)onLongPress:(UILongPressGestureRecognizer *)gesture cid:(NSInteger)cid {
    (void)gesture;
    (void)cid;
}

@end
