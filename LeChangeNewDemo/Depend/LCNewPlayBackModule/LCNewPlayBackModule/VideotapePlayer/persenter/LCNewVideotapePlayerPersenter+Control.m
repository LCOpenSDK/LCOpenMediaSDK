

#import "LCNewVideotapePlayerPersenter+Control.h"
#import <LCMediaBaseModule/VPVideoDefines.h>
#import "LCNewVideotapePlayerPersenter.h"
#import <objc/runtime.h>
#import <LCMediaBaseModule/PHAsset+Lechange.h>
#import <LCMediaBaseModule/UIImage+MediaBaseModule.h>
#import <LCNetworkModule/LCApplicationDataManager.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import <LCBaseModule/LCProgressHUD.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenSDK_Define.h>

/// 国标本地录像：onPlayerTime 连续无回调超过该秒数则视为播放结束
static const NSTimeInterval kLCGBPlayerTimeTimeoutSeconds = 3.0;

@interface LCNewVideotapePlayerPersenter ()
@end

@implementation LCNewVideotapePlayerPersenter (Control)

- (void)onUpDownScreen:(LCButton *)btn {
    dispatch_async(dispatch_get_main_queue(), ^{
        [LCNewDeviceVideotapePlayManager shareInstance].isFullScreen = NO;
        [self.container configUpDownScreenUI];
    });
}

- (void)onPortraitScreen:(LCButton *)btn {
    dispatch_async(dispatch_get_main_queue(), ^{
        [LCNewDeviceVideotapePlayManager shareInstance].isFullScreen = NO;
        [self.container configPortraitScreenUI];
    });
}

- (void)onFullScreen:(LCButton *)btn {
    dispatch_async(dispatch_get_main_queue(), ^{
        [LCNewDeviceVideotapePlayManager shareInstance].isFullScreen = ![LCNewDeviceVideotapePlayManager shareInstance].isFullScreen;
        [UIDevice lc_setRotateToSatusBarOrientation:self.container.navigationController];
    });
}

