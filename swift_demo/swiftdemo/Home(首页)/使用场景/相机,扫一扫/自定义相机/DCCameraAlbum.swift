//
//  DCCameraAlbum.swift
//  DCCameraAlbum
//
//  Created by point on 2016/11/28.
//  Copyright © 2016年 dacai. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

struct Platform {
    
    static let isSimulator: Bool = {
        
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

enum flashMode:Int {
    
    case off
    case on
    case auto
}

private var SessionQueue = "SessionQueue"
private var VideoDataOutputQueue = "VideoDataOutputQueue"
private var AudioDataOutputQueue = "AudioDataOutputQueue"
private let NotAuthorizedMessage = "\(Bundle.main.infoDictionary?["CFBundleDisplayName"] ?? "error") doesn't have permission to use the camera, please change privacy settings"
private let ConfigurationFailedMessage = "Unable to capture media"
private let CancelTitle = "OK"
private let SettingsTitle = "Settings"

private enum LWCamType: Int {
    case `default`
    case metaData
    case videoData
}
typealias StartRecordingHandler = ((_ captureOutput: AVCaptureFileOutput, _ connections: [Any]) -> Void)
typealias FinishRecordingHandler = ((_ captureOutput: AVCaptureFileOutput, _ outputFileURL: URL, _ connections: [Any], _ error: Error) -> Void)
typealias MetaDataOutputHandler = ((_ captureOutput: AVCaptureOutput, _ metadataObjects: [Any], _ connection: AVCaptureConnection) -> Void)
typealias VideoDataOutputHandler = ((_ videoCaptureOutput: AVCaptureOutput?, _ audioCaptureOutput: AVCaptureOutput?, _ sampleBuffer: CMSampleBuffer, _ connection: AVCaptureConnection) -> Void)



private enum LWCamSetupResult: Int {
    case success
    case cameraNotAuthorized
    case sessionConfigurationFailed
}

class DCCameraAlbum: NSObject {
    
    // MARK:- 相机属性
    fileprivate var focusImageView: UIImageView?
    fileprivate let FocusAnimateDuration: TimeInterval = 0.6
    fileprivate var camType: LWCamType = .default


    fileprivate let sessionQueue: DispatchQueue = DispatchQueue(label: SessionQueue, attributes: [])
    fileprivate var setupResult: LWCamSetupResult = .success
    fileprivate var backgroundRecordingID: UIBackgroundTaskIdentifier?
    fileprivate var sessionRunning: Bool = false
    fileprivate var recording: Bool = false
    fileprivate var audioEnabled: Bool = true
    fileprivate var tapFocusEnabled: Bool = true

    fileprivate lazy var metadataObjectTypes: [Any] = { return [Any]() }()

    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    fileprivate var videoDeviceInput: AVCaptureDeviceInput?
    fileprivate var audioDeviceInput: AVCaptureDeviceInput?
    fileprivate var movieFileOutput: AVCaptureMovieFileOutput?
    fileprivate var stillImageOutput: AVCaptureStillImageOutput?
    fileprivate var metaDataOutput: AVCaptureMetadataOutput?
    fileprivate var videoDataOutput: AVCaptureVideoDataOutput?
    fileprivate var audioDataOutput: AVCaptureAudioDataOutput?

    fileprivate var startRecordingHandler: StartRecordingHandler?
    fileprivate var finishRecordingHandler: FinishRecordingHandler?
    fileprivate var metaDataOutputHandler: MetaDataOutputHandler?
    fileprivate var videoDataOutputHandler: VideoDataOutputHandler?

    var inputDevice : AVCaptureDeviceInput!//输入源
    fileprivate lazy var imageOutput : AVCaptureStillImageOutput = AVCaptureStillImageOutput() //输出
    var priviewLayer : AVCaptureVideoPreviewLayer?
    fileprivate var currentView: LWVideoPreview? //管理控制器
    fileprivate var isUsingBackCamera:Bool = true //是否正在使用后置摄像头
    fileprivate var videoInput : AVCaptureDeviceInput?
    fileprivate var currentD :AVCaptureDevice!
    var focusView :UIView! //聚焦的View
    fileprivate var effectiveScale:CGFloat = 1.0 //默认缩放
    fileprivate var beginGestureScale:CGFloat = 1.0 //
    fileprivate let maxScale:CGFloat = 2.0 //最大缩放
    fileprivate let minScale:CGFloat = 1.0 //最小缩放
    
    // MARK:- 相册属性
    fileprivate var dCAlbumItems:[DCAlbumItem] = [] //相册列表
    fileprivate var imageManager:PHCachingImageManager! //带缓存的图片管理对象
    
    //单例
    //        internal static let shareCamera : DCCameraAlbum = {
    //            let camera = DCCameraAlbum()
    //            return camera
    //        }()
    
    //MARK: 单列
    class func shareCamera() -> DCCameraAlbum {
        
        struct single {
            static var manager : DCCameraAlbum? = DCCameraAlbum()
        }
        return single.manager!
    }
    




    // MARK:  Initial

    fileprivate override init() {
        super.init()



        if Platform.isSimulator {
            print("请不要使用模拟器测试")
        }
        else {

            if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            }

            // Check video authorization status
            checkVideoAuthoriztionStatus()

            sessionQueue.async {
                guard self.setupResult == .success else { return }
                self.backgroundRecordingID = UIBackgroundTaskInvalid
            }

            //installCameraDevice() //初始化摄像机
        }



    }

    deinit {
        print("\(NSStringFromClass(DCCameraAlbum.self)) deinit")
    }



}





// MARK:- =============相册
class DCAlbumItem {
    
