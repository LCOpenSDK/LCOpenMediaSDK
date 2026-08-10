#import "LCAIFrameSelectPlaybackViewController.h"
#import "LCAIQuickLookPlaybackTypes.h"
#import "LCAIFrameSelectRecordPluginPresenter.h"
#import "LCAIFrameSelectPlaybackToolbarImages.h"
#import "LCAICloudAppBundleImage.h"
#import "LCAICloudQuickLookChromePassThroughView.h"
#import "LCAICloudQuickLookToolDockView.h"
#import <LCBaseModule/UIViewController+LCNavigationBar.h>
#import <LCBaseModule/LCProgressHUD.h>
#import <LCBaseModule/UIColor+HexString.h>
#import <LCMediaBaseModule/LCNewDeviceVideoManager.h>
#import <LCNetworkModule/LCApplicationDataManager.h>
#import <LCNetworkModule/LCDeviceInfo.h>
#import <Masonry/Masonry.h>
#import <LCOpenMediaSDK/LCOpenMediaSDK.h>
#import <LCOpenMediaSDK/LCVideoPlayerDefines.h>
#import <LCOpenMediaSDK/LCOpenMediaSDK-Swift.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenMediaApiManager.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenSDK_Define.h>
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenSDK_Download.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenSDK_DownloadParam.h>
#import <LCMediaBaseModule/PHAsset+Lechange.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import <LCMediaBaseModule/UIDevice+MediaBaseModule.h>
#import <LCMediaBaseModule/UIImageView+MediaCircle.h>
#import "LCAICloudQuickLookBizPlayerIcons.h"
#import "LCAICloudQuickLookDayProgressView.h"
#import "LCNewDeviceVideotapePlayManager.h"

static const CGFloat kFSDH = 80.0f;
/// 竖屏白底区域：工具栏 + 与快看一致的 4pt 进度条（参考设计稿）
static const CGFloat kFSPortraitProgressH = 4.0f;
/// 帧选竖屏中，工具栏按钮与进度条留出触控间隙，避免热区上扩后与按钮手势互相抢占
static const CGFloat kFSPortraitProgressTopGap = 8.0f;
static const CGFloat kFSLandscapeDockH = 90.0f;
static const CGFloat kFII = 30.0f;
static const CGFloat kFSW = 58.0f;
static const CGFloat kFSL = 56.0f;

@interface LCAIFrameSelectPlaybackViewController () <LCOpenSDK_DownloadListener>
@property (nonatomic, strong) LCAIFrameSelectRecordPluginPresenter *frameSelectRecordPluginPresenter;
@property (nonatomic, strong) LCOpenMediaRecordPlugin *rp;
@property (nonatomic, strong) UIView *fsPortraitVideoSlot;
@property (nonatomic, strong) UIView *box;
@property (nonatomic, strong) LCAICloudQuickLookChromePassThroughView *crome;
@property (nonatomic, strong) LCAICloudQuickLookToolDockView *dk;
@property (nonatomic, strong) UIView *toolbarBg;
@property (nonatomic, strong) UIButton *bp, *bm, *bs, *bd, *bf;
@property (nonatomic, strong) UIView *sp;
@property (nonatomic, strong) UIView *fsToolbarStackSpacer;
@property (nonatomic, strong) UIView *fsBizLayer;
@property (nonatomic, strong) UIView *fsBizBackdrop;
@property (nonatomic, strong) UIStackView *fsBizStack;
@property (nonatomic, strong) UIImageView *fsBizLoadIV;
@property (nonatomic, strong) UIButton *fsBizPlayBtn;
@property (nonatomic, strong) UIButton *fsBizRetryBtn;
@property (nonatomic, strong) UIButton *fsBizReplayBtn;
@property (nonatomic, strong) UILabel *fsBizRetryHint;
@property (nonatomic, strong) UIStackView *fsBizRetryRow;
@property (nonatomic, assign) LCAICloudQuickLookBizScene fsAppliedBizScene;
@property (nonatomic, copy) NSString *fsLastPlayError;
@property (nonatomic, strong) UIActivityIndicatorView *di;
@property (nonatomic, strong) LCAICloudQuickLookChromePassThroughView *ltp;
@property (nonatomic, strong) UIButton *lbk;
@property (nonatomic, strong) UILabel *lti;
@property (nonatomic, assign) BOOL snd;
@property (nonatomic, assign) NSInteger stp;
@property (nonatomic, assign) NSInteger didx;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL dBusy;
@property (nonatomic, copy) NSString *dPath;
/// 0 未布局，1 竖屏 dock，2 横屏 dock — 用于避免重复 mas_remake
@property (nonatomic, assign) NSUInteger fsChromeLayToken;
@property (nonatomic, strong) LCAICloudQuickLookDayProgressView *fsProgress;
/// 仅本页取流/重试使用，与 `currentPsk` 无关，离开页面时清空
@property (nonatomic, copy, nullable) NSString *frameSelectPagePlayPsw;
@property (nonatomic, strong, nullable) NSArray<NSString *> *frameSelectPswArray;
@property (nonatomic, strong, nullable) UIAlertController *fsPskAlert;
- (NSString *)fs_resolvedPlaybackChannelIdString;
- (NSInteger)fs_resolvedPlaybackChannelIdInteger;
- (void)fs_executeDownloadMethod0NormalCloudWithSavePath:(NSString *)pth;
- (void)fs_executeDownloadMethod1LikeQuickLookWithSavePath:(NSString *)pth;
- (nullable NSArray<NSString *> *)fs_pswListByMergingBasePsk:(NSString *)basePsk extraFromArray:(nullable NSArray<NSString *> *)extra;
- (BOOL)fs_isDecryptErrorCode:(NSInteger)errorCode;
- (BOOL)fs_tryHandleDecryptFailureWithErrorCode:(NSInteger)errorCode;
- (void)fs_showPskAlertForPasswordMismatch:(BOOL)isPasswordError errorCode:(NSInteger)errorCode;
@end

@implementation LCAIFrameSelectPlaybackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.snd = [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn;
    self.stp = 0;
    self.didx = 20000;
    [self vPlayer];
    [self vBar];
    self.lti.text = [LCNewDeviceVideoManager shareInstance].currentDevice.name;
}

