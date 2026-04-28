#import "LCAICloudQuickLookCalendarViewController.h"
#import "LCAICloudAppBundleImage.h"
#import <LCBaseModule/UIColor+HexString.h>
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import <Masonry/Masonry.h>

static const CGFloat kCalEntranceDuration = 0.2;
static const CGFloat kCalHeaderCapsuleWidth = 140.0;
static const CGFloat kCalHeaderCapsuleCorner = 10.0;
static const CGFloat kCalSheetMinHeight = 368.0;
static const CGFloat kCalBottomCornerRadius = 10.0;
static const CGFloat kCalWeekdayRowHeight = 38.0;
static const NSInteger kCalGridWeekRows = 6;
static const CGFloat kCalGridHorizontalInset = 12.0;
static const CGFloat kCalGridInteritemSpacing = 5.0;
static const CGFloat kCalGridLineSpacing = 6.0;
static const CGFloat kCalMonthHeaderTop = 8.0;
static const CGFloat kCalMonthHeaderHeight = 36.0;
static const CGFloat kCalMonthToWeekSpacing = 12.0;
static const CGFloat kCalFoldTopSpacing = 4.0;
static const CGFloat kCalFoldButtonHeight = 30.0;
static const CGFloat kCalFoldBottomInset = 10.0;
static const CGFloat kCalMonthHeaderLeft = 12.0;
static const CGFloat kCalArrowHitSize = 28.0;

static UIImage *LCAIQLImageTemplate(NSString *name) {
    UIImage *img = LCAICloudAppBundleImage(name);
    return img ? [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil;
}

static UIImage *LCAIQLRotatedTemplateImage(UIImage *src, CGFloat rotationRadians) {
    if (!src) {
        return nil;
    }
    CGSize s = src.size;
    CGRect rect = CGRectMake(0, 0, s.width, s.height);
    UIGraphicsBeginImageContextWithOptions(s, NO, src.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, s.width / 2.0, s.height / 2.0);
    CGContextRotateCTM(ctx, rotationRadians);
    CGContextTranslateCTM(ctx, -s.width / 2.0, -s.height / 2.0);
    [src drawInRect:rect];
    UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [out imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static NSString *const kCalCellId = @"LCAICloudQuickLookCalCell";

@interface LCAICloudQuickLookCalCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *dayLabel;
@property (nonatomic, strong) UIView *dotView;
@end

@implementation LCAICloudQuickLookCalCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.dayLabel = [[UILabel alloc] init];
        self.dayLabel.textAlignment = NSTextAlignmentCenter;
        self.dayLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        [self.contentView addSubview:self.dayLabel];
        self.dotView = [[UIView alloc] init];
        self.dotView.layer.cornerRadius = 2.0;
        self.dotView.backgroundColor = [UIColor lc_colorWithHexString:@"#4F78FF"];
        self.dotView.hidden = YES;
        [self.contentView addSubview:self.dotView];
        [self.dayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView);
            make.centerY.equalTo(self.contentView).offset(-4);
        }];
        [self.dotView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView);
            make.top.equalTo(self.dayLabel.mas_bottom).offset(2);
            make.width.height.mas_equalTo(4);
        }];
    }
    return self;
}

@end

@interface LCAICloudQuickLookCalendarViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *cardContainer;
@property (nonatomic, assign) CGFloat qlCachedDayCellSide;
@property (nonatomic, assign) CGFloat qlCachedGridTotalHeight;
@property (nonatomic, assign) CGFloat qlCachedSheetHeight;
@property (nonatomic, assign) BOOL qlSheetDismissAnimating;
@property (nonatomic, copy) NSArray<NSDictionary *> *dayInfoList;
@property (nonatomic, copy, nullable) NSString *selectedDate;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *dateToHasVideo;
@property (nonatomic, strong) NSDate *monthAnchor;
@property (nonatomic, strong) NSDate *minDate;
@property (nonatomic, strong) NSDate *maxDate;
@property (nonatomic, strong) NSDateFormatter *ymdFmt;
@property (nonatomic, strong) NSDateFormatter *titleFmt;
@property (nonatomic, strong) UIView *monthHeaderCapsule;
@property (nonatomic, strong) UILabel *monthTitleLabel;
@property (nonatomic, strong) UIButton *prevBtn;
@property (nonatomic, strong) UIButton *nextBtn;
@property (nonatomic, strong) UICollectionView *weekdayCollection;
@property (nonatomic, strong) UICollectionView *gridCollection;
@property (nonatomic, copy) NSArray<NSString *> *weekdayTitles;
@property (nonatomic, copy) NSArray<NSNumber *> *gridDayNumbers;
@property (nonatomic, copy) NSArray<NSString *> *gridDateStrings;
@property (nonatomic, assign) BOOL didPlayEntrance;
@end

