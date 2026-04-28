#import "LCAICloudQuickLookDayProgressView.h"
#import <LCBaseModule/LCProgressHUD.h>
#import <LCBaseModule/UIColor+LeChange.h>
#import <LCBaseModule/UIColor+HexString.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>

static UIColor *LCAIQLTrackColor(void) {
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
}

static UIColor *LCAIQLPlayedColor(void) {
    return [UIColor lccolor_c10];
}

static UIColor *LCAIQLOverlayDotColor(void) {
    return [UIColor colorWithWhite:1 alpha:0.5];
}

@interface LCAICloudQuickLookDayProgressView ()
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, copy) NSArray<NSNumber *> *segmentOverlayRatios;
@property (nonatomic, strong) UIView *hitArea;
@property (nonatomic, strong) UIView *trackBackground;
@property (nonatomic, strong) UIView *trackPlayed;
@property (nonatomic, strong) UIView *dotsContainer;
@property (nonatomic, strong) NSMutableArray<UIView *> *markerDotViews;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *markerRatios;
@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, assign) CGFloat displayProgress;
@property (nonatomic, assign) BOOL dragging;
@end

@implementation LCAICloudQuickLookDayProgressView

static const CGFloat kQLPortraitProgressTouchExpandTop = 16.0f;

- (void)setPortraitLightChrome:(BOOL)portraitLightChrome {
    if (_portraitLightChrome == portraitLightChrome) {
        return;
    }
    _portraitLightChrome = portraitLightChrome;
    [self lc_applyTrackChromeColors];
}

- (void)lc_applyTrackChromeColors {
    if (self.isLandscapeLayout) {
        self.trackBackground.backgroundColor = LCAIQLTrackColor();
        self.trackPlayed.backgroundColor = LCAIQLPlayedColor();
        self.thumbView.backgroundColor = LCAIQLPlayedColor();
        return;
    }
    if (self.portraitLightChrome) {
        self.trackBackground.backgroundColor = [UIColor lc_colorWithHexString:@"#E5E5E5"];
        self.trackPlayed.backgroundColor = LCAIQLPlayedColor();
        self.thumbView.backgroundColor = LCAIQLPlayedColor();
        return;
    }
    self.trackBackground.backgroundColor = LCAIQLTrackColor();
    self.trackPlayed.backgroundColor = LCAIQLPlayedColor();
    self.thumbView.backgroundColor = LCAIQLPlayedColor();
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.canRefreshSlider = YES;
        self.displayProgress = 0;
        self.backgroundColor = [UIColor clearColor];
        self.markerDotViews = [NSMutableArray array];
        self.markerRatios = [NSMutableArray array];
        self.segmentOverlayRatios = @[];
        [self lc_build];
        [self lc_applyTrackChromeColors];
    }
    return self;
}

- (void)lc_build {
    self.hitArea = [[UIView alloc] init];
    self.hitArea.backgroundColor = [UIColor clearColor];
    [self addSubview:self.hitArea];
    self.trackBackground = [[UIView alloc] init];
    self.trackBackground.backgroundColor = LCAIQLTrackColor();
    [self.hitArea addSubview:self.trackBackground];
    self.trackPlayed = [[UIView alloc] init];
    self.trackPlayed.backgroundColor = LCAIQLPlayedColor();
    [self.trackBackground addSubview:self.trackPlayed];
    self.dotsContainer = [[UIView alloc] init];
    self.dotsContainer.userInteractionEnabled = NO;
    [self.hitArea addSubview:self.dotsContainer];

    self.thumbView = [[UIView alloc] init];
    self.thumbView.backgroundColor = LCAIQLPlayedColor();
    self.thumbView.layer.cornerRadius = 2;
    self.thumbView.clipsToBounds = YES;
    self.thumbView.hidden = YES;
    [self.hitArea addSubview:self.thumbView];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(lc_onPan:)];
    [self addGestureRecognizer:pan];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lc_onTap:)];
    [self addGestureRecognizer:tap];
}

- (BOOL)lc_interactionAllowed {
    if (self.interactionAllowedBlock) {
        return self.interactionAllowedBlock();
    }
    return YES;
}

- (void)setStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    self.startDate = startDate;
    self.endDate = endDate;
    [self lc_rebuildMarkerDots];
    [self setNeedsLayout];
    [self lc_refreshPlayedFrame];
}

- (void)setSegmentOverlayRatios:(NSArray<NSNumber *> *)ratios {
    _segmentOverlayRatios = [ratios copy] ?: @[];
    [self lc_rebuildMarkerDots];
    [self setNeedsLayout];
}