- (void)vPlayer {
    _fsPortraitVideoSlot = [UIView new];
    _fsPortraitVideoSlot.backgroundColor = [UIColor clearColor];
    _fsPortraitVideoSlot.userInteractionEnabled = NO;
    [self.view addSubview:_fsPortraitVideoSlot];

    _box = [UIView new];
    _box.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    [self.view addSubview:_box];

    _toolbarBg = [UIView new];
    _toolbarBg.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_toolbarBg];
    _frameSelectRecordPluginPresenter = [LCAIFrameSelectRecordPluginPresenter new];
    __weak typeof(self) w = self;
    _frameSelectRecordPluginPresenter.onBizState = ^(LCAICloudQuickLookBizScene s, NSString *m) {
        __strong typeof(w) ss = w;
        if (!ss) {
            return;
        }
        if (s == LCAICloudQuickLookBizSceneRetry) {
            NSInteger err = [m integerValue];
            if ([ss fs_isDecryptErrorCode:err]) {
                [ss fs_applyBizScene:s message:m];
                if ([ss fs_tryHandleDecryptFailureWithErrorCode:err]) {
                    return;
                }
            }
        }
        [ss fs_applyBizScene:s message:m];
    };
    _frameSelectRecordPluginPresenter.onRefresh = ^{ [w refreshFrameSelectPlayerToolbar]; };
    _frameSelectRecordPluginPresenter.onPlayTime = ^(NSTimeInterval t) {
        __strong typeof(w) ss = w;
        if (ss) {
            [ss fs_onPlayerUnixTime:t];
        }
    };
    _rp = [LCOpenMediaRecordPlugin new];
    [_rp setPlayerListener:(id)self.frameSelectRecordPluginPresenter];
    [_rp setGestureListener:(id)self.frameSelectRecordPluginPresenter];
    [_rp setDoubleCamListener:(id)self.frameSelectRecordPluginPresenter];
    [_rp configPlayerType:LCMediaPlayerTypeSingleIPC];
    self.frameSelectRecordPluginPresenter.recordPlugin = self.rp;
    [self.box addSubview:self.rp];
    [self.rp mas_makeConstraints:^(MASConstraintMaker *m) { m.edges.equalTo(self.box); }];

    _crome = [LCAICloudQuickLookChromePassThroughView new];
    _crome.userInteractionEnabled = YES;
    [self.box addSubview:self.crome];
    [self.crome mas_makeConstraints:^(MASConstraintMaker *m) { m.edges.equalTo(self.box); }];

    [self fs_setupBizLayer];

    _ltp = [LCAICloudQuickLookChromePassThroughView new];
    _ltp.userInteractionEnabled = YES;
    _ltp.hidden = YES;
    [self.box addSubview:self.ltp];
    [self.ltp mas_makeConstraints:^(MASConstraintMaker *m) { m.top.leading.trailing.equalTo(self.box); m.height.mas_equalTo(48.0); }];

    _lbk = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *bimg = LCAICloudAppBundleImage(@"common_icon_backarrow_white");
    if (bimg) {
        [self.lbk setImage:bimg forState:UIControlStateNormal];
    }
    [self.lbk addTarget:self action:@selector(landBack) forControlEvents:UIControlEventTouchUpInside];
    [self.ltp addSubview:self.lbk];
    [self.lbk mas_makeConstraints:^(MASConstraintMaker *m) { m.leading.offset(10.0); m.bottom.equalTo(self.ltp); m.width.mas_equalTo(44.0); m.height.mas_equalTo(48.0); }];

    _lti = [UILabel new];
    _lti.textColor = [UIColor whiteColor];
    _lti.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    _lti.textAlignment = NSTextAlignmentCenter;
    [self.ltp addSubview:self.lti];
    [self.lti mas_makeConstraints:^(MASConstraintMaker *m) { m.center.equalTo(self.ltp); }];

    self.fsAppliedBizScene = LCAICloudQuickLookBizSceneNone;
    [self fs_refreshChromeSubviewOrder];
}

/// 竖屏：播放窗「宽满屏 + 16:9」在导航下与底栏白底 dock 之间；横屏：播放区铺满安全区，渐变 dock 叠在画面底部（与每日快看一致，dock 挂在 `box` 上而非白底 `toolbarBg`）。
- (void)fsRemakePlaybackChromeConstraints {
    if (!self.box || !self.toolbarBg || !self.fsPortraitVideoSlot) {
        return;
    }
    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    NSUInteger want = land ? 2 : 1;
    if (want == self.fsChromeLayToken) {
        return;
    }
    self.fsChromeLayToken = want;
    if (!land) {
        self.toolbarBg.hidden = NO;
        self.fsPortraitVideoSlot.hidden = NO;
        [self.fsPortraitVideoSlot mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(4.0);
            make.bottom.equalTo(self.toolbarBg.mas_top).offset(-8.0);
        }];
        [self.box mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.fsPortraitVideoSlot);
            make.left.right.equalTo(self.fsPortraitVideoSlot);
            make.height.equalTo(self.box.mas_width).multipliedBy(9.0 / 16.0);
        }];
        [self.toolbarBg mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-(kFSDH + kFSPortraitProgressH + kFSPortraitProgressTopGap));
        }];
    } else {
        self.toolbarBg.hidden = YES;
        self.fsPortraitVideoSlot.hidden = YES;
        [self.fsPortraitVideoSlot mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.height.mas_equalTo(0.0);
        }];
        [self.box mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            // 贴齐屏幕物理底，避免安全区以下露出 `view` 白底形成横屏底白条
            make.bottom.equalTo(self.view);
        }];
        [self.toolbarBg mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.view);
            make.height.mas_equalTo(0.0);
        }];
    }
    [self fs_remountDockForLandscape:land];
    [self fs_refreshChromeSubviewOrder];
    [self refreshFrameSelectPlayerToolbar];
}

