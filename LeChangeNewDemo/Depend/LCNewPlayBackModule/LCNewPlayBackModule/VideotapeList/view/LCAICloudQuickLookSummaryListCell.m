#import "LCAICloudQuickLookSummaryListCell.h"
#import "LCAICloudAppBundleImage.h"
#import <LCBaseModule/UIColor+HexString.h>
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import <Masonry/Masonry.h>

static NSString *const kLCAICloudQuickLookSummaryListCellId = @"LCAICloudQuickLookSummaryListCell";

// RN summaryListView.js: tag Image width/height 20
static const CGFloat kQLSummaryTagIconSize = 20.0;
// RN: cellTopPartLeft — play icon 18×18；pill 内边距 paddingHorizontal 6, paddingVertical 4
static const CGFloat kQLSummaryStateIconSize = 18.0;

#pragma mark - RN alarmMessageVisual.js（与 RN 一致，用于 resolveIconSource）

static NSString *LCAIQLRnNormalizeAlarmTypeForIconKey(NSString *type) {
    if (type.length == 0) {
        return @"";
    }
    NSString *s = [type stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) {
        return @"";
    }
    if ([s.lowercaseString isEqualToString:@"ai_risk"]) {
        return @"AI_RISK";
    }
    if ([s hasPrefix:@"aiInsight_"]) {
        return s;
    }
    if ([s rangeOfString:@"_"].location == NSNotFound) {
        return s;
    }
    NSMutableString *m = [s mutableCopy];
    NSRange r = [m rangeOfString:@"_" options:0 range:NSMakeRange(0, m.length)];
    while (r.location != NSNotFound) {
        if (r.location + 1 >= m.length) {
            break;
        }
        unichar ch = [m characterAtIndex:r.location + 1];
        if (ch >= 'a' && ch <= 'z') {
            unichar u = ch - ('a' - 'A');
            NSString *rep = [[NSString stringWithCharacters:&u length:1] copy];
            [m replaceCharactersInRange:NSMakeRange(r.location, 2) withString:rep];
        } else {
            break;
        }
        r = [m rangeOfString:@"_" options:0 range:NSMakeRange(0, m.length)];
    }
    return [m copy];
}

/// 与 RN `getAlarmIconAssetKey` 返回值（资源 key）一致
static NSString *LCAIQLRnGetAlarmIconAssetKey(NSString *type) {
    if (type.length == 0) {
        return @"msg_icon_default";
    }
    NSString *s = LCAIQLRnNormalizeAlarmTypeForIconKey(type);
    if (s.length == 0) {
        return @"msg_icon_default";
    }
    if ([s hasPrefix:@"aiInsight_"]) {
        return @"protect_icon_ai_l";
    }
    static NSDictionary<NSString *, NSString *> *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"humanAlarm" : @"msg_icon_human_alarm",
            @"faceAlarm" : @"msg_icon_face_alarm",
            @"carAlarm" : @"msg_icon_car_alarm",
            @"petAlarm" : @"msg_icon_pet_alarm",
            @"packageAlarm" : @"msg_icon_package_alarm",
            @"motionAlarm" : @"msg_icon_motion_alarm",
            @"stayoverAlarm" : @"msg_icon_stayover_alarm",
            @"abSoundAlarm" : @"msg_icon_absound_alarm",
            @"voiceHelpAlarm" : @"msg_icon_voice_help_alarm",
            @"cryingAlarm" : @"msg_icon_crying_alarm",
            @"antiDismantleAlarm" : @"msg_icon_anti_dismantle_alarm",
            @"callAlarm" : @"msg_icon_default",
            @"suspectedPeopleFallAlarm" : @"msg_icon_suspected_people_fall_alarm",
            @"peopleFallAlarm" : @"msg_icon_people_fall_alarm",
            @"other" : @"msg_icon_other",
            @"composeAlarm" : @"msg_icon_compose_alarm",
            @"mixedAlarm" : @"msg_icon_compose_alarm",
            @"AI_RISK" : @"waterfall_icon_ai_insight_danger",
            @"aiSmokeDetect" : @"msg_icon_ai_smoking",
            @"aiPlayMobileDetect" : @"msg_icon_ai_playmobile",
            @"aiAbsenceDetect" : @"msg_icon_ai_absence",
            @"aiShelfStatusDetect" : @"msg_icon_ai_shelfstatus",
            @"aiEmployeeAttireDetect" : @"msg_icon_ai_employeeattire",
            @"all" : @"msg_icon_all",
        };
    });
    NSString *v = map[s];
    return v.length ? v : @"msg_icon_default";
}

