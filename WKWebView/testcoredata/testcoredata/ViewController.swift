//
//  BannerViewController.swift
//  CalledSeed
//
//  Created by  光合种子 on 2016/11/18.
//  Copyright © 2016年  光合种子. All rights reserved.
//

import UIKit
import JavaScriptCore
import WebKit



class ViewController: UIViewController,WKNavigationDelegate,WKScriptMessageHandler {
    
    
    var webView:WKWebView!
    
    var url:String! = "http://www.yilongzc.com/m/oldnew/old?appSource=True&msn=g38b2f5ff47436671b6e533d8dc3614845d"
    
    var jsContext:JSContext!
    
    
    var progressView:UIProgressView!
    
    

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        
        
        
        
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        self.view.backgroundColor = .white
        
        
        // 创建webveiew
        // 创建一个webiview的配置项
        let configuretion = WKWebViewConfiguration()
        
        // Webview的偏好设置
        configuretion.preferences = WKPreferences()
        configuretion.preferences.minimumFontSize = 10
        configuretion.preferences.javaScriptEnabled = true
        // 默认是不能通过JS自动打开窗口的，必须通过用户交互才能打开
        configuretion.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // 通过js与webview内容交互配置
        configuretion.userContentController = WKUserContentController()
        let script = WKUserScript(source: "function sharefunction(url, title, desc, image) { window.webkit.messageHandlers.sharefunction.postMessage([url,title,desc,image]); }",
                                  injectionTime: .atDocumentStart,// 在载入时就添加JS
            forMainFrameOnly: true) // 只添加到mainFrame中
        configuretion.userContentController.addUserScript(script)
        // 添加一个JS到HTML中，这样就可以直接在JS中调用我们添加的JS方法
//        let js = "window.platform = 'ios'; window.ios={appLogin:function(){window.webkit.messageHandlers.appLogin.postMessage({body: 'appLogin'});}};"
//        let sharescript = WKUserScript(source: js,
//                                       injectionTime: .atDocumentEnd,// 在载入时就添加JS
//            forMainFrameOnly: true) // 只添加到mainFrame中
//        configuretion.userContentController.addUserScript(sharescript)
//        
//        // 添加一个名称，就可以在JS通过这个名称发送消息：
//        configuretion.userContentController.add(self, name: "appLogin")
        
//        configuretion.userContentController.add(self, name: "sharefunction")
//        configuretion.userContentController.add(self, name: "Loginsuccess")
//        
//        let jsone = "window.platform = 'ios';"
//        let sharescript111 = WKUserScript(source: jsone,
//                                       injectionTime: .atDocumentEnd,// 在载入时就添加JS
//            forMainFrameOnly: true) // 只添加到mainFrame中
//        configuretion.userContentController.addUserScript(sharescript111)
        
        let js = "window.platform = 'ios';window.ios={appLogin:function(){window.webkit.messageHandlers.appLogin.postMessage({body: 'appLogin'});},sharefunction:function(urlt,image,ima,ttt){ var dict = [urlt,image,ima,ttt]; window.webkit.messageHandlers.sharefunction.postMessage(dict);},Loginsuccess:function(url){window.location.href=url;}}; "
        
//        let js = "window.ios={appLogin:function(){window.webkit.messageHandlers.appLogin.postMessage({body: 'appLogin'});},sharefunction:function(url, title, desc, image){window.webkit.messageHandlers.sharefunction.postMessage({url,title,desc,image});},Loginsuccess:function(url){window.location.href=url;}}"
        let sharescript = WKUserScript(source: js,
                                       injectionTime: .atDocumentEnd,// 在载入时就添加JS
            forMainFrameOnly: true) // 只添加到mainFrame中
        configuretion.userContentController.addUserScript(sharescript)
        
        // 添加一个名称，就可以在JS通过这个名称发送消息：
        configuretion.userContentController.add(self, name: "appLogin")
        
