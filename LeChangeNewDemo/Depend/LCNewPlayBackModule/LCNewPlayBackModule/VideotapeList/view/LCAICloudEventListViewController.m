#import "LCAICloudEventListViewController.h"
#import "LCAICloudQuickLookCalendarViewController.h"
#import <LCBaseModule/UIViewController+LCNavigationBar.h>
#import <LCBaseModule/UIColor+LeChange.h>
#import <LCBaseModule/UIColor+HexString.h>
#import <LCBaseModule/UIScrollView+Tips.h>
#import <LCBaseModule/LCProgressHUD.h>
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <LCMediaBaseModule/LCNewDeviceVideoManager.h>
#import <LCNetworkModule/LCApplicationDataManager.h>
#import <LCNetworkModule/LCCondensedRecordInterface.h>
#import <LCNetworkModule/LCCloudVideotapeInfo.h>
#import <LCNetworkModule/LCDeviceInfo.h>
#import <LCOpenMediaSDK/LCOpenMediaSDK.h>
#import <LCOpenMediaSDK/LCOpenMediaSDK-Swift.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenMediaApiManager.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenSDK_Define.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenSDK_Download.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenSDK_DownloadParam.h>
#import <LCOpenSDKDynamic/LCOpenSDK/LCOpenSDK_DownloadListener.h>
#import <LCOpenMediaSDK/LCVideoPlayerDefines.h>
#import <LCMediaBaseModule/PHAsset+Lechange.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import <LCMediaBaseModule/UIDevice+MediaBaseModule.h>
#import <LCMediaBaseModule/UIImageView+MediaCircle.h>
#import <Masonry/Masonry.h>
#import <QuartzCore/QuartzCore.h>
#import "LCAICloudQuickLookPlayerToolbarIcons.h"
#import "LCAICloudQuickLookBizPlayerIcons.h"
#import "LCAICloudQuickLookDayProgressView.h"
#import "LCAICloudQuickLookChromePassThroughView.h"
#import "LCAICloudQuickLookToolDockView.h"
#import "LCAICloudEventPersenter.h"
#import "LCAICloudQuickLookSummaryListCell.h"
#import "LCAICloudDayItem.h"
#import "LCAICloudAppBundleImage.h"
#import "LCAIQuickLookRecordPluginPresenter.h"
#import "LCNewDeviceVideotapePlayManager.h"

static const CGFloat kQuickLookPortraitProgressContainerHeight = 4.0;
static const CGFloat kQuickLookToolbarBottomInset = 12.0;
static const CGFloat kQuickLookToolDockHeight = 80.0;
static const CGFloat kQuickLookToolbarIconRowHeight = 30.0;
static const CGFloat kQuickLookSpeedButtonMinWidthPortrait = 58.0;
static const CGFloat kQuickLookSpeedButtonMinWidthLandscape = 56.0;

@interface LCAICloudEventListViewController () <UITableViewDelegate, UITableViewDataSource, LCOpenSDK_DownloadListener, LCAICloudEventPresenterHost>
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIScrollView *channelScrollView;
@property (nonatomic, strong) UIStackView *channelStackView;
@property (nonatomic, strong) UIView *playerContainer;
@property (nonatomic, strong) LCOpenMediaRecordPlugin *recordPlugin;
@property (nonatomic, strong) LCAIQuickLookRecordPluginPresenter *quickLookRecordPluginPresenter;
@property (nonatomic, strong) LCAICloudEventPersenter *persenter;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) LCAICloudQuickLookChromePassThroughView *playerChromeView;
@property (nonatomic, strong) UIView *quickLookNoRecordOverlay;
@property (nonatomic, strong) UILabel *quickLookNoRecordLabel;
@property (nonatomic, strong) UIView *quickLookListFailedOverlay;
@property (nonatomic, strong) UILabel *quickLookListFailedLabel;
@property (nonatomic, strong) LCAICloudQuickLookToolDockView *quickLookToolDock;
@property (nonatomic, strong) LCAICloudQuickLookChromePassThroughView *quickLookLandscapeTopBar;
@property (nonatomic, strong) UIButton *qlLandscapeBackBtn;
@property (nonatomic, strong) UILabel *qlLandscapeTitleLabel;
@property (nonatomic, strong) UIView *qlToolbarStackSpacer;
@property (nonatomic, strong) UIButton *qlPlayPauseBtn;
@property (nonatomic, strong) UIButton *qlMuteBtn;
@property (nonatomic, strong) UIButton *qlSpeedBtn;
@property (nonatomic, strong) UIButton *qlSnapBtn;
@property (nonatomic, strong) UIButton *qlRecordBtn;
@property (nonatomic, strong) UIButton *qlDownloadBtn;
@property (nonatomic, strong) UIButton *qlFullscreenBtn;
@property (nonatomic, strong) UIActivityIndicatorView *qlDownloadIndicator;
@property (nonatomic, assign) BOOL qlDownloadBusy;
@property (nonatomic, assign) BOOL qlToolbarLayoutIsLandscape;
@property (nonatomic, assign) BOOL qlToolbarViewportApplied;
@property (nonatomic, assign) BOOL qlChromeProcessLayoutIsLandscape;
@property (nonatomic, assign) BOOL qlLandscapePlaybackChromeHiddenByUser;
@property (nonatomic, strong) LCAICloudQuickLookDayProgressView *quickLookProcessView;
@property (nonatomic, assign) BOOL quickLookSoundOn;
@property (nonatomic, assign) NSInteger quickLookSpeedStep;
@property (nonatomic, assign) NSInteger quickLookDownloadIndex;
@property (nonatomic, copy) NSString *qlLastCloudDownloadSavePath;
@property (nonatomic, assign) NSTimeInterval quickLookStreamStartUnix;
@property (nonatomic, assign) NSInteger manualLockedSummaryRow;
@property (nonatomic, strong) NSTimer *manualLockTimer;
@property (nonatomic, strong) UIView *quickLookBizLayer;
@property (nonatomic, strong) UIView *quickLookBizBackdrop;
@property (nonatomic, strong) UIStackView *quickLookBizStack;
@property (nonatomic, strong) UIImageView *quickLookBizLoadImageView;
@property (nonatomic, strong) UIButton *quickLookBizPlayBtn;
@property (nonatomic, strong) UIButton *quickLookBizRetryBtn;
@property (nonatomic, strong) UILabel *quickLookBizRetryHint;
@property (nonatomic, strong) UIStackView *quickLookBizRetryRow;
@property (nonatomic, strong) UIButton *quickLookBizReplayBtn;
@property (nonatomic, assign) LCAICloudQuickLookBizScene quickLookAppliedBizScene;
@property (nonatomic, copy) NSString *quickLookLastPlayError;
/// 仅本页云取流使用，与 `currentPsk` 无关，离开页面时清空
@property (nonatomic, copy, nullable) NSString *quickLookPagePlayPsw;
@property (nonatomic, strong, nullable) NSArray<NSString *> *quickLookPswArray;
@property (nonatomic, strong, nullable) UIAlertController *qlPskAlert;
@property (nonatomic, assign) BOOL qlQuickLookShowChannelTabs;
@property (nonatomic, assign) NSInteger qlRootLayoutLandState;

- (void)lc_eventPersenterHostSetQuickLookLoadingVisible:(BOOL)show;
- (void)lc_eventPersenterHostApplyQuickLookAfterModelsChangedPlayRecord:(nullable LCCloudVideotapeInfo *)record;
- (void)ql_saveCloudDownloadToAlbumWithPath:(NSString *)path index:(NSInteger)index;
- (BOOL)ql_isDecryptErrorCode:(NSInteger)errorCode;
- (BOOL)ql_tryHandleDecryptFailureWithErrorCode:(NSInteger)errorCode;
- (void)ql_showPskAlertForPasswordMismatch:(BOOL)isPasswordError;
- (nullable NSArray<NSString *> *)ql_pswListByMergingBasePsk:(NSString *)basePsk extraFromQuickLook:(nullable NSArray<NSString *> *)extra;
/// 与 `LCNewVideotapePlayerPersenter+Control` 的 `getPlayWindowsSpeed` 档位一致（1/2/4/8/16/32）
- (CGFloat)ql_condensedRecordSourceSpeed;
@end

static const NSInteger kQLChannelTabIndicatorTag = 91001;

@implementation LCAICloudEventListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lc_colorWithHexString:@"#F6F6F6"];
    self.extendedLayoutIncludesOpaqueBars = YES;
    [self setupAIQuickLook];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        self.quickLookPagePlayPsw = nil;
        self.quickLookPswArray = nil;
        if (self.presentedViewController == self.qlPskAlert) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }
        self.qlPskAlert = nil;
    }
    if ((self.isMovingFromParentViewController || self.isBeingDismissed) && self.navigationController) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
    if ((self.isMovingFromParentViewController || self.isBeingDismissed) && self.tabBarController) {
        self.tabBarController.tabBar.hidden = NO;
    }
    [self invalidateQuickLookManualLock];
    [self ql_stopLoadingProgressSimulation];
    [self.recordPlugin stopRecordStream:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.tabBarController) {
        UIViewController *sel = self.tabBarController.selectedViewController;
        if (sel && sel != self.navigationController && sel != self) {
            self.tabBarController.tabBar.hidden = NO;
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self ql_updateQuickLookNavigationBarHiddenForViewportAnimated:NO];
    [self ql_updateQuickLookRootLayoutForViewportIfNeeded];
    [self ql_updateQuickLookProcessLayoutForViewportIfNeeded];
    [self ql_layoutQuickLookToolGradientIfNeeded];
    [self ql_updateQuickLookToolbarForViewportSize:self.view.bounds.size];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
        [self ql_updateQuickLookNavigationBarHiddenForViewportAnimated:YES];
        [self ql_updateQuickLookRootLayoutForViewportIfNeeded];
        [self ql_updateQuickLookProcessLayoutForViewportIfNeeded];
        [self ql_layoutQuickLookToolGradientIfNeeded];
        [self ql_updateQuickLookToolbarForViewportSize:self.view.bounds.size];
        [self refreshQuickLookPlayerToolbar];
    }];
}

- (void)ql_updateQuickLookNavigationBarHiddenForViewportAnimated:(BOOL)animated {
    UINavigationController *nav = self.navigationController;
    if (!nav) {
        return;
    }
    BOOL landscape = self.view.bounds.size.width > self.view.bounds.size.height;
    BOOL hide = landscape;
    if (nav.navigationBar.isHidden == hide) {
        return;
    }
    [nav setNavigationBarHidden:hide animated:animated];
}