- (void)vBar {
    _fsProgress = [[LCAICloudQuickLookDayProgressView alloc] init];
    _fsProgress.portraitLightChrome = YES;
    _fsProgress.hidden = NO;
    __weak typeof(self) wProg = self;
    _fsProgress.interactionAllowedBlock = ^BOOL{
        __strong typeof(wProg) s = wProg;
        return s != nil;
    };
    _fsProgress.valueChangeEndBlock = ^(float offset, NSDate *wallDate) {
        __strong typeof(wProg) s = wProg;
        if (s) {
            [s fs_onProgressSeekEndOffset:offset wallDate:wallDate];
        }
    };
    [self.toolbarBg addSubview:self.fsProgress];
    [self.fsProgress mas_makeConstraints:^(MASConstraintMaker *m) {
        m.left.right.bottom.equalTo(self.toolbarBg);
        m.height.mas_equalTo(kFSPortraitProgressH);
    }];

    _dk = [LCAICloudQuickLookToolDockView new];
    _dk.backgroundColor = [UIColor clearColor];
    [self.toolbarBg addSubview:self.dk];
    [self.dk mas_makeConstraints:^(MASConstraintMaker *m) {
        m.left.right.top.equalTo(self.toolbarBg);
        m.bottom.equalTo(self.fsProgress.mas_top).offset(-kFSPortraitProgressTopGap);
    }];
    [self.dk applyLandscapeCloudPlaybackChrome:NO embeddedProcessView:self.fsProgress];
    self.dk.gradientLayer.colors = @[ (__bridge id)[UIColor clearColor].CGColor, (__bridge id)[UIColor clearColor].CGColor ];
    self.dk.gradientLayer.locations = @[ @0.0f, @1.0f ];
    self.dk.toolStack.distribution = UIStackViewDistributionFill;
    self.dk.toolStack.alignment = UIStackViewAlignmentBottom;

    _bp = [self btnI:[LCAIFrameSelectPlaybackToolbarImages playImage] sel:@selector(tpp)];
    _bm = [self btnI:[LCAIFrameSelectPlaybackToolbarImages voiceOnImage] sel:@selector(tmt)];
    _bs = [UIButton buttonWithType:UIButtonTypeCustom];
    [_bs setTitle:@"1X" forState:UIControlStateNormal];
    [_bs setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_bs setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.35] forState:UIControlStateDisabled];
    _bs.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    _bs.titleLabel.lineBreakMode = NSLineBreakByClipping;
    _bs.contentEdgeInsets = UIEdgeInsetsMake(6, 2, 6, 2);
    [_bs setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [_bs setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [_bs addTarget:self action:@selector(tsp) forControlEvents:UIControlEventTouchUpInside];
    _bd = [self btnI:[LCAIFrameSelectPlaybackToolbarImages downloadImage] sel:@selector(tdl)];
    _bf = [self btnI:[LCAIFrameSelectPlaybackToolbarImages fullscreenImage] sel:@selector(tfs)];

    _sp = [UIView new];
    if (@available(iOS 13.0, *)) {
        _di = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    } else {
        _di = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    _di.hidesWhenStopped = YES;
    [_di setColor:[UIColor grayColor]];
    [self.bd addSubview:self.di];
    [self.di mas_makeConstraints:^(MASConstraintMaker *m) { m.center.equalTo(self.bd); }];

    [self fs_refreshDockStackLandscape:NO];
    [self.dk.fullscreenSlot addSubview:self.bf];
    [self.bf mas_makeConstraints:^(MASConstraintMaker *m) {
        m.centerX.equalTo(self.dk.fullscreenSlot);
        // 竖屏与左侧播放/伴音等图标同一中线对齐（不再贴 fullscreenSlot 底）
        m.centerY.equalTo(self.bp);
        m.width.height.mas_equalTo(kFII);
    }];
    [self.dk layoutGradientIfNeeded];

    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    [self fs_remountDockForLandscape:land];
    [self fs_refreshChromeSubviewOrder];
}

- (UIButton *)btnI:(nullable UIImage *)im sel:(SEL)se {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    if (im) {
        [b setImage:im forState:UIControlStateNormal];
    }
    b.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [b addTarget:self action:se forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)fs_refreshDockStackLandscape:(BOOL)landscape {
    if (!self.dk.toolStack) {
        return;
    }
    UIStackView *st = self.dk.toolStack;
    if (self.fsToolbarStackSpacer.superview == st) {
        [st removeArrangedSubview:self.fsToolbarStackSpacer];
        [self.fsToolbarStackSpacer removeFromSuperview];
    }
    for (UIView *v in st.arrangedSubviews.copy) {
        [st removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    if (!self.fsToolbarStackSpacer) {
        self.fsToolbarStackSpacer = [[UIView alloc] init];
        [self.fsToolbarStackSpacer setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
        [self.fsToolbarStackSpacer setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    }
    if (landscape) {
        st.distribution = UIStackViewDistributionFill;
        st.alignment = UIStackViewAlignmentCenter;
        for (UIButton *b in @[ self.bp, self.bm, self.bs ]) {
            [st addArrangedSubview:b];
        }
        [st addArrangedSubview:self.fsToolbarStackSpacer];
    } else {
        st.distribution = UIStackViewDistributionFill;
        st.alignment = UIStackViewAlignmentBottom;
        // 竖屏：播放 / 静音 / 倍速 / 下载（横屏不展示下载，与每日快看一致）
        for (UIButton *b in @[ self.bp, self.bm, self.bs, self.bd ]) {
            [st addArrangedSubview:b];
        }
        [st addArrangedSubview:self.fsToolbarStackSpacer];
    }
    [self fs_updateToolbarIconSizesForLandscape:landscape];
}

- (void)fs_updateToolbarIconSizesForLandscape:(BOOL)landscape {
    for (UIButton *b in @[ self.bp, self.bm, self.bd ]) {
        [b mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(kFII);
        }];
    }
    [self.bs mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(kFII);
        make.width.mas_greaterThanOrEqualTo(landscape ? kFSL : kFSW);
    }];
    if (self.bf.superview) {
        if (landscape) {
            [self.bf mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.center.equalTo(self.dk.fullscreenSlot);
                make.width.height.mas_equalTo(0.0);
            }];
        } else {
            [self.bf mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.dk.fullscreenSlot);
                make.centerY.equalTo(self.bp);
                make.width.height.mas_equalTo(kFII);
            }];
        }
    }
}

- (void)fs_applyLandscapeToolbarTemplateImage:(UIImage *)img button:(UIButton *)btn {
    if (!img || !btn) {
        return;
    }
    UIImage *tm = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btn setImage:tm forState:UIControlStateNormal];
    btn.tintColor = [UIColor whiteColor];
    btn.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
}

- (void)fs_onPlayerUnixTime:(NSTimeInterval)unix {
    if (!self.fsProgress || self.fsProgress.hidden) {
        return;
    }
    [self.fsProgress setCurrentDate:[NSDate dateWithTimeIntervalSince1970:unix]];
}

- (void)fs_onProgressSeekEndOffset:(float)offset wallDate:(__unused NSDate *)wallDate {
    LCPlayStatus st = [self.rp getPlayState];
    if (st == LCPlayStatusStop || st == LCPlayStatusError) {
        self.initialOffsetSeconds = (double)offset;
        [self play];
    } else {
        [self.rp seek:(NSInteger)llround((double)offset)];
    }
}

- (NSTimeInterval)fsUnixFromCreateTimeString:(NSString *)createTime {
    if (createTime.length == 0) {
        return 0;
    }
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *d = [f dateFromString:createTime];
    return d ? [d timeIntervalSince1970] : 0;
}

- (NSTimeInterval)fsUnixFromCompactDateTime:(NSString *)s {
    if (s.length < 15 || [s characterAtIndex:8] != 'T') {
        return 0;
    }
    NSInteger year = [[s substringWithRange:NSMakeRange(0, 4)] integerValue];
    NSInteger month = [[s substringWithRange:NSMakeRange(4, 2)] integerValue];
    NSInteger day = [[s substringWithRange:NSMakeRange(6, 2)] integerValue];
    NSInteger hour = [[s substringWithRange:NSMakeRange(9, 2)] integerValue];
    NSInteger minute = [[s substringWithRange:NSMakeRange(11, 2)] integerValue];
    NSInteger second = [[s substringWithRange:NSMakeRange(13, 2)] integerValue];
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.year = year;
    c.month = month;
    c.day = day;
    c.hour = hour;
    c.minute = minute;
    c.second = second;
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *d = [cal dateFromComponents:c];
    return d ? floor([d timeIntervalSince1970]) : 0;
}

- (NSTimeInterval)fsOriginUnixForCloudRecord:(LCCloudVideotapeInfo *)rec {
    if (!rec) {
        return 0;
    }
    NSString *ct = rec.createTime.length ? rec.createTime : rec.beginTime;
    if (ct.length == 15 && [ct containsString:@"T"]) {
        NSTimeInterval u = [self fsUnixFromCompactDateTime:ct];
        if (u > 0) {
            return u;
        }
    }
    if (rec.beginDate) {
        return floor([rec.beginDate timeIntervalSince1970]);
    }
    return [self fsUnixFromCreateTimeString:ct ?: @""];
}

- (NSTimeInterval)fsTotalSecondsForCloudRecord:(LCCloudVideotapeInfo *)rec {
    if (!rec) {
        return 0.001;
    }
    double t = rec.videoLength;
    if (t < 0.001 && rec.endDate && rec.beginDate) {
        t = [rec.endDate timeIntervalSinceDate:rec.beginDate];
    }
    if (t < 0.001) {
        t = 0.001;
    }
    return t;
}

- (void)fsRefreshProgressDateRange {
    if (!self.fsProgress || !self.cloudRecord) {
        return;
    }
    NSTimeInterval totalSec = [self fsTotalSecondsForCloudRecord:self.cloudRecord];
    NSTimeInterval originUnix = [self fsOriginUnixForCloudRecord:self.cloudRecord];
    if (originUnix <= 0) {
        if (self.cloudRecord.beginDate) {
            originUnix = floor([self.cloudRecord.beginDate timeIntervalSince1970]);
        } else {
            return;
        }
    }
    NSDate *barStart = [NSDate dateWithTimeIntervalSince1970:originUnix];
    NSDate *end = [barStart dateByAddingTimeInterval:totalSec];
    [self.fsProgress setStartDate:barStart endDate:end];
    [self.fsProgress setSegmentOverlayRatios:@[]];
}

- (void)fs_remountDockForLandscape:(BOOL)landscape {
    if (!self.dk) {
        return;
    }
    if (landscape) {
        self.box.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        if (self.dk.superview != self.box) {
            [self.dk removeFromSuperview];
            [self.box addSubview:self.dk];
        }
        [self.dk mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.box);
            make.height.mas_equalTo(kFSLandscapeDockH);
        }];
        [self.dk applyLandscapeLayout:YES];
        [self.dk applyLandscapeCloudPlaybackChrome:YES embeddedProcessView:self.fsProgress];
        [self.fsProgress setIsLandscapeLayout:YES];
        [self.fsProgress setPortraitLightChrome:NO];
        [self fs_refreshDockStackLandscape:YES];
        [self.bs setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.bs setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.35] forState:UIControlStateDisabled];
        self.bf.hidden = YES;
        // 横屏 fullscreenSlot 宽为 0 时，bf 仍 30×30 且相对 slot 居中，会画到 dock 外；收起约束避免「按钮跑出父控件」。
        if (self.bf.superview) {
            [self.bf mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.center.equalTo(self.dk.fullscreenSlot);
                make.width.height.mas_equalTo(0.0);
            }];
        }
    } else {
        self.box.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        if (self.dk.superview != self.toolbarBg) {
            [self.dk removeFromSuperview];
            [self.toolbarBg addSubview:self.dk];
        }
        [self.dk applyLandscapeLayout:NO];
        [self.dk applyLandscapeCloudPlaybackChrome:NO embeddedProcessView:self.fsProgress];
        [self.toolbarBg insertSubview:self.fsProgress belowSubview:self.dk];
        [self.fsProgress mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.toolbarBg);
            make.height.mas_equalTo(kFSPortraitProgressH);
        }];
        [self.fsProgress setIsLandscapeLayout:NO];
        [self.fsProgress setPortraitLightChrome:YES];
        [self.dk mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self.toolbarBg);
            make.bottom.equalTo(self.fsProgress.mas_top).offset(-kFSPortraitProgressTopGap);
        }];
        self.dk.gradientLayer.colors = @[ (__bridge id)[UIColor clearColor].CGColor, (__bridge id)[UIColor clearColor].CGColor ];
        self.dk.gradientLayer.locations = @[ @0.0f, @1.0f ];
        [self fs_refreshDockStackLandscape:NO];
        [self.bs setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.bs setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.35] forState:UIControlStateDisabled];
        self.bf.hidden = NO;
        if (self.bf.superview) {
            [self.bf mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.dk.fullscreenSlot);
                make.centerY.equalTo(self.bp);
                make.width.height.mas_equalTo(kFII);
            }];
        }
    }
    [self.dk layoutGradientIfNeeded];
    [self fsRefreshProgressDateRange];
}

