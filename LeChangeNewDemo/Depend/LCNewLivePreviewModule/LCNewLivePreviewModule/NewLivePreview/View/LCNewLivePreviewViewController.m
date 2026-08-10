//
//  Copyright © 2019 Imou. All rights reserved.
//

#import "LCNewLivePreviewViewController.h"
#import "LCNewVideoControlView.h"
#import "LCNewLivePreviewPresenter.h"
#import "LCNewPTZControlView.h"
#import "LCNewLandscapeControlView.h"
#import "LCNewLivePreviewPresenter+LandscapeControlView.h"
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <LCBaseModule/UIViewController+LCNavigationBar.h>
#import <LCBaseModule/NSString+AbilityAnalysis.h>
#import <LCBaseModule/UIColor+LeChange.h>
#import <KVOController/KVOController.h>
#import <Masonry/Masonry.h>
#import <LCDeviceDetailModule/LCDeviceDetailModule-Swift.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import "LCNewLivePreviewPresenter+VideotapeList.h"

/// 导航标题左右预留给返回/右侧按钮的宽度
static const CGFloat kLCNavTitleHorizontalInset = 120.0;
/// 长标题最小缩放比例
static const CGFloat kLCNavTitleMinScale = 0.7;
static const CGFloat kLCNavTitleHeight = 44.0;

@interface LCNewLivePreviewViewController ()

/// Presenter
@property (strong, nonatomic) LCNewLivePreviewPresenter *persenter;

@property (nonatomic, strong) LCNewVideoControlView *middleControlView;

@property (nonatomic, strong) LCNewVideoControlView *bottomControlView;

@property (nonatomic, strong) LCNewVideoControlView *upDownControlView;

@property (nonatomic, strong) LCNewPTZControlView * ptzControlView;

@property (nonatomic, strong) LCNewPTZPanel * landscapePtzControlView;

@property (nonatomic, strong) LCNewLandscapeControlView *landscapeControlView;

@property (nonatomic, strong) UIView *videoHistoryView;

/// 自定义导航标题文案（长 SN 场景）
@property (nonatomic, copy) NSString *lc_navTitleText;

@end

@implementation LCNewLivePreviewViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    [self setupView];
    
    //配置窗口模式
    if ([[LCNewDeviceVideoManager shareInstance] isMulti]) {
        [self.persenter.livePlugin configPlayerType:LCMediaPlayerTypeDoubleIPC];
        //默认画中画模式
        self.persenter.livePlugin.screenMode = LCScreenModeSingleScreen;
    }else {
        [self.persenter.livePlugin configPlayerType:LCMediaPlayerTypeSingleIPC];
    }
    
    UIImageView *defaultImageView = self.persenter.defaultImageView;
    defaultImageView.hidden = NO;
    [defaultImageView lc_setThumbImageWithURL:[LCNewDeviceVideoManager shareInstance].mainChannelInfo.picUrl placeholderImage:LC_IMAGENAMED(@"common_defaultcover_big") DeviceId:[LCNewDeviceVideoManager shareInstance].currentDevice.deviceId ChannelId:[LCNewDeviceVideoManager shareInstance].mainChannelInfo.channelId];
    
    if ([[LCNewDeviceVideoManager shareInstance] isMulti]) {
        UIImageView *subDefaultImageView = self.persenter.subDefaultImageView;
        subDefaultImageView.hidden = NO;
        [subDefaultImageView lc_setThumbImageWithURL:[LCNewDeviceVideoManager shareInstance].mainChannelInfo.picUrl placeholderImage:LC_IMAGENAMED(@"common_defaultcover_big") DeviceId:[LCNewDeviceVideoManager shareInstance].currentDevice.deviceId ChannelId:[LCNewDeviceVideoManager shareInstance].subChannelInfo.channelId];
    }
    
    self.persenter.videoTypeLabel.hidden = YES;
    self.persenter.subVideoTypeLabel.hidden = YES;
    
    NSString *titleStr = [LCNewDeviceVideoManager shareInstance].currentDevice.name;
    if ([LCNewDeviceVideoManager shareInstance].currentDevice.channelNum > 0 &&   ![[LCNewDeviceVideoManager shareInstance] isMulti]) {
        titleStr = [LCNewDeviceVideoManager shareInstance].mainChannelInfo.channelName;
    }
    [self lc_setupNavigationTitle:titleStr];
    [self.landscapeControlView refreshTitle:titleStr];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    
    self.videoHistoryView = [self.persenter getVideotapeView];
    [self.view addSubview:self.videoHistoryView];
    [self.videoHistoryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.bottomControlView.mas_bottom).offset(5);
        make.trailing.leading.mas_equalTo(self.view);
    }];
    [self.persenter loadCloudVideotape];
    
