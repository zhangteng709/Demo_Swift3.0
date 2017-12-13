//
//  ThreeViewController.swift
//  jsrouterdemo
//
//  Created by zhangzt on 2017/12/13.
//  Copyright © 2017年 zhangzt. All rights reserved.
//

import UIKit
import JLRoutes

class ThreeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        self.navigationItem.title = "板块3"
        self.view.backgroundColor = UIColor.init(red: 0.7, green: 0.3, blue: 0.2, alpha: 1)


        let btn = UIButton.init(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        btn.backgroundColor = UIColor.red
        btn.layer.cornerRadius = 50
        btn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        view.addSubview(btn)




    }

    @objc func btnAction()  {


        let ur = String.init(format: "%@://%@/%@/%@/%@/%@","JLRoutesThree", "ThreePushViewController", "123" , "123", "123", "123")

        UIApplication.shared.openURL(URL.init(string: ur )!)



    }
}