- (void)ql_updateQuickLookRootLayoutForViewportIfNeeded {
    if (!self.playerContainer || !self.tableView) {
        return;
    }
    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    NSInteger want = land ? 1 : 0;
    if (self.qlRootLayoutLandState == want) {
        return;
    }
    self.qlRootLayoutLandState = want;
    if (land) {
        self.channelScrollView.hidden = YES;
        self.tableView.hidden = YES;
        if (self.tabBarController) {
            self.tabBarController.tabBar.hidden = YES;
        }
        self.view.backgroundColor = [UIColor blackColor];
        [self.playerContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    } else {
        self.channelScrollView.hidden = !self.qlQuickLookShowChannelTabs;
        self.tableView.hidden = NO;
        if (self.tabBarController) {
            self.tabBarController.tabBar.hidden = NO;
        }
        self.view.backgroundColor = [UIColor lc_colorWithHexString:@"#F6F6F6"];
        [self.playerContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
            if (self.qlQuickLookShowChannelTabs) {
                make.top.equalTo(self.channelScrollView.mas_bottom);
            } else {
                make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            }
            make.left.right.equalTo(self.view);
            make.height.equalTo(self.playerContainer.mas_width).multipliedBy(9.0 / 16.0);
        }];
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.playerContainer.mas_bottom).offset(10);
            make.left.right.bottom.equalTo(self.view);
        }];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)setupAIQuickLook {
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    self.title = dev.name.length ? dev.name : @"ai_insight_quick_look_title".lcMedia_T;
    [self.persenter configureQuickLookInitialDataFromMainChannel];
    self.quickLookSoundOn = [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn;
    self.quickLookSpeedStep = 0;
    self.quickLookDownloadIndex = 10000;
    self.quickLookStreamStartUnix = 0;
    self.manualLockedSummaryRow = -1;

    [self.view addSubview:self.channelScrollView];
    [self.channelScrollView addSubview:self.channelStackView];
    [self.view addSubview:self.playerContainer];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.loadingView];

    BOOL showChannels = (dev.channels.count > 1);
    self.qlQuickLookShowChannelTabs = showChannels;
    self.qlRootLayoutLandState = -1;
    self.channelScrollView.hidden = !showChannels;
    [self.channelScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(showChannels ? 52.0 : 0.0);
    }];
    [self.channelStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.channelScrollView).insets(UIEdgeInsetsMake(10, 12, 10, 12));
        make.height.mas_equalTo(32);
    }];

    [self.playerContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        if (showChannels) {
            make.top.equalTo(self.channelScrollView.mas_bottom);
        } else {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        }
        make.left.right.equalTo(self.view);
        make.height.equalTo(self.playerContainer.mas_width).multipliedBy(9.0 / 16.0);
    }];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playerContainer.mas_bottom).offset(10);
        make.left.right.bottom.equalTo(self.view);
    }];

    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    [self buildChannelTabs];
    __weak typeof(self) weakSelfRef = self;
    self.quickLookRecordPluginPresenter = [[LCAIQuickLookRecordPluginPresenter alloc] initWithHostViewController:self onPlayTime:^(NSTimeInterval playTime) {
        [weakSelfRef highlightSummaryForAbsolutePlayTime:playTime];
        if (!weakSelfRef.quickLookProcessView || weakSelfRef.quickLookProcessView.hidden) {
            return;
        }
        [weakSelfRef.quickLookProcessView setCurrentDate:[NSDate dateWithTimeIntervalSince1970:playTime]];
    }];
    self.quickLookRecordPluginPresenter.onBizState = ^(LCAICloudQuickLookBizScene scene, NSString *_Nullable msg) {
        weakSelfRef.quickLookLastPlayError = msg ?: @"";
        if (scene == LCAICloudQuickLookBizSceneRetry) {
            NSInteger errorCode = [msg integerValue];
            if ([weakSelfRef ql_tryHandleDecryptFailureWithErrorCode:errorCode]) {
                return;
            }
        }
        [weakSelfRef applyQuickLookBizScene:scene];
    };
    self.recordPlugin = [[LCOpenMediaRecordPlugin alloc] initWithFrame:CGRectZero];
    [self.recordPlugin setPlayerListener:self.quickLookRecordPluginPresenter];
    [self.recordPlugin setGestureListener:self.quickLookRecordPluginPresenter];
    [self.recordPlugin setDoubleCamListener:self.quickLookRecordPluginPresenter];
    [self.recordPlugin configPlayerType:LCMediaPlayerTypeSingleIPC];
    self.quickLookRecordPluginPresenter.recordPlugin = self.recordPlugin;

    [self.playerContainer addSubview:self.recordPlugin];
    [self.recordPlugin mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playerContainer);
    }];
    self.quickLookRecordPluginPresenter.onChromeRefresh = ^{
        [weakSelfRef refreshQuickLookPlayerToolbar];
    };
    __weak typeof(weakSelfRef) wHost = weakSelfRef;
    self.quickLookRecordPluginPresenter.onDoubleTapVideo = ^(NSInteger cid) {
        __strong typeof(wHost) s = wHost;
        if (!s || !s.recordPlugin) {
            return;
        }
        if (![s.recordPlugin respondsToSelector:@selector(getEZoomScaleWithCid:)] || ![s.recordPlugin respondsToSelector:@selector(recoverEZooms)]) {
            return;
        }
        CGFloat scale = [s.recordPlugin getEZoomScaleWithCid:cid];
        BOOL isEZooming = scale != -1 && scale != 1;
        if (isEZooming) {
            [s.recordPlugin recoverEZooms];
        }
    };
    self.quickLookRecordPluginPresenter.onSingleTapVideo = ^(__unused NSInteger cid) {
        __strong typeof(wHost) s = wHost;
        if (!s) {
            return;
        }
        [s ql_toggleLandscapePlaybackChromeVisibility];
    };
    [self setupQuickLookPlayerChrome];

    [self setupQuickLookTableHeaderPoweredByAI];

    [self.tableView registerClass:[LCAICloudQuickLookSummaryListCell class]
           forCellReuseIdentifier:[LCAICloudQuickLookSummaryListCell summaryListCellReuseIdentifier]];

    [self.persenter buildLast30DaysPlain];
    [self updateQuickLookPlayerChromeAfterDataChange];
    [self refreshQuickLookPlayerToolbar];
    [self.persenter fetchCondensedRecordBitmap];
}

- (void)setupQuickLookTableHeaderPoweredByAI {
    UIView *hv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 36)];
    UILabel *lab = [[UILabel alloc] init];
    lab.translatesAutoresizingMaskIntoConstraints = NO;
    lab.font = [UIFont systemFontOfSize:9];
    lab.textColor = [UIColor colorWithRed:79 / 255.0 green:120 / 255.0 blue:1 alpha:0.6];
    lab.numberOfLines = 2;
    lab.text = @"ai_insight_summary_ai_disclaimer".lcMedia_T;
    [hv addSubview:lab];
    [NSLayoutConstraint activateConstraints:@[
        [lab.leadingAnchor constraintEqualToAnchor:hv.leadingAnchor constant:18],
        [lab.trailingAnchor constraintEqualToAnchor:hv.trailingAnchor constant:-18],
        [lab.topAnchor constraintEqualToAnchor:hv.topAnchor constant:10],
        [lab.bottomAnchor constraintLessThanOrEqualToAnchor:hv.bottomAnchor],
    ]];
    [hv setNeedsLayout];
    [hv layoutIfNeeded];
    CGRect f = hv.bounds;
    f.size.height = CGRectGetMaxY(lab.frame) + 8;
    hv.frame = f;
    self.tableView.tableHeaderView = hv;
}

- (UIScrollView *)channelScrollView {
    if (!_channelScrollView) {
        _channelScrollView = [[UIScrollView alloc] init];
        _channelScrollView.showsHorizontalScrollIndicator = NO;
        _channelScrollView.backgroundColor = [UIColor clearColor];
    }
    return _channelScrollView;
}

- (UIStackView *)channelStackView {
    if (!_channelStackView) {
        _channelStackView = [[UIStackView alloc] init];
        _channelStackView.axis = UILayoutConstraintAxisHorizontal;
        _channelStackView.spacing = 24;
        _channelStackView.alignment = UIStackViewAlignmentBottom;
    }
    return _channelStackView;
}

- (UIView *)playerContainer {
    if (!_playerContainer) {
        _playerContainer = [[UIView alloc] init];
        _playerContainer.backgroundColor = [UIColor lc_colorWithHexString:@"#484848"];
    }
    return _playerContainer;
}

- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        UIActivityIndicatorViewStyle st = UIActivityIndicatorViewStyleGray;
        if (@available(iOS 13.0, *)) {
            st = UIActivityIndicatorViewStyleLarge;
        }
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:st];
        _loadingView.hidesWhenStopped = YES;
    }
    return _loadingView;
}

- (void)buildChannelTabs {
    for (UIView *v in self.channelStackView.arrangedSubviews) {
        [self.channelStackView removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    for (LCChannelInfo *ch in dev.channels) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:(ch.channelName.length ? ch.channelName : ch.channelId) forState:UIControlStateNormal];
        btn.tag = ch.channelId.integerValue;
        [btn addTarget:self action:@selector(onChannelTab:) forControlEvents:UIControlEventTouchUpInside];
        btn.contentEdgeInsets = UIEdgeInsetsMake(8, 4, 10, 4);
        btn.backgroundColor = [UIColor clearColor];
        [self styleChannelButton:btn selected:[ch.channelId isEqualToString:self.persenter.selectedChannelId]];
        [self.channelStackView addArrangedSubview:btn];
    }
}

- (void)styleChannelButton:(UIButton *)btn selected:(BOOL)sel {
    btn.backgroundColor = [UIColor clearColor];
    btn.layer.borderWidth = 0;
    btn.layer.cornerRadius = 0;
    btn.clipsToBounds = NO;
    UIColor *titleBlack = [UIColor lc_colorWithHexString:@"#000000"];
    UIColor *titleMuted = [UIColor lc_colorWithHexString:@"#8F8F8F"];
    btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:sel ? UIFontWeightBold : UIFontWeightRegular];
    [btn setTitleColor:sel ? titleBlack : titleMuted forState:UIControlStateNormal];
    [btn setTitleColor:sel ? titleBlack : titleMuted forState:UIControlStateHighlighted];

    UIView *ind = [btn viewWithTag:kQLChannelTabIndicatorTag];
    if (!ind) {
        ind = [[UIView alloc] init];
        ind.tag = kQLChannelTabIndicatorTag;
        [btn addSubview:ind];
    }
    ind.backgroundColor = [UIColor lc_colorWithHexString:@"#4F78FF"];
    ind.layer.cornerRadius = 6.0;
    ind.clipsToBounds = YES;
    [ind mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(20.0);
        make.height.mas_equalTo(6.0);
        make.bottom.equalTo(btn);
        make.leading.equalTo(btn).offset(4.0);
    }];
    ind.hidden = !sel;
}

- (void)onChannelTab:(UIButton *)sender {
    NSString *cid = [NSString stringWithFormat:@"%ld", (long)sender.tag];
    if ([cid isEqualToString:self.persenter.selectedChannelId]) {
        return;
    }
    [self.persenter setSelectedChannelId:cid];
    for (UIView *v in self.channelStackView.arrangedSubviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)v;
            NSString *bid = [NSString stringWithFormat:@"%ld", (long)b.tag];
            [self styleChannelButton:b selected:[bid isEqualToString:self.persenter.selectedChannelId]];
        }
    }
    [self.recordPlugin stopRecordStream:NO];
    [self applyQuickLookBizScene:LCAICloudQuickLookBizSceneNone];
    self.persenter.quickLookHasLoaded = NO;
    [self.loadingView startAnimating];
    [self.persenter fetchCondensedListForCurrentDate];
}