- (NSTimeInterval)lc_duration {
    if (!self.startDate || !self.endDate) {
        return 0;
    }
    return MAX(0, [self.endDate timeIntervalSinceDate:self.startDate]);
}

- (UIEdgeInsets)lc_trackInset {
    if (self.isLandscapeLayout) {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
    return UIEdgeInsetsZero;
}

- (void)setIsLandscapeLayout:(BOOL)isLandscapeLayout {
    if (_isLandscapeLayout == isLandscapeLayout) {
        return;
    }
    _isLandscapeLayout = isLandscapeLayout;
    self.thumbView.hidden = !isLandscapeLayout;
    [self lc_applyTrackChromeColors];
    [self setNeedsLayout];
    [self lc_rebuildMarkerDots];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.hitArea.frame = self.bounds;
    self.dotsContainer.frame = self.hitArea.bounds;
    UIEdgeInsets inset = [self lc_trackInset];
    CGFloat w = CGRectGetWidth(self.bounds) - inset.left - inset.right;
    if (w < 1) {
        w = 1;
    }

    if (self.isLandscapeLayout) {
        self.thumbView.hidden = NO;
        CGFloat th = 2.0;
        CGFloat marginTop = 12.0;
        self.trackBackground.frame = CGRectMake(inset.left, marginTop, w, th);
        self.trackBackground.layer.cornerRadius = th * 0.5;
        [self lc_refreshPlayedFrame];
        CGFloat midY = marginTop + th * 0.5;
        CGFloat tx = inset.left + self.displayProgress * w - 5.0;
        self.thumbView.frame = CGRectMake(tx, midY - 8.0, 10, 16);
    } else {
        self.thumbView.hidden = YES;
        CGFloat h = CGRectGetHeight(self.bounds);
        CGFloat th = 4.0;
        CGFloat ty = MAX(0, h - th);
        self.trackBackground.frame = CGRectMake(inset.left, ty, w, th);
        self.trackBackground.layer.cornerRadius = th * 0.5;
        [self lc_refreshPlayedFrame];
        CGFloat midY = ty + th * 0.5;
        [self lc_layoutMarkerDotsInWidth:w left:inset.left trackMidY:midY];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    (void)event;
    CGFloat touchExpandTop = self.isLandscapeLayout ? 0.0f : kQLPortraitProgressTouchExpandTop;
    CGRect hitRect = CGRectMake(0, -touchExpandTop, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) + touchExpandTop);
    return CGRectContainsPoint(hitRect, point);
}

- (void)lc_refreshPlayedFrame {
    CGFloat tw = CGRectGetWidth(self.trackBackground.bounds);
    CGFloat ph = CGRectGetHeight(self.trackBackground.bounds);
    if (tw <= 0) {
        return;
    }
    CGFloat pw = tw * self.displayProgress;
    self.trackPlayed.frame = CGRectMake(0, 0, pw, ph);
    if (self.isLandscapeLayout && !self.thumbView.hidden) {
        UIEdgeInsets inset = [self lc_trackInset];
        CGFloat w = CGRectGetWidth(self.bounds) - inset.left - inset.right;
        if (w > 0) {
            CGFloat tx = inset.left + self.displayProgress * w - 5.0;
            CGFloat marginTop = 12.0;
            CGFloat th = 2.0;
            CGFloat midY = marginTop + th * 0.5;
            self.thumbView.frame = CGRectMake(tx, midY - 8.0, 10, 16);
        }
    }
}

- (void)setCurrentDate:(NSDate *)currentDate {
    if (!currentDate) {
        return;
    }
    _currentDate = currentDate;
    if (!self.canRefreshSlider || !self.startDate || self.dragging) {
        return;
    }
    NSTimeInterval dur = [self lc_duration];
    if (dur <= 0) {
        return;
    }
    NSTimeInterval off = [currentDate timeIntervalSinceDate:self.startDate];
    if (off < 0) {
        off = 0;
    }
    self.displayProgress = (CGFloat)MIN(1.0, off / dur);
    [self lc_refreshPlayedFrame];
    [self setNeedsLayout];
}

- (void)lc_rebuildMarkerDots {
    for (UIView *v in self.markerDotViews) {
        [v removeFromSuperview];
    }
    [self.markerDotViews removeAllObjects];
    [self.markerRatios removeAllObjects];
    if (self.isLandscapeLayout) {
        return;
    }
    for (NSNumber *n in self.segmentOverlayRatios) {
        CGFloat ratio = n.floatValue;
        if (ratio < 0 || ratio > 1) {
            continue;
        }
        UIView *dot = [[UIView alloc] initWithFrame:CGRectZero];
        dot.backgroundColor = LCAIQLOverlayDotColor();
        dot.layer.cornerRadius = 2.0;
        dot.clipsToBounds = YES;
        [self.dotsContainer addSubview:dot];
        [self.markerDotViews addObject:dot];
        [self.markerRatios addObject:@(ratio)];
    }
}

- (void)lc_layoutMarkerDotsInWidth:(CGFloat)trackWidth left:(CGFloat)leftInset trackMidY:(CGFloat)midY {
    static const CGFloat kDotW = 4.0;
    static const CGFloat kDotH = 4.0;
    NSUInteger n = self.markerDotViews.count;
    if (n == 0 || n != self.markerRatios.count) {
        return;
    }
    for (NSUInteger i = 0; i < n; i++) {
        CGFloat ratio = [self.markerRatios[i] floatValue];
        CGFloat cx = leftInset + ratio * trackWidth;
        UIView *dot = self.markerDotViews[i];
        dot.frame = CGRectMake(cx - kDotW * 0.5, midY - kDotH * 0.5, kDotW, kDotH);
    }
}

- (CGFloat)lc_ratioFromLocationX:(CGFloat)xInHitArea {
    UIEdgeInsets inset = [self lc_trackInset];
    CGFloat w = CGRectGetWidth(self.bounds) - inset.left - inset.right;
    if (w <= 0) {
        return 0;
    }
    CGFloat x = xInHitArea - inset.left;
    CGFloat r = x / w;
    return (CGFloat)MAX(0, MIN(1, r));
}

- (void)lc_onTap:(UITapGestureRecognizer *)gr {
    if (![self lc_interactionAllowed]) {
        [LCProgressHUD showMsg:@"play_record_no_drag_while_recordings".lcMedia_T];
        return;
    }
    CGPoint p = [gr locationInView:self];
    [self lc_commitRatio:[self lc_ratioFromLocationX:p.x]];
}

- (void)lc_onPan:(UIPanGestureRecognizer *)gr {
    CGPoint p = [gr locationInView:self];
    CGFloat r = [self lc_ratioFromLocationX:p.x];
    switch (gr.state) {
        case UIGestureRecognizerStateBegan:
            if (![self lc_interactionAllowed]) {
                [LCProgressHUD showMsg:@"play_record_no_drag_while_recordings".lcMedia_T];
                gr.enabled = NO;
                gr.enabled = YES;
                return;
            }
            self.dragging = YES;
            self.canRefreshSlider = NO;
            self.displayProgress = r;
            [self lc_refreshPlayedFrame];
            [self setNeedsLayout];
            if (self.valueChangeBlock) {
                NSTimeInterval dur = [self lc_duration];
                self.valueChangeBlock((float)(r * dur), [self.startDate dateByAddingTimeInterval:r * dur]);
            }
            break;
        case UIGestureRecognizerStateChanged: {
            if (!self.dragging) {
                return;
            }
            self.displayProgress = r;
            [self lc_refreshPlayedFrame];
            [self setNeedsLayout];
            NSTimeInterval dur = [self lc_duration];
            float offset = (float)(r * dur);
            if (self.valueChangeBlock) {
                self.valueChangeBlock(offset, [self.startDate dateByAddingTimeInterval:offset]);
            }
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            if (!self.dragging) {
                return;
            }
            self.dragging = NO;
            {
                CGPoint ep = [gr locationInView:self];
                CGFloat er = [self lc_ratioFromLocationX:ep.x];
                [self lc_commitRatio:er];
            }
            [self setNeedsLayout];
            break;
        default:
            break;
    }
}

- (void)lc_snapProgressToFull {
    if (!self.startDate || !self.endDate) {
        return;
    }
    self.displayProgress = 1.f;
    _currentDate = self.endDate;
    [self lc_refreshPlayedFrame];
    [self setNeedsLayout];
}

- (void)lc_commitRatio:(CGFloat)r {
    NSTimeInterval dur = [self lc_duration];
    float offset = (float)(r * dur);
    if (dur > 5 && offset >= (float)dur - 0.5f) {
        offset = (float)(dur - 5.f);
    } else if (dur > 3 && offset >= (float)dur - 0.5f) {
        offset = (float)(dur - 3.f);
    }
    self.displayProgress = dur > 0 ? (CGFloat)(offset / dur) : 0;
    if (self.valueChangeEndBlock) {
        self.valueChangeEndBlock(offset, [self.startDate dateByAddingTimeInterval:offset]);
    }
    self.canRefreshSlider = YES;
    [self lc_refreshPlayedFrame];
    [self setNeedsLayout];
}

@end
