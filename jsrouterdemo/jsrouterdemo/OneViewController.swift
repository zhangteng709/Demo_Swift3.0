//
//  OneViewController.swift
//  jsrouterdemo
//
//  Created by zhangzt on 2017/12/13.
//  Copyright © 2017年 zhangzt. All rights reserved.
//

import UIKit
import JLRoutes

class OneViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        self.navigationItem.title = "板块1"
        self.view.backgroundColor = UIColor.init(red: 0.3, green: 0.2, blue: 0.2, alpha: 1)


        let btn = UIButton.init(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        btn.backgroundColor = UIColor.red
        btn.layer.cornerRadius = 50
        btn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        view.addSubview(btn)




    }

    @objc func btnAction()  {



        let ur = String.init(format: "%@://%@/%@/%@/%@/%@","JLRoutesOne", "OnePushViewController", "123" , "123", "123", "123")




        print("错误head== ",ur)


        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL.init(string: ur )!, options: ["aa":"bb"], completionHandler: nil)
        } else {

            let urls = URL.init(string: ur )!

            let bo =   UIApplication.shared.openURL(URL.init(string: ur )!)

            print("错误head== ",bo)

        }
    }

}
