#import "LCAIFrameSelectListCell.h"
#import <LCNetworkModule/LCCloudVideotapeInfo.h>
#import "LCAICloudAppBundleImage.h"
#import <LCMediaBaseModule/UIImageView+LCMediaPicDecoder.h>
#import <LCMediaBaseModule/LCNewDeviceVideoManager.h>
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <Masonry/Masonry.h>
#import <LCBaseModule/UIColor+HexString.h>
#import <SDWebImage/SDWebImage.h>

static NSString *const kLCAIFrameSelectListCellId = @"LCAIFrameSelectListCell";
static const CGFloat kCardH = 194.0;
static const CGFloat kSide = 24.0;
static const CGFloat kRowGap = 12.0;

@interface LCAIFrameSelectListCell ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UIView *playBubble;
@property (nonatomic, strong) UIImageView *playIcon;
@end

@implementation LCAIFrameSelectListCell

+ (NSString *)reuseId {
    return kLCAIFrameSelectListCellId;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self buildUI];
    }
    return self;
}

- (void)buildUI {
    _cardView = [[UIView alloc] init];
    _cardView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    _cardView.layer.cornerRadius = 8;
    _cardView.clipsToBounds = YES;
    [self.contentView addSubview:_cardView];
    [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(kSide);
        make.right.equalTo(self.contentView).offset(-kSide);
        make.height.mas_equalTo(kCardH);
        make.bottom.equalTo(self.contentView).offset(-kRowGap);
    }];

    _coverView = [[UIImageView alloc] init];
    _coverView.contentMode = UIViewContentModeScaleAspectFill;
    _coverView.clipsToBounds = YES;
    [_cardView addSubview:_coverView];
    [_coverView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_cardView);
    }];

    _playBubble = [[UIView alloc] init];
    _playBubble.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    _playBubble.layer.cornerRadius = 28;
    _playBubble.clipsToBounds = YES;
    [_cardView addSubview:_playBubble];
    [_playBubble mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(_cardView);
        make.width.height.mas_equalTo(56);
    }];

    _playIcon = [[UIImageView alloc] init];
    _playIcon.tintColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        UIImage *p = [UIImage systemImageNamed:@"play.fill"];
        if (p) {
            _playIcon.image = [p imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
    _playIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_playBubble addSubview:_playIcon];
    [_playIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_playBubble).offset(2);
        make.centerY.equalTo(_playBubble);
        make.width.height.mas_equalTo(24);
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _coverView.image = nil;
}

- (void)applyWithRecord:(LCCloudVideotapeInfo *)rec tagTypeStrings:(NSArray<NSString *> *)tagStrings {
    (void)tagStrings;
    if (rec.thumbUrl.length) {
        NSString *pid = rec.productId.length ? rec.productId : @"";
        NSLog(@"applyWithRecord--> %@",rec.thumbUrl);
        [self.coverView sd_setImageWithURL:[NSURL URLWithString:rec.thumbUrl] placeholderImage:LCAICloudAppBundleImage(@"common_video_defaultpic_video")];
    } else {
        self.coverView.image = LCAICloudAppBundleImage(@"common_video_defaultpic_video");
    }
}

@end
