#import "LCAIFrameSelectEventListViewController.h"
#import "LCAIFrameSelectEventPersenter.h"
#import "LCAIFrameSelectListCell.h"
#import "LCAIFrameSelectPlaybackViewController.h"
#import "LCAICloudQuickLookCalendarViewController.h"
#import "LCAICloudDayItem.h"
#import "LCAICloudAppBundleImage.h"
#import <LCBaseModule/UIViewController+LCNavigationBar.h>
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <LCMediaBaseModule/LCNewDeviceVideoManager.h>
#import <LCNetworkModule/LCDeviceInfo.h>
#import <LCNetworkModule/LCCloudVideotapeInfo.h>
#import <LCBaseModule/UIColor+HexString.h>
#import <LCMediaBaseModule/LCMediaRefreshHeader.h>
#import <LCMediaBaseModule/LCMediaRefreshFooter.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import <Masonry/Masonry.h>

static const CGFloat kFSCardH = 194.0;
static const CGFloat kFSRowGap = 12.0;
static const CGFloat kFSChTabH = 52.0;
/// 列表与导航栏区域（及双目 Tab）之间的间距
static const CGFloat kFSListTopMargin = 20.0;

@interface LCAIFrameSelectEventListViewController () <UITableViewDataSource, UITableViewDelegate, LCAIFrameSelectEventPresenterHost>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) LCAIFrameSelectEventPersenter *persenter;
@property (nonatomic, strong) UIScrollView *channelScroll;
@property (nonatomic, strong) UIStackView *channelStack;
@property (nonatomic, assign) BOOL showChannels;
@end

static const NSInteger kFSTabInd = 90002;

@implementation LCAIFrameSelectEventListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lc_colorWithHexString:@"#F6F6F6"];
    self.persenter.eventListPage = self;
    [self.persenter configureQuickLookInitialDataFromMainChannel];
    self.showChannels = ([LCNewDeviceVideoManager shareInstance].currentDevice.channels.count > 1);
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    self.title = dev.name.length ? dev.name : @"ai_insight_frame_select_title".lcMedia_T;
    [self.persenter buildLast30DaysPlain];
    [self buildUI];
    [self.persenter fetchCondensedRecordBitmap];
}

- (void)buildUI {
    [self.view addSubview:self.channelScroll];
    [self.channelScroll addSubview:self.channelStack];
    [self.view addSubview:self.tableView];
    [self buildChannelTabButtons];
    [self.channelScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(self.showChannels ? kFSChTabH : 0.0);
    }];
    [self.channelStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.channelScroll).insets(UIEdgeInsetsMake(10, 12, 10, 12));
        make.height.mas_equalTo(32);
    }];
    self.channelScroll.hidden = !self.showChannels;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (self.showChannels) {
            make.top.equalTo(self.channelScroll.mas_bottom).offset(kFSListTopMargin);
        } else {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(kFSListTopMargin);
        }
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)buildChannelTabButtons {
    for (UIView *v in [self.channelStack.arrangedSubviews copy]) {
        [self.channelStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    for (LCChannelInfo *ch in dev.channels) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b setTitle:(ch.channelName.length ? ch.channelName : ch.channelId) forState:UIControlStateNormal];
        b.tag = ch.channelId.integerValue;
        b.contentEdgeInsets = UIEdgeInsetsMake(6, 4, 6, 4);
        [b addTarget:self action:@selector(tapCh:) forControlEvents:UIControlEventTouchUpInside];
        [self styleChBtn:b selected:[ch.channelId isEqualToString:self.persenter.selectedChannelId]];
        [self.channelStack addArrangedSubview:b];
    }
}

- (void)styleChBtn:(UIButton *)btn selected:(BOOL)sel {
    UIColor *b = [UIColor lc_colorWithHexString:@"#000000"];
    UIColor *g = [UIColor lc_colorWithHexString:@"#8F8F8F"];
    btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:sel ? UIFontWeightBold : UIFontWeightRegular];
    [btn setTitleColor:sel ? b : g forState:UIControlStateNormal];
    UIView *ind = [btn viewWithTag:kFSTabInd];
    if (!ind) {
        ind = [[UIView alloc] init];
        ind.tag = kFSTabInd;
        ind.backgroundColor = [UIColor lc_colorWithHexString:@"#4F78FF"];
        ind.layer.cornerRadius = 6;
        [btn addSubview:ind];
    }
    ind.hidden = !sel;
    [ind mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(4);
        make.bottom.equalTo(btn);
        make.leading.equalTo(btn);
    }];
}