//    [self.KVOController observe:[LCNewDeviceVideoManager shareInstance] keyPath:@"displayChannelID" options:NSKeyValueObservingOptionNew block:^(id _Nullable observer, id _Nonnull object, NSDictionary<NSString *, id> *_Nonnull change) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self changeDisplayWindow:[LCNewDeviceVideoManager shareInstance].displayChannelID];
//        });
//    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if ([window isKindOfClass:NSClassFromString(@"UITextEffectsWindow")]) {
            window.hidden = YES;
        }
    }
//    if (self.isFirstIntoVC != YES) {
//        [self.persenter onFullScreen:nil];
//    }
    self.isFirstIntoVC = NO;
    [self.persenter refreshMiddleControlItems];
    [self.persenter refreshBottomControlItems];
    // 开始拉流
    if ([[LCNewDeviceVideoManager shareInstance].currentDevice.status isEqualToString:@"online"] || [[LCNewDeviceVideoManager shareInstance].currentDevice.status isEqualToString:@"sleep"]) {
        [self.persenter startPlay];
    }
    
    if (self.persenter.displayStyle == LCPlayWindowDisplayStyleUpDownScreen) {
        [self.navigationController.navigationBar setBarBackgroundColorWithColor:[UIColor blackColor] titleColor:[UIColor whiteColor]];
        [self lc_refreshNavigationTitleView];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //退出该页面停止播放
    if ([LCNewDeviceVideoManager shareInstance].isPlay) {
        [self.persenter stopPlay:YES];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.persenter.displayStyle == LCPlayWindowDisplayStyleUpDownScreen) {
        [self.navigationController.navigationBar setBarBackgroundColorWithColor:[UIColor whiteColor] titleColor:[UIColor blackColor]];
    }
}

- (void)configDevice:(LCDeviceInfo *)device channelIndex:(NSInteger)index {
    [LCNewDeviceVideoManager shareInstance].currentDevice = device;
}

- (void)willResignActiveNotification:(NSNotification *)notic {
    [self.persenter stopPlay:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    if (size.width > size.height) {
        self.navigationController.navigationBar.hidden = YES;
        [self configFullScreenUI];
    } else {
        self.navigationController.navigationBar.hidden = NO;
        [self configPortraitScreenUI];
    }
    // 云台开启时，随横竖屏切换显示对应云台，隐藏另一朝向云台
    if ([LCNewDeviceVideoManager shareInstance].isOpenCloudStage) {
        BOOL isLandscape = size.width > size.height;
        if (!isLandscape) {
            [self.view bringSubviewToFront:self.ptzControlView];
        }
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            self.landscapePtzControlView.alpha = isLandscape ? 1.0 : 0;
            self.ptzControlView.alpha = isLandscape ? 0 : 1.0;
        } completion:nil];
    }
}


//MARK: - Private Methods
- (LCNewLivePreviewPresenter *)persenter {
    if (!_persenter) {
        _persenter = [LCNewLivePreviewPresenter new];
        _persenter.liveContainer  = self;
    }
    return _persenter;
}

- (void)setupView {
    self.view.backgroundColor = [UIColor lccolor_c8];
    
    weakSelf(self);
    // 导航栏按钮设置
    [self setupNavigationBarIsBlack:NO];
    
    //初始化播放窗口
    UIView * player1 = self.persenter.livePlugin;
    [self.view addSubview:player1];
    [player1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakself.view);
        make.leading.mas_equalTo(weakself.view);
        make.width.mas_equalTo(weakself.view.mas_width);
        make.height.mas_equalTo(211);
    }];
    
    if ([[LCNewDeviceVideoManager shareInstance] isMulti]) {
        [self.persenter.defaultImageView addSubview:self.persenter.cameraNameLabel];
        [self.persenter.subDefaultImageView addSubview:self.persenter.subCameraNameLabel];
        
        [self.persenter.cameraNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(15);
            make.top.mas_equalTo(8);
            make.width.mas_equalTo(68);
            make.height.mas_equalTo(26);
        }];
        
        [self.persenter.subCameraNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(15);
            make.top.mas_equalTo(8);
            make.width.mas_equalTo(68);
            make.height.mas_equalTo(26);
        }];
        