    //相簿名称
    var title:String?
    //相簿内的资源
    var fetchResult:PHFetchResult<PHAsset>
    init(title:String?,fetchResult:PHFetchResult<PHAsset>){
        self.title = title
        self.fetchResult = fetchResult
    }
}

// MARK: - 获取相册集合
extension DCCameraAlbum {
    
    // MARK: - 获取指定图片
    func getOriginalPicture(picAsset:PHAsset , finishedCallback: @escaping (_ image: UIImage) -> ()) {
        
        PHImageManager.default().requestImage(for: picAsset,
                                              targetSize: PHImageManagerMaximumSize , contentMode: .aspectFit,
                                              options: nil, resultHandler: {
                                                (image, _: [AnyHashable: Any]?) in
                                                finishedCallback(image!)
        })
    }
    
    // MARK: - 获取指定的相册缩略图列表
    func getAlbumItemFetchResults(assetsFetchResults: PHFetchResult<PHAsset> , thumbnailSize: CGSize , finishedCallback: @escaping (_ result : [UIImage] ) -> ()){
        
        cachingImageManager()
        let imageArr = fetchImage(assetsFetchResults: assetsFetchResults, thumbnailSize: thumbnailSize)
        finishedCallback(imageArr)
    }
    
    // MARK: - 获取默认的照相机照片缩略图列表
    func getAlbumItemFetchResultsDefault(thumbnailSize: CGSize , finishedCallback: @escaping (_ result : [UIImage] ) -> ()) {
        
        cachingImageManager()
        let allPhotosOptions = PHFetchOptions()
        
        //按照创建时间倒序排列
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",ascending: false)]
        
        //只获取图片
        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d",PHAssetMediaType.image.rawValue)
        let assetsFetchResults = PHAsset.fetchAssets(with: .image, options: allPhotosOptions)
        let imageArr = fetchImage(assetsFetchResults: assetsFetchResults, thumbnailSize: thumbnailSize)
        finishedCallback(imageArr)
    }
    
    //缓存管理
    fileprivate func cachingImageManager(){
        imageManager = PHCachingImageManager()
        imageManager.stopCachingImagesForAllAssets()
    }
    
    //获取图片
    fileprivate func fetchImage(assetsFetchResults:  PHFetchResult<PHAsset> , thumbnailSize: CGSize) -> [UIImage] {
        
        var imageArr:[UIImage] = []
        for i in 0..<assetsFetchResults.count {
            print(i)
            let asset = assetsFetchResults[i]
            self.imageManager.requestImage(for: asset, targetSize: thumbnailSize,
                                           contentMode: PHImageContentMode.aspectFill,
                                           options: nil) { (image, nfo) in
                                            imageArr.append(image!)
            }
        }
        return imageArr
    }
    
}

// MARK: - 获取相册列表
extension DCCameraAlbum {
    
    func getAlbumItem() -> [DCAlbumItem] {
        
        dCAlbumItems.removeAll()
        let smartOptions = PHFetchOptions()
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                  subtype: PHAssetCollectionSubtype.albumRegular,
                                                                  options: smartOptions)
        self.convertCollection(smartAlbums as! PHFetchResult<AnyObject>)
        
        //列出所有用户创建的相册
        let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        self.convertCollection(userCollections as! PHFetchResult<AnyObject>)
        
        //相册按包含的照片数量排序（降序）
        self.dCAlbumItems.sort { (item1, item2) -> Bool in
            return item1.fetchResult.count > item2.fetchResult.count
        }
        return dCAlbumItems
    }
    
    //转化处理获取到的相簿
    fileprivate func convertCollection(_ collection:PHFetchResult<AnyObject>) {
        
        for i in 0..<collection.count {
            
            //获取出但前相簿内的图片
            let resultsOptions = PHFetchOptions()
            resultsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",
                                                               ascending: false)]
            resultsOptions.predicate = NSPredicate(format: "mediaType = %d",
                                                   PHAssetMediaType.image.rawValue)
            guard let c = collection[i] as? PHAssetCollection else { return }
            let assetsFetchResult = PHAsset.fetchAssets(in: c,options: resultsOptions)
            
            //没有图片的空相簿不显示
            if assetsFetchResult.count > 0 {
                self.dCAlbumItems.append(DCAlbumItem(title: c.localizedTitle, fetchResult: assetsFetchResult ))
            }
        }
    }
}

// MARK:- =============相机
// MARK: - 开始
extension DCCameraAlbum {
    
    func start(view: LWVideoPreview , focusImageView: UIImageView?) {
        
        currentView = view
        view.backgroundColor = UIColor.black
        view.session = session


        setUpGesture() //添加手势
        checkVideoAuthoriztionStatus() ///检测相机权限


        self.focusImageView = focusImageView
        if let focusLayer = focusImageView?.layer {
            focusImageView?.alpha = 0.0
            view.layer.addSublayer(focusLayer)
        }

    }
}