/// 将 `getSummaryTagList` 中的单个元素规范为 RN 里传给 `resolveIconSource(remoteImages, tag)` 的字符串
static NSString *_Nullable LCAIQLRnTagStringFromItem(id tag) {
    if (tag == nil || tag == [NSNull null]) {
        return nil;
    }
    if ([tag isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return s.length ? s : nil;
    }
    if ([tag isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)tag stringValue];
    }
    NSString *s = [[NSString stringWithFormat:@"%@", tag] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return s.length ? s : nil;
}

/**
 * 与业务枚举别名对齐，再进入 RN `getAlarmIconAssetKey` 管线。
 * 参考：HUMAN_ALARM(人, human, humanAlarm)、CAR_ALARM(车, vehicle, carAlarm)、
 * PET_ALARM(宠物, pet, petAlarm)、PACKAGE_ALARM(包裹, parcel, packageAlarm)、
 * AI_DISMANTLE_ALARM(AI_RISK, AI_RISK, antiDismantleAlarm) 等中英混排。
 * 无匹配时返回 nil，由调用方继续用原始 trim。
 */
static NSString *_Nullable LCAIQLTagAliasToCanonicalTypeString(NSString *trim) {
    if (trim.length == 0) {
        return nil;
    }
    NSString *lower = [trim lowercaseString];
    if ([trim isEqualToString:@"人"] || [lower isEqualToString:@"human"] || [lower isEqualToString:@"humanalarm"] || [lower isEqualToString:@"human_alarm"]) {
        return @"humanAlarm";
    }
    if ([trim isEqualToString:@"车"] || [lower isEqualToString:@"vehicle"] || [lower isEqualToString:@"caralarm"] || [lower isEqualToString:@"car_alarm"]) {
        return @"carAlarm";
    }
    if ([trim isEqualToString:@"宠物"] || [lower isEqualToString:@"pet"] || [lower isEqualToString:@"petalarm"] || [lower isEqualToString:@"pet_alarm"]) {
        return @"petAlarm";
    }
    if ([trim isEqualToString:@"包裹"] || [lower isEqualToString:@"parcel"] || [lower isEqualToString:@"packagealarm"] || [lower isEqualToString:@"package_alarm"]) {
        return @"packageAlarm";
    }
    if ([lower isEqualToString:@"ai_risk"] || [trim isEqualToString:@"AI_RISK"]) {
        return @"AI_RISK";
    }
    if ([lower isEqualToString:@"antidismantlealarm"] || [lower isEqualToString:@"antidismantle_alarm"] || [trim isEqualToString:@"antiDismantleAlarm"]) {
        return @"antiDismantleAlarm";
    }
    return nil;
}

/**
 * 与 RN `resolveIconSource(remoteImages, tag)` 一致（alarmMessageVisual.js）：
 * 1) `const key = getAlarmIconAssetKey(type)`（type 可先经 `LCAIQLTagAliasToCanonicalTypeString` 与枚举别名对齐）；
 * 2) `const src = remoteImages[key]` → iOS 为 `LCAICloudAppBundleImage(key)`（宿主 mainBundle）；
 * 3) 否则 fallback：`msg_icon_default` → `waterfall_icon_default_alarm` → `msg_icon_human_alarm`。
 *
 * 若接口下发的 `tag` 已是 catalog 名（如 `msg_icon_human_alarm`），不能走 normalize（会破坏 key），
 * 与 RN 中 `remoteImages[tag]` 若存在即用的效果一致：先按原名尝试加载。
 */
static UIImage *_Nullable LCAIQLRnResolveIconSourceForTag(id tag) {
    NSString *trim = LCAIQLRnTagStringFromItem(tag);
    if (trim.length == 0) {
        return nil;
    }
    if ([trim hasPrefix:@"msg_icon_"] || [trim hasPrefix:@"protect_icon"] || [trim hasPrefix:@"waterfall_icon"]) {
        UIImage *direct = LCAICloudAppBundleImage(trim);
        if (direct) {
            return direct;
        }
    }
    NSString *typeForKey = LCAIQLTagAliasToCanonicalTypeString(trim) ?: trim;
    NSString *key = LCAIQLRnGetAlarmIconAssetKey(typeForKey);
    UIImage *src = LCAICloudAppBundleImage(key);
    if (src) {
        return src;
    }
    if ([key isEqualToString:@"msg_icon_motion_alarm"]) {
        src = LCAICloudAppBundleImage(@"msg_icon_motion_ai");
        if (src) {
            return src;
        }
    }
    src = LCAICloudAppBundleImage(@"msg_icon_default");
    if (src) {
        return src;
    }
    src = LCAICloudAppBundleImage(@"waterfall_icon_default_alarm");
    if (src) {
        return src;
    }
    return LCAICloudAppBundleImage(@"msg_icon_human_alarm");
}

@interface LCAICloudQuickLookSummaryListCell ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *errorContainer;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIView *contentContainer;
/// RN cellTopPart：paddingHorizontal 12, paddingVertical 15
@property (nonatomic, strong) UIView *rnCellTopPart;
/// RN cellTopPart 内横向 row：左 pill + 右 tags（space-between）
@property (nonatomic, strong) UIStackView *rnTopInnerRow;
@property (nonatomic, strong) UIView *headerSpacer;
@property (nonatomic, strong) UIView *timePill;
@property (nonatomic, strong) UIImageView *stateIconView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIStackView *tagStack;
@property (nonatomic, strong) UILabel *summaryLabel;
@end

@implementation LCAICloudQuickLookSummaryListCell

+ (NSString *)summaryListCellReuseIdentifier {
    return kLCAICloudQuickLookSummaryListCellId;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self lc_buildHierarchy];
    }
    return self;
}

