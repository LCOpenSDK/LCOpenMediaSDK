#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCAICloudQuickLookCalendarViewController : UIViewController

- (instancetype)initWithDayInfoList:(NSArray<NSDictionary *> *)dayInfoList selectedDate:(nullable NSString *)yyyyMMdd;

@property (nonatomic, copy, nullable) void (^onPickDate)(NSString *yyyyMMdd);
@property (nonatomic, copy, nullable) void (^onCancel)(void);

@end

NS_ASSUME_NONNULL_END