- (void)lc_eventPersenterHostSetQuickLookLoadingVisible:(BOOL)show {
    if (show) {
        [self.loadingView startAnimating];
    } else {
        [self.loadingView stopAnimating];
    }
}

- (void)lc_eventPersenterHostApplyQuickLookAfterModelsChangedPlayRecord:(nullable LCCloudVideotapeInfo *)record {
    [self invalidateQuickLookManualLock];
    [self updateQuickLookSummaryEmptyBackgroundIfNeeded];
    [self.tableView reloadData];
    [self updateQuickLookPlayerChromeAfterDataChange];
    if (record) {
        [self playCondensedRecord:record offsetSeconds:0];
    } else {
        [self.recordPlugin stopRecordStream:NO];
    }
    [self refreshQuickLookPlayerToolbar];
}

- (CGFloat)ql_condensedRecordSourceSpeed {
    static NSArray<NSNumber *> *f;
    static dispatch_once_t o;
    dispatch_once(&o, ^{
        f = @[ @1.0f, @2.0f, @4.0f, @8.0f, @16.0f, @32.0f ];
    });
    return [f[(NSUInteger)(self.quickLookSpeedStep % 6)] floatValue];
}

- (void)playCondensedRecord:(LCCloudVideotapeInfo *)record offsetSeconds:(double)offset {
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = self.quickLookSoundOn;
    weakSelf(self);
    [[LCOpenMediaApiManager shareInstance] getPlayTokenKey:[LCApplicationDataManager token] success:^(NSString *tokenKey) {
        LCOpenCloudSource *src = [LCOpenCloudSource new];
        src.pid = dev.productId;
        src.did = dev.deviceId;
        src.cid = weakself.persenter.selectedChannelId.integerValue;
        NSString *effectivePsk = weakself.quickLookPagePlayPsw.length > 0 ? weakself.quickLookPagePlayPsw : (dev.deviceId ?: @"");
        src.psk = effectivePsk;
        src.pswArray = [weakself ql_pswListByMergingBasePsk:effectivePsk extraFromQuickLook:weakself.quickLookPswArray];
        src.playToken = dev.playToken;
        src.accessToken = [LCApplicationDataManager token];
        src.playTokenKey = tokenKey;
        src.recordRegionId = record.recordRegionId;
        src.recordPath = record.recordPath ?: @"";
        src.region = record.region;
        src.streamAddr = record.streamAddr ?: @"";
        src.ak = record.ak ?: @"";
        src.fileToken = record.fileToken ?: @"";
        src.uid = record.userId ?: @"";
        src.expireTime = record.expireTime ?: @"";
        src.timeout = 180;
        src.speed = (float)[weakself ql_condensedRecordSourceSpeed];
        src.offsetTime = offset;
        src.recordType = record.type;
        src.businessType = [record.businessType integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.quickLookRecordPluginPresenter resetExpectFirstSDKLoadingForNewPlay];
            weakself.quickLookStreamStartUnix = [weakself.persenter quickLookStartUnixForRecord:record];
            [weakself applyQuickLookBizScene:LCAICloudQuickLookBizSceneFirstLoading];
            [weakself.recordPlugin stopRecordStream:YES];
            [weakself.recordPlugin playRecordStreamWith:src];
            [weakself.recordPlugin setPlaySpeed:(float)[weakself ql_condensedRecordSourceSpeed]];
        });
    } failure:^(NSString *errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [LCProgressHUD showMsg:errorCode ?: @"tokenKey fail"];
        });
    }];
}

- (nullable NSArray<NSString *> *)ql_pswListByMergingBasePsk:(NSString *)basePsk extraFromQuickLook:(nullable NSArray<NSString *> *)extra {
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

- (BOOL)ql_isDecryptErrorCode:(NSInteger)errorCode {
    return errorCode == STATE_LCHTTP_KEY_ERROR || errorCode == STATE_RTSP_KEY_MISMATCH || errorCode == STATE_HLS_KEY_MISMATCH;
}

- (BOOL)ql_tryHandleDecryptFailureWithErrorCode:(NSInteger)errorCode {
    if (![self ql_isDecryptErrorCode:errorCode]) {
        return NO;
    }
    LCDeviceInfo *device = [LCNewDeviceVideoManager shareInstance].currentDevice;
    if (!device) {
        return NO;
    }
    NSString *defaultPsk = device.deviceId ?: @"";
    NSString *activePsk = self.quickLookPagePlayPsw.length > 0 ? self.quickLookPagePlayPsw : defaultPsk;
    if (defaultPsk.length > 0 && ![activePsk isEqualToString:defaultPsk]) {
        self.quickLookPagePlayPsw = nil;
        self.quickLookPswArray = nil;
        LCCloudVideotapeInfo *rec = [self.persenter currentChannelRecord];
        if (rec) {
            [self playCondensedRecord:rec offsetSeconds:0];
            return YES;
        }
        return NO;
    }
    [self ql_showPskAlertForPasswordMismatch:(errorCode == STATE_HLS_KEY_MISMATCH)];
    return YES;
}

- (void)ql_showPskAlertForPasswordMismatch:(BOOL)isPasswordError {
    if (self.qlPskAlert != nil) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert_Title_Notice".lcMedia_T
                                                                             message:(isPasswordError ? @"mobile_common_input_video_password_tip".lcMedia_T : @"mobile_common_input_video_key_tip".lcMedia_T)
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Alert_Title_Button_Confirm".lcMedia_T
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(__unused UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) selfRef = weakSelf;
        if (!selfRef) {
            return;
        }
        NSString *psk = [alertController.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (psk.length == 0) {
            selfRef.qlPskAlert = nil;
            return;
        }
        selfRef.quickLookPagePlayPsw = psk;
        NSMutableArray<NSString *> *m = [NSMutableArray arrayWithArray:selfRef.quickLookPswArray ?: @[]];
        if (![m containsObject:psk]) {
            [m addObject:psk];
        }
        selfRef.quickLookPswArray = m.count ? [m copy] : nil;
        LCCloudVideotapeInfo *rec = [selfRef.persenter currentChannelRecord];
        if (rec) {
            [selfRef playCondensedRecord:rec offsetSeconds:0];
        }
        selfRef.qlPskAlert = nil;
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Alert_Title_Button_Cancle".lcMedia_T
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(__unused UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) selfRef = weakSelf;
        if (selfRef) {
            selfRef.qlPskAlert = nil;
        }
    }];
    [alertController addAction:confirmAction];
    [alertController addAction:cancelAction];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"";
    }];
    self.qlPskAlert = alertController;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)highlightSummaryForAbsolutePlayTime:(NSTimeInterval)playTime {
    if (self.quickLookStreamStartUnix <= 0) {
        return;
    }
    NSTimeInterval t = playTime - self.quickLookStreamStartUnix;
    if (t < 0) {
        t = 0;
    }
    [self highlightSummaryForTimelineOffset:t forceManualUnlock:NO];
}

- (void)highlightSummaryForTimelineOffset:(NSTimeInterval)t forceManualUnlock:(BOOL)forceManualUnlock {
    if (forceManualUnlock) {
        [self invalidateQuickLookManualLock];
    }
    if (self.persenter.playSegmentRanges.count == 0) {
        if (self.persenter.selectedSummaryIndex != NSNotFound) {
            self.persenter.selectedSummaryIndex = NSNotFound;
            [self.tableView reloadData];
        }
        return;
    }
    if (!forceManualUnlock && self.manualLockedSummaryRow >= 0) {
        NSDictionary *lockRng = [self playSegmentRangeForDisplayRowIndex:self.manualLockedSummaryRow];
        if (!lockRng) {
            [self invalidateQuickLookManualLock];
        } else {
            double mn = [lockRng[@"min"] doubleValue];
            double mx = [lockRng[@"max"] doubleValue];
            if (t >= mn && t < mx) {
                [self invalidateQuickLookManualLock];
            } else {
                return;
            }
        }
    }
    NSInteger derivedIndex = NSNotFound;
    for (NSDictionary *rng in self.persenter.playSegmentRanges) {
        double mn = [rng[@"min"] doubleValue];
        double mx = [rng[@"max"] doubleValue];
        NSInteger di = [rng[@"idx"] integerValue];
        if (t >= mn && t < mx) {
            derivedIndex = di;
            break;
        }
    }
    if (derivedIndex == NSNotFound) {
        NSDictionary *last = self.persenter.playSegmentRanges.lastObject;
        double lastMax = [last[@"max"] doubleValue];
        if (t >= lastMax) {
            derivedIndex = [last[@"idx"] integerValue];
        }
    }
    if (derivedIndex == NSNotFound) {
        if (self.persenter.selectedSummaryIndex != NSNotFound) {
            self.persenter.selectedSummaryIndex = NSNotFound;
            [self.tableView reloadData];
        }
        return;
    }
    if (derivedIndex != self.persenter.selectedSummaryIndex) {
        self.persenter.selectedSummaryIndex = derivedIndex;
        [self.tableView reloadData];
        if (forceManualUnlock) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:derivedIndex inSection:0];
            if (derivedIndex < (NSInteger)self.persenter.displaySummaryRows.count) {
                [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            }
        }
    }
}

- (nullable NSDictionary *)playSegmentRangeForDisplayRowIndex:(NSInteger)row {
    for (NSDictionary *rng in self.persenter.playSegmentRanges) {
        if ([rng[@"idx"] integerValue] == row) {
            return rng;
        }
    }
    return nil;
}

- (void)scheduleQuickLookManualLockRelease {
    [self.manualLockTimer invalidate];
    __weak typeof(self) wself = self;
    NSTimer *tm = [NSTimer timerWithTimeInterval:5.0 repeats:NO block:^(NSTimer *_Nonnull timer) {
        typeof(self) s = wself;
        if (!s) {
            return;
        }
        if (s.manualLockTimer == timer) {
            s.manualLockedSummaryRow = -1;
            s.manualLockTimer = nil;
        }
    }];
    self.manualLockTimer = tm;
    [[NSRunLoop mainRunLoop] addTimer:tm forMode:NSRunLoopCommonModes];
}