//        if ([[LCNewDeviceVideoManager shareInstance].displayChannelID isEqualToString:[LCNewDeviceVideoManager shareInstance].subChannelInfo.channelId]) {
//            self.persenter.subCameraNameLabel.hidden = NO;
//            self.persenter.cameraNameLabel.hidden = YES;
//            [self changeDisplayWindow:[LCNewDeviceVideoManager shareInstance].displayChannelID];
//        } else {
//            self.persenter.subCameraNameLabel.hidden = YES;
//            self.persenter.cameraNameLabel.hidden = NO;
//        }
        
    }
    
    //创建中间控制栏
    self.middleControlView = [LCNewVideoControlView new];
    self.middleControlView.items = [self.persenter getMiddleControlItems:[[LCNewDeviceVideoManager shareInstance] isMulti]];
    [self.view addSubview:self.middleControlView];
    [self.middleControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.persenter.livePlugin.mas_bottom);
        make.trailing.leading.mas_equalTo(weakself.view);
    }];
    
    //创建底部控制栏
    self.bottomControlView = [LCNewVideoControlView new];
    self.bottomControlView.style = LCNewVideoControlLightStyle;
    self.bottomControlView.items = [self.persenter getBottomControlItems];
    [self.view addSubview:self.bottomControlView];
    [self.bottomControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakself.middleControlView.mas_bottom);
        make.width.mas_equalTo(weakself.view.mas_width);
        make.leading.mas_equalTo(weakself.view);
    }];
    
    //上下屏底部控制栏
    self.upDownControlView = [LCNewVideoControlView new];
    self.upDownControlView.style = LCNewVideoControlLightStyle;
    self.upDownControlView.items = [self.persenter getUpDownControlItems];
    self.upDownControlView.hidden = YES;
    self.upDownControlView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.upDownControlView];
    [self.upDownControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.bottom.mas_equalTo(weakself.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.mas_equalTo(weakself.view.mas_bottom);
        }
        make.leading.trailing.mas_equalTo(weakself.view);
        make.height.mas_equalTo(80);
    }];
    
    ///创建云台
    self.ptzControlView = [[LCNewPTZControlView alloc] initWithDirection:[LCNewDeviceVideoManager shareInstance].currentDevice.ability.isSupportPTZ?LCNewPTZControlSupportEight:([LCNewDeviceVideoManager shareInstance].currentDevice.ability.isSupportPT?LCNewPTZControlSupportEight:LCNewPTZControlSupportFour)];
    self.ptzControlView.backgroundColor = [UIColor lccolor_c43];
    self.ptzControlView.alpha = 0;
    [self.view addSubview:self.ptzControlView];
    [self.ptzControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.bottomControlView.mas_bottom);
        make.leading.mas_equalTo(weakself.view.mas_leading);
        make.width.mas_equalTo(weakself.view.mas_width);
        make.bottom.mas_equalTo(weakself.view.mas_bottom);
    }];
    //竖屏云台操作回调
    self.ptzControlView.panel.resultBlock = ^(VPDirection direction, double scale, NSTimeInterval timeInterval) {
        if (direction == VPDirectionUnknown) {
            [weakself.persenter hideBorderView];
            [LCNewDeviceVideoManager shareInstance].directionTouch = NO;
        } else {
            [LCNewDeviceVideoManager shareInstance].directionTouch = YES;
        }
        [weakself.persenter ptzControlWith:[NSString stringWithFormat:@"%ld",direction] duration:timeInterval];
    };
    
    self.landscapeControlView = [LCNewLandscapeControlView new];
    self.landscapeControlView.delegate = self.persenter;
    [self.view addSubview:self.landscapeControlView];
    [self.landscapeControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.mas_equalTo(weakself.view);
    }];
    self.landscapeControlView.hidden = YES;
    self.landscapeControlView.presenter = self.persenter;
    
    [self.persenter configBigPlay];
    
    //横屏云台
    self.landscapePtzControlView = [[LCNewPTZPanel alloc] initWithFrame:CGRectMake(0, 0, 100, 100) style:[LCNewDeviceVideoManager shareInstance].currentDevice.ability.isSupportPTZ?LCNewPTZPanelStyle8Direction:([LCNewDeviceVideoManager shareInstance].currentDevice.ability.isSupportPT?LCNewPTZPanelStyle8Direction:LCNewPTZPanelStyle4Direction)];
    [self.landscapePtzControlView  configLandscapeUI];
    self.landscapePtzControlView.alpha = 0;
    [self.landscapeControlView addSubview:self.landscapePtzControlView];
    [self.landscapePtzControlView  mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.width.mas_equalTo(150);
        make.leading.mas_equalTo(self.landscapeControlView.mas_leading).offset(35);
        make.centerY.mas_equalTo(self.landscapeControlView.mas_centerY);
    }];
    
    //横屏云台操作回调
    self.landscapePtzControlView.resultBlock = ^(VPDirection direction, double scale, NSTimeInterval timeInterval) {
        if (direction == VPDirectionUnknown) {
            [weakself.persenter hideBorderView];
            [LCNewDeviceVideoManager shareInstance].directionTouch = NO;
        } else {
            [LCNewDeviceVideoManager shareInstance].directionTouch = YES;
        }
        [weakself.persenter ptzControlWith:[NSString stringWithFormat:@"%ld",direction] duration:timeInterval];
    };
    
    //加载Loading
    [self.persenter showVideoLoadImage];
    [self.persenter loadStatusView];
}