extension DCCameraAlbum {
    // Setup the capture session inputs
    fileprivate func setupCaptureSessionInputs() {

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            self.session.beginConfiguration()

            // Add videoDevice input
            if let videoDevice = DCCameraAlbum.device(mediaType: AVMediaTypeVideo,
                                                           preferringPosition: .back) {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                        if let previewView = self.currentView {
                            // Use the status bar orientation as the initial video orientation.
                            DispatchQueue.main.async(execute: {
                                let videoPreviewLayer = previewView.layer as! AVCaptureVideoPreviewLayer
                                videoPreviewLayer.connection.videoOrientation = DCCameraAlbum.videoOrientationDependonStatusBarOrientation()
                            })
                        }

                    } else {
                        print("Could not add video device input to the session")
                        self.setupResult = .sessionConfigurationFailed
                    }
                } catch {
                    let nserror = error as NSError
                    print("Could not create audio device input: \(nserror.localizedDescription)")
                }
            }

            // Add audioDevice input
            if self.audioEnabled {
                let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
                do {
                    let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                    if self.session.canAddInput(audioDeviceInput) {
                        self.session.addInput(audioDeviceInput)
                        self.audioDeviceInput = audioDeviceInput
                    } else {
                        print("Could not add audio device input to the session")
                    }
                } catch {
                    let nserror = error as NSError
                    print("Could not create audio device input: \(nserror.localizedDescription)")
                }
            }

            self.session.commitConfiguration()
        }
    }

    // Setup the capture session outputs
    fileprivate func setupCaptureSessionOutputs() {

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            self.session.beginConfiguration()

            switch self.camType {
            case .default:
                // Add movieFileOutput
                let movieFileOutput = AVCaptureMovieFileOutput()
                if self.session.canAddOutput(movieFileOutput) {
                    self.session.addOutput(movieFileOutput)
                    let connection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo)
                    // Setup videoStabilizationMode
                    if #available(iOS 8.0, *) {
                        if (connection?.isVideoStabilizationSupported)! {
                            connection?.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.movieFileOutput = movieFileOutput
                } else {
                    print("Could not add movie file output to the session")
                    self.setupResult = .sessionConfigurationFailed
                }

                // Add stillImageOutput
                let stillImageOutput = AVCaptureStillImageOutput()
                if self.session.canAddOutput(stillImageOutput) {
                    stillImageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
                    self.session.addOutput(stillImageOutput)
                    self.stillImageOutput = stillImageOutput
                } else {
                    print("Could not add still image output to the session")
                    self.setupResult = .sessionConfigurationFailed
                }

            case .metaData:
                // Add metaDataOutput
                let metaDataOutput = AVCaptureMetadataOutput()
                if self.session.canAddOutput(metaDataOutput) {
                    self.session.addOutput(metaDataOutput)
                    metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    metaDataOutput.metadataObjectTypes = self.metadataObjectTypes
                    self.metaDataOutput = metaDataOutput
                } else {
                    print("Could not add metaData output to the session")
                    self.setupResult = .sessionConfigurationFailed
                }

            case .videoData:
                // Add videoDataOutput
                let videoDataOutput = AVCaptureVideoDataOutput()
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                if self.session.canAddOutput(videoDataOutput) {
                    self.session.addOutput(videoDataOutput)
                    videoDataOutput.setSampleBufferDelegate(self,
                                                            queue: DispatchQueue(label: VideoDataOutputQueue,
                                                                                 attributes: []))
                    self.videoDataOutput = videoDataOutput

                    // Use the status bar orientation as the initial video orientation.
                    let connection = videoDataOutput.connection(withMediaType: AVMediaTypeVideo)
                    connection?.videoOrientation = DCCameraAlbum.videoOrientationDependonStatusBarOrientation()

                } else {
                    print("Could not add videoData output to the session")
                    self.setupResult = .sessionConfigurationFailed
                }

                // Add audioDataOutput
                let audioDataOutput = AVCaptureAudioDataOutput()
                if self.session.canAddOutput(audioDataOutput) {
                    self.session.addOutput(audioDataOutput)
                    audioDataOutput.setSampleBufferDelegate(self,
                                                            queue: DispatchQueue(label: AudioDataOutputQueue,
                                                                                 attributes: []))
                    self.audioDataOutput = audioDataOutput

                } else {
                    print("Could not add audioData output to the session")
                    self.setupResult = .sessionConfigurationFailed
                }

            }

            self.session.commitConfiguration()
        }
    }


    // MARK:  Target actions

    func focusAndExposeTap(_ sender: UITapGestureRecognizer) {
        guard tapFocusEnabled, let previewView = currentView else { return }

        let layer = previewView.layer as! AVCaptureVideoPreviewLayer
        let devicePoint = layer.captureDevicePointOfInterest(for: sender.location(in: sender.view))

        focus(withMode: .autoFocus,
              exposureMode: .autoExpose,
              atPoint: devicePoint,
              monitorSubjectAreaChange: true)

        if let focusCursor = focusImageView {
            focusCursor.center = sender.location(in: sender.view)
            focusCursor.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            focusCursor.alpha = 1.0
            UIView.animate(withDuration: FocusAnimateDuration,
                           animations: {
                            focusCursor.transform = CGAffineTransform.identity
            }, completion: { (_) in
                focusCursor.alpha = 0.0
            })
        }
    }

}
  // MARK:  Notifications
extension DCCameraAlbum {



