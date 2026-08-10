//
//  LCMediaEncryptionProtocol.h
//  LCOpenMediaSDK
//
//  Created by Cursor on 2026/6/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 弱摘要能力由 LCMedia / OpenMedia DiffImpl 分别实现；其余 PSK 逻辑在 Core `LCMediaUtilsInside` 统一处理。
@protocol LCMediaEncryptionProtocol <NSObject>

/// 弱摘要（协议兼容，32 位小写十六进制）；入参为空时返回 nil。
- (nullable NSString *)weakDigestForString:(NSString *)payloadString;

@end

NS_ASSUME_NONNULL_END