- (void)tapCh:(UIButton *)sender {
    NSString *cid = [NSString stringWithFormat:@"%ld", (long)sender.tag];
    if ([cid isEqualToString:self.persenter.selectedChannelId]) {
        return;
    }
    self.persenter.selectedChannelId = cid;
    self.persenter.quickLookBitmapChannelId = [cid copy];
    for (UIView *v in self.channelStack.arrangedSubviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)v;
            [self styleChBtn:b selected:[[NSString stringWithFormat:@"%ld", (long)b.tag] isEqualToString:cid]];
        }
    }
    self.persenter.quickLookHasLoaded = NO;
    [self.persenter fetchCondensedRecordBitmap];
}

#pragma mark - Host (condensed 列表与 bitmap)

- (void)lc_eventPersenterHostSetQuickLookLoadingVisible:(__unused BOOL)show {
    // 每日帧选：列表加载走 mj_header，不在页面中间展示 loading
}

- (void)lc_eventPersenterHostApplyQuickLookAfterModelsChangedPlayRecord:(__unused LCCloudVideotapeInfo *)record {
    [self.tableView reloadData];
    [self updateTableBackground];
}

#pragma mark - LCAIFrameSelectEventPresenterHost（MJRefresh，对齐 LCNewVideotapeListViewController）

- (void)lc_frameSelectTriggerHeaderRefreshForListLoad {
    if (!self.tableView.mj_header || self.tableView.mj_header.isRefreshing) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.tableView.mj_header && !self.tableView.mj_header.isRefreshing) {
            [self.tableView.mj_header beginRefreshing];
        }
    });
}

- (void)lc_frameSelectEndHeaderRefresh {
    [self.tableView.mj_header endRefreshing];
    [self.tableView.mj_footer resetNoMoreData];
    // 勿对 mj_footer 长期 hidden：BackFooter 依赖可见布局才能响应上拉；无更多时再隐藏即可
    self.tableView.mj_footer.hidden = NO;
}

- (void)lc_frameSelectEndFooterRefreshWithNoMoreData:(BOOL)noMore {
    if (noMore) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
        self.tableView.mj_footer.hidden = YES;
    } else {
        [self.tableView.mj_footer endRefreshing];
        self.tableView.mj_footer.hidden = NO;
    }
}

- (void)updateTableBackground {
    if (self.persenter.quickLookSummaryEmptyBoard && !self.persenter.quickLookLoadFailed) {
        UIView *wrap = [[UIView alloc] init];
        wrap.backgroundColor = [UIColor whiteColor];
        wrap.layer.cornerRadius = 8;
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
        lab.text = @"ai_insight_no_record_frame_select".lcMedia_T;
        lab.textColor = [UIColor lc_colorWithHexString:@"#8F8F8F"];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.font = [UIFont systemFontOfSize:14];
        lab.numberOfLines = 0;
        [stack addArrangedSubview:iv];
        [stack addArrangedSubview:lab];
        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(wrap);
            make.left.greaterThanOrEqualTo(wrap).offset(24);
            make.right.lessThanOrEqualTo(wrap).offset(-24);
        }];
        self.tableView.backgroundView = wrap;
    } else {
        self.tableView.backgroundView = nil;
    }
}

- (LCAIFrameSelectEventPersenter *)persenter {
    if (!_persenter) {
        _persenter = [[LCAIFrameSelectEventPersenter alloc] init];
    }
    return _persenter;
}

- (UIScrollView *)channelScroll {
    if (!_channelScroll) {
        _channelScroll = [[UIScrollView alloc] init];
        _channelScroll.showsHorizontalScrollIndicator = NO;
    }
    return _channelScroll;
}

- (UIStackView *)channelStack {
    if (!_channelStack) {
        _channelStack = [[UIStackView alloc] init];
        _channelStack.axis = UILayoutConstraintAxisHorizontal;
        _channelStack.spacing = 20;
    }
    return _channelStack;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.rowHeight = kFSCardH + kFSRowGap;
        _tableView.estimatedRowHeight = 206;
        [_tableView registerClass:[LCAIFrameSelectListCell class] forCellReuseIdentifier:[LCAIFrameSelectListCell reuseId]];
        __weak typeof(self) w = self;
        _tableView.mj_header = [LCMediaRefreshHeader headerWithRefreshingBlock:^{
            [w.persenter fs_pullRefreshFirstPage];
        }];
        _tableView.mj_footer = [LCMediaRefreshFooter footerWithRefreshingBlock:^{
            [w.persenter fs_loadMoreNextPage];
        }];
    }
    return _tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) w = self;
    [self lcCreatNavigationBarWith:LCNAVIGATION_STYLE_DEFAULT
                  buttonClickBlock:^(NSInteger index) {
                      if (index == 0) {
                          [w.navigationController popViewControllerAnimated:YES];
                      }
                  }];
    UIImage *calImg = LCAICloudAppBundleImage(@"common_nav_calendar");
    if (calImg) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[calImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(tapCal)];
    } else if (@available(iOS 13.0, *)) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"calendar"] style:UIBarButtonItemStylePlain target:self action:@selector(tapCal)];
    }
}