- (void)fs_setupBizLayer {
    self.fsBizLayer = [[UIView alloc] init];
    self.fsBizLayer.hidden = YES;
    self.fsBizLayer.userInteractionEnabled = YES;
    [self.box addSubview:self.fsBizLayer];
    [self.fsBizLayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.box);
    }];
    self.fsBizBackdrop = [[UIView alloc] init];
    self.fsBizBackdrop.userInteractionEnabled = NO;
    [self.fsBizLayer addSubview:self.fsBizBackdrop];
    [self.fsBizBackdrop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.fsBizLayer);
    }];
    self.fsBizStack = [[UIStackView alloc] init];
    self.fsBizStack.axis = UILayoutConstraintAxisVertical;
    self.fsBizStack.alignment = UIStackViewAlignmentCenter;
    self.fsBizStack.spacing = 10;
    [self.fsBizLayer addSubview:self.fsBizStack];
    [self.fsBizStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.fsBizLayer);
        make.left.greaterThanOrEqualTo(self.fsBizLayer).offset(20);
        make.right.lessThanOrEqualTo(self.fsBizLayer).offset(-20);
    }];
    self.fsBizLoadIV = [[UIImageView alloc] init];
    self.fsBizLoadIV.contentMode = UIViewContentModeCenter;
    self.fsBizLoadIV.hidden = YES;
    [self.fsBizLoadIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(60);
    }];
    self.fsBizPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fsBizPlayBtn setImage:[LCAICloudQuickLookBizPlayerIcons bigModePlayImage] forState:UIControlStateNormal];
    [self.fsBizPlayBtn addTarget:self action:@selector(fs_bizTapResume) forControlEvents:UIControlEventTouchUpInside];
    [self.fsBizPlayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(45);
    }];
    self.fsBizRetryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fsBizRetryBtn setImage:[LCAICloudQuickLookBizPlayerIcons bigModeRefreshImage] forState:UIControlStateNormal];
    [self.fsBizRetryBtn addTarget:self action:@selector(fs_bizTapRetry) forControlEvents:UIControlEventTouchUpInside];
    [self.fsBizRetryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(45);
    }];
    self.fsBizRetryHint = [[UILabel alloc] init];
    self.fsBizRetryHint.textColor = [UIColor whiteColor];
    self.fsBizRetryHint.font = [UIFont systemFontOfSize:11];
    self.fsBizRetryHint.textAlignment = NSTextAlignmentCenter;
    self.fsBizRetryHint.numberOfLines = 3;
    self.fsBizReplayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fsBizReplayBtn setImage:[LCAICloudQuickLookBizPlayerIcons bigModeReplayImage] forState:UIControlStateNormal];
    [self.fsBizReplayBtn addTarget:self action:@selector(fs_bizTapReplay) forControlEvents:UIControlEventTouchUpInside];
    [self.fsBizReplayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(45);
    }];
    self.fsBizRetryRow = [[UIStackView alloc] init];
    self.fsBizRetryRow.axis = UILayoutConstraintAxisVertical;
    self.fsBizRetryRow.alignment = UIStackViewAlignmentCenter;
    self.fsBizRetryRow.spacing = 10;
    [self.fsBizRetryRow addArrangedSubview:self.fsBizRetryBtn];
    [self.fsBizRetryRow addArrangedSubview:self.fsBizRetryHint];
    [self.fsBizStack addArrangedSubview:self.fsBizLoadIV];
    [self.fsBizStack addArrangedSubview:self.fsBizPlayBtn];
    [self.fsBizStack addArrangedSubview:self.fsBizRetryRow];
    [self.fsBizStack addArrangedSubview:self.fsBizReplayBtn];
}

- (void)fs_hideBizLoadAnimation {
    self.fsBizLoadIV.hidden = YES;
    [self.fsBizLoadIV releaseImgs];
}

- (void)fs_showBizLoadAnimation {
    self.fsBizLoadIV.hidden = NO;
    [self.fsBizLoadIV loadGifImageWith:@[ @"video_waiting_gif_1", @"video_waiting_gif_2", @"video_waiting_gif_3", @"video_waiting_gif_4" ] TimeInterval:0.3 Style:LCMediaIMGCirclePlayStyleCircle];
}

- (void)fs_refreshChromeSubviewOrder {
    if (!self.box) {
        return;
    }
    if (self.fsBizLayer && !self.fsBizLayer.hidden) {
        [self.box bringSubviewToFront:self.fsBizLayer];
    }
    if (self.dk.superview == self.box) {
        [self.box bringSubviewToFront:self.dk];
    }
    [self.box bringSubviewToFront:self.ltp];
}

