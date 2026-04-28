//
//  LCAICloudStorageBannerView.m
//  LCNewLivePreviewModule
//
//  蓝湖：云录像栏下方并排两个入口 — 左「AI每日快看」+ 右「每日帧选」


#import "LCAICloudStorageBannerView.h"
#import <Masonry/Masonry.h>
#import <LCMediaBaseModule/UIColor+MediaBaseModule.h>
#import <LCBaseModule/UIFont+Imou.h>
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>

/// 左右边距
static const CGFloat kCardRowHorizontalInset = 12.0;
static const CGFloat kCardRowVerticalInset = 8.0;
/// 双卡间距
static const CGFloat kCardSpacing = 8.0;
static const CGFloat kCardCornerRadius = 8.0;

static const CGFloat kBannerLeftWidthPxDesign = 343.0;
static const CGFloat kBannerLeftHeightPxDesign = 120.0;
static const CGFloat kBannerRightWidthPxDesign = 353.0;

static NSString * const kColorQuickLookBg = @"#E8F3FF";
static NSString * const kColorFrameSelectBg = @"#FFF6E5";
static NSString * const kColorTitle = @"#333333";

@interface LCAICloudStorageBannerView ()
@property (nonatomic, strong) UIView *leftBannerContainer;
@property (nonatomic, strong) UIView *rightBannerContainer;
@property (nonatomic, strong) UIImageView *leftBannerImageView;
@property (nonatomic, strong) UIImageView *rightBannerImageView;
@property (nonatomic, strong) UIButton *leftTapButton;
@property (nonatomic, strong) UIButton *rightTapButton;

@property (nonatomic, strong) UILabel *quickLookTitleLabel;
@property (nonatomic, strong) UILabel *frameSelectTitleLabel;
@end

@implementation LCAICloudStorageBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self buildDualBannerEntries];
    }
    return self;
}