static CGFloat LCAIQLDayCellSideForCardWidth(CGFloat cardWidth) {
    if (cardWidth < 32) {
        return 36;
    }
    CGFloat usable = cardWidth - kCalGridHorizontalInset * 2.0 - kCalGridInteritemSpacing * 6.0;
    return MAX(28, floor(usable / 7.0));
}

static CGFloat LCAIQLGridTotalHeightForSide(CGFloat side) {
    return (CGFloat)kCalGridWeekRows * side + (CGFloat)(kCalGridWeekRows - 1) * kCalGridLineSpacing;
}

static CGFloat LCAIQLSheetHeightForGridHeight(CGFloat gridTotalH, CGFloat safeTop) {
    CGFloat h = safeTop + kCalMonthHeaderTop + kCalMonthHeaderHeight + kCalMonthToWeekSpacing + kCalWeekdayRowHeight + gridTotalH + kCalFoldTopSpacing + kCalFoldButtonHeight + kCalFoldBottomInset + 2.0;
    h = MAX(h, kCalSheetMinHeight);
    return MIN(h, 520.0);
}

@implementation LCAICloudQuickLookCalendarViewController

- (instancetype)initWithDayInfoList:(NSArray<NSDictionary *> *)dayInfoList selectedDate:(NSString *)yyyyMMdd {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _dayInfoList = [dayInfoList copy];
        _selectedDate = [yyyyMMdd copy];
        _dateToHasVideo = [NSMutableDictionary dictionary];
        _ymdFmt = [[NSDateFormatter alloc] init];
        _ymdFmt.dateFormat = @"yyyy-MM-dd";
        _ymdFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _titleFmt = [[NSDateFormatter alloc] init];
        _titleFmt.dateFormat = @"yyyy/MM";
        _titleFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        for (NSDictionary *d in _dayInfoList) {
            NSString *ds = d[@"date"];
            if ([ds isKindOfClass:[NSString class]] && ds.length) {
                _dateToHasVideo[ds] = @([d[@"hasVideo"] boolValue]);
            }
        }
        [self computeMinMaxDates];
        NSDate *sel = [_ymdFmt dateFromString:_selectedDate ?: @""];
        if (sel && [self date:sel isBetweenMin:_minDate max:_maxDate]) {
            _monthAnchor = sel;
        } else {
            _monthAnchor = _maxDate ?: [NSDate date];
        }
        self.modalPresentationCapturesStatusBarAppearance = YES;
        _qlCachedDayCellSide = -1;
        _qlCachedGridTotalHeight = -1;
        _qlCachedSheetHeight = kCalSheetMinHeight;
    }
    return self;
}

- (void)computeMinMaxDates {
    self.minDate = nil;
    self.maxDate = nil;
    for (NSDictionary *d in self.dayInfoList) {
        NSString *ds = d[@"date"];
        if (![ds isKindOfClass:[NSString class]]) {
            continue;
        }
        NSDate *dt = [self.ymdFmt dateFromString:ds];
        if (!dt) {
            continue;
        }
        if (!self.minDate || [dt compare:self.minDate] == NSOrderedAscending) {
            self.minDate = dt;
        }
        if (!self.maxDate || [dt compare:self.maxDate] == NSOrderedDescending) {
            self.maxDate = dt;
        }
    }
    if (!self.minDate) {
        self.minDate = [NSDate date];
    }
    if (!self.maxDate) {
        self.maxDate = self.minDate;
    }
}

