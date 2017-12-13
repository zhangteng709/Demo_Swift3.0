//
//  CustomCameraViC.swift
//  Lex
//
//  Created by nbcb on 2017/3/14.
//  Copyright © 2017年 ZQC. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import CoreImage

class CustomCameraViC: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    

    fileprivate lazy var imgView : UIImageView = UIImageView()

    var previewView: LWVideoPreview!
    // 相机管理器
    lazy var cameraController: DCCameraAlbum = {

       return DCCameraAlbum(previewView: self.previewView, focusImageView: self.imgView, audioEnabled: false)
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIApplication.shared.isStatusBarHidden = true

        // 开始捕捉视图
        cameraController.startRunning()

    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraController.stopRunning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }






    override func viewDidLoad() {

        view.backgroundColor = UIColor.white

        setUpNav()
        initAVCapture()

        setUpUI()

    }

    func initAVCapture() {

        let cameraView = LWVideoPreview.init()
        cameraView.frame = CGRect(x: 0, y: 0, width: self.view.width, height: self.view.height - 230)
        view.addSubview(cameraView)
        //启动照相机
                let focusView = UIImageView.init(image: UIImage.init(named: "QRCode_ScanBox"))
                focusView.size = CGSize(width: 80, height: 80)
                cameraView.addSubview(focusView)
                focusView.center = cameraView.center
        self.imgView = focusView
        self.previewView = cameraView


    }
    func setUpUI()  {
        let bottomview = UIView.init(frame: CGRect(x: 0, y: self.view.height - 230 - 64, width: self.view.width, height: 230))
        view.addSubview(bottomview)
        bottomview.backgroundColor = UIColor.brown
        let leftbtn = UIButton.init(frame: CGRect(x: 30, y: 180, width: 50, height: 50))
        bottomview.addSubview(leftbtn)
        leftbtn.tag = 90
        leftbtn.backgroundColor = UIColor.orange
        leftbtn.layer.cornerRadius = 25

        leftbtn.addTarget(self, action: #selector(featureswithBtn(sender:)), for: .touchUpInside)

        let centenrbtn = UIButton.init(frame: CGRect(x: self.view.width / 2 - 25, y: 180, width: 50, height: 50))
        bottomview.addSubview(centenrbtn)
        centenrbtn.tag = 91
        centenrbtn.backgroundColor = UIColor.gray
        centenrbtn.layer.cornerRadius = 25

        centenrbtn.addTarget(self, action: #selector(featureswithBtn(sender:)), for: .touchUpInside)

        let rightbtn = UIButton.init(frame: CGRect(x: self.view.width - 80, y: 180, width: 50, height: 50))
        bottomview.addSubview(rightbtn)
        rightbtn.tag = 92
        rightbtn.backgroundColor = UIColor.green
        rightbtn.layer.cornerRadius = 25
        rightbtn.addTarget(self, action: #selector(featureswithBtn(sender:)), for: .touchUpInside)


    }

    func featureswithBtn(sender:UIButton) -> () {


        switch sender.tag {
        case 90:break
        case 91:
            takephotos()
        case 92:break
        default:
            break
        }


    }


    func takephotos() {
        // 拍照并保存至相册
        cameraController.snapStillImage(withFlashMode: .off) { (imageData, error) in
            if let data = imageData {
                if let image = UIImage(data: data as Data) {
                    // Save to Album
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                print(error?.localizedDescription ?? "出现错误！")
            }
        }

        // 录像并保存至相册
        if cameraController.isRecording() {
            cameraController.stopMovieRecording({
                [unowned self] (captureOutput, outputFileURL, connections, error) in

                print("end recording: \(outputFileURL)")
                // Save to Album
                let assetsLibrary = ALAssetsLibrary()
                assetsLibrary.writeVideoAtPath(toSavedPhotosAlbum: outputFileURL, completionBlock: { (assertURL: URL?, error: Error?) in
                    if error != nil {
                        print("视频保存出错：\(error)")
                    } else {
                        print("视频保存成功")
                    }
                    do {
                        try FileManager.default.removeItem(at: outputFileURL)
                        self.dismiss(animated: true, completion: nil)
                    } catch {
                        let nserror = error as NSError
                        print(nserror.localizedDescription)
                    }
                })
            })

        } else {
            let tmpFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("myMovie.mov")
            cameraController.startMovieRecording(outputFilePath: tmpFilePath, startRecordingHandler: { (captureOutput, connections) in
                print("start recording")
            })
        }
    }


}

extension CustomCameraViC {

    func setUpNav()  {

        self.navigationController?.navigationBar.isTranslucent = false
        let leftitem =  UIBarButtonItem(image: UIImage.init(named: "cross"), style: UIBarButtonItemStyle.done, target: self, action: #selector(onClickBtn(sender:)))
        self.navigationItem.leftBarButtonItem = leftitem



        let cameraType = UIBarButtonItem(image: UIImage.init(named: "flip"), style: UIBarButtonItemStyle.done, target: self, action: #selector(cameraType(_ : )))


        let lightbtn = UIButton.init(type: .custom)


        
        let switchLight = UIBarButtonItem(image: UIImage.init(named: "flash"), style: UIBarButtonItemStyle.done, target: self, action: #selector(switchLight(_ :)))

        switchLight.setBackButtonBackgroundImage(UIImage.init(named: "flash"), for: .normal, barMetrics: .default)
        switchLight.setBackButtonBackgroundImage(UIImage.init(named: "flash-on"), for: .selected, barMetrics: .default)

        self.navigationItem.rightBarButtonItems = [switchLight,cameraType]

    }





    func onClickBtn(sender: UIButton){

        self.dismiss(animated: true) {

        }

    }

    //闪关灯
    func switchLight(_ sender: UIButton) {

        sender.isSelected = !sender.isSelected
        sender.setImage(UIImage.init(named: "flash"), for: .normal)
        sender.setImage(UIImage.init(named: "flash-on"), for: .selected)
    }



    //镜头方向
    func cameraType(_ sender: UIButton) {


        // 切换摄像头
        switch cameraController.currentCameraPosition() {
        case .back:
            cameraController.toggleCamera(.front)
        case .front:
            cameraController.toggleCamera(.back)
        default:
            cameraController.toggleCamera(.back)
        }

    }
}