- (void)lc_buildHierarchy {
    _cardView = [[UIView alloc] init];
    _cardView.backgroundColor = [UIColor whiteColor];
    _cardView.layer.cornerRadius = 10;
    _cardView.layer.masksToBounds = YES;
    [self.contentView addSubview:_cardView];
    [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(10);
        make.left.equalTo(self.contentView).offset(12);
        make.right.equalTo(self.contentView).offset(-12);
        make.bottom.equalTo(self.contentView);
    }];

    _errorContainer = [[UIView alloc] init];
    [self.contentView addSubview:_errorContainer];
    [_errorContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    _errorLabel = [[UILabel alloc] init];
    _errorLabel.font = [UIFont systemFontOfSize:15];
    _errorLabel.textColor = [UIColor lc_colorWithHexString:@"#666666"];
    _errorLabel.textAlignment = NSTextAlignmentCenter;
    _errorLabel.numberOfLines = 0;
    _errorLabel.text = @"ai_insight_network_error_tap_retry".lcMedia_T;
    [_errorContainer addSubview:_errorLabel];
    [_errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_errorContainer);
        make.left.greaterThanOrEqualTo(_errorContainer).offset(24);
        make.right.lessThanOrEqualTo(_errorContainer).offset(-24);
    }];

    _emptyLabel = [[UILabel alloc] init];
    _emptyLabel.numberOfLines = 0;
    [_cardView addSubview:_emptyLabel];

    _contentContainer = [[UIView alloc] init];
    [_cardView addSubview:_contentContainer];

    _rnCellTopPart = [[UIView alloc] init];
    [_contentContainer addSubview:_rnCellTopPart];

    _rnTopInnerRow = [[UIStackView alloc] init];
    _rnTopInnerRow.axis = UILayoutConstraintAxisHorizontal;
    _rnTopInnerRow.alignment = UIStackViewAlignmentCenter;
    _rnTopInnerRow.spacing = 0;
    _rnTopInnerRow.distribution = UIStackViewDistributionFill;
    [_rnCellTopPart addSubview:_rnTopInnerRow];

    _timePill = [[UIView alloc] init];
    _timePill.layer.cornerRadius = 6;
    _timePill.clipsToBounds = YES;
    [_timePill setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    _stateIconView = [[UIImageView alloc] init];
    _stateIconView.contentMode = UIViewContentModeScaleAspectFit;
    [_timePill addSubview:_stateIconView];

    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:12];
    [_timePill addSubview:_timeLabel];

    [_stateIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_timePill).offset(6);
        make.top.equalTo(_timePill).offset(4);
        make.bottom.equalTo(_timePill).offset(-4);
        make.width.height.mas_equalTo(kQLSummaryStateIconSize);
    }];
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_stateIconView.mas_right).offset(2);
        make.right.equalTo(_timePill).offset(-6);
        make.centerY.equalTo(_stateIconView);
    }];

    _headerSpacer = [[UIView alloc] init];
    [_headerSpacer setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    [_headerSpacer setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];

    _tagStack = [[UIStackView alloc] init];
    _tagStack.axis = UILayoutConstraintAxisHorizontal;
    _tagStack.spacing = 4;
    _tagStack.alignment = UIStackViewAlignmentCenter;
    _tagStack.distribution = UIStackViewDistributionFill;
    [_tagStack setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [_rnTopInnerRow addArrangedSubview:_timePill];
    [_rnTopInnerRow addArrangedSubview:_headerSpacer];
    [_rnTopInnerRow addArrangedSubview:_tagStack];

    _summaryLabel = [[UILabel alloc] init];
    _summaryLabel.numberOfLines = 0;
    [_contentContainer addSubview:_summaryLabel];

    [_contentContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_cardView);
    }];

    [_rnCellTopPart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(_contentContainer);
    }];
    [_rnTopInnerRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_rnCellTopPart).offset(15);
        make.left.equalTo(_rnCellTopPart).offset(12);
        make.right.equalTo(_rnCellTopPart).offset(-12);
        make.bottom.equalTo(_rnCellTopPart).offset(-15);
    }];

    [_summaryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_rnCellTopPart.mas_bottom);
        make.left.equalTo(_contentContainer).offset(12);
        make.right.equalTo(_contentContainer).offset(-12);
        make.bottom.equalTo(_contentContainer).offset(-15);
    }];

    _errorContainer.hidden = YES;
    _cardView.hidden = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in [_tagStack.arrangedSubviews copy]) {
        [_tagStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (NSParagraphStyle *)lc_paragraphStyleLineHeight:(CGFloat)lh alignment:(NSTextAlignment)al {
    NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
    p.minimumLineHeight = lh;
    p.maximumLineHeight = lh;
    p.alignment = al;
    return p;
}

- (void)applyNetworkErrorState {
    self.cardView.hidden = YES;
    self.errorContainer.hidden = NO;
}

- (void)applyEmptySlotWithStartTime:(NSString *)startTime endTime:(NSString *)endTime {
    self.errorContainer.hidden = YES;
    self.cardView.hidden = NO;
    self.emptyLabel.hidden = NO;

    // RN 无摘要：content 不占位，避免与 emptyLabel 同时撑开 cell（此前导致空 cell 过高）
    self.contentContainer.hidden = YES;
    [self.contentContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.cardView);
        make.height.mas_equalTo(0);
    }];

    NSString *txt = [NSString stringWithFormat:@"ai_insight_summary_time_range_no_event".lcMedia_T, startTime ?: @"", endTime ?: @""];
    NSDictionary *attrs = @{
        NSFontAttributeName : [UIFont systemFontOfSize:12],
        NSForegroundColorAttributeName : [UIColor lc_colorWithHexString:@"#8F8F8F"],
        NSParagraphStyleAttributeName : [self lc_paragraphStyleLineHeight:24 alignment:NSTextAlignmentLeft],
    };
    self.emptyLabel.attributedText = [[NSAttributedString alloc] initWithString:txt attributes:attrs];
    [self.emptyLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(15);
        make.left.equalTo(self.cardView).offset(18);
        make.right.equalTo(self.cardView).offset(-18);
        make.bottom.equalTo(self.cardView).offset(-15);
    }];
}