- (BOOL)date:(NSDate *)d isBetweenMin:(NSDate *)a max:(NSDate *)b {
    if (!d || !a || !b) {
        return NO;
    }
    return ([d compare:a] != NSOrderedAscending) && ([d compare:b] != NSOrderedDescending);
}

- (NSDate *)startOfCalendarDay:(NSDate *)date {
    NSCalendar *cal = [NSCalendar currentCalendar];
    return [cal startOfDayForDate:date];
}

- (BOOL)dateStringIsSelectable:(NSString *)ds {
    if (ds.length == 0) {
        return NO;
    }
    NSDate *d = [self.ymdFmt dateFromString:ds];
    if (!d) {
        return NO;
    }
    NSDate *day = [self startOfCalendarDay:d];
    NSDate *lo = [self startOfCalendarDay:self.minDate];
    NSDate *hi = [self startOfCalendarDay:self.maxDate];
    return ([day compare:lo] != NSOrderedAscending) && ([day compare:hi] != NSOrderedDescending);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    self.dimView = [[UIView alloc] init];
    self.dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.dimView.alpha = 0;
    [self.view addSubview:self.dimView];
    UITapGestureRecognizer *tapDim = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackdrop:)];
    [self.dimView addGestureRecognizer:tapDim];

    UIView *card = [[UIView alloc] init];
    self.cardContainer = card;
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = kCalBottomCornerRadius;
    card.layer.masksToBounds = YES;
    if (@available(iOS 11.0, *)) {
        card.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    }
    [self.view addSubview:card];

    self.monthHeaderCapsule = [[UIView alloc] init];
    self.monthHeaderCapsule.backgroundColor = [UIColor lc_colorWithHexString:@"#F6F6F6"];
    self.monthHeaderCapsule.layer.cornerRadius = kCalHeaderCapsuleCorner;
    [card addSubview:self.monthHeaderCapsule];

    self.monthTitleLabel = [[UILabel alloc] init];
    self.monthTitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.monthTitleLabel.textColor = [UIColor lc_colorWithHexString:@"#2C2C2C"];
    self.monthTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.monthHeaderCapsule addSubview:self.monthTitleLabel];

    self.prevBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.prevBtn addTarget:self action:@selector(onPrevMonth) forControlEvents:UIControlEventTouchUpInside];
    self.prevBtn.adjustsImageWhenHighlighted = NO;
    self.prevBtn.accessibilityLabel = @"ai_insight_calendar_prev_month_a11y".lcMedia_T;
    [self.monthHeaderCapsule addSubview:self.prevBtn];

    self.nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextBtn addTarget:self action:@selector(onNextMonth) forControlEvents:UIControlEventTouchUpInside];
    self.nextBtn.adjustsImageWhenHighlighted = NO;
    self.nextBtn.accessibilityLabel = @"ai_insight_calendar_next_month_a11y".lcMedia_T;
    [self.monthHeaderCapsule addSubview:self.nextBtn];

    [self configureMonthStepButtonsWithImages];

    self.weekdayTitles = [self buildWeekdayTitles];
    UICollectionViewFlowLayout *wl = [[UICollectionViewFlowLayout alloc] init];
    wl.minimumLineSpacing = 0;
    wl.minimumInteritemSpacing = kCalGridInteritemSpacing;
    UIEdgeInsets gridInset = UIEdgeInsetsMake(0, kCalGridHorizontalInset, 0, kCalGridHorizontalInset);
    wl.sectionInset = gridInset;
    self.weekdayCollection = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:wl];
    self.weekdayCollection.backgroundColor = [UIColor clearColor];
    self.weekdayCollection.scrollEnabled = NO;
    [self.weekdayCollection registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"w"];
    self.weekdayCollection.delegate = self;
    self.weekdayCollection.dataSource = self;
    self.weekdayCollection.tag = 9001;
    [card addSubview:self.weekdayCollection];

    UICollectionViewFlowLayout *gl = [[UICollectionViewFlowLayout alloc] init];
    gl.minimumInteritemSpacing = kCalGridInteritemSpacing;
    gl.minimumLineSpacing = kCalGridLineSpacing;
    gl.sectionInset = gridInset;
    self.gridCollection = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:gl];
    self.gridCollection.backgroundColor = [UIColor clearColor];
    self.gridCollection.scrollEnabled = NO;
    [self.gridCollection registerClass:[LCAICloudQuickLookCalCell class] forCellWithReuseIdentifier:kCalCellId];
    self.gridCollection.delegate = self;
    self.gridCollection.dataSource = self;
    self.gridCollection.tag = 9002;
    [card addSubview:self.gridCollection];

    UIButton *foldBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [foldBtn addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    foldBtn.accessibilityLabel = @"ai_insight_calendar_fold_a11y".lcMedia_T;
    UIImage *foldImg = LCAICloudAppBundleImage(@"ai_insight_report_btn_fold");
    if (foldImg) {
        foldImg = [foldImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [foldBtn setImage:foldImg forState:UIControlStateNormal];
        foldBtn.tintColor = [UIColor lc_colorWithHexString:@"#C2C2C2"];
        foldBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        [foldBtn setTitle:@"⌄" forState:UIControlStateNormal];
        [foldBtn setTitleColor:[UIColor lc_colorWithHexString:@"#C2C2C2"] forState:UIControlStateNormal];
        foldBtn.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightLight];
    }
    [card addSubview:foldBtn];

    [self.dimView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    CGFloat initialGridH = LCAIQLGridTotalHeightForSide(LCAIQLDayCellSideForCardWidth(CGRectGetWidth([UIScreen mainScreen].bounds)));
    self.qlCachedGridTotalHeight = initialGridH;
    self.qlCachedDayCellSide = LCAIQLDayCellSideForCardWidth(CGRectGetWidth([UIScreen mainScreen].bounds));
    self.qlCachedSheetHeight = LCAIQLSheetHeightForGridHeight(initialGridH, 47);
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(self.qlCachedSheetHeight);
    }];
    [self.monthHeaderCapsule mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card.mas_safeAreaLayoutGuideTop).offset(kCalMonthHeaderTop);
        make.left.equalTo(card).offset(kCalMonthHeaderLeft);
        make.width.mas_equalTo(kCalHeaderCapsuleWidth);
        make.height.mas_equalTo(kCalMonthHeaderHeight);
    }];
    [self.prevBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.monthHeaderCapsule).offset(4);
        make.centerY.equalTo(self.monthHeaderCapsule);
        make.width.height.mas_equalTo(kCalArrowHitSize);
    }];
    [self.nextBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.monthHeaderCapsule).offset(-4);
        make.centerY.equalTo(self.monthHeaderCapsule);
        make.width.height.mas_equalTo(kCalArrowHitSize);
    }];
    [self.monthTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.monthHeaderCapsule);
        make.width.mas_lessThanOrEqualTo(62);
    }];
    [self.weekdayCollection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.monthHeaderCapsule.mas_bottom).offset(kCalMonthToWeekSpacing);
        make.left.right.equalTo(card);
        make.height.mas_equalTo(kCalWeekdayRowHeight);
    }];
    [self.gridCollection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.weekdayCollection.mas_bottom);
        make.left.right.equalTo(card);
        make.height.mas_equalTo(initialGridH);
    }];
    [foldBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.gridCollection.mas_bottom).offset(kCalFoldTopSpacing);
        make.left.right.equalTo(card);
        make.height.mas_equalTo(kCalFoldButtonHeight);
        make.bottom.equalTo(card).offset(-kCalFoldBottomInset);
    }];

    self.cardContainer.transform = CGAffineTransformMakeTranslation(0, -(self.qlCachedSheetHeight + 80));
    [self reloadMonthUI];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self ql_updateCalendarLayoutMetrics];
}

