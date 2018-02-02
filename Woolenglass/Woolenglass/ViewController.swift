//
//  ViewController.swift
//  Woolenglass
//
//  Created by  光合种子 on 2017/8/1.
//  Copyright © 2017年 ghzz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.backgroundColor = UIColor.white
        
        let v = UIView.init(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        
        v.backgroundColor = UIColor.red
        view.addSubview(v)
        
        view.addSubview(visualEffectView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private lazy var visualEffectView: UIVisualEffectView = {
        let effect = UIBlurEffect.init(style: .dark)
        let view = UIVisualEffectView.init(effect: effect)
        view.frame = self.view.bounds
        return view
    }()
}