- (void)fs_applyBizScene:(LCAICloudQuickLookBizScene)scene message:(NSString *)message {
    if (scene == LCAICloudQuickLookBizSceneRetry) {
        self.fsLastPlayError = message.length ? message : @"";
    }
    self.fsAppliedBizScene = scene;
    if (!self.fsBizLayer) {
        return;
    }
    if (scene == LCAICloudQuickLookBizSceneNone) {
        [self fs_hideBizLoadAnimation];
        [LCProgressHUD hideAllHuds:self.view];
        self.fsBizLayer.hidden = YES;
        self.fsBizStack.spacing = 10;
        [self fs_refreshChromeSubviewOrder];
        [self refreshFrameSelectPlayerToolbar];
        return;
    }
    [LCProgressHUD hideAllHuds:self.view];
    self.fsBizLayer.hidden = NO;
    [self fs_hideBizLoadAnimation];
    self.fsBizPlayBtn.hidden = YES;
    self.fsBizReplayBtn.hidden = YES;
    self.fsBizRetryRow.hidden = YES;

    UIColor *bg = [UIColor clearColor];
    switch (scene) {
        case LCAICloudQuickLookBizSceneFirstLoading:
            bg = [UIColor lc_colorWithHexString:@"#484848"];
            self.fsBizStack.spacing = 5;
            [self fs_showBizLoadAnimation];
            break;
        case LCAICloudQuickLookBizSceneLoading:
            bg = [UIColor colorWithWhite:0 alpha:0.5];
            self.fsBizStack.spacing = 5;
            [self fs_showBizLoadAnimation];
            break;
        case LCAICloudQuickLookBizScenePlay:
            [self fs_hideBizLoadAnimation];
            self.fsBizStack.spacing = 10;
            bg = [UIColor colorWithWhite:0 alpha:0.5];
            self.fsBizPlayBtn.hidden = NO;
            break;
        case LCAICloudQuickLookBizSceneRetry:
            [self fs_hideBizLoadAnimation];
            self.fsBizStack.spacing = 10;
            bg = [UIColor lc_colorWithHexString:@"#484848"];
            self.fsBizRetryRow.hidden = NO;
            {
                NSString *hint = @"ai_insight_play_failed".lcMedia_T;
                if (self.fsLastPlayError.length) {
                    hint = [NSString stringWithFormat:@"%@\n%@", hint, self.fsLastPlayError];
                }
                self.fsBizRetryHint.text = hint;
            }
            break;
        case LCAICloudQuickLookBizSceneReplay:
            [self fs_hideBizLoadAnimation];
            self.fsBizStack.spacing = 10;
            bg = [UIColor colorWithWhite:0 alpha:0.5];
            self.fsBizReplayBtn.hidden = NO;
            [self.fsProgress lc_snapProgressToFull];
            break;
        default:
            [self fs_hideBizLoadAnimation];
            self.fsBizStack.spacing = 10;
            break;
    }
    self.fsBizBackdrop.backgroundColor = bg;
    [self fs_refreshChromeSubviewOrder];
    [self refreshFrameSelectPlayerToolbar];
}

- (void)refreshFrameSelectPlayerToolbar {
    if (!self.bp) {
        return;
    }
    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    LCPlayStatus st = [self.rp getPlayState];
    BOOL playing = (st == LCPlayStatusPlaying);
    static NSArray<NSString *> *T;
    static dispatch_once_t onceT;
    dispatch_once(&onceT, ^{
        T = @[ @"1X", @"2X", @"4X", @"8X", @"16X", @"32X" ];
    });
    [self.bs setTitle:T[(NSUInteger)(self.stp % 6)] forState:UIControlStateNormal];

    if (land) {
        // 与竖屏统一使用 `lc_frameselect_tb_*` 图套；横屏为白线稿 + template（与快看 dock 同视觉策略），避免与竖屏用两套图标导致状态/图形不一致
        self.dk.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        self.bs.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        [self fs_applyLandscapeToolbarTemplateImage:(playing ? [LCAIFrameSelectPlaybackToolbarImages pauseImage] : [LCAIFrameSelectPlaybackToolbarImages playImage]) button:self.bp];
        [self fs_applyLandscapeToolbarTemplateImage:(self.snd ? [LCAIFrameSelectPlaybackToolbarImages voiceOnImage] : [LCAIFrameSelectPlaybackToolbarImages voiceOffImage]) button:self.bm];
        [self fs_applyLandscapeToolbarTemplateImage:[LCAIFrameSelectPlaybackToolbarImages fullscreenImage] button:self.bf];
    } else {
        self.dk.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        self.bs.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        for (UIButton *b in @[ self.bp, self.bm, self.bf ]) {
            b.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            b.tintColor = nil;
        }
        [self.bp setImage:(playing ? [LCAIFrameSelectPlaybackToolbarImages pauseImage] : [LCAIFrameSelectPlaybackToolbarImages playImage]) forState:UIControlStateNormal];
        [self.bm setImage:(self.snd ? [LCAIFrameSelectPlaybackToolbarImages voiceOnImage] : [LCAIFrameSelectPlaybackToolbarImages voiceOffImage]) forState:UIControlStateNormal];
        [self.bf setImage:[LCAIFrameSelectPlaybackToolbarImages fullscreenImage] forState:UIControlStateNormal];
    }

    self.bd.hidden = land;
    if (land) {
        [self.di stopAnimating];
    } else if (self.dBusy) {
        [self.di startAnimating];
        [self.bd setImage:nil forState:UIControlStateNormal];
    } else {
        [self.di stopAnimating];
        [self.bd setImage:[LCAIFrameSelectPlaybackToolbarImages downloadImage] forState:UIControlStateNormal];
        self.bd.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        self.bd.tintColor = nil;
    }

    LCAICloudQuickLookBizScene biz = self.fsAppliedBizScene;
    BOOL bizFail = (biz == LCAICloudQuickLookBizSceneRetry);
    BOOL bizFinish = (biz == LCAICloudQuickLookBizSceneReplay);
    BOOL sdkLoad = (st == LCPlayStatusLoading);
    BOOL rebufferWhileStillPlaying = (st == LCPlayStatusPlaying && biz == LCAICloudQuickLookBizSceneLoading);
    BOOL loading = sdkLoad
        || (biz == LCAICloudQuickLookBizSceneFirstLoading)
        || (biz == LCAICloudQuickLookBizSceneLoading && !rebufferWhileStillPlaying);
    BOOL fail = bizFail || (st == LCPlayStatusError);
    BOOL normalPlaying = (st == LCPlayStatusPlaying
        && (biz == LCAICloudQuickLookBizSceneNone || rebufferWhileStillPlaying));
    BOOL paused = (st == LCPlayStatusPause);
    BOOL stoppedIdle = (st == LCPlayStatusStop && biz == LCAICloudQuickLookBizSceneNone);

    BOOL at1x = (self.stp == 0);
    BOOL enMute = normalPlaying && at1x;
    BOOL enDl = (normalPlaying || paused || bizFinish || stoppedIdle) && !loading && !fail;
    BOOL enSpeed = YES;

    self.bm.enabled = enMute;
    self.bs.enabled = enSpeed;
    if (!self.bd.hidden) {
        self.bd.enabled = enDl && !self.dBusy;
    } else {
        self.bd.enabled = YES;
    }

    [self.dk layoutGradientIfNeeded];
    [self fs_refreshChromeSubviewOrder];
}

