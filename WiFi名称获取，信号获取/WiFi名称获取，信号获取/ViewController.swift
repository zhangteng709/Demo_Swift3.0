//
//  ViewController.swift
//  WiFi名称获取，信号获取
//
//  Created by iOSER on 2018/2/1.
//  Copyright © 2018年 iOSER. All rights reserved.
//

import UIKit
import CoreTelephony
import SystemConfiguration
import NetworkExtension

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       
        getCellInfo()
        
        getWiFiInfo()
        
        getsystemInfo()

    }

    func getsystemInfo()  {
        
//        NSLog(@"获取电池电量(一般用百分数表示,大家自行处理就好)====%f",[GetSystemInfoHelper getBatteryQuantity]);
//        NSLog(@"获取电池状态(UIDeviceBatteryState为枚举类型)====%ld",[GetSystemInfoHelper getBatteryStauts]);
//        NSLog(@"获取总内存大小====%lld",[GetSystemInfoHelper getTotalMemorySize]);
//        NSLog(@"容量转换====%@",[GetSystemInfoHelper fileSizeToString: [GetSystemInfoHelper getTotalMemorySize]]);
//        NSLog(@"IP地址====%@",[GetSystemInfoHelper deviceIPAdress]);
//        NSLog(@"当前手机连接的WIFI名称(SSID)====%@",[GetSystemInfoHelper getWifiName]);
//        NSLog(@"获取当前连接Wi-Fi名称与MAC地址====%@",[GetSystemInfoHelper fetchSSIDInfo]);
//        NSLog(@"获取当前连接Wi-Fi的IP地址====%@",[GetSystemInfoHelper getIPAddress:YES]);
        
        
        print("获取电池电量(一般用百分数表示,大家自行处理就好)====%f",GetSystemInfoHelper.getBatteryQuantity())
        print("获取电池状态(UIDeviceBatteryState为枚举类型)====%ld",GetSystemInfoHelper.getBatteryStauts())
        print("获取总内存大小====%lld",GetSystemInfoHelper.getTotalMemorySize())
        print("容量转换====%@",GetSystemInfoHelper.fileSize(toString: UInt64(GetSystemInfoHelper.getTotalMemorySize())))
        print("IP地址====%@",GetSystemInfoHelper.deviceIPAdress())
        print("当前手机连接的WIFI名称(SSID)====%@",GetSystemInfoHelper.getWifiName())
        print("获取当前连接Wi-Fi名称与MAC地址====%@",GetSystemInfoHelper.fetchSSIDInfo())
        print("获取当前连接Wi-Fi的IP地址====%@",GetSystemInfoHelper.getIPAddress(true))

    }
    
    ///手机所属运营商
    func getCellInfo()  {
        
        let  info = CTTelephonyNetworkInfo.init()
        let carrier = info.subscriberCellularProvider
        
        var mobile = ""
        
        if ((carrier?.isoCountryCode) != nil) {
            
            mobile = carrier?.carrierName ?? "错误啦"
            
        }else {
            mobile  = "无运营商"
            
        }
        
        print(info.currentRadioAccessTechnology ?? "currentRadioAccessTechnolo")
        print(carrier?.mobileNetworkCode ?? "mobileNetworkCode")
        print(carrier?.mobileCountryCode ?? "mobileCountryCode")
        print(carrier?.isoCountryCode ?? "isoCountryCode")
        print(carrier?.carrierName ?? "carrierName")
        
        print(mobile)

    }

    ///wifi信息获取
    func getWiFiInfo()  {
        
        print(WIFITool.getSSIDName())
        print(WIFITool.getMacAdress())

    }
    
}