- (void)ql_updateCalendarLayoutMetrics {
    if (self.qlSheetDismissAnimating) {
        return;
    }
    CGFloat cardW = CGRectGetWidth(self.cardContainer.bounds);
    if (cardW < 32) {
        return;
    }
    CGFloat side = LCAIQLDayCellSideForCardWidth(cardW);
    CGFloat gridH = LCAIQLGridTotalHeightForSide(side);
    CGFloat safeTop = self.view.safeAreaInsets.top;
    CGFloat sheetH = LCAIQLSheetHeightForGridHeight(gridH, safeTop);
    BOOL changed = (fabs(gridH - self.qlCachedGridTotalHeight) > 0.5) || (fabs(sheetH - self.qlCachedSheetHeight) > 0.5) || (fabs(side - self.qlCachedDayCellSide) > 0.5);
    if (!changed) {
        return;
    }
    self.qlCachedDayCellSide = side;
    self.qlCachedGridTotalHeight = gridH;
    self.qlCachedSheetHeight = sheetH;
    [self.gridCollection mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(gridH);
    }];
    [self.cardContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(sheetH);
    }];
    [self.gridCollection.collectionViewLayout invalidateLayout];
    [self.weekdayCollection.collectionViewLayout invalidateLayout];
    [self.weekdayCollection reloadData];
    [self.gridCollection reloadData];
}

