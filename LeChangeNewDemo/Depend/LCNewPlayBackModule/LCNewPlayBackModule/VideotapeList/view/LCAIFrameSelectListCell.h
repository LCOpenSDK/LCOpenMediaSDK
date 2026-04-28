#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LCCloudVideotapeInfo;

@interface LCAIFrameSelectListCell : UITableViewCell
@property (class, nonatomic, copy, readonly) NSString *reuseId;

- (void)applyWithRecord:(LCCloudVideotapeInfo *)rec tagTypeStrings:(NSArray<NSString *> *)tagStrings;
@end

NS_ASSUME_NONNULL_END