- (void)tapCal {
    NSMutableArray<NSDictionary *> *list = [NSMutableArray array];
    for (LCAICloudDayItem *it in self.persenter.dayItems) {
        [list addObject:@{@"date" : it.dateString ?: @"", @"hasVideo" : @(it.hasVideo)}];
    }
    LCAICloudQuickLookCalendarViewController *cal = [[LCAICloudQuickLookCalendarViewController alloc] initWithDayInfoList:list
                                                                                                            selectedDate:self.persenter.selectedDateStr];
    __weak typeof(self) w = self;
    cal.onPickDate = ^(NSString *yyyyMMdd) {
        [w dismissViewControllerAnimated:NO completion:nil];
        w.persenter.selectedDateStr = yyyyMMdd;
        w.persenter.quickLookHasLoaded = NO;
        [w lc_frameSelectTriggerHeaderRefreshForListLoad];
    };
    cal.onCancel = ^{ [w dismissViewControllerAnimated:NO completion:nil]; };
    cal.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:cal animated:NO completion:nil];
}

#pragma mark - Table

- (NSArray<NSNumber *> *)contentDisplayIndices {
    NSMutableArray<NSNumber *> *a = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)self.persenter.displaySummaryRows.count; i++) {
        if (![self.persenter.displaySummaryRows[(NSUInteger)i][@"empty"] boolValue]) {
            [a addObject:@(i)];
        }
    }
    return a;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    if (self.persenter.quickLookLoadFailed) {
        return 1;
    }
    if (self.persenter.quickLookSummaryEmptyBoard) {
        return 0;
    }
    return (NSInteger)[self contentDisplayIndices].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (self.persenter.quickLookLoadFailed) {
        UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"fs_err"];
        if (!c) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fs_err"];
            c.textLabel.textAlignment = NSTextAlignmentCenter;
            c.textLabel.textColor = [UIColor lc_colorWithHexString:@"#666666"];
        }
        c.textLabel.text = @"ai_insight_network_error_tap_retry".lcMedia_T;
        c.selectionStyle = UITableViewCellSelectionStyleDefault;
        return c;
    }
    LCAIFrameSelectListCell *cell = [tableView dequeueReusableCellWithIdentifier:[LCAIFrameSelectListCell reuseId] forIndexPath:ip];
    NSArray<NSNumber *> *idxs = [self contentDisplayIndices];
    if (ip.row >= (NSInteger)idxs.count) {
        return cell;
    }
    NSInteger dIdx = [idxs[(NSUInteger)ip.row] integerValue];
    NSDictionary *row = self.persenter.displaySummaryRows[(NSUInteger)dIdx];
    id rowRecObj = row[@"frameSelectRecord"];
    LCCloudVideotapeInfo *rec = [rowRecObj isKindOfClass:[LCCloudVideotapeInfo class]] ? (LCCloudVideotapeInfo *)rowRecObj : [self.persenter currentChannelRecord];
    NSArray<NSString *> *tags = [self.persenter summaryTagStringsForDisplayRow:row];
    [cell applyWithRecord:rec tagTypeStrings:tags];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip {
    if (self.persenter.quickLookLoadFailed) {
        [self.persenter clearListLoadFailureAndRefetch];
        return;
    }
    NSArray<NSNumber *> *idxs = [self contentDisplayIndices];
    if (ip.row >= (NSInteger)idxs.count) {
        return;
    }
    NSInteger dIdx = [idxs[(NSUInteger)ip.row] integerValue];
    NSDictionary *row = self.persenter.displaySummaryRows[(NSUInteger)dIdx];
    id rowRecObj = row[@"frameSelectRecord"];
    LCCloudVideotapeInfo *rec = [rowRecObj isKindOfClass:[LCCloudVideotapeInfo class]] ? (LCCloudVideotapeInfo *)rowRecObj : [self.persenter currentChannelRecord];
    if (!rec) {
        return;
    }
    BOOL isFlatAiInsight = [row[@"frameSelectRecord"] isKindOfClass:[LCCloudVideotapeInfo class]];
    double off = 0;
    if (!isFlatAiInsight) {
        off = [self.persenter offsetSecondsForSummaryDisplayIndex:dIdx];
        double itemDur = [self.persenter doubleValueFromId:row[@"segment"][@"duration"]];
        if (itemDur > 3) {
            off += 3;
        }
    }
    LCAIFrameSelectPlaybackViewController *p = [LCAIFrameSelectPlaybackViewController new];
    p.cloudRecord = rec;
    p.playbackChannelId = self.persenter.selectedChannelId;
    p.initialOffsetSeconds = off;
    p.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:p animated:YES];
}

@end