    fileprivate func addObservers() {

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(DCCameraAlbum.subjectAreaDidChange(_:)),
                                               name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput?.device)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(DCCameraAlbum.sessionRuntimeError(_:)),
                                               name: NSNotification.Name.AVCaptureSessionRuntimeError,
                                               object: session)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(DCCameraAlbum.deviceOrientationDidChange(_:)),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)
    }

    func subjectAreaDidChange(_ notification: Notification) {

        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(withMode: .autoFocus,
              exposureMode: .autoExpose,
              atPoint: devicePoint,
              monitorSubjectAreaChange: false)
    }

    func sessionRuntimeError(_ notification: Notification) {

        if let error = (notification as NSNotification).userInfo?[AVCaptureSessionErrorKey] as? NSError {
            print("Capture session runtime error: \(error.localizedDescription)")

            if error.code == AVError.Code.mediaServicesWereReset.rawValue {
                self.sessionQueue.async(execute: {
                    if self.sessionRunning {
                        self.session.startRunning()
                        self.sessionRunning = self.session.isRunning
                    }
                })
            }
        }
    }

    func deviceOrientationDidChange(_ notification: Notification) {
        guard !recording else { return }

        // Note that the app delegate controls the device orientation notifications required to use the device orientation.
        let deviceOrientation = UIDevice.current.orientation
        if UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation) {
            // Preview
            if let previewView = currentView {
                let layer = previewView.layer as! AVCaptureVideoPreviewLayer
                let videoOrientation = DCCameraAlbum.videoOrientationDependonStatusBarOrientation()
                if layer.connection.videoOrientation != videoOrientation {
                    layer.connection.videoOrientation = videoOrientation
                }
            }
            // VideoDataOutput
            if let videoDataOutput = videoDataOutput {
                let connect = videoDataOutput.connection(withMediaType: AVMediaTypeVideo)
                let videoOrientation = DCCameraAlbum.videoOrientationDependonStatusBarOrientation()
                if connect?.videoOrientation != videoOrientation {
                    connect?.videoOrientation = videoOrientation
                }
            }
        }
    }



    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK:  Helper methods
extension DCCameraAlbum {




    fileprivate class func device(mediaType type: String, preferringPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {

        if let devices = AVCaptureDevice.devices(withMediaType: type) as? [AVCaptureDevice] {
            var captureDevice = devices.first
            for device in devices {
                if device.position == position {
                    captureDevice = device
                    break
                }
            }
            return captureDevice
        }
        return nil
    }
    fileprivate class func videoOrientationDependonStatusBarOrientation() -> AVCaptureVideoOrientation {

        var inititalVideoOrientation = AVCaptureVideoOrientation.portrait
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            inititalVideoOrientation = .portrait
        case .portraitUpsideDown:
            inititalVideoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            inititalVideoOrientation = .landscapeLeft
        case .landscapeRight:
            inititalVideoOrientation = .landscapeRight
        default:
            break
        }
        return inititalVideoOrientation
    }
}

// MARK: - 结束
extension DCCameraAlbum {
    
    func stop() {
        if session.isRunning == true {
            session.stopRunning()
        }
    }
}

// MARK: - 拍照
extension DCCameraAlbum {
    

    
    //图片中截取图片
    func getImageFromImage(oldImage:UIImage,newImageRect:CGRect) ->UIImage {
        
        let imageRef = oldImage.cgImage;
        let subImageRef = imageRef!.cropping(to: newImageRect);
        return UIImage(cgImage: subImageRef!)
    }
}

// MARK: - 闪光灯
extension DCCameraAlbum {
    
    func flashLamp(mode:flashMode) {
        
        do { try currentD.lockForConfiguration() } catch { }
        if currentD.hasFlash == false { return }
        if mode.rawValue == 0 { currentD.flashMode = .off}
        if mode.rawValue == 1 { currentD.flashMode = .on}
        if mode.rawValue == 2 { currentD.flashMode = .auto}
        
        currentD.unlockForConfiguration()
    }
}

// MARK: - 前后摄像头
extension DCCameraAlbum {
    
    func beforeAfterCamera() {
        
        //获取之前的镜头
        guard var position = videoInput?.device.position else { return }
        
        //获取当前应该显示的镜头
        position = position == .front ? .back : .front
        
        //创建新的device
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else { return }
        
        // 1.2.取出获取前置摄像头
        let d = devices.filter({ return $0.position == position }).first
        currentD = d
        
        //input
        guard let videoInput = try? AVCaptureDeviceInput(device: d) else { return }
        
        //切换
        self.session.beginConfiguration()
        self.session.removeInput(self.videoInput!)
        self.session.addInput(videoInput)
        self.session.commitConfiguration()
        self.videoInput = videoInput
    }
}

// MARK: - 初始化相机相关
extension DCCameraAlbum:UIGestureRecognizerDelegate {
    
