//
//  BaseTabarViewController.swift
//  jsrouterdemo
//
//  Created by zhangzt on 2017/12/13.
//  Copyright © 2017年 zhangzt. All rights reserved.
//

import UIKit
import JLRoutes

class BaseTabarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        let test1 = OneViewController()

        let nav1 = BaseNavViewController.init(rootViewController: test1)
        nav1.tabBarItem.title = "test1"

        self.addChildViewController(nav1)


        let test2 = TwoViewController()

        let nav2 = BaseNavViewController.init(rootViewController: test2)
        nav2.tabBarItem.title = "test2"

        self.addChildViewController(nav2)


        let test3 = ThreeViewController()

        let nav3 = BaseNavViewController.init(rootViewController: test3)
        nav3.tabBarItem.title = "test3"

        self.addChildViewController(nav3)


        JLRoutes.global().addRoute("/:toController/:paramOne/:paramTwo/:paramThree/:paramFour") { (dic) -> Bool in

            guard let viewstring = dic["toController"] as?String else {

                print("错误toController")
                return false
            }


            let cla = NSClassFromString("jsrouterdemo." + viewstring) as? UIViewController.Type

            guard let clsscontroller = cla else {

                print("错误jsrouterdemo")

                return false
            }

            let vc:UIViewController = clsscontroller.init()

            guard let headUrl = dic[JLRouteURLKey] as? NSURL else {

                print("错误headUrl")

                return false
            }


            guard let head = headUrl.absoluteString?.components(separatedBy: "://").first else {

                print("错误head")

                return false
            }




          let ro =  UIApplication.shared.keyWindow?.rootViewController

            ro?.present(vc, animated: true, completion: nil)



            return true

            if (  head == "JLRoutesOne") {
                nav1.pushViewController(vc, animated: true)
            }else if (head == "JLRoutesTwo"){
                nav2.pushViewController(vc, animated: true)
            }else if(head == "JLRoutesThree"){
                nav3.pushViewController(vc, animated: true)
            }


            return true
        }



    }


}