- (void)ql_dismissSheetThen:(void (^)(void))completion {
    if (self.qlSheetDismissAnimating) {
        return;
    }
    self.qlSheetDismissAnimating = YES;
    CGFloat hideY = -(MAX(self.qlCachedSheetHeight, kCalSheetMinHeight) + 80.0);
    [UIView animateWithDuration:kCalEntranceDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.dimView.alpha = 0;
        self.cardContainer.transform = CGAffineTransformMakeTranslation(0, hideY);
    } completion:^(BOOL finished) {
        (void)finished;
        self.qlSheetDismissAnimating = NO;
        if (completion) {
            completion();
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didPlayEntrance) {
        return;
    }
    self.didPlayEntrance = YES;
    CGFloat offY = MAX(self.qlCachedSheetHeight, kCalSheetMinHeight) + 80.0;
    self.cardContainer.transform = CGAffineTransformMakeTranslation(0, -offY);
    [UIView animateWithDuration:kCalEntranceDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.dimView.alpha = 1;
        self.cardContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)configureMonthStepButtonsWithImages {
    UIImage *rightT = LCAIQLImageTemplate(@"time_selector_arror_right_n");
    UIImage *leftT = LCAIQLRotatedTemplateImage(rightT, (CGFloat)M_PI);
    if (!leftT || !rightT) {
        UIImage *fallback = LCAIQLImageTemplate(@"time_selector_arror_left");
        if (fallback) {
            leftT = fallback;
        }
        UIImage *fr = LCAIQLImageTemplate(@"time_selector_arror_right_n");
        if (fr) {
            rightT = fr;
        }
    }
    if (leftT) {
        [self.prevBtn setImage:leftT forState:UIControlStateNormal];
    } else {
        [self.prevBtn setTitle:@"‹" forState:UIControlStateNormal];
        [self.prevBtn setTitleColor:[UIColor lc_colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    }
    if (rightT) {
        [self.nextBtn setImage:rightT forState:UIControlStateNormal];
    } else {
        [self.nextBtn setTitle:@"›" forState:UIControlStateNormal];
        [self.nextBtn setTitleColor:[UIColor lc_colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    }
    [self refreshArrowTint];
}

- (void)refreshArrowTint {
    UIColor *on = [UIColor lc_colorWithHexString:@"#2C2C2C"];
    UIColor *off = [UIColor lc_colorWithHexString:@"#C2C2C2"];
    if ([self.prevBtn imageForState:UIControlStateNormal]) {
        self.prevBtn.tintColor = self.prevBtn.enabled ? on : off;
    } else {
        [self.prevBtn setTitleColor:(self.prevBtn.enabled ? on : off) forState:UIControlStateNormal];
    }
    if ([self.nextBtn imageForState:UIControlStateNormal]) {
        self.nextBtn.tintColor = self.nextBtn.enabled ? on : off;
    } else {
        [self.nextBtn setTitleColor:(self.nextBtn.enabled ? on : off) forState:UIControlStateNormal];
    }
}

- (NSArray<NSString *> *)buildWeekdayTitles {
    return @[
        @"ai_insight_calendar_weekday_0".lcMedia_T,
        @"ai_insight_calendar_weekday_1".lcMedia_T,
        @"ai_insight_calendar_weekday_2".lcMedia_T,
        @"ai_insight_calendar_weekday_3".lcMedia_T,
        @"ai_insight_calendar_weekday_4".lcMedia_T,
        @"ai_insight_calendar_weekday_5".lcMedia_T,
        @"ai_insight_calendar_weekday_6".lcMedia_T,
    ];
}

- (void)onBackdrop:(UITapGestureRecognizer *)g {
    (void)g;
    [self onClose];
}

- (void)onClose {
    if (self.qlSheetDismissAnimating) {
        return;
    }
    __weak typeof(self) wself = self;
    [self ql_dismissSheetThen:^{
        if (wself.onCancel) {
            wself.onCancel();
        }
    }];
}

- (void)onPrevMonth {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *d = [cal dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:self.monthAnchor options:0];
    NSDate *newMonthStart = [self startOfMonth:d];
    NSDate *minMonthStart = [self startOfMonth:self.minDate];
    if ([newMonthStart compare:minMonthStart] == NSOrderedAscending) {
        return;
    }
    self.monthAnchor = newMonthStart;
    [self reloadMonthUI];
}

- (void)onNextMonth {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *d = [cal dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:self.monthAnchor options:0];
    NSDate *newMonthStart = [self startOfMonth:d];
    NSDate *maxMonthStart = [self startOfMonth:self.maxDate];
    if ([newMonthStart compare:maxMonthStart] == NSOrderedDescending) {
        return;
    }
    self.monthAnchor = newMonthStart;
    [self reloadMonthUI];
}

- (NSDate *)startOfMonth:(NSDate *)date {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *c = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date];
    c.day = 1;
    c.hour = 0;
    c.minute = 0;
    c.second = 0;
    return [cal dateFromComponents:c];
}

- (void)reloadMonthUI {
    self.monthTitleLabel.text = [self.titleFmt stringFromDate:self.monthAnchor];
    NSDate *firstOfMonth = [self startOfMonth:self.monthAnchor];
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    cal.firstWeekday = 1;
    NSRange daysRange = [cal rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstOfMonth];
    NSInteger daysInMonth = daysRange.length;
    NSInteger weekday = [cal component:NSCalendarUnitWeekday fromDate:firstOfMonth];
    NSInteger leading = (weekday - cal.firstWeekday + 7) % 7;

    NSMutableArray *nums = [NSMutableArray array];
    NSMutableArray *strs = [NSMutableArray array];
    for (NSInteger i = 0; i < 42; i++) {
        NSInteger dayNum = (NSInteger)i - leading + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
            [nums addObject:@0];
            [strs addObject:@""];
        } else {
            NSDateComponents *comp = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:firstOfMonth];
            comp.day = dayNum;
            NSDate *cellDate = [cal dateFromComponents:comp];
            NSString *ds = [self.ymdFmt stringFromDate:cellDate];
            [nums addObject:@(dayNum)];
            [strs addObject:ds ?: @""];
        }
    }
    self.gridDayNumbers = nums;
    self.gridDateStrings = strs;

    NSDate *monthStart = [self startOfMonth:self.monthAnchor];
    NSDate *minMonthStart = [self startOfMonth:self.minDate];
    NSDate *maxMonthStart = [self startOfMonth:self.maxDate];
    self.prevBtn.enabled = ([monthStart compare:minMonthStart] == NSOrderedDescending);
    self.nextBtn.enabled = ([monthStart compare:maxMonthStart] == NSOrderedAscending);
    [self refreshArrowTint];

    [self.weekdayCollection reloadData];
    [self.gridCollection reloadData];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    (void)section;
    if (collectionView.tag == 9001) {
        return self.weekdayTitles.count;
    }
    return self.gridDayNumbers.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 9001) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"w" forIndexPath:indexPath];
        UILabel *lab = [cell.contentView viewWithTag:11];
        if (!lab) {
            lab = [[UILabel alloc] init];
            lab.tag = 11;
            lab.textAlignment = NSTextAlignmentCenter;
            lab.font = [UIFont systemFontOfSize:12];
            lab.textColor = [UIColor lc_colorWithHexString:@"#8F8F8F"];
            [cell.contentView addSubview:lab];
            [lab mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(cell.contentView);
            }];
        }
        lab.text = self.weekdayTitles[indexPath.item];
        return cell;
    }

    LCAICloudQuickLookCalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCalCellId forIndexPath:indexPath];
    NSInteger day = [self.gridDayNumbers[indexPath.item] integerValue];
    NSString *ds = self.gridDateStrings[indexPath.item];
    BOOL inRange = (day > 0 && ds.length && [self dateStringIsSelectable:ds]);
    BOOL hasVideo = inRange && [self.dateToHasVideo[ds] boolValue];
    BOOL sel = inRange && [ds isEqualToString:self.selectedDate];

    if (day <= 0) {
        cell.dayLabel.text = @"";
        cell.dotView.hidden = YES;
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.dayLabel.textColor = [UIColor clearColor];
        cell.contentView.layer.cornerRadius = 0;
        cell.contentView.layer.masksToBounds = NO;
        return cell;
    }

    cell.dayLabel.text = [NSString stringWithFormat:@"%ld", (long)day];
    cell.dotView.hidden = !hasVideo;
    if (sel) {
        cell.dayLabel.textColor = [UIColor whiteColor];
        cell.contentView.backgroundColor = [UIColor lc_colorWithHexString:@"#4F78FF"];
        cell.contentView.layer.cornerRadius = 10;
        cell.contentView.layer.masksToBounds = YES;
        cell.dotView.backgroundColor = [UIColor whiteColor];
    } else if (!inRange) {
        cell.dayLabel.textColor = [UIColor lc_colorWithHexString:@"#C2C2C2"];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.contentView.layer.cornerRadius = 0;
        cell.contentView.layer.masksToBounds = NO;
        cell.dotView.hidden = YES;
        cell.dotView.backgroundColor = [UIColor lc_colorWithHexString:@"#4F78FF"];
    } else {
        cell.dayLabel.textColor = [UIColor lc_colorWithHexString:@"#2C2C2C"];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.contentView.layer.cornerRadius = 0;
        cell.contentView.layer.masksToBounds = NO;
        cell.dotView.backgroundColor = [UIColor lc_colorWithHexString:@"#4F78FF"];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    (void)collectionViewLayout;
    (void)indexPath;
    CGFloat cw = CGRectGetWidth(collectionView.bounds);
    CGFloat side = self.qlCachedDayCellSide > 0 ? self.qlCachedDayCellSide : LCAIQLDayCellSideForCardWidth(cw);
    if (collectionView.tag == 9001) {
        return CGSizeMake(side, kCalWeekdayRowHeight);
    }
    return CGSizeMake(side, side);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag != 9002) {
        return;
    }
    NSInteger day = [self.gridDayNumbers[indexPath.item] integerValue];
    NSString *ds = self.gridDateStrings[indexPath.item];
    if (day <= 0 || ds.length == 0 || ![self dateStringIsSelectable:ds]) {
        return;
    }
    if (self.qlSheetDismissAnimating) {
        return;
    }
    self.selectedDate = ds;
    __weak typeof(self) wself = self;
    [self ql_dismissSheetThen:^{
        if (wself.onPickDate) {
            wself.onPickDate(ds);
        }
    }];
}

@end