    fileprivate func installCameraDevice() {
        
        // 1.创建输入
        // 1.1.获取所有的设备（包括前置&后置摄像头）
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else { return }
        
        // 1.2.取出获取前置摄像头
        guard let d = devices.filter({ return $0.position == .back }).first else{ return}
        self.currentD = d



        // 1.3.通过前置摄像头创建输入设备
        guard let inputDevice = try? AVCaptureDeviceInput(device: d) else { return }
        self.videoInput = inputDevice
        
        //输出
        self.imageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        self.imageOutput.isHighResolutionStillImageOutputEnabled = true
        
        //加入
        if self.session.canAddInput(inputDevice) == true {
            self.session.addInput(self.videoInput)
        }
        
        if self.session.canAddOutput(self.imageOutput) == true {
            self.session.addOutput(self.imageOutput)
        }



//        if let previewView = self.currentView {
//            // Use the status bar orientation as the initial video orientation.
//            DispatchQueue.main.async(execute: {
//                let videoPreviewLayer = previewView.layer as! AVCaptureVideoPreviewLayer
//
//                videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
//            })
//        }
//
//
//        if let previewView = self.currentView {
//            let layer = previewView.layer as! AVCaptureVideoPreviewLayer
//            let videoOrientation = AVCaptureVideoOrientation.portrait
//            if layer.connection.videoOrientation != videoOrientation {
//                layer.connection.videoOrientation = videoOrientation
//            }
//        }
        self.session.commitConfiguration()


        //视图
                self.priviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                self.priviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                //        self.priviewLayer?.videoGravity = AVLayerVideoGravityResizeAspect  //部分大小
                self.priviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait

        //视图
//        self.priviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
//        self.priviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
//        //        self.priviewLayer?.videoGravity = AVLayerVideoGravityResizeAspect  //部分大小
//        self.priviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait

        //闪光灯
        do { try d.lockForConfiguration() } catch { }
        if d.hasFlash == false { return }
        d.flashMode = AVCaptureFlashMode.auto
        d.unlockForConfiguration()






    }
    

    //添加手势 + 缩放 + 聚焦
    fileprivate func setUpGesture() {
        
        let pinGesutre = UIPinchGestureRecognizer(target: self, action: #selector(pinFunc(_:)))
        pinGesutre.delegate = self
        currentView?.addGestureRecognizer(pinGesutre)
        
        let tapGesutre = UITapGestureRecognizer(target: self, action: #selector(tipFunc(_:)))
        currentView?.addGestureRecognizer(tapGesutre)
    }
    
    //添加上聚焦
    @objc func tipFunc(_ ges:UITapGestureRecognizer) {

        guard let previewView = currentView else { return }

        let layer = previewView.layer as! AVCaptureVideoPreviewLayer
        let devicePoint = layer.captureDevicePointOfInterest(for: ges.location(in: ges.view))

        focus(withMode: .autoFocus,
              exposureMode: .autoExpose,
              atPoint: devicePoint,
              monitorSubjectAreaChange: true)

        if let focusCursor = focusImageView {
            focusCursor.center = ges.location(in: ges.view)
            focusCursor.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            focusCursor.alpha = 1.0
            UIView.animate(withDuration: FocusAnimateDuration,
                           animations: {
                            focusCursor.transform = CGAffineTransform.identity
            }, completion: { (_) in
                focusCursor.alpha = 0.0
            })
        }

    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer .isKind(of: UIPinchGestureRecognizer.classForCoder()) {
            beginGestureScale = self.effectiveScale
        }
        return true
    }
    
    //添加缩放
    @objc func pinFunc(_ recognizer:UIPinchGestureRecognizer) {


        guard  let connection = self.stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) else {  return }

        guard  let viewlayer = self.currentView?.layer as? AVCaptureVideoPreviewLayer else {  return }



        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0) {
            self.effectiveScale = 1.0;
        }



        let maxScaleAndCropFactor = connection.videoMaxScaleAndCropFactor




        if  self.effectiveScale > maxScaleAndCropFactor {
            self.effectiveScale = maxScaleAndCropFactor;
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.025)
        viewlayer.setAffineTransform(CGAffineTransform(scaleX: self.effectiveScale, y: self.effectiveScale))


        CATransaction.commit()
    }




    fileprivate func focus(withMode focusMode: AVCaptureFocusMode,
                           exposureMode: AVCaptureExposureMode,
                           atPoint point: CGPoint,
                           monitorSubjectAreaChange: Bool) {

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            if let device = self.videoInput?.device {
                do {
                    try device.lockForConfiguration()
                    // focus
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                        device.focusPointOfInterest = point
                        device.focusMode = focusMode
                    }
                    // exposure
                    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                        device.exposurePointOfInterest = point
                        device.exposureMode = exposureMode
                    }
                    // If subject area change monitoring is enabled, the receiver
                    // sends an AVCaptureDeviceSubjectAreaDidChangeNotification whenever it detects
                    // a change to the subject area, at which time an interested client may wish
                    // to re-focus, adjust exposure, white balance, etc.
                    device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                } catch {
                    let nserror = error as NSError
                    print("Could not lock device for configuration: \(nserror.localizedDescription)")
                }
            }
        }
    }


}

// MARK:- =============权限
extension DCCameraAlbum {
    