- (void)applyContentWithStartTime:(NSString *)startTime
                            endTime:(NSString *)endTime
                            summary:(NSString *)summary
                           selected:(BOOL)selected
                   tagTypeStrings:(NSArray<NSString *> *)tagStrings {
    self.errorContainer.hidden = YES;
    self.cardView.hidden = NO;
    self.emptyLabel.hidden = YES;
    self.contentContainer.hidden = NO;
    [self.contentContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardView);
    }];

    self.timePill.backgroundColor = selected ? [UIColor colorWithRed:79 / 255.0 green:120 / 255.0 blue:1 alpha:0.1] : [UIColor lc_colorWithHexString:@"#F6F6F6"];
    self.timeLabel.textColor = selected ? [UIColor lc_colorWithHexString:@"#4F78FF"] : [UIColor lc_colorWithHexString:@"#2C2C2C"];
    self.timeLabel.text = [NSString stringWithFormat:@"%@ - %@", startTime ?: @"", endTime ?: @""];

    UIImage *pauseImg = LCAICloudAppBundleImage(@"Event_Summary_List_pause");
    if (pauseImg) {
        pauseImg = [pauseImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    if (selected) {
        UIImage *playImg = LCAICloudAppBundleImage(@"Event_Summary_List_Playing");
        self.stateIconView.image = playImg ?: pauseImg;
        self.stateIconView.tintColor = playImg ? nil : [UIColor lc_colorWithHexString:@"#4570FE"];
    } else {
        self.stateIconView.image = pauseImg;
        self.stateIconView.tintColor = [UIColor lc_colorWithHexString:@"#2C2C2C"];
    }

    for (UIView *v in [self.tagStack.arrangedSubviews copy]) {
        [self.tagStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    // RN: tagList.map((tag, tagIdx) => resolveIconSource(remoteImages, tag))；style 首个 marginLeft 0、其后 4 → UIStackView.spacing=4
    for (id tok in tagStrings) {
        UIImage *img = LCAIQLRnResolveIconSourceForTag(tok);
        if (!img) {
            continue;
        }
        UIImageView *iv = [[UIImageView alloc] initWithImage:img];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(kQLSummaryTagIconSize);
        }];
        [self.tagStack addArrangedSubview:iv];
    }

    UIColor *sumColor = selected ? [UIColor lc_colorWithHexString:@"#4F78FF"] : [UIColor lc_colorWithHexString:@"#2C2C2C"];
    NSDictionary *attrs = @{
        NSFontAttributeName : [UIFont systemFontOfSize:16],
        NSForegroundColorAttributeName : sumColor,
        NSParagraphStyleAttributeName : [self lc_paragraphStyleLineHeight:24 alignment:NSTextAlignmentLeft],
    };
    self.summaryLabel.attributedText = [[NSAttributedString alloc] initWithString:(summary ?: @"") attributes:attrs];
}

+ (nullable UIImage *)ql_resolvedImageForTagItem:(id)tag {
    return LCAIQLRnResolveIconSourceForTag(tag);
}

@end
