//object detection controller
import UIKit
import AVFoundation
import Vision
import AudioToolbox
import CoreVideo
import CoreImage
import SwiftUI
//speech
import Foundation
import Speech


let toneVol = Float(3.0)

let defaultColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.8, 0.6, 1.0, 0.4])

let okayColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.6, 1.0, 0.6, 0.4])


struct Target {
    var X:Float
    var Y:Float
    var ratioToSup:Float
    var posErr:Float
    var ratioErr:Float
}


extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // 确定比例，使得图像不会被拉伸
        let scaleFactor = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let newImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return newImage
    }
}

func refreshCount() {
    for key in labelCounts.keys {
        labelCounts[key] = 0
    }
}


class VisionObjectRecognitionViewController: UIViewController, CameraCaptureDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPreview()
        CameraCaptureSession.shared.delegate = self
        CameraCaptureSession.shared.startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CameraCaptureSession.shared.stopSession()
        CameraCaptureSession.shared.delegate = nil
    }

    
    @IBOutlet var previewView: UIView!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    func setupPreview() {
        guard let captureSession = CameraCaptureSession.shared.session else { return }
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = previewView.layer.bounds
        previewView.layer.cornerRadius=10
        previewView.layer.insertSublayer(videoPreviewLayer!,at:0)
    }
    
    
    
    //三回调
    func processCapturedImage(_ image: Data) {
        return
    }
    
    func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
    
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])

        do {
            try imageRequestHandler.perform(CameraCaptureSession.shared.requests)
        } catch {
            print(error)
        }
    }
    
    func handleVisionRequestResults(_ results: [Any]) {
        if asked && !answered{
            refreshCount()
        }
        
        let screenWidth = previewView.layer.bounds.width
        let screenHeight = previewView.layer.bounds.height
        var targetDetected = false
        var targetBounds: CGRect?
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            let boundingBox = objectObservation.boundingBox
            
            let objectBounds = VNImageRectForNormalizedRect(boundingBox , Int(1080), Int(1920))
            //mod
            
            var shapeLayer=CALayer()
            
            if isdancing && topLabelObservation.identifier == tracking && mood != 2{
                shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds,color:okayColor!)
            }
            
            else{
                shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds,color:defaultColor!)
            }
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: yoloLabels[ topLabelObservation.identifier]!)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
            labelCounts[topLabelObservation.identifier]!+=1
            
            if (selected && objectObservation.labels.first?.identifier==tracking)||(mood==3&&isdancing) {
                targetDetected = true
                targetBounds = VNImageRectForNormalizedRect(boundingBox, Int(1080), Int(1920))
                break
            }
        }
        
        if asked && !answered{
            objectstr="画面中主要有："
            for(key,value)in labelCounts{
                if value>0{
                    objectstr += "\(value)" + measureWords[key]! + yoloLabels[key]! + "，"
                }
            }
            if(mood==3){
                objectstr+="您想选择哪个作为运镜对象？"
            }
            answered=true
            speechManager!.speak(text: objectstr)
        }
        
        self.updateLayerGeometry()
        CATransaction.commit()
        
        //------------得到person的bounding box后，进行引导-------------//
        guard targetDetected, let bounds = targetBounds else {
            // 提示用户重新进入画面
            if isAdjusting{return}
            //speak(description: "未检测到您，请重新进入画面中心。")
            initialPromptGiven = false
            isAdjusting = false
            
            //要改！！但功能正常
            if mood==3
            {
                if(cameraMotionEvaluator.recording){
                    cameraMotionEvaluator.evaluateMotion(for: nil)
                }
            }
            return
        }
        

        // 将 targetBounds 转换为屏幕坐标
        let scaleX = screenWidth / 1080
        let scaleY = screenHeight / 1920
        let scale=fmax(scaleX,scaleY)
        
        //物体在rootLayer系下的坐标
        let screenBounds = CGRect(x: bounds.origin.x * scale,
                                  y: (1920 - bounds.origin.y - bounds.height) * scale - (1920 * scale-screenHeight)/2,
                                  width: bounds.width * scale,
                                  height: bounds.height * scale)
        
        let targetX = bounds.origin.x * scale+screenBounds.width/2
        let targetY =  (1920 - bounds.origin.y - bounds.height) * scale - (1920 * scale-screenHeight)/2 + screenBounds.height/2
    
       
        
        var targetlenth : Float
        var supLenth :Float
        if screenBounds.height/screenBounds.width>previewView.layer.bounds.height/previewView.layer.bounds.width{
            targetlenth=Float(screenBounds.height)
            supLenth=Float(previewView.layer.bounds.height)
        }
        else{
            targetlenth=Float(screenBounds.width)
            supLenth=Float(previewView.layer.bounds.width)
        }
        
        let sceneTarget = Target(X: Float(screenWidth * 0.3 ), Y: Float(screenHeight*0.72), ratioToSup: 0.4,posErr: 10,ratioErr: 0.05)
        
        let defaultTarget = Target(X: Float(screenWidth/2), Y: Float(screenHeight/2), ratioToSup: 0.5,posErr: 20,ratioErr: 0.05)
        
        var target = defaultTarget
        
        if(mood==1||mood==3){
            target=defaultTarget
        }
        else if(mood==2){
            target = sceneTarget
        }
       
        
        //调整引导
        if (mood==1 || mood == 2 || mood==3) && !isdancing {
            if abs(Float(targetX) - target.X) < target.posErr {
                flags[2][0]=true
            }else{
                flags[2][0]=false
            }
            if abs(Float(targetY) - target.Y) < target.posErr {
                flags[2][1]=true
            }else{
                flags[2][1]=false
            }
            if abs(targetlenth/supLenth - target.ratioToSup) <= target.ratioErr{
                flags[2][2]=true
            }else{
                flags[2][2]=false
            }
            
            
            if flags[2][0]&&flags[2][1]&&flags[2][2] {
                audioPlayer?.volume=0
                print("stopf")
                
                //修缮
                playSuccessTone()
                isdancing=true
                flags[0][0]=false
                flags[1][0]=false
                flags[0][1]=false
                flags[1][1]=false
                flags[1][1]=false
                flags[0][2]=false
                flags[1][2]=false
                
                asked=false
                answered=false
                selected=false
//                tracking=""
                
                if mood==1 || mood==2{
                    speechManager?.speak(text: "位置合适，可以开始录制。")
                }
                else if mood==3{
                    speechManager?.speak(text: "三，二，一",rate: 0.3)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.cameraMotionEvaluator.startRecording()
                    }
                }
                isdancing=true
                //开始录制
                
                //.......
                
            }
            
            else if flags[1][0]{//横向正在调整
                var currentOffset: CGFloat = 0.0
                if currentDirection == "right" {
                    currentOffset = CGFloat(target.X) - targetX
                } else if currentDirection == "left" {
                    currentOffset = targetX - CGFloat(target.X)
                }
                
                if Float(abs(currentOffset)) < target.posErr {
                    //更新flag
                    flags[0][0]=false
                    flags[1][0]=false
                    flags[2][0]=true
                    speechManager?.speak(text: "横向位置合适。")
                    //                    audioPlayer?.stop()
                    //                    print("stop0")
                } else {
                    // 调整音量
                    let volume = toneVol-toneVol * min(1.0, Float(abs(currentOffset) / initialOffset))
                    audioPlayer?.volume = volume
                }
            }
            else if flags[1][1]{//纵向正在调整
                var currentOffset: CGFloat = 0.0
                if currentDirection == "down" {
                    currentOffset = CGFloat(target.Y) - targetY
                } else if currentDirection == "up" {
                    currentOffset = targetY - CGFloat(target.Y)
                }
                
                if Float(abs(currentOffset)) < target.posErr {
                    //更新flag
                    flags[0][1]=false
                    flags[1][1]=false
                    flags[2][1]=true
                    speechManager?.speak(text: "纵向位置合适。")
       
                } else {
                    // 调整音量
                    let volume = toneVol-toneVol*min(1.0, Float(abs(currentOffset) / initialOffset))
                    audioPlayer?.volume = volume
                }
            }
            
            else if flags[1][2]{//前后正在调整
                var currentOffset: CGFloat = 0.0
                if currentDirection == "closer" {
                    currentOffset = CGFloat(target.ratioToSup - targetlenth/supLenth)
                } else if currentDirection == "further" {
                    currentOffset = CGFloat( targetlenth/supLenth - target.ratioToSup)
                }
                
                if Float(abs(currentOffset)) < target.ratioErr {
                    flags[0][2]=false
                    flags[1][2]=false
                    flags[2][2]=true
                    speechManager?.speak(text: "前后位置合适。")
                    print("stop1")
                } else {
                    let volume = toneVol - toneVol * max(0.1, min(1.0, Float(abs(currentOffset) / initialOffset)))
                    audioPlayer?.volume = volume
                }
            }
            
            else if !flags[0][0] && !flags[2][0] && !flags[1][1] && !flags[1][2]{//说横向第一次提示
                if targetX < CGFloat(target.X - target.posErr){
                    currentDirection = "right"
                    initialOffset =  CGFloat(target.X)-targetX
                    speechManager?.speak(text: "请向左移动一些。")
                } else if targetX > CGFloat(target.X + target.posErr) {
                    currentDirection = "left"
                    initialOffset = targetX - CGFloat(target.X)
                    speechManager?.speak(text: "请向右移动一些。")
                }
                flags[0][0] = true
                flags[1][0] = true
                playTone(volume:10)
                print("play")
            }
            else if !flags[0][1] && !flags[2][1] && !flags[1][0] && !flags[1][2]{//说纵向第一次提示
                if targetY < CGFloat(target.Y - target.posErr){
                    currentDirection = "up"
                    initialOffset =  CGFloat(target.Y)-targetY
                    speechManager?.speak(text: "请将手机向上移动一些。")
                } else if targetY > CGFloat(target.Y + target.posErr) {
                    currentDirection = "down"
                    initialOffset = targetY - CGFloat(target.Y)
                    speechManager?.speak(text: "请将手机向下移动一些。")
                }
                flags[0][1] = true
                flags[1][1] = true
                playTone(volume:10)
                print("play")
            }
            else if !flags[0][2] && !flags[2][2] && !flags[1][0] && !flags[1][1]{//说前后第一次提示
                if targetlenth/supLenth  < target.ratioToSup - target.ratioErr {
                    currentDirection = "closer"
                    initialOffset = CGFloat(target.ratioToSup - targetlenth/supLenth)
                    speechManager?.speak(text: "请靠近一些。")
                } else if targetlenth/supLenth  > target.ratioToSup + target.ratioErr {
                    currentDirection = "further"
                    initialOffset = CGFloat(targetlenth/supLenth + target.ratioToSup)
                    speechManager?.speak(text: "请远离一些。")
                }
                flags[0][2] = true
                flags[1][2] = true
                playTone(volume: 10)
                print("play")
            }
        }
        else if mood==3 && isdancing{
            if(cameraMotionEvaluator.recording){
                cameraMotionEvaluator.evaluateMotion(for: screenBounds)
            }
        }
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func teardownAVCapture() {
        videoPreviewLayer?.removeFromSuperlayer()
        videoPreviewLayer = nil
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        return .right
    }
    
    
    //----------------------------- original------------------------------//

    var rec = false
    
    @IBAction func startRoc(_ sender: UIButton) {
        if !rec{
            startRocBtn.setImage(UIImage(named: "Shutter Button_pressed")?.resized(to: CGSize(width: 80, height: 80)), for: .normal)
            CameraCaptureSession.shared.startRecording()
        }
        else{
            startRocBtn.setImage(UIImage(named: "Shutter Button")?.resized(to: CGSize(width: 80, height: 80)), for: .normal)
            CameraCaptureSession.shared.stopRecording()
        }
        rec = !rec
    }
    
    @IBAction func dbTouch(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
            feedbackGenerator.impactOccurred()
            asked = true
            answered = false
            selected = false
            isdancing=false
            tracking=""
            print("1")
            return
        }
    }
    
    //speak结束后收音
    
    
    @IBOutlet weak var selectbar: UIImageView!
    
    @IBAction func swpRight(_ sender: Any) {
        
        audioPlayer?.volume=0
        selectbar.image = UIImage(named: "select1")
        sceneTemplate.isHidden=true
        resetFlags()
        mood=1
        isdancing=false
        asked=false
        answered=false
        selected=false
        tracking=""
    }
    
    
    
    @IBAction func swpLeft(_ sender: Any) {
        
        audioPlayer?.volume=0
        selectbar.image = UIImage(named: "select2")
        sceneTemplate.isHidden=false
        resetFlags()
        mood=2
        isdancing=false
        asked=true
        answered=true
        selected=true
        tracking="person"
    }
    @IBOutlet weak var backBtn: UIButton!
    
    @IBOutlet weak var sceneTemplate: UIImageView!
    
    
    
    @IBOutlet weak var bottomBar: UIImageView!
    
    
    @IBOutlet weak var startPracticeBtn: UIButton!
    
    
    @IBAction func flipCamera(_ sender: UIButton) {
        CameraCaptureSession.shared.switchCamera()
    }
    
    @IBAction func startPractice(_ sender: Any) {
//        mood=3
        audioPlayer?.volume=0
        asked=true
        answered=false
        selected=false
        isdancing=false
        tracking=""
    }
    
    
    @IBOutlet weak var listenBtn: UIButton!
    
    @IBOutlet weak var refreshBtn: UIButton!
    // 通过代码为按钮添加点击事件处理器
    
    
    @IBOutlet weak var startRocBtn: UIButton!
    
    
    @IBAction func motionBtn(_ sender: Any) {
        mood=3
        bottomBar.isHidden=true
        selectbar.isHidden=true
        audioPlayer?.volume=0
        sceneTemplate.isHidden=true
        backBtn.isHidden=false
        startPracticeBtn.isHidden=false
        listenBtn.isHidden=true
        refreshBtn.isHidden=true
        startRocBtn.isHidden=true
        //cameraMotionEvaluator.startRecording()
    }
    
    @IBAction func backToDft(_ sender: Any) {
        mood=1
        isdancing=false
        asked=false
        answered=false
        selected=false
        tracking=""
        audioPlayer?.volume=0
        bottomBar.isHidden=false
       
        selectbar.isHidden=false
        startPracticeBtn.isHidden=true
        backBtn.isHidden=true
        listenBtn.isHidden=false
        refreshBtn.isHidden=false
        startRocBtn.isHidden=false
        if cameraMotionEvaluator.recording{
            cameraMotionEvaluator.endRecording()
        }
    }
    

    var mood: Int = 1 // 添加 mood 属性，dancing模式下值为1，先初始化为1
    var audioPlayer: AVAudioPlayer?
    var speechManager:SpeechManager?
    public var recognizedText :String?
    //运镜模块！！！！
    private var cameraMotionEvaluator = CameraMotionEvaluator()
    //运镜模块！！！！
    
    private var detectionOverlay: CALayer! = nil
    // Vision parts
   
    
    
    let phrase1=["拍"]
    //问答相关
    var asked = false
    var answered = false
    var selected = false
    var tracking = ""

    
    //长按，已取代
    @objc func buttonPressed() {
    }
    @objc func buttonReleased() {
    }
        

    func handleRecognizedText(_ text: String) {
        // 处理识别到的文本
        print("Recognized Text: \(text)")
        
        if  text.contains(phrase1[0])  {
            asked = true
            answered = false
            selected = false
            tracking=""
            return
        }
        else if asked && answered && !selected{
            for (key, value) in yoloLabels {
                if text.contains(value){
                    tracking = key
                    selected = true
                    return
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for label in yoloLabels.keys {
            labelCounts[label] = 0
        }
        self.speechManager = SpeechManager(objectDetectionController: self)

        
        //长按手势
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(dbTouch))
        longPressGestureRecognizer.minimumPressDuration = 1 // 设置长按持续时间（秒）
        longPressGestureRecognizer.numberOfTouchesRequired = 2 // 设置需要的触摸次数为2，即双指
        
        
        
        
        
        previewView.addGestureRecognizer(longPressGestureRecognizer)
       
        //录制按钮
        startRocBtn.setImage(UIImage(named: "Shutter Button")?.resized(to: CGSize(width: 80, height: 80)), for: .normal)
        startRocBtn.setBackgroundImage(UIImage(), for: .selected)
        
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: 1080,
                                         height: 1920)
        detectionOverlay.anchorPoint=CGPoint(x: 0.5, y: 0.5)
        detectionOverlay.position = CGPoint(x: previewView.layer.bounds.midX, y: previewView.layer.bounds.midY)

        
        previewView.layer.masksToBounds=true
        print(detectionOverlay.anchorPoint)
        print(detectionOverlay.position)
        previewView.layer.addSublayer(detectionOverlay)
        //dancing模式，显示虚线
        if(mood==1){
            //addDashedLine()
        }
    }
    
    func playTone(volume: Float) {
        if audioPlayer == nil {
            guard let asset = NSDataAsset(name: "tone") else {
                print("Error: Audio asset not found")
                return
            }
            
            do {
                audioPlayer = try AVAudioPlayer(data: asset.data, fileTypeHint: AVFileType.wav.rawValue)
                audioPlayer?.numberOfLoops = -1 // 无限循环
                audioPlayer?.play()
            } catch {
                print("Error playing tone: \(error)")
            }
        }
        audioPlayer?.volume = volume
    }
        
    func playSuccessTone() {
        playSystemSound(soundID: 1007) // 成功提示音
    }
    
    func playSystemSound(soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    
    func addDashedLine() {
        let screenWidth = previewView.bounds.width
        let screenHeight = previewView.bounds.height
        let lineYPosition = screenHeight * 1 / 5
        let dashedLineLayer = CAShapeLayer()
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: 0, y: lineYPosition), CGPoint(x: screenWidth, y: lineYPosition)])
        path.addLines(between: [CGPoint(x: 0, y: 2.7*lineYPosition), CGPoint(x: screenWidth, y: 2.7*lineYPosition)])
        path.addLines(between: [CGPoint(x: 0, y: 4.8*lineYPosition), CGPoint(x: screenWidth, y: 4.8*lineYPosition)])
        dashedLineLayer.path = path
        dashedLineLayer.strokeColor = UIColor.purple.cgColor
        dashedLineLayer.lineWidth = 2
        dashedLineLayer.lineDashPattern = [4, 2] // 虚线样式
        previewView.layer.addSublayer(dashedLineLayer)
    }
    
    
    //--------- variables for dancing adjustment---------------- variables for dancing adjustment-------------//
                                    private var initialPromptGiven = false
                                    private var currentDirection: String = ""
                                    private var initialOffset: CGFloat = 0.0
                                    private var isAdjusting = false
    
                        private var danceflags: [[Bool]] = [[false,false],//is promptgiven
                                                            [false,false],//is adjusting
                                                            [false,false]]//is down
    
                                    private var isdancing = false
    //--------- variables for dancing adjustment---------------- variables for dancing adjustment-------------//

    
    //--------- variables for default adjustment---------------- variables for default adjustment-------------//
    
    
    private var flags: [[Bool]] = [[false,false,false],//is promptgiven
                                        [false,false,false],//is adjusting
                                        [false,false,false]]//is down
    
    func resetFlags() {
        for i in 0..<flags.count {
            for j in 0..<flags[i].count {
                flags[i][j] = false
            }
        }
    }
    
    //--------- variables for default adjustment---------------- variables for default adjustment-------------//
    private var ratio = 1080.0/1920.0
    private var margin = (1-1080.0/1920.0)/2.0
    private var objectstr = ""

    
    func updateLayerGeometry() {
        videoPreviewLayer?.frame = previewView.layer.bounds
        let bounds = previewView.layer.bounds
       
        var scale: CGFloat

        let xScale: CGFloat = bounds.width / 1080
        let yScale: CGFloat = bounds.height / 1920

        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(0)).scaledBy(x: scale, y: -scale))
        // center the layer
        
        detectionOverlay.anchorPoint=CGPoint(x: 0.5, y: 0.5)
        detectionOverlay.position = CGPoint(x: previewView.layer.bounds.midX, y: previewView.layer.bounds.midY)


        CATransaction.commit()
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        
        // 设置文本内容，使用加粗字体
        let boldFont = UIFont.boldSystemFont(ofSize: 48.0)
        let formattedString = NSMutableAttributedString(string: identifier)
        
        // 设置字体和颜色属性，确保字体加粗和颜色为白色
        formattedString.addAttributes([
            .font: boldFont,
            .foregroundColor: UIColor.white
        ], range: NSRange(location: 0, length: identifier.count))
        
        textLayer.string = formattedString
        
        // 设置文本层的边界和位置
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.width - 10, height: bounds.size.height - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        textLayer.opacity=0.8
        
        // 设置文本颜色为白色
        textLayer.foregroundColor = UIColor.white.cgColor
        
        // 设置文本层内容的缩放比例
        textLayer.contentsScale = UIScreen.main.scale
        
        // 旋转图层并翻转
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(0)).scaledBy(x: 1.0, y: -1.0))
        
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect,color:CGColor) -> CALayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        
        // 创建圆角矩形路径
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 25)
        shapeLayer.path = path.cgPath
        
        // 设置填充颜色
        shapeLayer.fillColor = color
        
        // 圆弧参数
        let cornerRadius: CGFloat = 20.0  // 圆角半径
        let arcRadius: CGFloat = 25.0    // 圆弧半径
        let arcLineWidth: CGFloat = 8.0  // 圆弧线条宽度
        let arcColor = UIColor.white.cgColor  // 圆弧颜色
        
        // 创建四个独立的圆弧
        let corners: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: bounds.minX + cornerRadius, y: bounds.minY + cornerRadius), CGFloat.pi, 1.5 * CGFloat.pi),  // 左上角
            (CGPoint(x: bounds.maxX - cornerRadius, y: bounds.minY + cornerRadius), 1.5 * CGFloat.pi, 0),           // 右上角
            (CGPoint(x: bounds.maxX - cornerRadius, y: bounds.maxY - cornerRadius), 0, 0.5 * CGFloat.pi),           // 右下角
            (CGPoint(x: bounds.minX + cornerRadius, y: bounds.maxY - cornerRadius), 0.5 * CGFloat.pi, CGFloat.pi)   // 左下角
        ]
        
        for (center, startAngle, endAngle) in corners {
            let arcPath = UIBezierPath()
            arcPath.addArc(withCenter: center, radius: arcRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            let arcShapeLayer = CAShapeLayer()
            arcShapeLayer.path = arcPath.cgPath
            arcShapeLayer.strokeColor = arcColor
            arcShapeLayer.lineWidth = arcLineWidth
            arcShapeLayer.fillColor = UIColor.clear.cgColor
            
            shapeLayer.addSublayer(arcShapeLayer)
        }
        return shapeLayer
    }
}