    //必须info.plist 配置上这2句
    //Privacy - Camera Usage Description
    //Privacy - Photo Library Usage Description
    /** 相机权限检测 */
    func cameraPermissions() -> Bool {
        
        let authStatus:AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        switch authStatus {
        case .denied , .restricted:
            return false
        case .authorized:
            return true
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: nil)
            return true
        }
    }
    
    /** 相册权限检测 */
    func photoPermissions() -> Bool {
        
        let authStatus:PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch authStatus {
        case .denied , .restricted:
            return false
        case .authorized:
            return true
        case .notDetermined:
            let vc = UIImagePickerController()
            vc.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
            return true
        }
    }

    // Check video authorization status
    fileprivate func checkVideoAuthoriztionStatus() {

        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
                                          completionHandler: { (granted: Bool) in
                                            if !granted {
                                                self.setupResult = .cameraNotAuthorized
                                            }
                                            self.sessionQueue.resume()
            })
        default:
            setupResult = .cameraNotAuthorized
        }
    }


    fileprivate class func setFlashMode(_ flashMode: AVCaptureFlashMode, forDevice device: AVCaptureDevice) {
        guard device.hasFlash && device.isFlashModeSupported(flashMode) else { return }

        do {
            try device.lockForConfiguration()
            device.flashMode = flashMode
            device.unlockForConfiguration()
        } catch {
            let nserror = error as NSError
            print("Could not lock device for configuration: \(nserror.localizedDescription)")
        }
    }

    fileprivate func showAlertView(withMessage message: String, showSettings: Bool) {

        let rootViewController = UIApplication.shared.keyWindow?.rootViewController

        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: nil,
                                                    message: message,
                                                    preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: CancelTitle,
                                             style: .cancel,
                                             handler: nil)
            alertController.addAction(cancelAction)
            if showSettings {
                let settingsAction = UIAlertAction(title: SettingsTitle,
                                                   style: .default,
                                                   handler: { (_) in
                                                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                })
                alertController.addAction(settingsAction)
            }
            rootViewController?.present(alertController,
                                        animated: true,
                                        completion: nil)

        } else {
            let alertView = UIAlertView(title: nil,
                                        message: message,
                                        delegate: nil,
                                        cancelButtonTitle: CancelTitle)
            alertView.show()
        }
    }

}


// 用来显示session捕捉到的画面
class LWVideoPreview: UIView {

    override class var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var session: AVCaptureSession {
        set {
            let previewLayer = layer as! AVCaptureVideoPreviewLayer
            previewLayer.session = newValue
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        }
        get {
            let previewLayer = layer as! AVCaptureVideoPreviewLayer
            return previewLayer.session
        }
    }
}

   // MARK:  ----------Delegate
extension DCCameraAlbum:AVCaptureFileOutputRecordingDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    // MARK:  AVCaptureFileOutputRecordingDelegate

    func capture(_ captureOutput: AVCaptureFileOutput!,
                 didStartRecordingToOutputFileAt fileURL: URL!,
                 fromConnections connections: [Any]!) {

        recording = true
        startRecordingHandler?(captureOutput, connections)
    }

    func capture(_ captureOutput: AVCaptureFileOutput!,
                 didFinishRecordingToOutputFileAt outputFileURL: URL!,
                 fromConnections connections: [Any]!,
                 error: Error!) {

        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskInvalid
            if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }

        recording = false
        finishRecordingHandler?(captureOutput,
                                outputFileURL,
                                connections,
                                error)
    }


    // MARK:  AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputMetadataObjects metadataObjects: [Any]!,
                       from connection: AVCaptureConnection!) {

        metaDataOutputHandler?(captureOutput,
                               metadataObjects,
                               connection)
    }


    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate / AVCaptureAudioDataOutputSampleBufferDelegate

    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {

        if captureOutput == videoDataOutput {
            videoDataOutputHandler?(captureOutput,
                                    nil,
                                    sampleBuffer,
                                    connection)

        } else if captureOutput == audioDataOutput {
            videoDataOutputHandler?(nil,
                                    captureOutput,
                                    sampleBuffer,
                                    connection)
        }

    }

}


// MARK: - ============== Public methods ==============


// MARK: Common

extension DCCameraAlbum {

    /**
     开始捕捉画面
     */
    func startRunning() {
        guard !sessionRunning else { return }

        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.addObservers()
                self.session.startRunning()
                self.sessionRunning = self.session.isRunning

            case .cameraNotAuthorized:
                DispatchQueue.main.async(execute: {
                    self.showAlertView(withMessage: NotAuthorizedMessage, showSettings: true)
                })

            case .sessionConfigurationFailed:
                DispatchQueue.main.async(execute: {
                    self.showAlertView(withMessage: ConfigurationFailedMessage, showSettings: false)
                })
            }
        }
    }

    /**
     结束画面的捕捉
     */
    func stopRunning() {
        guard sessionRunning else { return }

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            self.session.stopRunning()
            self.sessionRunning = self.session.isRunning
            self.removeObservers()
        }
    }



    // MARK:  Camera

    func currentCameraInputDevice() -> AVCaptureDevice? {
        return videoDeviceInput?.device
    }

    func currentCameraPosition() -> AVCaptureDevicePosition {
        return videoDeviceInput?.device.position ?? .unspecified
    }

    /**
     切换摄像头

     - parameter position: 要切换到的摄像头位置
     */
    func toggleCamera(_ position: AVCaptureDevicePosition) {
        guard !recording else {
            print("The session is recording, can not complete the operation!")
            return
        }

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            // Return if it is the same position
            if let currentVideoDevice = self.videoDeviceInput?.device {
                if currentVideoDevice.position == position {
                    return
                }
            }

            if let videoDevice = DCCameraAlbum.device(mediaType: AVMediaTypeVideo,
                                                           preferringPosition: position) {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

                    self.session.beginConfiguration()
                    // Remove old videoDeviceInput
                    if let oldDeviceInput = self.videoDeviceInput {
                        self.session.removeInput(oldDeviceInput)
                    }
                    // Add new videoDeviceInput
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                        print("Could not add movie file output to the session")
                    }
                    self.session.commitConfiguration()
                } catch {
                    let nserror = error as NSError
                    print("Could not add video device input to the session: \(nserror.localizedDescription)")
                    return
                }
            }
        }
    }


    // MARK:  Flash

    func currentFlashAvailable() -> Bool {
        guard let device = currentCameraInputDevice() else { return false }
        return device.isFlashAvailable
    }

    func isFlashModeSupported(_ flashMode: AVCaptureFlashMode) -> Bool {
        guard let device = currentCameraInputDevice() else { return false }
        return device.isFlashModeSupported(flashMode)
    }

    func currentFlashMode() -> AVCaptureFlashMode {
        guard let device = currentCameraInputDevice() else { return .off }
        return device.flashMode
    }


    // MARK:  Torch

    func currentTorchAvailable() -> Bool {
        guard let device = currentCameraInputDevice() else { return false }
        return device.isTorchAvailable
    }

    func isTorchModeSupported(_ torchMode: AVCaptureTorchMode) -> Bool {
        guard let device = currentCameraInputDevice() else { return false }
        return device.isTorchModeSupported(torchMode)
    }

    func currentTorchMode() -> AVCaptureTorchMode {
        guard let device = currentCameraInputDevice() else { return .off }
        return device.torchMode
    }

    func setTorchModeOnWithLevel(_ torchLevel: Float) {
        guard let device = currentCameraInputDevice() , device.isTorchModeSupported(.on) else { return }

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            do {
                try device.lockForConfiguration()
                do {
                    try device.setTorchModeOnWithLevel(torchLevel)
                } catch {
                    let nserror = error as NSError
                    print("Could not set torchModeOn with level \(torchLevel): \(nserror.localizedDescription)")
                }
                device.unlockForConfiguration()
            } catch {
                let nserror = error as NSError
                print("Could not lock device for configuration: \(nserror.localizedDescription)")
            }
        }
    }

    func setTorchMode(_ torchMode: AVCaptureTorchMode) {
        guard let device = currentCameraInputDevice() , device.isTorchModeSupported(torchMode) else { return }

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            do {
                try device.lockForConfiguration()
                device.torchMode = torchMode
                device.unlockForConfiguration()
            } catch {
                let nserror = error as NSError
                print("Could not lock device for configuration: \(nserror.localizedDescription)")
            }
        }
    }

}

