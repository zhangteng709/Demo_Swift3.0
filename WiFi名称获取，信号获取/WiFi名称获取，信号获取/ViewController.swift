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