- (void)invalidateQuickLookManualLock {
    [self.manualLockTimer invalidate];
    self.manualLockTimer = nil;
    self.manualLockedSummaryRow = -1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    if (self.persenter.quickLookLoadFailed && self.persenter.quickLookHasLoaded) {
        return 1;
    }
    if (self.persenter.quickLookSummaryEmptyBoard) {
        return 0;
    }
    return (NSInteger)self.persenter.displaySummaryRows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *rid = [LCAICloudQuickLookSummaryListCell summaryListCellReuseIdentifier];
    LCAICloudQuickLookSummaryListCell *cell = [tableView dequeueReusableCellWithIdentifier:rid forIndexPath:indexPath];
    if (self.persenter.quickLookLoadFailed && self.persenter.quickLookHasLoaded) {
        [cell applyNetworkErrorState];
        return cell;
    }
    NSDictionary *row = self.persenter.displaySummaryRows[(NSUInteger)indexPath.row];
    BOOL isSel = (indexPath.row == self.persenter.selectedSummaryIndex);
    if ([row[@"empty"] boolValue]) {
        [cell applyEmptySlotWithStartTime:row[@"startTime"] ?: @"" endTime:row[@"endTime"] ?: @""];
        return cell;
    }
    NSArray<NSString *> *tags = [self.persenter summaryTagStringsForDisplayRow:row];
    [cell applyContentWithStartTime:row[@"startTime"] ?: @""
                            endTime:row[@"endTime"] ?: @""
                            summary:row[@"summary"] ?: @""
                           selected:isSel
                   tagTypeStrings:tags];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.persenter.quickLookLoadFailed && self.persenter.quickLookHasLoaded) {
        [self.persenter clearListLoadFailureAndRefetch];
        return;
    }
    NSDictionary *row = self.persenter.displaySummaryRows[(NSUInteger)indexPath.row];
    if ([row[@"empty"] boolValue]) {
        return;
    }
    LCCloudVideotapeInfo *rec = [self.persenter currentChannelRecord];
    if (!rec) {
        return;
    }
    self.persenter.selectedSummaryIndex = indexPath.row;
    [tableView reloadData];
    double off = [self.persenter offsetSecondsForSummaryDisplayIndex:indexPath.row];
    double itemDur = [self.persenter doubleValueFromId:row[@"segment"][@"duration"]];
    if (itemDur > 3) {
        off += 3;
    }
    self.manualLockedSummaryRow = indexPath.row;
    [self scheduleQuickLookManualLockRelease];
    [self playCondensedRecord:rec offsetSeconds:off];
    NSIndexPath *scrollIp = [indexPath copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (scrollIp.row < (NSInteger)self.persenter.displaySummaryRows.count) {
            [self.tableView scrollToRowAtIndexPath:scrollIp atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    });
}


- (void)setupQuickLookPlayerChrome {
    self.playerChromeView = [[LCAICloudQuickLookChromePassThroughView alloc] init];
    self.playerChromeView.backgroundColor = [UIColor clearColor];
    self.playerChromeView.userInteractionEnabled = NO;
    [self.playerContainer addSubview:self.playerChromeView];
    [self.playerChromeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playerContainer);
    }];

    self.quickLookLandscapeTopBar = [[LCAICloudQuickLookChromePassThroughView alloc] init];
    self.quickLookLandscapeTopBar.backgroundColor = [UIColor clearColor];
    self.quickLookLandscapeTopBar.hidden = YES;
    self.quickLookLandscapeTopBar.userInteractionEnabled = YES;
    [self.playerChromeView addSubview:self.quickLookLandscapeTopBar];
    [self.quickLookLandscapeTopBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.playerChromeView);
        make.height.mas_equalTo(48.0);
    }];
    self.qlLandscapeBackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *landBackImg = LCAICloudAppBundleImage(@"common_icon_backarrow_white");
    if (landBackImg) {
        [self.qlLandscapeBackBtn setImage:landBackImg forState:UIControlStateNormal];
    } else if (@available(iOS 13.0, *)) {
        UIImage *chev = [UIImage systemImageNamed:@"chevron.backward"];
        [self.qlLandscapeBackBtn setImage:[chev imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.qlLandscapeBackBtn.tintColor = [UIColor whiteColor];
    }
    [self.qlLandscapeBackBtn addTarget:self action:@selector(ql_onTapLandscapeChromeBack) forControlEvents:UIControlEventTouchUpInside];
    [self.quickLookLandscapeTopBar addSubview:self.qlLandscapeBackBtn];
    [self.qlLandscapeBackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.quickLookLandscapeTopBar).offset(15.0);
        make.bottom.equalTo(self.quickLookLandscapeTopBar);
        make.width.mas_equalTo(50.0);
        make.height.mas_equalTo(48.0);
    }];
    self.qlLandscapeTitleLabel = [[UILabel alloc] init];
    self.qlLandscapeTitleLabel.textColor = [UIColor lc_colorWithHexString:@"#FFFFFF"];
    self.qlLandscapeTitleLabel.font = [UIFont systemFontOfSize:19.0];
    self.qlLandscapeTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.qlLandscapeTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.quickLookLandscapeTopBar addSubview:self.qlLandscapeTitleLabel];
    [self.qlLandscapeTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.quickLookLandscapeTopBar);
        make.centerY.equalTo(self.quickLookLandscapeTopBar);
        make.leading.greaterThanOrEqualTo(self.qlLandscapeBackBtn.mas_trailing).offset(20.0);
        make.trailing.lessThanOrEqualTo(self.quickLookLandscapeTopBar).offset(-16.0);
    }];
    [self ql_updateLandscapeChromeTitle];

    self.quickLookNoRecordOverlay = [[UIView alloc] init];
    self.quickLookNoRecordOverlay.backgroundColor = [UIColor lc_colorWithHexString:@"#484848"];
    self.quickLookNoRecordOverlay.hidden = YES;
    self.quickLookNoRecordOverlay.userInteractionEnabled = YES;
    [self.playerChromeView addSubview:self.quickLookNoRecordOverlay];
    [self.quickLookNoRecordOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playerChromeView);
    }];
    {
        UIStackView *nrStack = [[UIStackView alloc] init];
        nrStack.axis = UILayoutConstraintAxisVertical;
        nrStack.alignment = UIStackViewAlignmentCenter;
        nrStack.spacing = 8;
        [self.quickLookNoRecordOverlay addSubview:nrStack];
        [nrStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.quickLookNoRecordOverlay);
            make.left.greaterThanOrEqualTo(self.quickLookNoRecordOverlay).offset(24);
            make.right.lessThanOrEqualTo(self.quickLookNoRecordOverlay).offset(-24);
        }];
        UIImageView *nrIcon = [[UIImageView alloc] initWithImage:LCAICloudAppBundleImage(@"mobile_common_pic_cleandaily")];
        nrIcon.contentMode = UIViewContentModeScaleAspectFit;
        [nrIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(72);
        }];
        [nrStack addArrangedSubview:nrIcon];
        self.quickLookNoRecordLabel = [[UILabel alloc] init];
        self.quickLookNoRecordLabel.textColor = [UIColor whiteColor];
        self.quickLookNoRecordLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        self.quickLookNoRecordLabel.textAlignment = NSTextAlignmentCenter;
        self.quickLookNoRecordLabel.text = @"ai_insight_no_record_quick_look".lcMedia_T;
        self.quickLookNoRecordLabel.numberOfLines = 0;
        [nrStack addArrangedSubview:self.quickLookNoRecordLabel];
    }

    self.quickLookListFailedOverlay = [[UIView alloc] init];
    self.quickLookListFailedOverlay.backgroundColor = [UIColor lc_colorWithHexString:@"#484848"];
    self.quickLookListFailedOverlay.hidden = YES;
    self.quickLookListFailedOverlay.userInteractionEnabled = YES;
    [self.playerChromeView addSubview:self.quickLookListFailedOverlay];
    [self.quickLookListFailedOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playerChromeView);
    }];
    {
        UIStackView *lfStack = [[UIStackView alloc] init];
        lfStack.axis = UILayoutConstraintAxisVertical;
        lfStack.alignment = UIStackViewAlignmentCenter;
        lfStack.spacing = 10;
        [self.quickLookListFailedOverlay addSubview:lfStack];
        [lfStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.quickLookListFailedOverlay);
            make.left.greaterThanOrEqualTo(self.quickLookListFailedOverlay).offset(24);
            make.right.lessThanOrEqualTo(self.quickLookListFailedOverlay).offset(-24);
        }];
        UIImageView *lfIcon = [[UIImageView alloc] initWithImage:[LCAICloudQuickLookBizPlayerIcons bigModeRefreshImage]];
        lfIcon.contentMode = UIViewContentModeScaleAspectFit;
        [lfIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(45);
        }];
        [lfStack addArrangedSubview:lfIcon];
        self.quickLookListFailedLabel = [[UILabel alloc] init];
        self.quickLookListFailedLabel.textColor = [UIColor whiteColor];
        self.quickLookListFailedLabel.font = [UIFont systemFontOfSize:11];
        self.quickLookListFailedLabel.textAlignment = NSTextAlignmentCenter;
        self.quickLookListFailedLabel.numberOfLines = 0;
        self.quickLookListFailedLabel.text = @"ai_insight_network_error_tap_retry".lcMedia_T;
        [lfStack addArrangedSubview:self.quickLookListFailedLabel];
        UITapGestureRecognizer *lfTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ql_onTapListLoadFailedRetry)];
        [self.quickLookListFailedOverlay addGestureRecognizer:lfTap];
    }

    self.quickLookBizLayer = [[UIView alloc] init];
    self.quickLookBizLayer.hidden = YES;
    self.quickLookBizLayer.userInteractionEnabled = YES;
    [self.playerChromeView addSubview:self.quickLookBizLayer];
    [self.quickLookBizLayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playerChromeView);
    }];
    self.quickLookBizBackdrop = [[UIView alloc] init];
    self.quickLookBizBackdrop.userInteractionEnabled = NO;
    [self.quickLookBizLayer addSubview:self.quickLookBizBackdrop];
    [self.quickLookBizBackdrop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.quickLookBizLayer);
    }];
    self.quickLookBizStack = [[UIStackView alloc] init];
    self.quickLookBizStack.axis = UILayoutConstraintAxisVertical;
    self.quickLookBizStack.alignment = UIStackViewAlignmentCenter;
    self.quickLookBizStack.spacing = 10;
    [self.quickLookBizLayer addSubview:self.quickLookBizStack];
    [self.quickLookBizStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.quickLookBizLayer);
        make.left.greaterThanOrEqualTo(self.quickLookBizLayer).offset(20);
        make.right.lessThanOrEqualTo(self.quickLookBizLayer).offset(-20);
    }];
    self.quickLookBizLoadImageView = [[UIImageView alloc] init];
    self.quickLookBizLoadImageView.contentMode = UIViewContentModeCenter;
    self.quickLookBizLoadImageView.hidden = YES;
    [self.quickLookBizLoadImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(60);
    }];
    self.quickLookBizPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.quickLookBizPlayBtn setImage:[LCAICloudQuickLookBizPlayerIcons bigModePlayImage] forState:UIControlStateNormal];
    [self.quickLookBizPlayBtn addTarget:self action:@selector(ql_bizTapResume) forControlEvents:UIControlEventTouchUpInside];
    [self.quickLookBizPlayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(45);
    }];
    self.quickLookBizRetryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.quickLookBizRetryBtn setImage:[LCAICloudQuickLookBizPlayerIcons bigModeRefreshImage] forState:UIControlStateNormal];
    [self.quickLookBizRetryBtn addTarget:self action:@selector(ql_bizTapRetry) forControlEvents:UIControlEventTouchUpInside];
    [self.quickLookBizRetryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(45);
    }];
    self.quickLookBizRetryHint = [[UILabel alloc] init];
    self.quickLookBizRetryHint.textColor = [UIColor whiteColor];
    self.quickLookBizRetryHint.font = [UIFont systemFontOfSize:11];
    self.quickLookBizRetryHint.textAlignment = NSTextAlignmentCenter;
    self.quickLookBizRetryHint.numberOfLines = 3;
    self.quickLookBizReplayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.quickLookBizReplayBtn setImage:[LCAICloudQuickLookBizPlayerIcons bigModeReplayImage] forState:UIControlStateNormal];
    [self.quickLookBizReplayBtn addTarget:self action:@selector(ql_bizTapReplay) forControlEvents:UIControlEventTouchUpInside];
    [self.quickLookBizReplayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(45);
    }];
    self.quickLookBizRetryRow = [[UIStackView alloc] init];
    self.quickLookBizRetryRow.axis = UILayoutConstraintAxisVertical;
    self.quickLookBizRetryRow.alignment = UIStackViewAlignmentCenter;
    self.quickLookBizRetryRow.spacing = 10;
    [self.quickLookBizRetryRow addArrangedSubview:self.quickLookBizRetryBtn];
    [self.quickLookBizRetryRow addArrangedSubview:self.quickLookBizRetryHint];
    [self.quickLookBizStack addArrangedSubview:self.quickLookBizLoadImageView];
    [self.quickLookBizStack addArrangedSubview:self.quickLookBizPlayBtn];
    [self.quickLookBizStack addArrangedSubview:self.quickLookBizRetryRow];
    [self.quickLookBizStack addArrangedSubview:self.quickLookBizReplayBtn];
    self.quickLookAppliedBizScene = LCAICloudQuickLookBizSceneNone;

    self.quickLookProcessView = [[LCAICloudQuickLookDayProgressView alloc] init];
    self.quickLookProcessView.hidden = YES;
    __weak typeof(self) wQL = self;
    self.quickLookProcessView.interactionAllowedBlock = ^BOOL{
        __strong typeof(wQL) s = wQL;
        return s && ![s.recordPlugin isRecording];
    };
    self.quickLookProcessView.valueChangeEndBlock = ^(float offset, NSDate *wallDate) {
        __strong typeof(wQL) s = wQL;
        if (s) {
            [s ql_onQuickLookProcessSeekEndOffset:offset wallDate:wallDate];
        }
    };
    self.quickLookProcessView.valueChangeBlock = ^(float offset, NSDate *wallDate) {
        __strong typeof(wQL) s = wQL;
        if (!s) {
            return;
        }
        NSTimeInterval t = offset;
        if (wallDate && s.quickLookStreamStartUnix > 0) {
            t = [wallDate timeIntervalSince1970] - s.quickLookStreamStartUnix;
        }
        if (t < 0) {
            t = 0;
        }
        [s highlightSummaryForTimelineOffset:t forceManualUnlock:YES];
    };
    [self.playerChromeView addSubview:self.quickLookProcessView];
    [self.quickLookProcessView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.playerChromeView);
        make.height.mas_equalTo(kQuickLookPortraitProgressContainerHeight);
    }];

    self.quickLookToolDock = [[LCAICloudQuickLookToolDockView alloc] init];
    self.quickLookToolDock.hidden = YES;
    [self.playerChromeView addSubview:self.quickLookToolDock];
    [self.quickLookToolDock mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.playerChromeView);
        make.bottom.equalTo(self.quickLookProcessView.mas_top);
        make.height.mas_equalTo(kQuickLookToolDockHeight);
    }];

    self.qlPlayPauseBtn = [self ql_toolbarIconButtonImage:[LCAICloudQuickLookPlayerToolbarIcons portraitPlayImage] action:@selector(ql_onTapPlayPause)];
    self.qlMuteBtn = [self ql_toolbarIconButtonImage:[LCAICloudQuickLookPlayerToolbarIcons portraitVoiceOnImage] action:@selector(ql_onTapMute)];
    self.qlSpeedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.qlSpeedBtn setTitle:@"1X" forState:UIControlStateNormal];
    [self.qlSpeedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.qlSpeedBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.35] forState:UIControlStateDisabled];
    self.qlSpeedBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.qlSpeedBtn.titleLabel.lineBreakMode = NSLineBreakByClipping;
    self.qlSpeedBtn.contentEdgeInsets = UIEdgeInsetsMake(6, 2, 6, 2);
    [self.qlSpeedBtn addTarget:self action:@selector(ql_onTapSpeed) forControlEvents:UIControlEventTouchUpInside];
    [self.qlSpeedBtn setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.qlSpeedBtn setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    self.qlSnapBtn = [self ql_toolbarIconButtonImage:[LCAICloudQuickLookPlayerToolbarIcons portraitScreenshotImage] action:@selector(ql_onTapSnap)];
    self.qlRecordBtn = [self ql_toolbarIconButtonImage:[LCAICloudQuickLookPlayerToolbarIcons portraitRecordImage] action:@selector(ql_onTapRecord)];
    self.qlDownloadBtn = [self ql_toolbarIconButtonImage:[LCAICloudQuickLookPlayerToolbarIcons portraitDownloadImage] action:@selector(ql_onTapDownload)];
    self.qlFullscreenBtn = [self ql_toolbarIconButtonImage:[LCAICloudQuickLookPlayerToolbarIcons portraitFullscreenImage] action:@selector(ql_onTapFullscreen)];
    for (UIButton *b in @[ self.qlPlayPauseBtn, self.qlMuteBtn, self.qlSpeedBtn, self.qlSnapBtn, self.qlRecordBtn, self.qlDownloadBtn ]) {
        if (b == self.qlSpeedBtn) {
            [self.quickLookToolDock.toolStack addArrangedSubview:b];
            [b mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(kQuickLookToolbarIconRowHeight);
                make.width.mas_greaterThanOrEqualTo(kQuickLookSpeedButtonMinWidthPortrait);
            }];
        } else {
            [b mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.mas_equalTo(kQuickLookToolbarIconRowHeight);
            }];
            [b setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            [self.quickLookToolDock.toolStack addArrangedSubview:b];
        }
    }
    [self.quickLookToolDock.fullscreenSlot addSubview:self.qlFullscreenBtn];
    [self.qlFullscreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.quickLookToolDock.fullscreenSlot);
        make.bottom.equalTo(self.quickLookToolDock.fullscreenSlot).offset(-kQuickLookToolbarBottomInset);
        make.width.height.mas_equalTo(kQuickLookToolbarIconRowHeight);
    }];

    UIActivityIndicatorViewStyle dst = UIActivityIndicatorViewStyleWhite;
    if (@available(iOS 13.0, *)) {
        dst = UIActivityIndicatorViewStyleMedium;
    }
    self.qlDownloadIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:dst];
    if (@available(iOS 13.0, *)) {
        self.qlDownloadIndicator.color = [UIColor whiteColor];
    }
    self.qlDownloadIndicator.hidesWhenStopped = YES;
    [self.qlDownloadBtn addSubview:self.qlDownloadIndicator];
    [self.qlDownloadIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.qlDownloadBtn);
    }];

    [self ql_layoutQuickLookToolGradientIfNeeded];
    [self ql_updateChromeSubviewOrder];
}