// MARK: - MovieFileOutput、StillImageOutput

extension DCCameraAlbum {

    /**
     初始化一个自定义相机，用于普通的拍照和录像

     - parameter view:           预览图层
     - parameter focusImageView: 点击聚焦时显示的图片
     - parameter audioEnabled:   录像时是否具有录音功能

     */
    convenience init(previewView view: LWVideoPreview,
                     focusImageView: UIImageView?,
                     audioEnabled: Bool) {
        self.init()

        self.camType = .default
        self.audioEnabled = audioEnabled

        // Setup the previewView and focusImageView
        start(view: view, focusImageView: focusImageView)

        // Setup the capture session inputs
        setupCaptureSessionInputs()

        // Setup the capture session outputs
        setupCaptureSessionOutputs()
    }



    /**
     设置录像是否具有录音功能，默认值: 参考初始化传入的参数audioEnabled（录像期间使用无效）
     */
    func setAudioEnabled(_ enabled: Bool) {
        guard !recording else {
            print("The session is recording, can not complete the operation!")
            return
        }

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            if self.audioEnabled  {
                // Add audioDevice input
                if let _ = self.audioDeviceInput {
                    print("The session already added aduioDevice input")
                } else {
                    self.session.beginConfiguration()
                    let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
                    do {
                        let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                        if self.session.canAddInput(audioDeviceInput) {
                            self.session.addInput(audioDeviceInput)
                            self.audioDeviceInput = audioDeviceInput
                        } else {
                            print("Could not add audio device input to the session")
                        }
                    } catch {
                        let nserror = error as NSError
                        print("Could not create audio device input: \(nserror.localizedDescription)")
                    }
                    self.session.commitConfiguration()
                }
            } else {
                // Remove audioDevice input
                if let audioDeviceInput = self.audioDeviceInput {
                    self.session.beginConfiguration()
                    self.session.removeInput(audioDeviceInput)
                    self.session.commitConfiguration()
                    self.audioDeviceInput = nil
                } else {
                    print("AduioDevice input was already removed")
                }
            }
            self.audioEnabled = enabled
        }
    }

    /**
     设置点击聚焦手势的开关，默认为true
     */
    func setTapToFocusEnabled(_ enabled: Bool) {
        tapFocusEnabled = enabled
    }