- (void)setupNavigationBarIsBlack:(BOOL)black {
    weakSelf(self);
    LCNAVIGATION_STYLE style = LCNAVIGATION_STYLE_LIVE;
    if (black) {
        style = LCNAVIGATION_STYLE_LIVE_BLACK;
    }
    [self lcCreatNavigationBarWith:style buttonClickBlock:^(NSInteger index) {
        if (index == 0) {
            [weakself.persenter stopPlay:NO];
            [weakself.persenter uninitPlayWindow];
            [weakself.navigationController popViewControllerAnimated:YES];
        } else {
            LCDeviceDetailPresenter *presenter = [[LCDeviceDetailPresenter alloc] initWithDeviceInfo:[LCNewDeviceVideoManager shareInstance].currentDevice selectedChannelId:[LCNewDeviceVideoManager shareInstance].mainChannelInfo.channelId];
            LCDeviceDetailVC *deviceDetail = [[LCDeviceDetailVC alloc] init];
            deviceDetail.title = @"setting_device_device_info_title".lcMedia_T;
            deviceDetail.presenter = presenter;
            presenter.viewController = deviceDetail;
            [weakself.navigationController pushViewController:deviceDetail animated:YES];
            self.isFirstIntoVC = YES;
        }
    }];
}

- (void)showPtz {
    // 仅展示当前朝向对应的云台：竖屏展示竖屏云台，横屏展示横屏云台，避免多余云台按钮
    BOOL isLandscape = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    // 竖屏云台需置顶，避免被后添加的每日快看/录像列表图层遮挡
    if (!isLandscape) {
        [self.view bringSubviewToFront:self.ptzControlView];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.landscapePtzControlView.alpha = isLandscape ? 1.0 : 0;
        self.ptzControlView.alpha = isLandscape ? 0 : 1.0;
    }];
}

- (void)hidePtz {
    //竖屏云台
    [UIView animateWithDuration:0.2 animations:^{
        self.landscapePtzControlView.alpha = 0;
        self.ptzControlView.alpha = 0;
    }];
}

