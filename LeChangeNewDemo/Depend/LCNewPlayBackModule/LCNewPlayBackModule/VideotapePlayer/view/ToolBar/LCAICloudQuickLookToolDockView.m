#import "LCAICloudQuickLookToolDockView.h"
#import <Masonry/Masonry.h>

static const CGFloat kDockHeight = 80.0;
static const CGFloat kToolbarBottomInset = 12.0;
static const CGFloat kToolbarIconRowHeight = 30.0;

@interface LCAICloudQuickLookToolDockView ()
@property (nonatomic, strong, readwrite) CAGradientLayer *gradientLayer;
@property (nonatomic, strong, readwrite) UIScrollView *toolScrollView;
@property (nonatomic, strong, readwrite) UIStackView *toolStack;
@property (nonatomic, strong, readwrite) UIView *fullscreenSlot;
@property (nonatomic, assign) BOOL landscapeCloudPlaybackChrome;
@end

@implementation LCAICloudQuickLookToolDockView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;

        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[ (id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:(CGFloat)0x90 / 255.0].CGColor ];
        _gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        _gradientLayer.endPoint = CGPointMake(0.5, 1.0);
        [self.layer insertSublayer:_gradientLayer atIndex:0];

        _toolScrollView = [[UIScrollView alloc] init];
        _toolScrollView.showsHorizontalScrollIndicator = NO;
        _toolScrollView.alwaysBounceHorizontal = YES;
        _toolScrollView.delaysContentTouches = NO;
        _toolScrollView.backgroundColor = [UIColor clearColor];
        [self addSubview:_toolScrollView];

        _fullscreenSlot = [[UIView alloc] init];
        _fullscreenSlot.backgroundColor = [UIColor clearColor];
        [self addSubview:_fullscreenSlot];

        [_fullscreenSlot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.bottom.top.equalTo(self);
            make.width.mas_equalTo(45);
        }];
        [_toolScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.top.bottom.equalTo(self);
            make.trailing.equalTo(_fullscreenSlot.mas_leading);
        }];

        _toolStack = [[UIStackView alloc] init];
        _toolStack.axis = UILayoutConstraintAxisHorizontal;
        _toolStack.alignment = UIStackViewAlignmentBottom;
        _toolStack.distribution = UIStackViewDistributionEqualSpacing;
        _toolStack.spacing = 10;
        _toolStack.translatesAutoresizingMaskIntoConstraints = NO;
        [_toolScrollView addSubview:_toolStack];

        CGFloat stackTopInset = kDockHeight - kToolbarBottomInset - kToolbarIconRowHeight;
        [_toolStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_toolScrollView).insets(UIEdgeInsetsMake(stackTopInset, 15, kToolbarBottomInset, 8));
        }];
    }
    return self;
}

- (void)layoutGradientIfNeeded {
    [self layoutIfNeeded];
    if (self.landscapeCloudPlaybackChrome) {
        CGFloat h = CGRectGetHeight(self.bounds);
        CGFloat w = CGRectGetWidth(self.bounds);
        CGFloat gh = MIN(90.0, h);
        self.gradientLayer.frame = CGRectMake(0, h - gh, w, gh);
    } else {
        self.gradientLayer.frame = self.bounds;
    }
}

- (void)applyLandscapeLayout:(BOOL)landscape {
    self.fullscreenSlot.hidden = landscape;
    // 横屏全屏按钮隐藏时，仍保留 trailing=45 会叠在 toolScrollView 上，导致工具栏右侧（倍速等）被挡或无法点击；快看横屏走 embeddedProcess 路径不明显，帧选等走 nil 路径必须让位宽为 0。
    [_fullscreenSlot mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.trailing.bottom.top.equalTo(self);
        make.width.mas_equalTo(landscape ? 0.0 : 45.0);
    }];
    [_toolScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self);
        if (landscape) {
            make.trailing.equalTo(self);
        } else {
            make.trailing.equalTo(self.fullscreenSlot.mas_leading);
        }
    }];
}

- (void)applyLandscapeCloudPlaybackChrome:(BOOL)on embeddedProcessView:(UIView *)processView {
    self.landscapeCloudPlaybackChrome = on;
    if (on) {
        self.gradientLayer.colors = @[ (__bridge id)[UIColor clearColor].CGColor, (__bridge id)[UIColor blackColor].CGColor ];
        self.gradientLayer.locations = @[ @0.0f, @1.0f ];
        self.gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        self.gradientLayer.endPoint = CGPointMake(0.5, 1.0);
        self.toolStack.spacing = 20.0;
        self.toolStack.alignment = UIStackViewAlignmentCenter;
        self.toolStack.distribution = UIStackViewDistributionFill;
        if (processView) {
            self.toolScrollView.hidden = YES;
            self.toolScrollView.scrollEnabled = NO;
            self.toolScrollView.alwaysBounceHorizontal = NO;
            [self.toolScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.top.trailing.equalTo(self);
                make.height.mas_equalTo(0.0);
            }];
            [self.toolStack removeFromSuperview];
            [self addSubview:self.toolStack];
            [processView removeFromSuperview];
            [self insertSubview:processView belowSubview:self.toolStack];
            [processView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self).offset(20.0);
                make.leading.trailing.equalTo(self);
                make.height.mas_equalTo(23.0);
            }];
            [self.toolStack mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(self).offset(15.0);
                make.trailing.equalTo(self).offset(-15.0);
                make.bottom.equalTo(self).offset(-15.0);
                make.height.mas_equalTo(30.0);
            }];
        } else {
            // 无进度条嵌入时：不要把 toolStack 只「底+高」挂在 ScrollView 上（缺与 content 的完整约束时，内容宽度/原点易算错，按钮会画出 dock）。与 embedded 分支一致：折叠 scroll，把 toolStack 直接钉在 dock 底部。
            self.toolScrollView.hidden = YES;
            self.toolScrollView.scrollEnabled = NO;
            self.toolScrollView.alwaysBounceHorizontal = NO;
            [self.toolScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.top.trailing.equalTo(self);
                make.height.mas_equalTo(0.0);
            }];
            [self.toolStack removeFromSuperview];
            [self addSubview:self.toolStack];
            [self.toolStack mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.leading.equalTo(self).offset(15.0);
                make.trailing.equalTo(self).offset(-15.0);
                make.bottom.equalTo(self).offset(-15.0);
                make.height.mas_equalTo(30.0);
            }];
        }
    } else {
        if (processView && processView.superview == self) {
            [processView removeFromSuperview];
        }
        [self.toolStack removeFromSuperview];
        [self.toolScrollView addSubview:self.toolStack];
        self.toolScrollView.hidden = NO;
        self.toolScrollView.scrollEnabled = YES;
        self.toolScrollView.alwaysBounceHorizontal = YES;
        self.gradientLayer.colors = @[ (id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:(CGFloat)0x90 / 255.0].CGColor ];
        self.gradientLayer.locations = nil;
        self.gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        self.gradientLayer.endPoint = CGPointMake(0.5, 1.0);
        self.toolStack.spacing = 10.0;
        self.toolStack.alignment = UIStackViewAlignmentBottom;
        self.toolStack.distribution = UIStackViewDistributionFill;
        CGFloat stackTopInset = kDockHeight - kToolbarBottomInset - kToolbarIconRowHeight;
        [self.toolStack mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.toolScrollView).insets(UIEdgeInsetsMake(stackTopInset, 15, kToolbarBottomInset, 8));
        }];
    }
    [self layoutGradientIfNeeded];
}

@end