- (void)ql_layoutQuickLookToolGradientIfNeeded {
    if (!self.quickLookToolDock) {
        return;
    }
    [self.quickLookToolDock layoutGradientIfNeeded];
}

- (void)ql_updateQuickLookToolbarForViewportSize:(CGSize)size {
    if (!self.quickLookToolDock) {
        return;
    }
    BOOL landscape = size.width > size.height;
    if (self.qlToolbarViewportApplied && landscape == self.qlToolbarLayoutIsLandscape) {
        return;
    }
    self.qlToolbarViewportApplied = YES;
    self.qlToolbarLayoutIsLandscape = landscape;
    [self.quickLookToolDock applyLandscapeLayout:landscape];
}

- (UIButton *)ql_toolbarIconButtonImage:(UIImage *)img action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.adjustsImageWhenHighlighted = YES;
    b.adjustsImageWhenDisabled = YES;
    [b setImage:img forState:UIControlStateNormal];
    b.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)ql_requestInterfaceOrientationMask:(UIInterfaceOrientationMask)mask {
    UIInterfaceOrientation target = UIInterfaceOrientationPortrait;
    if (mask & UIInterfaceOrientationMaskLandscapeRight) {
        target = UIInterfaceOrientationLandscapeRight;
    } else if (mask & UIInterfaceOrientationMaskLandscapeLeft) {
        target = UIInterfaceOrientationLandscapeLeft;
    }
    [UIDevice lc_setOrientation:target viewController:self];
}

- (void)ql_rotateToPortraitFromLandscape {
    [self ql_requestInterfaceOrientationMask:UIInterfaceOrientationMaskPortrait];
}

- (void)ql_onTapFullscreen {
    BOOL landscape = self.view.bounds.size.width > self.view.bounds.size.height;
    if (landscape) {
        [self ql_requestInterfaceOrientationMask:UIInterfaceOrientationMaskPortrait];
    } else {
        [self ql_requestInterfaceOrientationMask:UIInterfaceOrientationMaskLandscapeRight];
    }
}

- (void)ql_onTapLandscapeChromeBack {
    [self ql_rotateToPortraitFromLandscape];
}

- (void)ql_updateLandscapeChromeTitle {
    if (!self.qlLandscapeTitleLabel) {
        return;
    }
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    NSString *t = dev.name.length ? dev.name : (self.title.length ? self.title : @"ai_insight_quick_look_title".lcMedia_T);
    self.qlLandscapeTitleLabel.text = t;
}