- (BOOL)shouldAutorotate {
//    if ([LCNewDeviceVideoManager shareInstance].isFullScreen) {
//        return NO;
//    }
//    if (![LCNewDeviceVideoManager shareInstance].isFullScreen &&
//        ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft ||
//         [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)) {
//        //竖转横
//        [LCNewDeviceVideoManager shareInstance].isFullScreen = ![LCNewDeviceVideoManager shareInstance].isFullScreen;
//    }
//    if ([LCNewDeviceVideoManager shareInstance].isFullScreen && [[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationPortrait) {
//        //横转竖
//        [LCNewDeviceVideoManager shareInstance].isFullScreen = ![LCNewDeviceVideoManager shareInstance].isFullScreen;
//    }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)configFullScreenUI {
    [self setupNavigationBarIsBlack:NO];
    self.persenter.displayStyle = LCPlayWindowDisplayStyleFullScreen;
    self.videoHistoryView.hidden = YES;
    self.bottomControlView.hidden = YES;
    self.middleControlView.hidden = YES;
    self.landscapeControlView.hidden = NO;
    self.view.backgroundColor = [UIColor lccolor_c8];
    [self.navigationController.navigationBar setBarBackgroundColorWithColor:[UIColor whiteColor] titleColor:[UIColor blackColor]];
    [self lc_refreshNavigationTitleView];
    self.upDownControlView.hidden = YES;
    weakSelf(self);
    LCOpenMediaLivePlugin * player =  self.persenter.livePlugin;
    [player mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.mas_equalTo(weakself.view);
        make.height.mas_equalTo(SCREEN_HEIGHT > SCREEN_WIDTH ? SCREEN_WIDTH : SCREEN_HEIGHT);
        make.width.mas_equalTo(SCREEN_HEIGHT > SCREEN_WIDTH ? SCREEN_HEIGHT : SCREEN_WIDTH);
    }];
    
    player.screenMode = LCScreenModeSingleScreen;

//    if ([[LCNewDeviceVideoManager shareInstance] isMulti]) {
//        if ([[LCNewDeviceVideoManager shareInstance].displayChannelID isEqualToString:[LCNewDeviceVideoManager shareInstance].subChannelInfo.channelId]) {
//            self.persenter.subCameraNameLabel.hidden = NO;
//            self.persenter.cameraNameLabel.hidden = YES;
//        } else {
//            self.persenter.subCameraNameLabel.hidden = YES;
//            self.persenter.cameraNameLabel.hidden = NO;
//        }
//    }
    
    [self.persenter.loadImageview mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.bottom.mas_equalTo(self.view);
    }];
    
    [self.persenter.errorBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(60);
    }];

    [self.persenter.bigPlayBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(60);
    }];
    
}

- (void)configPortraitScreenUI {
    [self setupNavigationBarIsBlack:NO];
    self.persenter.displayStyle = LCPlayWindowDisplayStylePictureInScreen;
    // 云台开启时保持录像列表隐藏，避免竖屏云台被压在每日快看/录像列表图层之下
    self.videoHistoryView.hidden = [LCNewDeviceVideoManager shareInstance].isOpenCloudStage;
    self.bottomControlView.hidden = NO;
    self.middleControlView.hidden = NO;
    self.landscapeControlView.hidden = YES;
    self.view.backgroundColor = [UIColor lccolor_c8];
    [self.navigationController.navigationBar setBarBackgroundColorWithColor:[UIColor whiteColor] titleColor:[UIColor blackColor]];
    [self lc_refreshNavigationTitleView];
    self.upDownControlView.hidden = YES;
    
    LCOpenMediaLivePlugin * player =  self.persenter.livePlugin;
    [player mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view);
        make.leading.mas_equalTo(self.view);
        make.width.mas_equalTo(self.view);
        make.height.mas_equalTo(211);
    }];

    if ([[LCNewDeviceVideoManager shareInstance] isMulti]) {
        player.screenMode = LCScreenModeSingleScreen; //双目设置画中画模式
//        if ([[LCNewDeviceVideoManager shareInstance].displayChannelID isEqualToString:[LCNewDeviceVideoManager shareInstance].subChannelInfo.channelId]) {
//            self.persenter.subCameraNameLabel.hidden = NO;
//            self.persenter.cameraNameLabel.hidden = YES;
//        } else {
//            self.persenter.subCameraNameLabel.hidden = YES;
//            self.persenter.cameraNameLabel.hidden = NO;
//        }
    }
    
    [self.persenter.loadImageview mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.mas_equalTo(self.view);
        make.width.mas_equalTo(self.view);
        make.height.mas_equalTo(211);
    }];
    
    [self.persenter.errorBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(70);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(60);
    }];

    [self.persenter.bigPlayBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(70);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(60);
    }];
}

