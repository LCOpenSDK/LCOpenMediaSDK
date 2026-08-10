//
//  Copyright © 2020 Imou. All rights reserved.
//

#import "LCNewLandscapeControlView.h"
#import "LCNewLivePreviewPresenter+LandscapeControlView.h"
#import "LCNewLandscapeControlView+Gesture.h"
#import <LCMediaBaseModule/NSString+MediaBaseModule.h>
#import <LCMediaBaseModule/UIColor+MediaBaseModule.h>
#import <LCMediaBaseModule/LCMediaBaseDefine.h>
#import <Masonry/Masonry.h>
#import <KVOController/KVOController.h>

/// 长序列号标题最小缩放比例
static const CGFloat kLCLandscapeTitleMinScale = 0.7;
/// 标题相对返回按钮/右边距的间距
static const CGFloat kLCLandscapeTitleSidePadding = 8.0;
static const CGFloat kLCLandscapeTitleTrailingPadding = 20.0;

@interface LCNewLandscapeControlView ()

@property (strong,nonatomic) UIView * topView;

@property (strong,nonatomic) UIView * bottomView;

//底部控制按钮
@property (strong, nonatomic) NSMutableArray *items;

//@property (strong,nonatomic)UILabel * startLab;
//
//@property (strong,nonatomic)UILabel * endLab;

////单击手势
//@property(nonatomic, strong) UITapGestureRecognizer *clickGesture;
//
////双击手势
//@property(nonatomic, strong) UITapGestureRecognizer *doubleClickGesture;
//
////长按手势
//@property(nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
//
////滑动手势
//@property(nonatomic, strong) UIPanGestureRecognizer *panGesture;
//
////缩放手势
//@property(nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;

@property(nonatomic, strong) UILabel * titleLab;

@end

@implementation LCNewLandscapeControlView


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView* hitView = [super hitTest:point withEvent:event];
    if ([hitView isKindOfClass:LCNewLandscapeControlView.class]) {
        return nil;
    }
    return hitView;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        //添加手势
//        self.clickGesture = [UITapGestureRecognizer new];
//        self.doubleClickGesture = [UITapGestureRecognizer new];
//        self.longPressGesture = [UILongPressGestureRecognizer new];
//        self.panGesture = [UIPanGestureRecognizer new];
//        self.pinchGesture = [UIPinchGestureRecognizer new];
//        [self addTheGestureRecognizer];
//        [self setPinchEnable:YES];
    }
     return self;
}

-(NSMutableArray *)items{
    if (!_items) {
        _items = [self.delegate currentButtonItem];
    }
    return _items;
}
-(void)setPresenter:(LCNewLivePreviewPresenter *)presenter{
    _presenter = presenter;
    [self setupView];
}
-(void)changeAlpha{
    [UIView animateWithDuration:0.3 animations:^{
        self.topView.alpha =  self.topView.alpha==1 ? 0 : 1;
        self.bottomView.alpha =  self.bottomView.alpha==1 ? 0 : 1;
    }];
}
-(void)setupView{
    weakSelf(self);
    //顶部视图
    UIView * topView= [UIView new];
    self.topView = topView;
    [self addSubview:topView];
    topView.backgroundColor = [UIColor lc_colorWithHexString:@"#7F000000"];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(self);
        make.height.mas_equalTo(40);
    }];
    //返回按钮
    LCButton * portrait = [LCButton createButtonWithType:LCButtonTypeCustom];
    [topView addSubview:portrait];
    [portrait setTintColor:[UIColor lc_colorWithHexString:@"#FFFFFF"]];
    [portrait setImage:LC_IMAGENAMED(@"common_icon_backarrow_white") forState:UIControlStateNormal];
    [portrait mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(topView.mas_left).offset(20);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(40);
        make.centerY.mas_equalTo(topView.mas_centerY);
    }];
    portrait.touchUpInsideblock = ^(LCButton * _Nonnull btn) {
        [weakself.delegate naviBackClick:btn];
    };
    
    //序列号显示（国标等长 SN：限宽 + 中间截断，避免撑破顶栏）
    self.titleLab = [UILabel new];
    self.titleLab.text = [self.delegate currentTitle];
    self.titleLab.textColor = [UIColor lc_colorWithHexString:@"#FFFFFF"];
    self.titleLab.textAlignment = NSTextAlignmentCenter;
    self.titleLab.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.titleLab.adjustsFontSizeToFitWidth = YES;
    self.titleLab.minimumScaleFactor = kLCLandscapeTitleMinScale;
    [topView addSubview:self.titleLab];
    [self.titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(topView.mas_centerY);
        make.centerX.mas_equalTo(topView.mas_centerX);
        make.leading.mas_greaterThanOrEqualTo(portrait.mas_trailing).offset(kLCLandscapeTitleSidePadding);
        make.trailing.mas_lessThanOrEqualTo(topView.mas_trailing).offset(-kLCLandscapeTitleTrailingPadding);
    }];
    
    //底部视图
    UIView * bottomView= [UIView new];
    self.bottomView = bottomView;
    [self addSubview:bottomView];
    bottomView.backgroundColor = [UIColor lc_colorWithHexString:@"#7F000000"];
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.mas_equalTo(self);
        make.height.mas_equalTo(70);
    }];
    
    int index = 0;
    while (index<self.items.count) {
        LCButton * btn = self.items[index];
        [bottomView addSubview:btn];
        index++;
    }
    [self.items mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedItemLength:30 leadSpacing:120 tailSpacing:120];
    [self.items mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(bottomView.mas_top).offset(10);
        make.width.height.mas_equalTo(30);
    }];
}

- (void)refreshTitle:(NSString *)title {
    self.titleLab.text = title;
}

- (void)dealloc {
    NSLog(@" 💔💔💔 %@ dealloced 💔💔💔", NSStringFromClass(self.class));
}

@end