/// 左、右各一张切图 + 文案（切图无字或未加载时仍符合 UI）
- (void)buildDualBannerEntries {
    self.leftBannerContainer = [[UIView alloc] init];
    self.rightBannerContainer = [[UIView alloc] init];
    self.leftBannerContainer.backgroundColor = [UIColor lc_colorWithHexString:kColorQuickLookBg];
    self.rightBannerContainer.backgroundColor = [UIColor lc_colorWithHexString:kColorFrameSelectBg];
    self.leftBannerContainer.layer.cornerRadius = kCardCornerRadius;
    self.rightBannerContainer.layer.cornerRadius = kCardCornerRadius;
    self.leftBannerContainer.layer.masksToBounds = YES;
    self.rightBannerContainer.layer.masksToBounds = YES;

    self.leftBannerImageView = [[UIImageView alloc] init];
    self.rightBannerImageView = [[UIImageView alloc] init];
    self.leftBannerImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.rightBannerImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.leftBannerImageView.clipsToBounds = YES;
    self.rightBannerImageView.clipsToBounds = YES;
    self.leftBannerImageView.image = LC_IMAGENAMED(@"event_summary_banner_l");
    self.rightBannerImageView.image = LC_IMAGENAMED(@"playback_daily_event_banner_l");

    [self.leftBannerContainer addSubview:self.leftBannerImageView];
    [self.leftBannerContainer addSubview:self.quickLookTitleLabel];
    [self.rightBannerContainer addSubview:self.rightBannerImageView];
    [self.rightBannerContainer addSubview:self.frameSelectTitleLabel];

    self.leftTapButton = [self tapButtonWithAction:@selector(tapSilhouette:) accessibilityLabel:@"ai_insight_quick_look_title".lcMedia_T];
    self.rightTapButton = [self tapButtonWithAction:@selector(tapDaily:) accessibilityLabel:@"ai_insight_frame_select_title".lcMedia_T];
    [self.leftBannerContainer addSubview:self.leftTapButton];
    [self.rightBannerContainer addSubview:self.rightTapButton];

    [self addSubview:self.leftBannerContainer];
    [self addSubview:self.rightBannerContainer];

    [self applyTitleLabelShadow:self.quickLookTitleLabel];
    [self applyTitleLabelShadow:self.frameSelectTitleLabel];

    CGFloat leftWidthFrac = kBannerLeftWidthPxDesign / (kBannerLeftWidthPxDesign + kBannerRightWidthPxDesign);
    CGFloat horizontalOccupied = kCardRowHorizontalInset * 2.0 + kCardSpacing;
    CGFloat heightOverWidth = kBannerLeftHeightPxDesign / kBannerLeftWidthPxDesign;

    [self.leftBannerContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(kCardRowVerticalInset);
        make.leading.equalTo(self).offset(kCardRowHorizontalInset);
        make.width.equalTo(self.mas_width).multipliedBy(leftWidthFrac).offset(-horizontalOccupied * leftWidthFrac);
        make.height.equalTo(self.leftBannerContainer.mas_width).multipliedBy(heightOverWidth);
    }];
    [self.rightBannerContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.leftBannerContainer.mas_trailing).offset(kCardSpacing);
        make.trailing.equalTo(self).offset(-kCardRowHorizontalInset);
        make.top.equalTo(self.leftBannerContainer);
        make.height.equalTo(self.leftBannerContainer);
    }];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.leftBannerContainer.mas_bottom).offset(kCardRowVerticalInset);
    }];

    [self.leftBannerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.leftBannerContainer);
    }];
    [self.rightBannerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.rightBannerContainer);
    }];

    [self.quickLookTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.leftBannerContainer).offset(10);
        make.centerY.equalTo(self.leftBannerContainer);
        make.trailing.lessThanOrEqualTo(self.leftBannerContainer).offset(-10);
    }];

    [self.frameSelectTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.rightBannerContainer).offset(10);
        make.centerY.equalTo(self.rightBannerContainer);
        make.trailing.lessThanOrEqualTo(self.rightBannerContainer).offset(-10);
    }];

    [self.leftTapButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.leftBannerContainer);
    }];
    [self.rightTapButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.rightBannerContainer);
    }];
}

- (void)applyTitleLabelShadow:(UILabel *)label {
    label.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowRadius = 2.0;
    label.layer.shadowOpacity = 0.85;
}

- (UIButton *)tapButtonWithAction:(SEL)action accessibilityLabel:(NSString *)accessibilityLabel {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor clearColor];
    btn.accessibilityLabel = accessibilityLabel;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UILabel *)quickLookTitleLabel {
    if (!_quickLookTitleLabel) {
        _quickLookTitleLabel = [[UILabel alloc] init];
        _quickLookTitleLabel.text = @"ai_insight_quick_look_title".lcMedia_T;
        _quickLookTitleLabel.textColor = [UIColor lc_colorWithHexString:kColorTitle];
        _quickLookTitleLabel.font = [UIFont lcFont_t5];
        _quickLookTitleLabel.numberOfLines = 1;
    }
    return _quickLookTitleLabel;
}

- (UILabel *)frameSelectTitleLabel {
    if (!_frameSelectTitleLabel) {
        _frameSelectTitleLabel = [[UILabel alloc] init];
        _frameSelectTitleLabel.text = @"ai_insight_frame_select_title".lcMedia_T;
        _frameSelectTitleLabel.textColor = [UIColor lc_colorWithHexString:kColorTitle];
        _frameSelectTitleLabel.font = [UIFont lcFont_t5];
        _frameSelectTitleLabel.numberOfLines = 1;
    }
    return _frameSelectTitleLabel;
}

- (void)tapSilhouette:(id)sender {
    if (self.entryTapHandler) {
        self.entryTapHandler(LCAICloudStorageBannerEntrySilhouetteAlbum);
    }
}

- (void)tapDaily:(id)sender {
    if (self.entryTapHandler) {
        self.entryTapHandler(LCAICloudStorageBannerEntryDailyBrief);
    }
}

@end