- (void)configUpDownScreenUI {
    [self setupNavigationBarIsBlack:YES];
    self.persenter.displayStyle = LCPlayWindowDisplayStyleUpDownScreen;
    if ([LCNewDeviceVideoManager shareInstance].isOpenCloudStage) {
        [self.persenter onPtz:nil];
    }
    self.persenter.subCameraNameLabel.hidden = NO;
    self.persenter.cameraNameLabel.hidden = NO;
    self.bottomControlView.hidden = YES;
    self.middleControlView.hidden = YES;
    self.upDownControlView.hidden = NO;
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController.navigationBar setBarBackgroundColorWithColor:[UIColor blackColor] titleColor:[UIColor whiteColor]];
    [self lc_refreshNavigationTitleView];
    self.landscapeControlView.hidden = YES;
    self.videoHistoryView.hidden = YES;
    self.view.backgroundColor = [UIColor blackColor];
    
    LCOpenMediaLivePlugin * player =  self.persenter.livePlugin;
    if ([[LCNewDeviceVideoManager shareInstance] isMulti]) {
        [player mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.view).offset(63);
            make.leading.mas_equalTo(self.view);
            make.width.mas_equalTo(self.view);
            make.height.mas_equalTo(211 + 211);
        }];
        player.screenMode = LCScreenModeDoubleScreen;
    } else {
        [player mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.view).offset(63);
            make.leading.mas_equalTo(self.view);
            make.width.mas_equalTo(self.view);
            make.height.mas_equalTo(211);
        }];
        player.screenMode = LCScreenModeSingleScreen;
    }
    
    [self.persenter.loadImageview mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.mas_equalTo(self.view);
        make.centerY.mas_equalTo(self.view).offset(-110);
    }];
    
    [self.persenter.errorBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.centerY.mas_equalTo(self.view).offset(-110);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(60);
    }];

    [self.persenter.bigPlayBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.centerY.mas_equalTo(self.view).offset(-110);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(60);
    }];
}

/// 切换大屏展示window
- (void)changeDisplayWindow:(NSString *)displayWindowId {
    if ([[LCNewDeviceVideoManager shareInstance] isMulti] == NO) {
        return;
    }
    if (self.persenter.displayStyle == LCPlayWindowDisplayStyleFullScreen) {
        [self configFullScreenUI];
    } else if (self.persenter.displayStyle == LCPlayWindowDisplayStylePictureInScreen) {
        [self configPortraitScreenUI];
    }
}


- (void)onResignActive:(id)sender {
    [self.persenter onResignActive:sender];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self lc_refreshNavigationTitleView];
}

/// 国标等长序列号作标题时限宽并中间截断，避免导航栏显示异常
- (void)lc_setupNavigationTitle:(NSString *)title {
    self.lc_navTitleText = title ?: @"";
    self.title = self.lc_navTitleText;
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = kLCNavTitleMinScale;
    self.navigationItem.titleView = titleLabel;
    [self lc_refreshNavigationTitleView];
}

/// 同步标题颜色（随黑/白导航栏）与可用宽度（随布局/旋转）
- (void)lc_refreshNavigationTitleView {
    UILabel *titleLabel = (UILabel *)self.navigationItem.titleView;
    if (![titleLabel isKindOfClass:[UILabel class]]) {
        return;
    }
    titleLabel.text = self.lc_navTitleText;
    BOOL darkBar = (self.persenter.displayStyle == LCPlayWindowDisplayStyleUpDownScreen);
    titleLabel.textColor = darkBar ? [UIColor whiteColor] : [UIColor blackColor];
    CGFloat containerWidth = CGRectGetWidth(self.view.bounds);
    if (containerWidth <= 0) {
        containerWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    }
    CGFloat maxWidth = MAX(containerWidth - kLCNavTitleHorizontalInset, 80.0);
    titleLabel.bounds = CGRectMake(0, 0, maxWidth, kLCNavTitleHeight);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [self.persenter uninitPlayWindow];
}


@end