- (void)ql_refreshQuickLookToolbarStackForLandscape:(BOOL)landscape {
    if (!self.quickLookToolDock || !self.quickLookToolDock.toolStack) {
        return;
    }
    UIStackView *stack = self.quickLookToolDock.toolStack;
    if (self.qlToolbarStackSpacer.superview == stack) {
        [stack removeArrangedSubview:self.qlToolbarStackSpacer];
        [self.qlToolbarStackSpacer removeFromSuperview];
    }
    for (UIView *v in [stack.arrangedSubviews copy]) {
        [stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    if (!self.qlToolbarStackSpacer) {
        self.qlToolbarStackSpacer = [[UIView alloc] init];
        [self.qlToolbarStackSpacer setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
        [self.qlToolbarStackSpacer setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    }
    if (landscape) {
        stack.distribution = UIStackViewDistributionFill;
        stack.alignment = UIStackViewAlignmentCenter;
        for (UIButton *b in @[ self.qlPlayPauseBtn, self.qlMuteBtn, self.qlRecordBtn, self.qlSnapBtn, self.qlSpeedBtn ]) {
            [stack addArrangedSubview:b];
        }
        [stack addArrangedSubview:self.qlToolbarStackSpacer];
    } else {
        stack.distribution = UIStackViewDistributionFill;
        stack.alignment = UIStackViewAlignmentBottom;
        for (UIButton *b in @[ self.qlPlayPauseBtn, self.qlMuteBtn, self.qlSpeedBtn, self.qlSnapBtn, self.qlRecordBtn, self.qlDownloadBtn ]) {
            [stack addArrangedSubview:b];
        }
        [stack addArrangedSubview:self.qlToolbarStackSpacer];
    }
}

- (void)ql_updateQuickLookToolbarIconSizeForLandscape:(BOOL)landscape {
    CGFloat iconSz = kQuickLookToolbarIconRowHeight;
    for (UIButton *b in @[ self.qlPlayPauseBtn, self.qlMuteBtn, self.qlSnapBtn, self.qlRecordBtn, self.qlDownloadBtn ]) {
        [b mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(iconSz);
        }];
    }
    [self.qlSpeedBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(iconSz);
        make.width.mas_greaterThanOrEqualTo(landscape ? kQuickLookSpeedButtonMinWidthLandscape : kQuickLookSpeedButtonMinWidthPortrait);
    }];
    [self.qlFullscreenBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.quickLookToolDock.fullscreenSlot);
        make.bottom.equalTo(self.quickLookToolDock.fullscreenSlot).offset(-kQuickLookToolbarBottomInset);
        make.width.height.mas_equalTo(iconSz);
    }];
}

- (void)ql_applyImage:(NSString *)symbolName pointSize:(CGFloat)pt toButton:(UIButton *)btn {
    btn.tintColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        UIImage *img = [UIImage systemImageNamed:symbolName];
        if (img) {
            UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightRegular];
            UIImage *sized = [img imageByApplyingSymbolConfiguration:cfg];
            [btn setImage:sized forState:UIControlStateNormal];
        }
    }
}

- (void)ql_stopLoadingProgressSimulation {
    [self ql_hideQuickLookBizLoadAnimation];
}

- (void)ql_showQuickLookBizLoadAnimation {
    if (!self.quickLookBizLoadImageView) {
        return;
    }
    self.quickLookBizLoadImageView.hidden = NO;
    [self.quickLookBizLoadImageView loadGifImageWith:@[
        @"video_waiting_gif_1",
        @"video_waiting_gif_2",
        @"video_waiting_gif_3",
        @"video_waiting_gif_4"
    ] TimeInterval:0.3 Style:LCMediaIMGCirclePlayStyleCircle];
}

- (void)ql_hideQuickLookBizLoadAnimation {
    if (!self.quickLookBizLoadImageView) {
        return;
    }
    self.quickLookBizLoadImageView.hidden = YES;
    [self.quickLookBizLoadImageView releaseImgs];
}

- (void)applyQuickLookBizScene:(LCAICloudQuickLookBizScene)scene {
    self.quickLookAppliedBizScene = scene;
    if (!self.quickLookBizLayer) {
        return;
    }
    if (scene == LCAICloudQuickLookBizSceneNone) {
        [self ql_stopLoadingProgressSimulation];
        self.quickLookBizLayer.hidden = YES;
        self.quickLookBizStack.spacing = 10;
        [self ql_updateChromeSubviewOrder];
        [self refreshQuickLookChromeInteraction];
        [self refreshQuickLookPlayerToolbar];
        return;
    }
    self.quickLookBizLayer.hidden = NO;
    [self ql_hideQuickLookBizLoadAnimation];
    self.quickLookBizPlayBtn.hidden = YES;
    self.quickLookBizReplayBtn.hidden = YES;
    self.quickLookBizRetryRow.hidden = YES;

    UIColor *bg = [UIColor clearColor];
    switch (scene) {
        case LCAICloudQuickLookBizSceneFirstLoading:
            bg = [UIColor lc_colorWithHexString:@"#484848"];
            self.quickLookBizStack.spacing = 5;
            [self ql_showQuickLookBizLoadAnimation];
            break;
        case LCAICloudQuickLookBizSceneLoading:
            bg = [UIColor colorWithWhite:0 alpha:0.5];
            self.quickLookBizStack.spacing = 5;
            [self ql_showQuickLookBizLoadAnimation];
            break;
        case LCAICloudQuickLookBizScenePlay:
            [self ql_stopLoadingProgressSimulation];
            self.quickLookBizStack.spacing = 10;
            bg = [UIColor colorWithWhite:0 alpha:0.5];
            self.quickLookBizPlayBtn.hidden = NO;
            break;
        case LCAICloudQuickLookBizSceneRetry:
            [self ql_stopLoadingProgressSimulation];
            self.quickLookBizStack.spacing = 10;
            bg = [UIColor lc_colorWithHexString:@"#484848"];
            self.quickLookBizRetryRow.hidden = NO;
            {
                NSString *hint = @"ai_insight_play_failed".lcMedia_T;
                if (self.quickLookLastPlayError.length) {
                    hint = [NSString stringWithFormat:@"%@\n%@", hint, self.quickLookLastPlayError];
                }
                self.quickLookBizRetryHint.text = hint;
            }
            break;
        case LCAICloudQuickLookBizSceneReplay:
            [self ql_stopLoadingProgressSimulation];
            self.quickLookBizStack.spacing = 10;
            bg = [UIColor colorWithWhite:0 alpha:0.5];
            self.quickLookBizReplayBtn.hidden = NO;
            if (self.quickLookProcessView && !self.quickLookProcessView.hidden) {
                [self.quickLookProcessView lc_snapProgressToFull];
            }
            break;
        default:
            [self ql_stopLoadingProgressSimulation];
            self.quickLookBizStack.spacing = 10;
            break;
    }
    self.quickLookBizBackdrop.backgroundColor = bg;
    [self ql_updateChromeSubviewOrder];
    [self refreshQuickLookChromeInteraction];
    [self refreshQuickLookPlayerToolbar];
}

- (void)ql_applyLandscapePlaybackChromeAlphaAnimated:(BOOL)animated {
    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    if (!land) {
        self.quickLookToolDock.alpha = 1.0;
        self.quickLookProcessView.alpha = 1.0;
        if (self.quickLookLandscapeTopBar) {
            self.quickLookLandscapeTopBar.alpha = 1.0;
        }
        return;
    }
    CGFloat a = self.qlLandscapePlaybackChromeHiddenByUser ? 0.0 : 1.0;
    BOOL processEmbeddedInDock = (self.quickLookProcessView.superview == self.quickLookToolDock);
    void (^anim)(void) = ^{
        self.quickLookToolDock.alpha = a;
        if (!processEmbeddedInDock) {
            self.quickLookProcessView.alpha = a;
        } else {
            self.quickLookProcessView.alpha = 1.0;
        }
        if (self.quickLookLandscapeTopBar && !self.quickLookLandscapeTopBar.hidden) {
            self.quickLookLandscapeTopBar.alpha = a;
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.3 animations:anim];
    } else {
        anim();
    }
}

- (void)ql_toggleLandscapePlaybackChromeVisibility {
    if (!self.quickLookToolDock || self.quickLookToolDock.hidden || !self.quickLookProcessView || self.quickLookProcessView.hidden) {
        return;
    }
    if (self.quickLookListFailedOverlay && !self.quickLookListFailedOverlay.hidden) {
        return;
    }
    if (self.quickLookNoRecordOverlay && !self.quickLookNoRecordOverlay.hidden) {
        return;
    }
    if (self.quickLookBizLayer && !self.quickLookBizLayer.hidden) {
        return;
    }
    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    if (!land) {
        return;
    }
    self.qlLandscapePlaybackChromeHiddenByUser = !self.qlLandscapePlaybackChromeHiddenByUser;
    [self ql_applyLandscapePlaybackChromeAlphaAnimated:YES];
}

- (void)ql_updateChromeSubviewOrder {
    if (!self.playerChromeView || !self.quickLookNoRecordOverlay) {
        return;
    }
    if (self.quickLookListFailedOverlay && !self.quickLookListFailedOverlay.hidden) {
        [self.playerChromeView bringSubviewToFront:self.quickLookListFailedOverlay];
        return;
    }
    if (!self.quickLookNoRecordOverlay.hidden) {
        [self.playerChromeView bringSubviewToFront:self.quickLookNoRecordOverlay];
        return;
    }
    if (self.quickLookBizLayer && !self.quickLookBizLayer.hidden) {
        [self.playerChromeView bringSubviewToFront:self.quickLookBizLayer];
    }
    if (self.quickLookToolDock && !self.quickLookToolDock.hidden) {
        [self.playerChromeView bringSubviewToFront:self.quickLookToolDock];
    }
    if (self.quickLookProcessView && !self.quickLookProcessView.hidden && self.quickLookProcessView.superview == self.playerChromeView) {
        [self.playerChromeView bringSubviewToFront:self.quickLookProcessView];
    }
    if (self.quickLookLandscapeTopBar && !self.quickLookLandscapeTopBar.hidden) {
        [self.playerChromeView bringSubviewToFront:self.quickLookLandscapeTopBar];
    }
}

- (void)refreshQuickLookChromeInteraction {
    if (!self.playerChromeView) {
        return;
    }
    BOOL listFail = self.quickLookListFailedOverlay && !self.quickLookListFailedOverlay.hidden;
    BOOL noRec = !self.quickLookNoRecordOverlay.hidden;
    BOOL tools = !self.quickLookToolDock.hidden;
    BOOL progress = self.quickLookProcessView && !self.quickLookProcessView.hidden;
    BOOL biz = self.quickLookBizLayer && !self.quickLookBizLayer.hidden;
    self.playerChromeView.userInteractionEnabled = listFail || noRec || tools || progress || biz;
}

- (void)ql_updateQuickLookProcessLayoutForViewportIfNeeded {
    if (!self.playerChromeView || !self.quickLookToolDock || !self.quickLookProcessView) {
        return;
    }
    if (self.quickLookToolDock.hidden) {
        return;
    }
    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    if (land == self.qlChromeProcessLayoutIsLandscape) {
        return;
    }
    [self ql_remakeQuickLookPlayerChromeLayoutForLandscape:land];
}

