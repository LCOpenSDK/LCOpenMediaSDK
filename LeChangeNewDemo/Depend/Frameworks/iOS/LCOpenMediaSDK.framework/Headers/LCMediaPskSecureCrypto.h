//
//  LCMediaPskSecureCrypto.h
//  LCMediaComponents
//
//  Core 层 PSK 后缀等敏感串的 AES-256-GCM 解密（不依赖 LCEncryption）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCMediaPskSecureCrypto : NSObject

/// 解密 Base64(ciphertext||tag) 载荷，成功返回 UTF-8 明文。
+ (nullable NSString *)decryptGCMBase64Payload:(NSString *)base64Payload;

@end

NS_ASSUME_NONNULL_END