- (void)onAudio:(LCButton *)btn {
    if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed>1) {
        return;
    }
    if ([LCNewDeviceVideotapePlayManager shareInstance].isSoundOn) {
        [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = NO;
        //关闭声音
        [self.recordPlugin stopAudioWithIsCallback:YES];
    } else {
        [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = YES;
        //开启声音
        [self.recordPlugin playAudioWithIsCallback:YES];
    }
}

- (void)onPlay:(LCButton *)btn {
    if ([LCNewDeviceVideotapePlayManager shareInstance].isPlay) {
        [self showPlayBtn];
        [self hideVideoLoadImage];
        [self pausePlay];
    } else {
        //位移超出或等于结束日期->处于正常播放结束状态
        if ([[LCNewDeviceVideotapePlayManager shareInstance].currentPlayOffest timeIntervalSinceDate:[LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo ? [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo.endDate : [LCNewDeviceVideotapePlayManager shareInstance].localVideotapeInfo.endDate] >= 0 ||
            [LCNewDeviceVideotapePlayManager shareInstance].playStatus == STATE_RTSP_FILE_PLAY_OVER) {
            self.sssdate = 0;
            [self startPlay:0];
        } else {
            if ([LCNewDeviceVideotapePlayManager shareInstance].pausePlay) {
                //播放中
                [self resumePlay];
            }else {
                NSTimeInterval offsetTime = [[LCNewDeviceVideotapePlayManager shareInstance].currentPlayOffest timeIntervalSinceDate:[LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo ? [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo.beginDate : [LCNewDeviceVideotapePlayManager shareInstance].localVideotapeInfo.beginDate];
                [self startPlay:offsetTime > 0 ? offsetTime : 0];
            }
        }
    }
    NSLog(@"%@", [NSThread currentThread]);
}

- (void)onSpeed:(LCButton *)btn {
    if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 6) {
        [LCNewDeviceVideotapePlayManager shareInstance].playSpeed = 1;
        [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = YES;
    } else {
        [LCNewDeviceVideotapePlayManager shareInstance].playSpeed ++;
        [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = NO;
    }
    
    if ([LCNewDeviceVideotapePlayManager shareInstance].isSoundOn) {
        //开启声音
        [self.recordPlugin playAudioWithIsCallback:YES];
    } else {
        //关闭声音
        [self.recordPlugin stopAudioWithIsCallback:YES];
    }
}

//停止播放
- (void)stopPlay:(BOOL)isKeepLastFrame clearOffset:(BOOL)clearOffset {
    [self stopGbPlayerTimeWatch];
    [self.recordPlugin stopRecordStream:isKeepLastFrame];
    [LCNewDeviceVideotapePlayManager shareInstance].isPlay = NO;
    [LCNewDeviceVideotapePlayManager shareInstance].pausePlay = NO;
    if (clearOffset) {
        [LCNewDeviceVideotapePlayManager shareInstance].currentPlayOffest = [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo ? [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo.beginDate : [LCNewDeviceVideotapePlayManager shareInstance].localVideotapeInfo.beginDate;
    }
    self.videoTypeLabel.hidden = YES;
    self.subVideoTypeLabel.hidden = YES;
    [self hideVideoLoadImage];
    [self showPlayBtn];
}

//开始播放
- (void)startPlay:(NSInteger)offsetTime {
    [self stopGbPlayerTimeWatch];
    [self hidePlayBtn];
    [self hideErrorBtn];
    [self.recordPlugin stopRecordStream:YES];
    [self showVideoLoadImage];
    [LCNewDeviceVideotapePlayManager shareInstance].isPlay = YES;
    [LCNewDeviceVideotapePlayManager shareInstance].pausePlay = NO;
    [[LCOpenMediaApiManager shareInstance] getPlayTokenKeyV2:[LCApplicationDataManager token] success:^(NSString * _Nonnull tokenKey, NSString * _Nonnull tokenKeyV2) {
        if ([LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo && [LCNewDeviceVideotapePlayManager shareInstance].type == LCNewPlayBackCloud) {
            //播放云录像
            LCOpenCloudSource *source = [LCOpenCloudSource new];
            source.pid = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.productId;
            source.did = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.deviceId;
            source.cid = [[LCNewDeviceVideoManager shareInstance].mainChannelInfo.channelId integerValue];
            source.psk = [LCNewDeviceVideotapePlayManager shareInstance].currentPsk;
            source.playToken = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.playTokenV2;
            source.accessToken = LCApplicationDataManager.token;
            source.recordRegionId = [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo.recordRegionId;
            source.timeout = 3 * 60;
            source.recordType = [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo.type;
            source.speed = [self getPlayWindowsSpeed];
            source.offsetTime = offsetTime;
            source.playTokenKey = tokenKeyV2;
            if ([[LCNewDeviceVideotapePlayManager shareInstance] existSubWindow]) {
                LCOpenCloudSource *subSource = [LCOpenCloudSource new];
                subSource.pid = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.productId;
                subSource.did = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.deviceId;
                subSource.cid = [[LCNewDeviceVideoManager shareInstance].subChannelInfo.channelId integerValue];
                subSource.psk = [LCNewDeviceVideotapePlayManager shareInstance].currentPsk;
                subSource.playToken = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.playTokenV2;
                subSource.accessToken = LCApplicationDataManager.token;
                subSource.recordRegionId = [LCNewDeviceVideotapePlayManager shareInstance].subCloudVideotapeInfo.recordRegionId;
                subSource.timeout = 3 * 60;
                subSource.recordType = [LCNewDeviceVideotapePlayManager shareInstance].subCloudVideotapeInfo.type;
                subSource.speed = [self getPlayWindowsSpeed];
                subSource.offsetTime = offsetTime;
                subSource.playTokenKey = tokenKeyV2;
                source.associcatChannels = @[subSource];
            }
            [self.recordPlugin playRecordStreamWith:source];

        } else if ([LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo && [LCNewDeviceVideotapePlayManager shareInstance].type == LCNewPlayBackCloudPic) {
            LCOpenCloudSource *source = [LCOpenCloudSource new];
            source.pid = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.productId;
            source.did = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.deviceId;
            source.cid = [[LCNewDeviceVideoManager shareInstance].mainChannelInfo.channelId integerValue];
            source.psk = [LCNewDeviceVideotapePlayManager shareInstance].currentPsk;
            source.playToken = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.playTokenV2;
            source.accessToken = LCApplicationDataManager.token;
            source.recordRegionId = [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo.recordRegionId;
            source.timeout = 3 * 60;
            source.recordType = [LCNewDeviceVideotapePlayManager shareInstance].cloudVideotapeInfo.type;
            source.speed = [self getPlayWindowsSpeed];
            source.offsetTime = offsetTime;
            source.playTokenKey = tokenKeyV2;
            source.playframeRate = 1;
            source.hlsType = 0;
            if ([[LCNewDeviceVideotapePlayManager shareInstance] existSubWindow]) {
                LCOpenCloudSource *subSource = [LCOpenCloudSource new];
                subSource.pid = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.productId;
                subSource.did = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.deviceId;
                subSource.cid = [[LCNewDeviceVideoManager shareInstance].subChannelInfo.channelId integerValue];
                subSource.psk = [LCNewDeviceVideotapePlayManager shareInstance].currentPsk;
                subSource.playToken = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.playTokenV2;
                subSource.accessToken = LCApplicationDataManager.token;
                subSource.recordRegionId = [LCNewDeviceVideotapePlayManager shareInstance].subCloudVideotapeInfo.recordRegionId;
                subSource.timeout = 3 * 60;
                subSource.recordType = [LCNewDeviceVideotapePlayManager shareInstance].subCloudVideotapeInfo.type;
                subSource.speed = [self getPlayWindowsSpeed];
                subSource.offsetTime = offsetTime;
                subSource.playTokenKey = tokenKeyV2;
                source.associcatChannels = @[subSource];
            }
            [self.recordPlugin playRecordStreamWith:source];

        } else {
            BOOL isGbDevice = [[LCNewDeviceVideotapePlayManager shareInstance] isGbDevice];
            if ([LCNewDeviceVideotapePlayManager shareInstance].currentDevice.productId.length > 0 || isGbDevice) {
                //播放本地录像（多目或国标设备按UTC时间播放）
                // 使用 beginDate/endDate（内部 LCDateFormatter），避免系统 12 小时制导致解析失败
                NSTimeInterval beginTime = [[LCNewDeviceVideotapePlayManager shareInstance].localVideotapeInfo.beginDate timeIntervalSince1970];
                NSTimeInterval endTime = [[LCNewDeviceVideotapePlayManager shareInstance].localVideotapeInfo.endDate timeIntervalSince1970];
                LCOpenDeviceTimeSource *source = [LCOpenDeviceTimeSource new];
                source.pid = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.productId;
                source.did = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.deviceId;
                source.cid = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.multiFlag ? 0 : [[LCNewDeviceVideoManager shareInstance].mainChannelInfo.channelId integerValue];
                source.playToken = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.playTokenV2;
                source.playTokenKey = tokenKeyV2;
                source.accessToken = LCApplicationDataManager.token;
                source.psk = [LCNewDeviceVideotapePlayManager shareInstance].currentPsk;
                source.startTime = beginTime + offsetTime;
                source.endTime = endTime;
                source.speed = [self getPlayWindowsSpeed];
                
                if ([LCNewDeviceVideotapePlayManager shareInstance].currentDevice.multiFlag) {
                    LCOpenDeviceTimeSource *subSource = [source copy];
                    subSource.cid = 1;
                    source.associcatChannels = @[subSource];
                }
                [self.recordPlugin playRecordStreamWith:source];
            } else {
                //播放本地录像
                LCOpenDeviceFileSource *source = [LCOpenDeviceFileSource new];
                source.pid = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.productId;
                source.did = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.deviceId;
                source.cid = [[LCNewDeviceVideoManager shareInstance].mainChannelInfo.channelId integerValue];
                source.playToken = [LCNewDeviceVideotapePlayManager shareInstance].currentDevice.playTokenV2;
                source.playTokenKey = tokenKeyV2;
                source.accessToken = LCApplicationDataManager.token;
                source.psk = [LCNewDeviceVideotapePlayManager shareInstance].currentPsk;
                source.fileId = [LCNewDeviceVideotapePlayManager shareInstance].localVideotapeInfo.recordId;
                source.offsetTime = offsetTime;
                source.speed = [self getPlayWindowsSpeed];
                [self.recordPlugin playRecordStreamWith:source];
            }
        }

    } failure:^(NSString * _Nonnull errorCode) {
        //
    }];
}

//暂停播放
- (void)pausePlay {
    [self stopGbPlayerTimeWatch];
    [self showPlayBtn];
    [self.recordPlugin pauseAsync];
    [LCNewDeviceVideotapePlayManager shareInstance].isPlay = NO;
    [LCNewDeviceVideotapePlayManager shareInstance].pausePlay = YES;
}

//恢复暂停播放
- (void)resumePlay {
    [self showVideoLoadImage];
    [self hideErrorBtn];
    [self.recordPlugin resumeAsync];
    [LCNewDeviceVideotapePlayManager shareInstance].isPlay = YES;
    [LCNewDeviceVideotapePlayManager shareInstance].pausePlay = NO;
    LCNewDeviceVideotapePlayManager *manager = [LCNewDeviceVideotapePlayManager shareInstance];
    if (manager.isGbDevice && manager.localVideotapeInfo && manager.type == LCNewPlayBackDevice) {
        [self refreshGbPlayerTimeWatch];
    }
}

- (void)stopGbPlayerTimeWatch {
    if (self.gbPlayerTimeWatchTimer) {
        [self.gbPlayerTimeWatchTimer invalidate];
        self.gbPlayerTimeWatchTimer = nil;
    }
}

- (void)refreshGbPlayerTimeWatch {
    [self stopGbPlayerTimeWatch];
    __weak typeof(self) weakSelf = self;
    self.gbPlayerTimeWatchTimer = [NSTimer scheduledTimerWithTimeInterval:kLCGBPlayerTimeTimeoutSeconds
                                                                  repeats:NO
                                                                    block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        LCNewDeviceVideotapePlayManager *manager = [LCNewDeviceVideotapePlayManager shareInstance];
        if (!manager.isGbDevice || !manager.localVideotapeInfo || manager.type != LCNewPlayBackDevice || !manager.isPlay) {
            return;
        }
        [strongSelf finishPlaybackAsPlayOver];
    }];
}

- (void)handleGbLocalPlaybackProgress:(NSTimeInterval)playTime {
    LCNewDeviceVideotapePlayManager *manager = [LCNewDeviceVideotapePlayManager shareInstance];
    // 仅国标设备本地录像
    if (!manager.isGbDevice || !manager.localVideotapeInfo || manager.type != LCNewPlayBackDevice || !manager.isPlay) {
        return;
    }
    NSDate *endDate = manager.localVideotapeInfo.endDate;
    if (endDate && playTime >= [endDate timeIntervalSince1970]) {
        [self finishPlaybackAsPlayOver];
        return;
    }
    [self refreshGbPlayerTimeWatch];
}

- (void)finishPlaybackAsPlayOver {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishPlaybackAsPlayOver];
        });
        return;
    }
    [self stopGbPlayerTimeWatch];
    LCNewDeviceVideotapePlayManager *manager = [LCNewDeviceVideotapePlayManager shareInstance];
    if (manager.playStatus == STATE_RTSP_FILE_PLAY_OVER && manager.isPlay == NO) {
        return;
    }
    if (manager.isOpenRecoding) {
        [self onRecording];
    }
    [self.recordPlugin stopRecordStream:YES];
    manager.playStatus = STATE_RTSP_FILE_PLAY_OVER;
    manager.isPlay = NO;
    manager.pausePlay = YES;
    NSDate *endDate = manager.cloudVideotapeInfo ? manager.cloudVideotapeInfo.endDate : manager.localVideotapeInfo.endDate;
    if (endDate && [manager.currentPlayOffest timeIntervalSinceDate:endDate] < 0) {
        manager.currentPlayOffest = endDate;
    }
    [self hideVideoLoadImage];
    [self showPlayBtn];
}

- (void)onChangeOffset:(NSInteger)offsetTime playDate:(NSDate *)playDate {
    LCNewDeviceVideotapePlayManager *manager = [LCNewDeviceVideotapePlayManager shareInstance];
    // 国标本地录像不支持拖动进度条，拦截后提示，避免 seek 失败展示 500000
    if (manager.isGbDevice && manager.localVideotapeInfo) {
        [LCProgressHUD showMsg:@"play_module_gb_record_seek_unsupported".lcMedia_T];
        // 拖动结束回调内 canRefreshSlider 仍为 NO，需下一 runloop 再回写以触发进度条回弹
        NSDate *current = [manager.currentPlayOffest copy];
        if (current) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [LCNewDeviceVideotapePlayManager shareInstance].currentPlayOffest = current;
            });
        }
        return;
    }
    [self showVideoLoadImage];
    [self hideErrorBtn];
    self.sssdate = [playDate timeIntervalSinceReferenceDate];
    //播放结束状态，拖动后操作不同
    if ((manager.isPlay == NO && manager.playStatus == STATE_RTSP_FILE_PLAY_OVER )|| offsetTime==0) {
        [self startPlay:offsetTime];
    } else {
        [self.recordPlugin seek:offsetTime];
    }
}

- (void)onSnap:(LCButton *)btn {
    [self.recordPlugin snapShotWithIsCallback:YES];
}

NSString *rSavePath = nil;
NSString *rSavePath2 = nil;
- (void)onRecording {
    if (![LCNewDeviceVideotapePlayManager shareInstance].isOpenRecoding) {
        [self.recordPlugin startRecord];
    } else {
        [self.recordPlugin stopRecord];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [LCNewDeviceVideotapePlayManager shareInstance].isOpenRecoding = ![LCNewDeviceVideotapePlayManager shareInstance].isOpenRecoding;
    });
}

- (void)loadPlaySpeed {
    CGFloat speedTime = 1.0;
    if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 1) {
        speedTime = 1.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 2) {
        speedTime = 2.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 3) {
        speedTime = 4.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 4) {
        speedTime = 8.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 5) {
        speedTime = 16.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 6) {
        speedTime = 32.0;
    }
    [self.recordPlugin setPlaySpeed:speedTime];
}

- (CGFloat)getPlayWindowsSpeed {
    CGFloat speedTime = 1.0;
    if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 1) {
        speedTime = 1.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 2) {
        speedTime = 2.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 3) {
        speedTime = 4.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 4) {
        speedTime = 8.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 5) {
        speedTime = 16.0;
    } else if ([LCNewDeviceVideotapePlayManager shareInstance].playSpeed == 6) {
        speedTime = 32.0;
    }
    return speedTime;
}

@end