- (void)ql_remakeQuickLookPlayerChromeLayoutForLandscape:(BOOL)land {
    if (!self.quickLookProcessView || self.quickLookProcessView.hidden) {
        return;
    }
    BOOL wasPortraitLayout = !self.qlChromeProcessLayoutIsLandscape;
    if (land && wasPortraitLayout) {
        self.qlLandscapePlaybackChromeHiddenByUser = NO;
    }
    if (!land) {
        self.qlLandscapePlaybackChromeHiddenByUser = NO;
    }
    self.quickLookProcessView.isLandscapeLayout = land;
    if (land) {
        static const CGFloat kQuickLookLandscapeDockHeight = 90.0;
        [self.quickLookToolDock mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.playerChromeView);
            make.height.mas_equalTo(kQuickLookLandscapeDockHeight);
        }];
        self.quickLookLandscapeTopBar.hidden = NO;
        [self.quickLookLandscapeTopBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.trailing.equalTo(self.playerChromeView);
            make.height.mas_equalTo(48.0);
        }];
        self.qlDownloadBtn.hidden = YES;
        [self.quickLookToolDock applyLandscapeLayout:YES];
        [self ql_refreshQuickLookToolbarStackForLandscape:YES];
        [self.quickLookToolDock applyLandscapeCloudPlaybackChrome:YES embeddedProcessView:self.quickLookProcessView];
        [self ql_updateQuickLookToolbarIconSizeForLandscape:YES];
    } else {
        [self.quickLookToolDock applyLandscapeLayout:NO];
        [self ql_refreshQuickLookToolbarStackForLandscape:NO];
        [self.quickLookToolDock applyLandscapeCloudPlaybackChrome:NO embeddedProcessView:self.quickLookProcessView];
        [self.playerChromeView addSubview:self.quickLookProcessView];
        [self.quickLookProcessView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.playerChromeView);
            make.height.mas_equalTo(kQuickLookPortraitProgressContainerHeight);
        }];
        [self.quickLookToolDock mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.playerChromeView);
            make.bottom.equalTo(self.quickLookProcessView.mas_top);
            make.height.mas_equalTo(kQuickLookToolDockHeight);
        }];
        self.quickLookLandscapeTopBar.hidden = YES;
        self.qlDownloadBtn.hidden = NO;
        [self ql_updateQuickLookToolbarIconSizeForLandscape:NO];
    }
    self.qlChromeProcessLayoutIsLandscape = land;
    if (land) {
        [self.quickLookProcessView setSegmentOverlayRatios:@[]];
    } else {
        [self.quickLookProcessView setSegmentOverlayRatios:[self.persenter ql_progressBarOverlayRatios]];
    }
    [self ql_layoutQuickLookToolGradientIfNeeded];
    [self ql_updateChromeSubviewOrder];
    [self ql_applyLandscapePlaybackChromeAlphaAnimated:NO];
}

- (void)ql_refreshQuickLookProcessDateRange {
    if (!self.quickLookProcessView) {
        return;
    }
    LCCloudVideotapeInfo *rec = [self.persenter currentChannelRecord];
    if (!rec) {
        return;
    }
    NSTimeInterval totalSec = [self.persenter ql_quickLookTimelineTotalSecondsForRecord:rec];
    NSTimeInterval originUnix = [self.persenter quickLookStartUnixForRecord:rec];
    if (originUnix <= 0) {
        if (rec.beginDate) {
            originUnix = [rec.beginDate timeIntervalSince1970];
        } else {
            return;
        }
    }
    NSDate *barStart = [NSDate dateWithTimeIntervalSince1970:originUnix];
    NSDate *end = [barStart dateByAddingTimeInterval:totalSec];
    [self.quickLookProcessView setStartDate:barStart endDate:end];
    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    if (land) {
        [self.quickLookProcessView setSegmentOverlayRatios:@[]];
    } else {
        [self.quickLookProcessView setSegmentOverlayRatios:[self.persenter ql_progressBarOverlayRatios]];
    }
}

- (void)ql_onQuickLookProcessSeekEndOffset:(float)offset wallDate:(NSDate *)wallDate {
    LCCloudVideotapeInfo *rec = [self.persenter currentChannelRecord];
    if (!rec) {
        return;
    }
    NSTimeInterval tHighlight = (double)offset;
    if (wallDate && self.quickLookStreamStartUnix > 0) {
        tHighlight = [wallDate timeIntervalSince1970] - self.quickLookStreamStartUnix;
    }
    if (tHighlight < 0) {
        tHighlight = 0;
    }
    [self highlightSummaryForTimelineOffset:tHighlight forceManualUnlock:YES];
    LCPlayStatus st = [self.recordPlugin getPlayState];
    if (st == LCPlayStatusStop || st == LCPlayStatusError) {
        [self playCondensedRecord:rec offsetSeconds:(double)offset];
    } else {
        [self.recordPlugin seek:(NSInteger)llround((double)offset)];
    }
}

- (void)ql_bizTapResume {
    [self ql_onTapPlayPause];
}

- (void)ql_bizTapRetry {
    LCCloudVideotapeInfo *rec = [self.persenter currentChannelRecord];
    if (!rec) {
        return;
    }
    [self playCondensedRecord:rec offsetSeconds:0];
}

- (void)ql_bizTapReplay {
    [self ql_bizTapRetry];
}

- (void)ql_onTapListLoadFailedRetry {
    [self.persenter clearListLoadFailureAndRefetch];
}

- (void)updateQuickLookPlayerChromeAfterDataChange {
    BOOL listFailed = self.persenter.quickLookHasLoaded && self.persenter.quickLookLoadFailed;
    BOOL loadedOk = self.persenter.quickLookHasLoaded && !self.persenter.quickLookLoadFailed;
    LCCloudVideotapeInfo *rec = [self.persenter currentChannelRecord];
    BOOL noRec = (rec == nil);
    if (!(loadedOk && rec != nil)) {
        [self applyQuickLookBizScene:LCAICloudQuickLookBizSceneNone];
    }
    self.quickLookListFailedOverlay.hidden = !listFailed;
    self.quickLookNoRecordOverlay.hidden = !(loadedOk && noRec);
    self.quickLookToolDock.hidden = !(loadedOk && rec != nil);
    self.quickLookProcessView.hidden = !(loadedOk && rec != nil);
    self.qlLandscapePlaybackChromeHiddenByUser = NO;
    self.quickLookToolDock.alpha = 1.0;
    self.quickLookProcessView.alpha = 1.0;
    if (self.quickLookLandscapeTopBar) {
        self.quickLookLandscapeTopBar.alpha = 1.0;
    }
    [self ql_refreshQuickLookProcessDateRange];
    [self ql_layoutQuickLookToolGradientIfNeeded];
    [self ql_updateChromeSubviewOrder];
    [self refreshQuickLookChromeInteraction];
    if (!self.quickLookProcessView.hidden) {
        [self ql_remakeQuickLookPlayerChromeLayoutForLandscape:(self.view.bounds.size.width > self.view.bounds.size.height)];
    }
}

- (void)updateQuickLookSummaryEmptyBackgroundIfNeeded {
    if (!self.persenter.quickLookSummaryEmptyBoard || self.persenter.quickLookLoadFailed) {
        self.tableView.backgroundView = nil;
        return;
    }
    UIView *wrap = [[UIView alloc] initWithFrame:CGRectZero];
    wrap.backgroundColor = [UIColor whiteColor];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 8;
    [wrap addSubview:stack];
    UIImageView *iv = [[UIImageView alloc] initWithImage:LCAICloudAppBundleImage(@"mobile_common_pic_cleandaily")];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [iv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(100);
    }];
    UILabel *lab = [[UILabel alloc] init];
    lab.textAlignment = NSTextAlignmentCenter;
    lab.font = [UIFont systemFontOfSize:14];
    lab.textColor = [UIColor lc_colorWithHexString:@"#8F8F8F"];
    lab.text = @"ai_insight_no_record_quick_look".lcMedia_T;
    lab.numberOfLines = 0;
    [stack addArrangedSubview:iv];
    [stack addArrangedSubview:lab];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(wrap);
        make.left.greaterThanOrEqualTo(wrap).offset(24);
        make.right.lessThanOrEqualTo(wrap).offset(-24);
    }];
    self.tableView.backgroundView = wrap;
}

- (void)refreshQuickLookPlayerToolbar {
    if (!self.qlPlayPauseBtn) {
        return;
    }
    LCPlayStatus st = [self.recordPlugin getPlayState];
    BOOL playing = (st == LCPlayStatusPlaying);
    UIImage *pp = playing ? [LCAICloudQuickLookPlayerToolbarIcons portraitPlayImage] : [LCAICloudQuickLookPlayerToolbarIcons portraitPauseImage];
    [self.qlPlayPauseBtn setImage:pp forState:UIControlStateNormal];
    UIImage *vm = self.quickLookSoundOn ? [LCAICloudQuickLookPlayerToolbarIcons portraitVoiceOnImage] : [LCAICloudQuickLookPlayerToolbarIcons portraitVoiceOffImage];
    [self.qlMuteBtn setImage:vm forState:UIControlStateNormal];
    NSArray<NSString *> *speedTitles = @[ @"1X", @"2X", @"4X", @"8X", @"16X", @"32X" ];
    NSInteger idx = self.quickLookSpeedStep % (NSInteger)speedTitles.count;
    [self.qlSpeedBtn setTitle:speedTitles[(NSUInteger)idx] forState:UIControlStateNormal];
    BOOL recOn = [self.recordPlugin isRecording];
    if (recOn) {
        UIImage *recImg = LCAICloudAppBundleImage(@"video_playvideo_video_h");
        if (recImg) {
            [self.qlRecordBtn setImage:[recImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        } else {
            [self.qlRecordBtn setImage:[LCAICloudQuickLookPlayerToolbarIcons portraitRecordImage] forState:UIControlStateNormal];
        }
        self.qlRecordBtn.tintColor = [UIColor whiteColor];
    } else {
        [self.qlRecordBtn setImage:[LCAICloudQuickLookPlayerToolbarIcons portraitRecordImage] forState:UIControlStateNormal];
        self.qlRecordBtn.tintColor = [UIColor whiteColor];
    }
    BOOL land = self.view.bounds.size.width > self.view.bounds.size.height;
    BOOL hideDownload = land;
    self.qlDownloadBtn.hidden = hideDownload;
    if (hideDownload) {
        [self.qlDownloadIndicator stopAnimating];
    } else if (self.qlDownloadBusy) {
        [self.qlDownloadBtn setImage:nil forState:UIControlStateNormal];
        [self.qlDownloadIndicator startAnimating];
    } else {
        [self.qlDownloadIndicator stopAnimating];
        [self.qlDownloadBtn setImage:[LCAICloudQuickLookPlayerToolbarIcons portraitDownloadImage] forState:UIControlStateNormal];
    }

    LCAICloudQuickLookBizScene biz = self.quickLookAppliedBizScene;
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

    BOOL at1x = (self.quickLookSpeedStep == 0);
    BOOL enMute = normalPlaying && at1x;
    BOOL enDl = (normalPlaying || paused || bizFinish || stoppedIdle) && !loading && !fail;
    BOOL enSpeed = YES;
    BOOL enSnap = (normalPlaying || paused) && !loading && !fail && !bizFinish;
    BOOL enRec = !loading && !fail && !bizFinish && (at1x || recOn) && (normalPlaying || (paused && recOn));

    self.qlMuteBtn.enabled = enMute;
    self.qlSpeedBtn.enabled = enSpeed;
    self.qlSnapBtn.enabled = enSnap;
    self.qlRecordBtn.enabled = enRec;
    if (!hideDownload) {
        self.qlDownloadBtn.enabled = enDl && !self.qlDownloadBusy;
    } else {
        self.qlDownloadBtn.enabled = YES;
    }

    [self refreshQuickLookChromeInteraction];
}

- (void)ql_onTapPlayPause {
    LCPlayStatus st = [self.recordPlugin getPlayState];
    if (st == LCPlayStatusPlaying) {
        [self.recordPlugin pauseAsync];
    } else if (st == LCPlayStatusPause) {
        [self.recordPlugin resumeAsync];
    } else if (st == LCPlayStatusStop || st == LCPlayStatusError) {
        LCCloudVideotapeInfo *rec = [self.persenter currentChannelRecord];
        if (rec) {
            [self playCondensedRecord:rec offsetSeconds:0];
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshQuickLookPlayerToolbar];
    });
}

- (void)ql_onTapMute {
    if (!self.qlMuteBtn.isEnabled) {
        return;
    }
    if (self.quickLookSoundOn) {
        self.quickLookSoundOn = NO;
        [self.recordPlugin stopAudioWithIsCallback:YES];
    } else {
        self.quickLookSoundOn = YES;
        [self.recordPlugin playAudioWithIsCallback:YES];
    }
    [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = self.quickLookSoundOn;
    [self refreshQuickLookPlayerToolbar];
}

- (void)ql_onTapSpeed {
    if (!self.qlSpeedBtn.isEnabled) {
        return;
    }
    static NSArray<NSNumber *> *kFactors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kFactors = @[ @1.0f, @2.0f, @4.0f, @8.0f, @16.0f, @32.0f ];
    });
    NSInteger n = (NSInteger)kFactors.count;
    self.quickLookSpeedStep = (self.quickLookSpeedStep + 1) % n;
    CGFloat sp = [kFactors[(NSUInteger)self.quickLookSpeedStep] floatValue];
    [self.recordPlugin setPlaySpeed:sp];
    // 高倍速下不伴音；1x 时仅按用户静音状态开关伴音，勿在切到 1x 时自动打开（否则与「先关音再调倍速」矛盾）
    if (sp > 1.01f) {
        [self.recordPlugin stopAudioWithIsCallback:YES];
    } else {
        if (self.quickLookSoundOn) {
            [self.recordPlugin playAudioWithIsCallback:YES];
        } else {
            [self.recordPlugin stopAudioWithIsCallback:YES];
        }
    }
    [LCNewDeviceVideotapePlayManager shareInstance].isSoundOn = self.quickLookSoundOn;
    [self refreshQuickLookPlayerToolbar];
}