- (void)fs_bizTapResume {
    [self tpp];
}

- (void)fs_bizTapRetry {
    [self play];
}

- (void)fs_bizTapReplay {
    [self fs_bizTapRetry];
}

- (void)tpp {
    LCPlayStatus s = [self.rp getPlayState];
    if (s == LCPlayStatusPlaying) {
        [self.rp pauseAsync];
    } else if (s == LCPlayStatusPause) {
        [self.rp resumeAsync];
    } else {
        self.frameSelectRecordPluginPresenter.expectFirstSDKLoading = YES;
        [self play];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshFrameSelectPlayerToolbar];
    });
}

- (void)tmt {
    if (!self.bm.isEnabled) {
        return;
    }
    if (self.snd) {
        self.snd = NO;
        [self.rp stopAudioWithIsCallback:YES];
    } else {
        self.snd = YES;
        [self.rp playAudioWithIsCallback:YES];
    }
    [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = self.snd;
    [self refreshFrameSelectPlayerToolbar];
}

- (void)tsp {
    if (!self.bs.isEnabled) {
        return;
    }
    static NSArray<NSNumber *> *f;
    static dispatch_once_t o;
    dispatch_once(&o, ^{
        f = @[ @1.0f, @2.0f, @4.0f, @8.0f, @16.0f, @32.0f ];
    });
    self.stp = (self.stp + 1) % 6;
    float sp = [f[(NSUInteger)self.stp] floatValue];
    [self.rp setPlaySpeed:sp];
    if (sp > 1.01f) {
        [self.rp stopAudioWithIsCallback:YES];
    } else {
        if (self.snd) {
            [self.rp playAudioWithIsCallback:YES];
        } else {
            [self.rp stopAudioWithIsCallback:YES];
        }
    }
    [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = self.snd;
    [self refreshFrameSelectPlayerToolbar];
}

- (void)tfs {
    BOOL landscape = self.view.bounds.size.width > self.view.bounds.size.height;
    if (landscape) {
        [self fs_requestInterfaceOrientationMask:UIInterfaceOrientationMaskPortrait];
    } else {
        [self fs_requestInterfaceOrientationMask:UIInterfaceOrientationMaskLandscapeRight];
    }
}

- (void)landBack {
    [self fs_requestInterfaceOrientationMask:UIInterfaceOrientationMaskPortrait];
}

/// 与 `LCAICloudEventListViewController` 的 `ql_requestInterfaceOrientationMask:` 一致，统一走 `UIDevice+MediaBaseModule` 的 `lc_setOrientation:viewController:`
- (void)fs_requestInterfaceOrientationMask:(UIInterfaceOrientationMask)mask {
    UIInterfaceOrientation target = UIInterfaceOrientationPortrait;
    if (mask & UIInterfaceOrientationMaskLandscapeRight) {
        target = UIInterfaceOrientationLandscapeRight;
    } else if (mask & UIInterfaceOrientationMaskLandscapeLeft) {
        target = UIInterfaceOrientationLandscapeLeft;
    }
    [UIDevice lc_setOrientation:target viewController:self];
}

/// 与 `LCNewVideotapePlayerPersenter+Control` 中 `getPlayWindowsSpeed` 档位一致（1/2/4/8/16/32）
- (CGFloat)fsPlaySourceSpeed {
    static NSArray<NSNumber *> *f;
    static dispatch_once_t o;
    dispatch_once(&o, ^{
        f = @[ @1.0f, @2.0f, @4.0f, @8.0f, @16.0f, @32.0f ];
    });
    return [f[(NSUInteger)(self.stp % 6)] floatValue];
}

/// 与列表 `LCAIFrameSelectEventListViewController` 传入的 `playbackChannelId` 一致；未传时回退 `cloudRecord.channelId`（与 `playCloudLikeQuickLook` 相同策略）
- (NSString *)fs_resolvedPlaybackChannelIdString {
    NSString *ch = self.playbackChannelId;
    if (!ch.length) {
        ch = self.cloudRecord.channelId.length ? self.cloudRecord.channelId : @"0";
    }
    return ch;
}

- (NSInteger)fs_resolvedPlaybackChannelIdInteger {
    return (NSInteger)[self fs_resolvedPlaybackChannelIdString].integerValue;
}

- (nullable NSArray<NSString *> *)fs_pswListByMergingBasePsk:(NSString *)basePsk extraFromArray:(nullable NSArray<NSString *> *)extra {
    if (basePsk.length == 0 && (extra == nil || extra.count == 0)) {
        return nil;
    }
    NSMutableArray<NSString *> *m = [NSMutableArray array];
    if (basePsk.length > 0) {
        [m addObject:basePsk];
    }
    for (NSString *s in extra) {
        if (s.length > 0 && ![m containsObject:s]) {
            [m addObject:s];
        }
    }
    return m.count ? [m copy] : nil;
}

- (BOOL)fs_isDecryptErrorCode:(NSInteger)errorCode {
    return errorCode == STATE_LCHTTP_KEY_ERROR || errorCode == STATE_RTSP_KEY_MISMATCH || errorCode == STATE_HLS_KEY_MISMATCH;
}

- (BOOL)fs_tryHandleDecryptFailureWithErrorCode:(NSInteger)errorCode {
    if (![self fs_isDecryptErrorCode:errorCode]) {
        return NO;
    }
    LCDeviceInfo *device = [LCNewDeviceVideoManager shareInstance].currentDevice;
    if (!device) {
        return NO;
    }
    NSString *defaultPsk = device.deviceId ?: @"";
    NSString *activePsk = self.frameSelectPagePlayPsw.length > 0 ? self.frameSelectPagePlayPsw : defaultPsk;
    if (defaultPsk.length > 0 && ![activePsk isEqualToString:defaultPsk]) {
        self.frameSelectPagePlayPsw = nil;
        self.frameSelectPswArray = nil;
        [self play];
        return YES;
    }
    [self fs_showPskAlertForPasswordMismatch:(errorCode == STATE_HLS_KEY_MISMATCH) errorCode:errorCode];
    return YES;
}

- (void)fs_showPskAlertForPasswordMismatch:(BOOL)isPasswordError errorCode:(NSInteger)errorCode {
    if (self.fsPskAlert != nil) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Alert_Title_Notice".lcMedia_T
                                                                 message:(isPasswordError ? @"mobile_common_input_video_password_tip".lcMedia_T : @"mobile_common_input_video_key_tip".lcMedia_T)
                                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Alert_Title_Button_Confirm".lcMedia_T
                                                 style:UIAlertActionStyleDefault
                                               handler:^(__unused UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) selfRef = weakSelf;
        if (!selfRef) {
            return;
        }
        NSString *psk = [ac.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (psk.length == 0) {
            selfRef.fsPskAlert = nil;
            return;
        }
        selfRef.frameSelectPagePlayPsw = psk;
        NSMutableArray<NSString *> *m = [NSMutableArray arrayWithArray:selfRef.frameSelectPswArray ?: @[]];
        if (![m containsObject:psk]) {
            [m addObject:psk];
        }
        selfRef.frameSelectPswArray = m.count ? [m copy] : nil;
        [selfRef play];
        selfRef.fsPskAlert = nil;
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Alert_Title_Button_Cancle".lcMedia_T
                                                    style:UIAlertActionStyleCancel
                                                  handler:^(__unused UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) selfRef = weakSelf;
        if (selfRef) {
            NSString *err = [NSString stringWithFormat:@"{errCode: %ld}", (long)errorCode];
            [selfRef fs_applyBizScene:LCAICloudQuickLookBizSceneRetry message:err];
            selfRef.fsPskAlert = nil;
        }
    }];
    [ac addAction:ok];
    [ac addAction:cancel];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"";
    }];
    self.fsPskAlert = ac;
    [self presentViewController:ac animated:YES completion:nil];
}

