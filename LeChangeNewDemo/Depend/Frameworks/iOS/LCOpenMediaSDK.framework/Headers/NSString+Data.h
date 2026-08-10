//
//  NSString+Data.h
//  LCMediaComponents
//
//  Created by lei on 2021/3/23.
//

#import <Foundation/Foundation.h>
#import "LCMediaDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Data)

- (NSString *)lc_weakDigestString;

- (NSString *)hlsDecodeWith:(E_RULE_VERSION)ruleVersion;
/// json转字段；解析失败或非 JSON 对象时返回 nil。
- (nullable NSDictionary *)openMedia_jsonDictionary;

+ (NSString*)transformTimeFromLong:(long)time;
/// 字段转json
+ (NSString *)openMedia_dictionaryToJson:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