- (void)ql_onTapSnap {
    if (!self.qlSnapBtn.isEnabled) {
        return;
    }
    [self.recordPlugin snapShotWithIsCallback:YES];
}

- (void)ql_onTapRecord {
    if (!self.qlRecordBtn.isEnabled) {
        return;
    }
    if ([self.recordPlugin isRecording]) {
        [self.recordPlugin stopRecord];
    } else {
        [self.recordPlugin startRecord];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshQuickLookPlayerToolbar];
    });
}

- (NSString *)ql_downloadDestinationPathForRecord:(LCCloudVideotapeInfo *)rec {
    (void)rec;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *myDirectory = [libraryDirectory stringByAppendingPathComponent:@"lechange"];
    NSString *downloadDirectory = [myDirectory stringByAppendingPathComponent:@"download"];
    NSString *infoPath = [downloadDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%f_download", [[NSDate date] timeIntervalSince1970]]];
    NSString *downPath = [infoPath stringByAppendingString:@".mp4"];
    NSFileManager *fileManage = [NSFileManager defaultManager];
    NSError *pErr = nil;
    BOOL isDir = NO;
    if (![fileManage fileExistsAtPath:myDirectory isDirectory:&isDir]) {
        [fileManage createDirectoryAtPath:myDirectory withIntermediateDirectories:YES attributes:nil error:&pErr];
    }
    isDir = NO;
    if (![fileManage fileExistsAtPath:downloadDirectory isDirectory:&isDir]) {
        [fileManage createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:&pErr];
    }
    return downPath;
}

- (void)ql_onTapDownload {
    if (!self.qlDownloadBtn.isEnabled || self.qlDownloadBtn.hidden) {
        return;
    }
    LCCloudVideotapeInfo *rec = [self.persenter currentChannelRecord];
    if (!rec) {
        return;
    }
    LCOpenSDK_DownloadByRecordIdParam *p = [[LCOpenSDK_DownloadByRecordIdParam alloc] init];
    p.index = self.quickLookDownloadIndex++;
    p.savePath = [self ql_downloadDestinationPathForRecord:rec];
    p.accessToken = [LCApplicationDataManager token];
    p.deviceId = [LCNewDeviceVideoManager shareInstance].currentDevice.deviceId;
    p.psk = self.quickLookPagePlayPsw.length > 0 ? self.quickLookPagePlayPsw : p.deviceId;
    p.productId = [LCNewDeviceVideoManager shareInstance].currentDevice.productId;
    p.channelId = (NSInteger)self.persenter.selectedChannelId.integerValue;
    p.recordRegionId = rec.recordPath ?: @"";
    p.speed = 2.0f;
    LCOpenSDK_CloudExtraInfo *ex = [[LCOpenSDK_CloudExtraInfo alloc] init];
    ex.m3uPath = rec.recordPath ?: @"";
    ex.streamAddr = rec.streamAddr ?: @"";
    ex.regionId = rec.recordRegionId ?: @"";
    ex.ak = rec.ak ?: @"";
    ex.fileToken = rec.fileToken ?: @"";
    ex.expireTime = rec.expireTime ?: @"";
    ex.uid = rec.userId ?: @"";
    ex.businessType = 1;
    p.extraInfo = ex;
    [[LCOpenSDK_Download shareMyInstance] setListener:self];
    NSInteger code = [[LCOpenSDK_Download shareMyInstance] startDownloadCloudRecord:p];
    if (code != 0) {
        self.qlDownloadBusy = NO;
        self.qlLastCloudDownloadSavePath = nil;
        [self refreshQuickLookPlayerToolbar];
        [LCProgressHUD showMsg:[NSString stringWithFormat:@"ai_insight_download_start_failed_format".lcMedia_T, (long)code]];
    } else {
        self.qlDownloadBusy = YES;
        self.qlLastCloudDownloadSavePath = [p.savePath copy];
        [self refreshQuickLookPlayerToolbar];
        [LCProgressHUD showMsg:@"ai_insight_download_started".lcMedia_T];
    }
}

- (void)ql_saveCloudDownloadToAlbumWithPath:(NSString *)path index:(NSInteger)index {
    (void)index;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSURL *downloadURL = [NSURL fileURLWithPath:path];
            [PHAsset deleteFormCameraRoll:downloadURL success:^{
            } failure:^(NSError *error) {
                (void)error;
            }];
            [PHAsset saveVideoAtURL:downloadURL success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [LCProgressHUD showMsg:@"mobile_common_data_download_success".lcMedia_T];
                });
            } failure:^(NSError *error) {
                (void)error;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [LCProgressHUD showMsg:@"mobile_common_data_download_fail".lcMedia_T];
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [LCProgressHUD showMsg:@"mobile_common_data_download_fail".lcMedia_T];
            });
        }
    });
}

- (void)onDownloadState:(NSInteger)index code:(NSString *)code type:(NSInteger)type {
    (void)type;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([code isEqualToString:@"2"] || [code isEqualToString:@"0"]) {
            self.qlDownloadBusy = NO;
            [self refreshQuickLookPlayerToolbar];
        }
        if ([code isEqualToString:@"2"]) {
            [[LCOpenSDK_Download shareMyInstance] stopDownload:index];
            NSString *savePath = self.qlLastCloudDownloadSavePath;
            self.qlLastCloudDownloadSavePath = nil;
            if (savePath.length) {
                [self ql_saveCloudDownloadToAlbumWithPath:savePath index:index];
            } else {
                [LCProgressHUD showMsg:@"mobile_common_data_download_success".lcMedia_T];
            }
        } else if ([code isEqualToString:@"0"]) {
            self.qlLastCloudDownloadSavePath = nil;
            [LCProgressHUD showMsg:@"mobile_common_data_download_fail".lcMedia_T];
        }
    });
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    weakSelf(self);
    [self lcCreatNavigationBarWith:LCNAVIGATION_STYLE_DEFAULT buttonClickBlock:^(NSInteger index) {
        if (index == 0) {
            BOOL land = weakself.view.bounds.size.width > weakself.view.bounds.size.height;
            if (land) {
                [weakself ql_rotateToPortraitFromLandscape];
            } else {
                [weakself.navigationController popViewControllerAnimated:YES];
            }
        }
    }];
    UIImage *calImg = LCAICloudAppBundleImage(@"common_nav_calendar");
    UIBarButtonItem *calItem;
    if (calImg) {
        calItem = [[UIBarButtonItem alloc] initWithImage:[calImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(onTapQuickLookCalendar:)];
    } else if (@available(iOS 13.0, *)) {
        calItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"calendar"] style:UIBarButtonItemStylePlain target:self action:@selector(onTapQuickLookCalendar:)];
    } else {
        calItem = [[UIBarButtonItem alloc] initWithTitle:@"ai_insight_bar_calendar".lcMedia_T style:UIBarButtonItemStylePlain target:self action:@selector(onTapQuickLookCalendar:)];
    }
    self.navigationItem.rightBarButtonItem = calItem;
    [self ql_updateLandscapeChromeTitle];
    [self ql_updateQuickLookNavigationBarHiddenForViewportAnimated:NO];
    self.qlRootLayoutLandState = -1;
    [self ql_updateQuickLookRootLayoutForViewportIfNeeded];
}

- (void)onTapQuickLookCalendar:(id)sender {
    NSMutableArray<NSDictionary *> *list = [NSMutableArray array];
    for (LCAICloudDayItem *it in self.persenter.dayItems) {
        [list addObject:@{ @"date" : it.dateString ?: @"", @"hasVideo" : @(it.hasVideo) }];
    }
    LCAICloudQuickLookCalendarViewController *cal = [[LCAICloudQuickLookCalendarViewController alloc] initWithDayInfoList:list selectedDate:self.persenter.selectedDateStr];
    __weak typeof(self) wself = self;
    cal.onPickDate = ^(NSString *yyyyMMdd) {
        [wself dismissViewControllerAnimated:NO completion:nil];
        if (![yyyyMMdd isEqualToString:wself.persenter.selectedDateStr]) {
            wself.persenter.selectedDateStr = yyyyMMdd ?: @"";
            [wself.recordPlugin stopRecordStream:NO];
            [wself.persenter fetchCondensedListForCurrentDate];
        }
    };
    cal.onCancel = ^{
        [wself dismissViewControllerAnimated:NO completion:nil];
    };
    cal.modalPresentationStyle = UIModalPresentationOverFullScreen;
    cal.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:cal animated:NO completion:nil];
}


- (LCAICloudEventPersenter *)persenter {
    if (!_persenter) {
        _persenter = [[LCAICloudEventPersenter alloc] init];
        _persenter.eventListPage = self;
    }
    return _persenter;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor lc_colorWithHexString:@"#F6F6F6"];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 140;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        }
    }
    return _tableView;
}

@end