/// `method == 0`：与 `LCNewVideotapePlayerPersenter+Control` 云录像（`LCNewPlayBackCloud`）段一致 — 通道与列表选中一致、`recordRegionId`、不填 m3u 路径等扩展字段
- (void)playCloudLikeVideotapePlayer {
    LCDeviceInfo *d = [LCNewDeviceVideoManager shareInstance].currentDevice;
    if (!self.cloudRecord || !d) {
        return;
    }
    NSInteger playCid = [self fs_resolvedPlaybackChannelIdInteger];
    __weak typeof(self) w = self;
    [[LCOpenMediaApiManager shareInstance] getPlayTokenKeyV2:[LCApplicationDataManager token] success:^(NSString *key, NSString *keyV2) {
        __strong typeof(w) s = w;
        if (!s) {
            return;
        }
        NSString *effectivePsk = s.frameSelectPagePlayPsw.length > 0 ? s.frameSelectPagePlayPsw : (d.deviceId ?: @"");
        LCOpenCloudSource *so = [LCOpenCloudSource new];
        so.pid = d.productId;
        so.did = d.deviceId;
        so.cid = playCid;
        so.psk = effectivePsk;
        so.pswArray = [s fs_pswListByMergingBasePsk:effectivePsk extraFromArray:s.frameSelectPswArray];
        so.playToken = d.playTokenV2;
        so.accessToken = [LCApplicationDataManager token];
        so.playTokenKey = keyV2;
        so.recordRegionId = s.cloudRecord.recordRegionId ?: @"";
        so.timeout = 3 * 60;
        so.recordType = s.cloudRecord.type;
        so.speed = [s fsPlaySourceSpeed];
        so.offsetTime = s.initialOffsetSeconds;
        dispatch_async(dispatch_get_main_queue(), ^{
            [s.rp stopRecordStream:YES];
            [s.rp playRecordStreamWith:so];
            [s.rp setPlaySpeed:(float)[s fsPlaySourceSpeed]];
        });
    } failure:^(NSString *c) {
        dispatch_async(dispatch_get_main_queue(), ^{ [LCProgressHUD showMsg:c.length ? c : @"-"]; });
    }];
}

/// `method == 1`：与 `LCAICloudEventListViewController` 的 `playCondensedRecord:offsetSeconds:` 一致
- (void)playCloudLikeQuickLook {
    LCDeviceInfo *d = [LCNewDeviceVideoManager shareInstance].currentDevice;
    if (!self.cloudRecord || !d) {
        return;
    }
    NSString *ch = [self fs_resolvedPlaybackChannelIdString];
    __weak typeof(self) w = self;
    [[LCOpenMediaApiManager shareInstance] getPlayTokenKeyV2:[LCApplicationDataManager token] success:^(NSString *key, NSString *keyV2) {
        __strong typeof(w) s = w;
        if (!s) {
            return;
        }
        LCOpenCloudSource *so = [LCOpenCloudSource new];
        so.pid = d.productId;
        so.did = d.deviceId;
        so.cid = (NSInteger)ch.integerValue;
        NSString *effectivePsk = s.frameSelectPagePlayPsw.length > 0 ? s.frameSelectPagePlayPsw : (d.deviceId ?: @"");
        so.psk = effectivePsk;
        so.pswArray = [s fs_pswListByMergingBasePsk:effectivePsk extraFromArray:s.frameSelectPswArray];
        so.playToken = d.playTokenV2;
        so.accessToken = [LCApplicationDataManager token];
        so.playTokenKey = keyV2;
        NSString *rg = s.cloudRecord.recordRegionId.length ? s.cloudRecord.recordRegionId : @"";
        so.recordRegionId = rg.length ? rg : @"";
        so.recordPath = s.cloudRecord.recordPath ?: @"";
        so.region = so.recordRegionId;
        so.streamAddr = s.cloudRecord.streamAddr ?: @"";
        so.ak = s.cloudRecord.ak ?: @"";
        so.fileToken = s.cloudRecord.fileToken ?: @"";
        so.uid = s.cloudRecord.userId ?: @"";
        so.expireTime = s.cloudRecord.expireTime ?: @"";
        so.timeout = 180;
        so.speed = (float)[s fsPlaySourceSpeed];
        so.offsetTime = s.initialOffsetSeconds;
        so.recordType = s.cloudRecord.type;
        dispatch_async(dispatch_get_main_queue(), ^{
            [s.rp stopRecordStream:YES];
            [s.rp playRecordStreamWith:so];
            [s.rp setPlaySpeed:(float)[s fsPlaySourceSpeed]];
        });
    } failure:^(NSString *c) { dispatch_async(dispatch_get_main_queue(), ^{ [LCProgressHUD showMsg:c.length ? c : @"-"]; }); }];
}

