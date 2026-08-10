//
//  LCOpenPlayTokenModel.h
//  LCMediaComponents
//
//  Created by lei on 2024/10/8.
//

#import <Foundation/Foundation.h>
#import "LCOpenBindDeviceInfo.h"
#import "LCVideoPlayerDefines.h"

@class LCOpenStreamInfo;

NS_ASSUME_NONNULL_BEGIN

/// playToken.accessType：国标设备标识
FOUNDATION_EXPORT NSString * const LCOpenAccessTypeGB28181;
/// 国标实时/对讲强制走私有协议类型（与能力集 RTSV1 同字面量）
FOUNDATION_EXPORT NSString * const LCOpenStreamTypeRTSV1;
/// 国标卡录像/本地录像强制走私有协议类型（与能力集 PBSV1 同字面量）
FOUNDATION_EXPORT NSString * const LCOpenStreamTypePBSV1;

@interface LCOpenPlayTokenModel : NSObject

//管理员token
@property(nonatomic, copy)NSString *accessToken;

// 设备序列号
@property (nonatomic, copy)   NSString  *deviceId;
// 通道号
@property (nonatomic, assign) NSInteger channelId;
/** iot设备产品ID，iot设备必传 */
@property (nonatomic, copy, nullable) NSString *productId;

// 设备接入平台编号：-1-未知平台  0-只支持p2p（netsdk老设备） 1-(海外非pass)接入旧接入平台 2-海外paas设备接入平台 3-国内非pass设备，4-国内pass设备
@property (nonatomic, assign) int platform;
// 设备登录名
@property (nonatomic, copy)   NSString  *devLoginName;
// 设备登录密码
@property (nonatomic, copy)   NSString  *devLoginPassword;

// 设备能力集
@property (nonatomic, copy)   NSString  *ability;
// 设备大类（NVR/DVR/HCVR/IPC/SD/IHG/ARC）
@property (nonatomic, copy)   NSString  *deviceCatalog;
/* 子设备码流加密方式（由 ability / platform 推断；国标 GB28181 固定为 0） */
@property (nonatomic, assign) NSInteger encrypt;
/* 接入类型：playToken.accessType，国标见 LCOpenAccessTypeGB28181 */
@property (nonatomic, copy)   NSString  *accessType;
@property (nonatomic, assign) int       streamPort;
// p2p port
@property (nonatomic, assign) int       p2pPort;
@property (nonatomic, copy) NSString *wssekey;     /** 设备密码摘要盐值P2P */


// 限制并发路数 -1:不限制路数 其它:具体限制数
@property (nonatomic, assign) int     videoLimit;
// 是否跳过回环认证：true-跳过, false-不跳过
@property (nonatomic, copy) NSString  *skipAuth;

// RTSV1:支持私有协议拉流,RTSP:RTSP拉流 参数空默认为RTSP拉流
@property (nonatomic, copy) NSString  *type;
// 所属平台open:开放平台 base:base 平台
@property (nonatomic, copy) NSString  *ownerType;
// project标签  appID：开放平台 base:base App
@property (nonatomic, copy) NSString  *project;
// 获取实时流url的入口地址
@property (nonatomic, copy) NSString  *streamAddr;
// 设备加密模式：0-设备默认加密 1-用户自定义加密
@property (nonatomic, assign) NSInteger encryptMode;
// tls开关
@property (nonatomic, assign) BOOL tlsEnable;

// 新版NVR使用，NVR码流类型
@property (nonatomic, copy) NSString *nvrType;
// 若设备接入新版本NVR，响应该NVR信息
@property (nonatomic, strong) LCOpenBindDeviceInfo *nvrDeviceInfo;
/// 主出流加解密类型（int）：1-子设备凭证；非1-主设备凭证（仅 NVR 主设备出流场景生效）
@property (nonatomic, assign) NSInteger streamEncType;
//（新版NVR使用）NVR/IPC 表示实时预览走的链路
@property (nonatomic, copy) NSString *realLink;
//（新版NVR使用）NVR/IPC 表示语音对讲走的链路
@property (nonatomic, copy) NSString *talkLink;
//（新版NVR使用）NVR/IPC 表示云台控制走的链路
@property (nonatomic, copy) NSString *ptzLink;

//初始化函数
-(instancetype)initWithPlayToken:(NSString *)playToken playTokenKey:(NSString *)playTokenKey deviceId:(NSString *)deviceId channelId:(NSInteger)channelId productId:(nullable NSString *)productId;

/// 拉流是否走私有协议拉流
-(BOOL)isLiveOpt;

/// 对讲是否走私有协议
-(BOOL)isTalkOpt;

/// 卡录像回放支持私有协议
-(BOOL)isDevRecordOpt;

/// 支持共享链路
-(BOOL)isCanReuse;

/// 能力判断
/// - Parameter ability: 相关能力标示字符串
-(BOOL)hasAbility:(NSString *)ability;

/// 是否是海外pass设备
-(BOOL)isPssPlatform;

/// 是否是国内设备
-(BOOL)isLcPlatform;

/// legacy platform type 1 device
-(BOOL)isImsPlatform;

/// 实时是否支持走NVR拉流
-(BOOL)isSupportNVRRealStream;

/// 对讲是否支持走NVR拉流
-(BOOL)isSupportNVRTalkStream;

/// NVR 主设备出流场景下的登录名（非 NVR 主出流返回 devLoginName）
- (NSString *)devLoginNameForStreamOnNVRLink:(BOOL)isMainDeviceStreamOnNVRLink;
/// NVR 主设备出流场景下的登录密码
- (NSString *)devLoginPasswordForStreamOnNVRLink:(BOOL)isMainDeviceStreamOnNVRLink;
/// NVR 主设备出流场景下的 bindDevice 类型（调用方已确认主设备出流）
- (LCMediaBindDeviceType)bindDeviceTypeForStreamOnNVRLink;

/// 是否国标设备（playToken.accessType == LCOpenAccessTypeGB28181）
- (BOOL)isGbDevice;

/// 拉流地址请求 encrypt 字符串（ability 推断值，NVR 链路取 nvrDeviceInfo.encrypt；国标固定 0）
- (NSString *)streamEncryptStringForNVRLink:(BOOL)isNVRLink;
/// 拉流地址 / commonSDK encrypt 整型值（ability 推断，NVR 链路取 nvrDeviceInfo.encrypt；国标固定 0）
- (NSInteger)streamEncryptModeValueForNVRLink:(BOOL)isNVRLink;
- (BOOL)isTCMStreamEncryptForNVRLink:(BOOL)isNVRLink;

/// 卡录像是否走 NVR 主设备出流（与 LCDeviceVideoPlayer / LCOpenMedia_ApiManager 一致）
- (BOOL)isNVRRecordStreamForRecordType:(LCOpenMediaRecordType)recordType;
/// NVR 主出流时用 nvrDeviceInfo.ability，否则用子设备 ability
- (BOOL)hasAbility:(NSString *)ability forNVRLink:(BOOL)isNVRLink;

@end

NS_ASSUME_NONNULL_END
