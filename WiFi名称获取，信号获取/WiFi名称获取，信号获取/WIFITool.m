//
//  WIFITool.m
//  WiFi名称获取，信号获取
//
//  Created by iOSER on 2018/2/1.
//  Copyright © 2018年 iOSER. All rights reserved.
//

#import "WIFITool.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation WIFITool

+(NSString *)getMacAdress {
    NSArray * ifs = CFBridgingRelease(CNCopySupportedInterfaces());
    
    id info = nil;
    
    for (NSString * ifnm in ifs) {
        
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((CFStringRef)ifnm);
        
        if (info && [info count]) {
            break;
        }
    }
    NSDictionary * dic = (NSDictionary *) info;
    
    NSString * ssid = [dic[@"SSID"] lowercaseString];
    NSString * bssid = dic[@"BSSID"];
    
    NSLog(@"ssid== %@  \n bssid == %@",ssid,bssid);
    return bssid;
    
    
}

+(NSString *)getSSIDName {
    
    NSArray * ifs = CFBridgingRelease(CNCopySupportedInterfaces());

    id info = nil;
    
    for (NSString * ifnm in ifs) {
        
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((CFStringRef)ifnm);
        
        if (info && [info count]) {
            break;
        }
    }
    NSDictionary * dic = (NSDictionary *) info;
    
    NSString * ssid = [dic[@"SSID"] lowercaseString];
    NSString * bssid = dic[@"BSSID"];
    
    NSLog(@"ssid== %@  \n bssid == %@",ssid,bssid);
    return ssid;
}


@end