//    func takePhoto(finishedCallback :  @escaping (_ result : UIImage ) -> ()) {
//
//        let captureConnetion = imageOutput.connection(withMediaType: AVMediaTypeVideo)
//
//        captureConnetion?.videoScaleAndCropFactor = effectiveScale
//        imageOutput.captureStillImageAsynchronously(from: captureConnetion) { (imageBuffer, error) in
//            let jpegData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer)
//            let jpegImage = UIImage(data: jpegData!)
//
//            //这里你可以 生成任意大小的图片
//            //jpegImage = jpegImage.rotate(aImage: jpegImage)
//
//            //图片入库
//            UIImageWriteToSavedPhotosAlbum(jpegImage!, self,nil, nil)
//            finishedCallback(jpegImage!)
//        }
//    }
    /**
     拍照

     - parameter mode:            设置拍照时闪光灯模式
     - parameter completeHandler: 拍照结果回调
     */
    func snapStillImage(withFlashMode mode: AVCaptureFlashMode,
                        completeHandler: ((_ imageData: Data?, _ error: Error?) -> Void)?) {

        guard sessionRunning && !recording, let previewView = currentView else { return }

        sessionQueue.async {
            guard self.setupResult == .success else { return }

            if let connection = self.stillImageOutput?.connection(withMediaType: AVMediaTypeVideo), let device = self.videoDeviceInput?.device {
                // Update the orientation on the still image output video connection before capturing
                connection.videoOrientation = (previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
                // Flash set to Auto for Still Capture.
                DCCameraAlbum.setFlashMode(mode, forDevice: device)
                // Capture a still image.
                connection.videoScaleAndCropFactor = self.effectiveScale

                self.stillImageOutput?.captureStillImageAsynchronously(from: connection,
                                                                       completionHandler: {
                                                                        (buffer: CMSampleBuffer?, error: Error?) in

                                                                        var imageData: Data?
                                                                        if buffer != nil {
                                                                            imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                                                                        }
                                                                        DispatchQueue.main.async {
                                                                            completeHandler?(imageData, error)
                                                                        }

                })
                DispatchQueue.main.async(execute: {
                    let layer = previewView.layer
                    layer.opacity = 0.0
                    UIView.animate(withDuration: 0.25, animations: {
                        layer.opacity = 1.0
                    })
                })
            }
        }
    }

    /**
     判断当前是否正在录像
     */
    func isRecording() -> Bool {
        return recording
    }

    /**
     开始录像

     - parameter path:                  录像文件保存地址
     - parameter startRecordingHandler: 开始录像时触发的回调
     */
    func startMovieRecording(outputFilePath path: String,
                             startRecordingHandler: StartRecordingHandler?) {

        guard sessionRunning && !recording, let previewView = currentView else { return }

        sessionQueue.async {
            guard self.setupResult == .success, let movieFileOutput = self.movieFileOutput else { return }

            if UIDevice.current.isMultitaskingSupported {
                // Setup background task. This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
                // callback is not received until AVCam returns to the foreground unless you request background execution time.
                // This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                // To conclude this background execution, -endBackgroundTask is called in
                // -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
                self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            // Update the orientation on the movie file output video connection before starting recording.
            let connection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo)
            connection?.videoOrientation = (previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation

            // Turn Off flash for video recording
            if let device = self.videoDeviceInput?.device {
                DCCameraAlbum.setFlashMode(.off, forDevice: device)
            }
            // Start recording
            DispatchQueue.main.async(execute: {
                self.startRecordingHandler = startRecordingHandler
            })
            movieFileOutput.startRecording(toOutputFileURL: URL(fileURLWithPath: path),
                                           recordingDelegate: self)
        }
    }

    /**
     结束录像

     - parameter finishRecordingHandler: 结束录像时触发的回调
     */
    func stopMovieRecording(_ finishRecordingHandler: FinishRecordingHandler?) {
        guard sessionRunning && recording else { return }

        sessionQueue.async {
            guard self.setupResult == .success, let movieFileOutput = self.movieFileOutput else { return }

            movieFileOutput.stopRecording()
            self.finishRecordingHandler = finishRecordingHandler
        }
    }

}


// MARK: - MetaDataOutput

extension DCCameraAlbum {


    /**
     初始化一个MetaData输出的控制器，主要用于扫描二维码、条形码等

     - parameter view:                  预览图层
     - parameter metadataObjectTypes:   二维码（AVMetadataObjectTypeQRCode）
     人脸（AVMetadataObjectTypeFace）
     条形码（AVMetadataObjectTypeCode128Code）
     - parameter metaDataOutputHandler: 扫描到数据时的回调

     */
    convenience init(metaDataPreviewView view: LWVideoPreview,
                     metadataObjectTypes: [Any],
                     metaDataOutputHandler: MetaDataOutputHandler?) {
        self.init()

        self.camType = .metaData
        self.audioEnabled = false
        self.metadataObjectTypes = metadataObjectTypes

        // Setup the previewView and focusImageView
        start(view: view, focusImageView: focusImageView)

        // Setup the capture session inputs
        setupCaptureSessionInputs()

        // Setup the capture session outputs
        setupCaptureSessionOutputs()

        self.metaDataOutputHandler = metaDataOutputHandler
    }

}


// MARK: - VideoDataOutput

extension DCCameraAlbum {

    convenience init(withVideoDataOutputHandler handler: @escaping VideoDataOutputHandler) {
        self.init()

        self.camType = .videoData
        self.audioEnabled = true

        // Setup the capture session inputs
        setupCaptureSessionInputs()

        // Setup the capture session outputs
        setupCaptureSessionOutputs()

        self.videoDataOutputHandler = handler
    }


    /**
     Create a UIImage from sample buffer data
     */
    class func image(fromSampleBuffer sampleBuffer: CMSampleBuffer) -> UIImage? {

        // Get a CMSampleBuffer's Core Video image buffer for the media data
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil}

        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bitsPerComponent: Int = 8
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue

        // Create a bitmap graphics context with the sample buffer data
        let context = CGContext(data: baseAddress,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo)

        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

        // Create a Quartz image from the pixel data in the bitmap graphics context
        guard let quartzImage = context?.makeImage() else { return nil }

        // Create an image object from the Quartz image
        let image = UIImage(cgImage: quartzImage)

        return image
    }


    class func ciImage(fromSampleBuffer sampleBuffer: CMSampleBuffer,
                       filter: CIFilter) -> CIImage? {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        let inputImage = CIImage(cvPixelBuffer: imageBuffer)
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        return filter.outputImage
    }


}

