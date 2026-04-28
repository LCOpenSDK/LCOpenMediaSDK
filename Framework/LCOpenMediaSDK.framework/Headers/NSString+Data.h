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

- (NSString *)lc_MD5String;

- (NSString *)hlsDecodeWith:(E_RULE_VERSION)ruleVersion;
/// json转字段
- (NSDictionary *)openMedia_jsonDictionary;

+ (NSString*)transformTimeFromLong:(long)time;
/// 字段转json
+ (NSString *)openMedia_dictionaryToJson:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