        configuretion.userContentController.add(self, name: "sharefunction")
        configuretion.userContentController.add(self, name: "Loginsuccess")
        

        
        
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), configuration: configuretion)
        
        //        webView.uiDelegate =  self
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        
        
        
//        let path = Bundle.main.path(forResource: "yaoqing", ofType: "htm")
//        
//        let localurl = URL.init(fileURLWithPath: path!)
//        
//        if #available(iOS 9.0, *) {
//            webView.loadFileURL(localurl, allowingReadAccessTo: localurl)
//        } else {
//            // Fallback on earlier versions
//            
//            webView.load(URLRequest.init(url: localurl))
//            
//        }

       webView.load(URLRequest.init(url: URL.init(string: url)!))

        //打开左划回退功能
        webView.allowsBackForwardNavigationGestures = true
        
        // Do any additional setup after loading the view.
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        
        
        
        
        
        
        
        // 添加进入条
        self.progressView =  UIProgressView(progressViewStyle: .default)
        self.progressView.frame.size.width = self.view.frame.size.width
        self.progressView.backgroundColor = UIColor.red
        self.view.addSubview(self.progressView)
    }
    
    
    func test()  {
        
        print("111111111111")
        
    }
    
    
    //MARK:-KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //[keyPath isEqualToString:@"loading"]
        if (keyPath == "loading") {
            // print("loading")
        } else if (keyPath == "estimatedProgress") {
            
            // print("progress: %f", webView.estimatedProgress)
            self.progressView.progress = Float(webView.estimatedProgress)
            
            if webView.estimatedProgress  > 0.82 {
                
                progressView.progress = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(0.5)) {
                    
                    self.progressView.isHidden = true
                    
                }
            }
            
        }
        
        //$('a[data-login]').click(function(){window.webkit.messageHandlers.sharefunc.postMessage({body: [url,title,desc,image]});}
        
        // 加载完成
        if (!webView.isLoading ) {
            // 手动调用JS代码
//             每次页面完成都弹出来，大家可以在测试时再打开
            
            

            
            
            UIView.animate(withDuration: 0.55, animations: { () -> Void in
                self.progressView.alpha = 0.0;
            })
            
        }
        
        
        
        
    }
    
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    
    
    
    func handleCustomAction(urlstr:URL) -> Bool
    {
        
        
        
        
        return true
        
    }
    
    //MARK:-分享
    func shareAction(button:UIButton){
        
        
    }
    
    
    
    
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    
    
    //MARK:-wkdelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        
        let path = webView.url?.absoluteString
        
        let  newPath = path?.lowercased()
        
        if ((newPath?.hasPrefix("sms:")) ?? false || (newPath?.hasPrefix("tel:")) ?? false ) {
            
            let  app = UIApplication.shared
            if (app.canOpenURL(URL.init(string: newPath ?? "")!)) {
                
                let telstring = newPath!.replacingOccurrences(of: "tel:", with: "")
                
                let alert = UIAlertController(title: "提示", message: "确定拨打电话：\(telstring) 吗？", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .default, handler: { (_) -> Void in
                    
                }))
                alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: { (_) -> Void in
                    
                    app.openURL(URL.init(string: newPath ?? "")!)

                    
                }))

               self.present(alert, animated: true, completion: nil)
            }
            return;
        }
        
        if webView.url?.absoluteString.contains("/plan/") ?? false && webView.url?.absoluteString.contains(".html") ?? false {
            
            let urlString = NSString.init(string: webView.url?.absoluteString ?? "")
            
            let start = urlString.range(of: "plan/")
            let end = urlString.range(of: ".html")
            
            let range = NSRange.init(location: (start.location + start.length), length: end.location - start.location - start.length)
            
            let idstr = urlString.substring(with: range)
            
            
            webView.stopLoading()
        }
        
        if webView.url?.absoluteString.contains("integral/myprize.html") ?? false {  //  查看奖品
            return
        }
    }
    
    
    
    //  加载完成
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        progressView.progress = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(0.5)) {
            
            self.progressView.isHidden = true
            
        }
//              let js = "callJsAlert(){}";
//        //      self.webView.evaluateJavaScript(js) { (_, _) -> Void in
//        //        print("call js alert")
//        //      }18612316312
////        let js = "function sharefunction(url, title, desc, image) { window.webkit.messageHandlers.appmodel.postMessage({body: [url,title,desc,image]}); }"
//        
//        self.webView.evaluateJavaScript(js) { (dost, errr) in
//            
//            print("方法执行了" + self.webView.description)
//            print(dost ?? "不能解析")
//            print(errr ?? "不能解析111")
//
//        }
        
//        // 发送POST的参数
//        let postData = "\"username\":\"aaa\",\"password\":\"123\""
//        // 请求的页面地址
//        let urlStr = "http://www.postexample.com"
//        // 拼装成调用JavaScript的字符串
//        let jscript = "post('\(urlStr)', {\(postData)});"
//        // 调用JS代码
//        webView.evaluateJavaScript(jscript) { (object, error) in
//                        print("方法执行了" + self.webView.description)
//                        print(object ?? "不能解析")
//                        print(error ?? "不能解析111")
//        }

        
//        //加载完成之后开始注入js事件
//        [self.webView stringByEvaluatingJavaScriptFromString:@"\
//        function imageClickAction(){\
//            var imgs=document.getElementsByTagName('img');\
//            var length=imgs.length;\
//            for(var i=0;i<length;i++){\
//                img=imgs[i];\
//                img.onclick=function(){\
//                    window.location ='image-preview:'+this.src;\
//                }\
//            }\
//        }\
//        "];
//        //触发方法 给所有的图片添加onClick方法
//        [self.webView stringByEvaluatingJavaScriptFromString:@"imageClickAction();"];
        
        
    }
    
    
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("失败")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        //  print("内容开始返回时调用")
        
        
    }
    
    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        
       print(message.body)
        
        if message.name == "appmodel" {
            
            print("appmodel")
            
        }
        
        if message.name == "sharefunc" {
            print("sharefunc")
 
        }
        if message.name == "Loginsuccess" {
            print("Loginsuccess")
            
        }
    }
    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        completionHandler()

        
//        let alert = UIAlertController(title: "Tip", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) -> Void in
//            // We must call back js
//        }))
//        
//        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - WKNavigationDelegate
    
    // 决定导航的动作，通常用于处理跨域的链接能否导航。WebKit对跨域进行了安全检查限制，不允许跨域，因此我们要对不能跨域的链接
    // 单独处理。但是，对于Safari是允许跨域的，不用这么处理。
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // print(#function)
        
        let hostname = (navigationAction.request as NSURLRequest).url
        
        if  self.handleCustomAction(urlstr: hostname!) {
            
            self.progressView.alpha = 1.0
            decisionHandler(.allow)
            
        }else {
            decisionHandler(.cancel)
            
        }
        
        
    }
    
    
    
}