- (void)play {
    if (!self.cloudRecord) {
        return;
    }
    [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = self.snd;
    self.frameSelectRecordPluginPresenter.expectFirstSDKLoading = YES;
    self.fsLastPlayError = nil;
    [self fsRefreshProgressDateRange];
    if (self.cloudRecord.cloudPlayMethod == 0) {
        [self playCloudLikeVideotapePlayer];
    } else {
        // method == 1 或其它：与每日快看 `playCondensedRecord` 一致
        [self playCloudLikeQuickLook];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.started) {
        return;
    }
    self.started = YES;
    [self play];
}

- (void)viewWillAppear:(BOOL)flag {
    [super viewWillAppear:flag];
    __weak typeof(self) w = self;
    [self lcCreatNavigationBarWith:LCNAVIGATION_STYLE_DEFAULT
                  buttonClickBlock:^(NSInteger idx) {
                      if (idx == 0) {
                          [w.navigationController popViewControllerAnimated:YES];
                      }
                  }];
    LCDeviceInfo *d = [LCNewDeviceVideoManager shareInstance].currentDevice;
    self.title = d.name.length ? d.name : @"";
    self.lti.text = self.title;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self fsRemakePlaybackChromeConstraints];
    BOOL l = (self.view.bounds.size.width > self.view.bounds.size.height);
    self.view.backgroundColor = l ? [UIColor blackColor] : [UIColor whiteColor];
    self.ltp.hidden = !l;
    [self.navigationController setNavigationBarHidden:l animated:YES];
    if (l) {
        if (self.tabBarController) {
            self.tabBarController.tabBar.hidden = YES;
        }
    } else if (self.tabBarController) {
        self.tabBarController.tabBar.hidden = NO;
    }
    [self refreshFrameSelectPlayerToolbar];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak typeof(self) w = self;
    [coordinator animateAlongsideTransition:nil completion:^(__unused id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        // 转场中 bounds 未稳定，完成后按最终横竖屏与 `getPlayState` 重刷，避免与竖屏/横屏各刷一次时状态或图标错半拍
        __strong typeof(w) s = w;
        if (s) {
            [s fsRemakePlaybackChromeConstraints];
            [s refreshFrameSelectPlayerToolbar];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        self.frameSelectPagePlayPsw = nil;
        self.frameSelectPswArray = nil;
    }
    if (self.fsPskAlert && self.presentedViewController == self.fsPskAlert) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    self.fsPskAlert = nil;
    [self.rp stopRecordStream:NO];
    [self fs_applyBizScene:LCAICloudQuickLookBizSceneNone message:nil];
    [LCProgressHUD hideAllHuds:self.view];
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.tabBarController) {
        self.tabBarController.tabBar.hidden = NO;
    }
}

- (void)tdl {
    if (self.bd.hidden) {
        return;
    }
    if (!self.bd.isEnabled) {
        return;
    }
    if (!self.cloudRecord) {
        return;
    }
    NSArray<NSString *> *p = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *lib = p.firstObject;
    NSString *dir = [[lib stringByAppendingPathComponent:@"lechange"] stringByAppendingPathComponent:@"download"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *pth = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%f_dl.mp4", [NSDate date].timeIntervalSince1970]];
    self.didx = self.didx + 1;
    if (self.cloudRecord.cloudPlayMethod == 0) {
        // 与 `LCNewDeviceVideotapePlayManager` 云录像（LCNewPlayBackCloud）下载一致：非多目 `startDownload:`，多目 `startDownloadCloudRecord:` 且无 condensed 扩展
        [self fs_executeDownloadMethod0NormalCloudWithSavePath:pth];
    } else {
        // method == 1：与 `LCAICloudEventListViewController` 的 `ql_onTapDownload` 一致
        [self fs_executeDownloadMethod1LikeQuickLookWithSavePath:pth];
    }
}

/// 与 `LCNewDeviceVideotapePlayManager` `-startDeviceDownload` 中 `LCNewPlayBackCloud` 分支一致；通道与列表选中及 `playCloudLikeVideotapePlayer` 一致
- (void)fs_executeDownloadMethod0NormalCloudWithSavePath:(NSString *)pth {
    LCDeviceInfo *d = [LCNewDeviceVideoManager shareInstance].currentDevice;
    if (!d) {
        return;
    }
    NSString *psk = self.frameSelectPagePlayPsw.length > 0 ? self.frameSelectPagePlayPsw : (d.deviceId ?: @"");
    NSInteger channelId = [self fs_resolvedPlaybackChannelIdInteger];
    BOOL multi = (d.multiFlag == YES);
    [[LCOpenSDK_Download shareMyInstance] setListener:self];
    NSInteger c = 0;
    if (multi) {
        LCOpenSDK_DownloadByRecordIdParam *pa = [LCOpenSDK_DownloadByRecordIdParam new];
        pa.index = self.didx;
        pa.savePath = pth;
        pa.accessToken = [LCApplicationDataManager token];
        pa.deviceId = d.deviceId;
        pa.psk = psk;
        pa.productId = d.productId;
        pa.playToken = d.playTokenV2;
        pa.useTLS = d.tlsEnable;
        pa.channelId = channelId;
        pa.recordRegionId = self.cloudRecord.recordRegionId ?: @"";
        pa.cloudType = self.cloudRecord.type;
        pa.speed = 1.0f;
        c = [[LCOpenSDK_Download shareMyInstance] startDownloadCloudRecord:pa];
    } else {
        c = [[LCOpenSDK_Download shareMyInstance] startDownload:self.didx
                                                       filepath:pth
                                                          token:[LCApplicationDataManager token]
                                                          devID:d.deviceId
                                                      channelID:channelId
                                                            psk:psk
                                                 recordRegionId:self.cloudRecord.recordRegionId ?: @""
                                                           Type:(NSInteger)self.cloudRecord.type
                                                         useTls:d.tlsEnable];
    }
    if (c != 0) {
        self.dBusy = NO;
        [self refreshFrameSelectPlayerToolbar];
        [LCProgressHUD showMsg:[NSString stringWithFormat:@"err(%ld)", (long)c]];
    } else {
        self.dBusy = YES;
        self.dPath = [pth copy];
        [self refreshFrameSelectPlayerToolbar];
    }
}

/// 与 `LCAICloudEventListViewController` `ql_onTapDownload` 字段一致；通道与 `playCloudLikeQuickLook` 一致
- (void)fs_executeDownloadMethod1LikeQuickLookWithSavePath:(NSString *)pth {
    LCDeviceInfo *d = [LCNewDeviceVideoManager shareInstance].currentDevice;
    if (!d) {
        return;
    }
    NSString *ch = [self fs_resolvedPlaybackChannelIdString];
    LCOpenSDK_DownloadByRecordIdParam *pa = [LCOpenSDK_DownloadByRecordIdParam new];
    pa.index = self.didx;
    pa.savePath = pth;
    pa.accessToken = [LCApplicationDataManager token];
    pa.deviceId = d.deviceId;
    pa.psk = self.frameSelectPagePlayPsw.length > 0 ? self.frameSelectPagePlayPsw : (d.deviceId ?: @"");
    pa.productId = d.productId;
    pa.channelId = (NSInteger)ch.integerValue;
    pa.recordRegionId = self.cloudRecord.recordPath ?: @"";
    pa.speed = 2.0f;
    LCOpenSDK_CloudExtraInfo *ex = [LCOpenSDK_CloudExtraInfo new];
    ex.m3uPath = self.cloudRecord.recordPath ?: @"";
    ex.streamAddr = self.cloudRecord.streamAddr ?: @"";
    ex.regionId = self.cloudRecord.recordRegionId ?: @"";
    ex.ak = self.cloudRecord.ak ?: @"";
    ex.fileToken = self.cloudRecord.fileToken ?: @"";
    ex.expireTime = self.cloudRecord.expireTime ?: @"";
    ex.uid = self.cloudRecord.userId ?: @"";
    ex.businessType = 1;
    pa.extraInfo = ex;
    [[LCOpenSDK_Download shareMyInstance] setListener:self];
    NSInteger c = [[LCOpenSDK_Download shareMyInstance] startDownloadCloudRecord:pa];
    if (c != 0) {
        self.dBusy = NO;
        [self refreshFrameSelectPlayerToolbar];
        [LCProgressHUD showMsg:[NSString stringWithFormat:@"err(%ld)", (long)c]];
    } else {
        self.dBusy = YES;
        self.dPath = [pa.savePath copy];
        [self refreshFrameSelectPlayerToolbar];
    }
}

- (void)onDownloadState:(NSInteger)index code:(NSString *)code type:(__unused NSInteger)ty {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![code isEqualToString:@"0"] && ![code isEqualToString:@"2"]) {
            return;
        }
        self.dBusy = NO;
        [self refreshFrameSelectPlayerToolbar];
        if ([code isEqualToString:@"2"]) {
            [[LCOpenSDK_Download shareMyInstance] stopDownload:index];
            NSString *path = self.dPath;
            self.dPath = nil;
            if (path.length) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    [PHAsset saveVideoAtURL:[NSURL fileURLWithPath:path]
                                    success:^{ [LCProgressHUD showMsg:@"mobile_common_data_download_success".lcMedia_T]; }
                                    failure:^(__unused NSError *err) { [LCProgressHUD showMsg:@"mobile_common_data_download_fail".lcMedia_T]; }];
                }
            } else {
                [LCProgressHUD showMsg:@"mobile_common_data_download_success".lcMedia_T];
            }
        } else {
            self.dPath = nil;
            [LCProgressHUD showMsg:@"mobile_common_data_download_fail".lcMedia_T];
        }
    });
}

- (BOOL)shouldAutorotate { return YES; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAllButUpsideDown; }

@end
