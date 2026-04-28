//
//  Copyright © 2016年 Imou. All rights reserved.
//

#import <LCBaseModule/LCMobileInfo.h>
#include <sys/sysctl.h>
#import <LCBaseModule/LCUDIDTool.h>
#import <LCBaseModule/LCNetWorkHelper.h>

@implementation LCMobileInfo

+ (instancetype)sharedInstance {
	static dispatch_once_t onceToken;
	static LCMobileInfo *_sharedInstance;
	dispatch_once(&onceToken, ^{
		_sharedInstance = [[self alloc] init];
	});
	
	return _sharedInstance;
}

- (NSString *)UUIDString
{
    return [LCUDIDTool shareInstance].UDIDString;
}

- (CGRect)mainScreenRect
{
    CGRect rect;
    rect = [UIScreen mainScreen].bounds;
    if (rect.size.width > rect.size.height)
    {
        float tem = rect.size.width;
        rect.size.width = rect.size.height;
        rect.size.height = tem;
    }
    return rect;
}

#pragma mark - WIFISSID
- (NSString *)WIFIBSSID
{
    NSDictionary *dic = [self getWIFIDic];
    if (dic == nil) {
        return nil;
    }
    
    return dic[@"BSSID"];
}

- (NSDictionary *)getWIFIDic
{
    @try {
        NSDictionary *d = [[LCNetWorkHelper sharedInstance] currentWiFiInfoSync];
        if (d && d.count) {
            return d;
        }
    } @catch (NSException *exception) {
    }
    return nil;
}

- (NSString *)WIFISSID
{
    NSDictionary *dic = [self getWIFIDic];
    if (dic == nil) {
        return nil;
    }
    
    return dic[@"SSID"];
}

@end
