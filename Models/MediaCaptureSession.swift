import Foundation
import AVFoundation
import Photos
import Vision

// 获取后置摄像头设备
func getBackCamera() -> AVCaptureDevice? {
    return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
}

// 获取前置摄像头设备
func getFrontCamera() -> AVCaptureDevice? {
    return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
}


protocol CameraCaptureDelegate: AnyObject {
    func processCapturedImage(_ image:Data)
    func processVideoFrame(_ sampleBuffer: CMSampleBuffer)
    func handleVisionRequestResults(_ results: [Any])
}


class CameraCaptureSession: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    private override init() {
        super.init()
        setupAVCapture()
        setupVision()
    }

    // 全局共享这个 session
    static let shared = CameraCaptureSession()
    weak var delegate: CameraCaptureDelegate?

    // 初始化 session
    var session : AVCaptureSession?
    var currentCameraInput: AVCaptureDeviceInput?
    var bufferSize: CGSize = .zero

    // 初始化 session 输出
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var capturePhotoOutput = AVCapturePhotoOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput() // 录制

    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    func setupAVCapture() {
        session = AVCaptureSession()
        session?.beginConfiguration()
        session?.sessionPreset = .high // 提高分辨率

        // 添加 video 输入
        setupCameraInput()

        // 添加 photo 输出
        setupPhotoOutput()

        // 添加 video data 输出
        setupVideoDataOutput()

        // 添加 movie file 输出
        setupMovieFileOutput()
  

        session?.commitConfiguration()
    }

    private func setupCameraInput() {
        guard let initialCamera = getBackCamera() else {
            print("Error: No back camera available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: initialCamera)
            if ((session?.canAddInput(input)) != nil) {
                session?.addInput(input)
                currentCameraInput = input
            }
        } catch {
            print("Error: Could not create AVCaptureDeviceInput - \(error)")
        }
    }

    private func setupPhotoOutput() {
        if ((session?.canAddOutput(capturePhotoOutput)) != nil) {
            session?.addOutput(capturePhotoOutput)
        } else {
            print("Could not add photo output to the session")
        }
    }

    private func setupVideoDataOutput() {
        if ((session?.canAddOutput(videoDataOutput)) != nil) {
            session?.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
        }
    }

    private func setupMovieFileOutput() {
        if ((session?.canAddOutput(movieFileOutput)) != nil) {
            session?.addOutput(movieFileOutput)
        } else {
            print("Could not add movie file output to the session")
        }
    }

    // 切换摄像头
    func switchCamera() {
        guard ((session?.isRunning) != nil) else { return }

        session?.beginConfiguration()

        // 移除当前输入
        if let currentInput = currentCameraInput {
            session?.removeInput(currentInput)
        }

        // 获取新的摄像头设备
        var newCamera: AVCaptureDevice?
        if let currentInput = currentCameraInput, currentInput.device.position == .back {
            newCamera = getFrontCamera()
        } else {
            newCamera = getBackCamera()
        }

        // 创建新的输入并添加到会话
        if let newCamera = newCamera {
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if ((session?.canAddInput(newInput)) != nil) {
                    session?.addInput(newInput)
                    currentCameraInput = newInput
                } else {
                    // 如果无法添加新输入，恢复旧输入
                    if let currentInput = currentCameraInput {
                        session?.addInput(currentInput)
                    }
                }
            } catch {
                print("Error: Could not switch camera - \(error)")
            }
        }
        session?.commitConfiguration()
    }

    // 视频回调
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 只在 bufferSize 尚未设置时获取一次
        if bufferSize == .zero {
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let width = CVPixelBufferGetWidth(pixelBuffer)
                let height = CVPixelBufferGetHeight(pixelBuffer)
                self.bufferSize = CGSize(width: width, height: height)
                print("Buffer size set to: \(self.bufferSize)")
            }
        }
        self.delegate?.processVideoFrame(sampleBuffer)
    }

    // 照片捕获
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        capturePhotoOutput.capturePhoto(with: settings, delegate: self)
    }
    //照片回调
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Photo captured")
        guard let imageData = photo.fileDataRepresentation() else { return }
        delegate?.processCapturedImage(imageData)
    }

    // 录制视频相关
    func startRecording() {
        let outputPath = NSTemporaryDirectory() + "output.mov"
        let outputURL = URL(fileURLWithPath: outputPath)

        // 删除已存在的文件
        if FileManager.default.fileExists(atPath: outputPath) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
    }

    func stopRecording() {
        if movieFileOutput.isRecording {
            movieFileOutput.stopRecording()
        }
    }

    // 录制视频的回调方法
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            print("Video recorded successfully: \(outputFileURL.absoluteString)")
            saveVideoToPhotoLibrary(videoURL: outputFileURL)
        }
    }

    // 保存视频到相册
    func saveVideoToPhotoLibrary(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    if let error = error {
                        print("Error saving video to photo library: \(error.localizedDescription)")
                    } else {
                        print("Video saved to photo library successfully.")
                    }
                }
            } else {
                print("Permission not granted to access photo library.")
            }
        }
    }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }

    func startSession() {
        requestCameraPermission { granted in
            if granted {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.session?.startRunning()
                }
            } else {
                print("Camera permission not granted")
            }
        }
    }
    
    func stopSession() {
        guard let session = session, session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }

    
    
    //vision
    public var requests = [VNRequest]()
    
    func setupVision()  {
        // Setup Vision parts
        do {
            let visionModel = try VNCoreMLModel(for: YOLOv3().model)
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.delegate?.handleVisionRequestResults(results)
                    }
                })
            })
            objectRecognition.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFit

            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
    }
    
    //析构
    deinit {
        session?.stopRunning()
    }
    
}


//    func analyzeImage(imageData: Data) {
//        // 调用 GPT 的图片分析 API
//        print("called")
//        let url = URL(string: "https://api.openai.com/v1/images/analyze")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let body: [String: Any] = ["image": imageData.base64EncodedString()]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else { return }
//            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
////                if let description = jsonResponse["description"] as? String {
////                    //self.speak(description: description)
////                }
//            }
//        }
//        task.resume()
//    }


let yoloLabels: [String: String] = [
    "person": "人",
    "bicycle": "自行车",
    "car": "汽车",
    "motorbike": "摩托车",
    "airplane": "飞机",
    "bus": "公交车",
    "train": "火车",
    "truck": "卡车",
    "boat": "船",
    "traffic light": "红绿灯",
    "fire hydrant": "消防栓",
    "stop sign": "停车标志",
    "parking meter": "停车计时器",
    "bench": "长椅",
    "bird": "鸟",
    "cat": "猫",
    "dog": "狗",
    "horse": "马",
    "sheep": "羊",
    "cow": "牛",
    "elephant": "大象",
    "bear": "熊",
    "zebra": "斑马",
    "giraffe": "长颈鹿",
    "backpack": "背包",
    "umbrella": "雨伞",
    "handbag": "手提包",
    "tie": "领带",
    "suitcase": "行李箱",
    "frisbee": "飞盘",
    "skis": "滑雪板",
    "snowboard": "滑雪板",
    "sports ball": "运动球",
    "kite": "风筝",
    "baseball bat": "棒球棒",
    "baseball glove": "棒球手套",
    "skateboard": "滑板",
    "surfboard": "冲浪板",
    "tennis racket": "网球拍",
    "bottle": "瓶子",
    "wine glass": "酒杯",
    "cup": "杯子",
    "fork": "叉子",
    "knife": "刀",
    "spoon": "勺子",
    "bowl": "碗",
    "banana": "香蕉",
    "apple": "苹果",
    "sandwich": "三明治",
    "orange": "橙子",
    "broccoli": "西兰花",
    "carrot": "胡萝卜",
    "hot dog": "热狗",
    "pizza": "披萨",
    "donut": "甜甜圈",
    "cake": "蛋糕",
    "chair": "椅子",
    "sofa": "沙发",
    "pottedplant": "盆栽植物",
    "bed": "床",
    "diningtable": "餐桌",
    "toilet": "厕所",
    "tvmonitor": "电视",
    "laptop": "笔记本电脑",
    "mouse": "鼠标",
    "remote": "遥控器",
    "keyboard": "键盘",
    "cell phone": "手机",
    "microwave": "微波炉",
    "oven": "烤箱",
    "toaster": "烤面包机",
    "sink": "水槽",
    "refrigerator": "冰箱",
    "book": "书",
    "clock": "时钟",
    "vase": "花瓶",
    "scissors": "剪刀",
    "teddy bear": "泰迪熊",
    "hair drier": "吹风机",
    "toothbrush": "牙刷"
]

// 计数字典
var labelCounts: [String: Int] = [:]


// 中文量词字典
let measureWords: [String: String] = [
    "sofa": "个",
    "person": "位",
    "bicycle": "辆",
    "car": "辆",
    "motorbike": "辆",
    "airplane": "架",
    "bus": "辆",
    "train": "列",
    "truck": "辆",
    "boat": "艘",
    "traffic light": "个",
    "fire hydrant": "个",
    "stop sign": "个",
    "parking meter": "个",
    "bench": "条",
    "bird": "只",
    "cat": "只",
    "dog": "只",
    "horse": "匹",
    "sheep": "只",
    "cow": "头",
    "elephant": "头",
    "bear": "头",
    "zebra": "匹",
    "giraffe": "头",
    "backpack": "个",
    "umbrella": "把",
    "handbag": "个",
    "tie": "条",
    "suitcase": "个",
    "frisbee": "个",
    "skis": "对",
    "snowboard": "块",
    "sports ball": "个",
    "kite": "只",
    "baseball bat": "支",
    "baseball glove": "只",
    "skateboard": "块",
    "surfboard": "块",
    "tennis racket": "个",
    "bottle": "个",
    "wine glass": "个",
    "cup": "个",
    "fork": "把",
    "knife": "把",
    "spoon": "把",
    "bowl": "个",
    "banana": "根",
    "apple": "个",
    "sandwich": "个",
    "orange": "个",
    "broccoli": "颗",
    "carrot": "根",
    "hot dog": "个",
    "pizza": "片",
    "donut": "个",
    "cake": "块",
    "chair": "把",
    "couch": "条",
    "pottedplant": "盆",
    "bed": "张",
    "diningtable": "张",
    "toilet": "个",
    "tvmonitor": "台",
    "laptop": "台",
    "mouse": "只",
    "remote": "个",
    "keyboard": "个",
    "cell phone": "部",
    "microwave": "台",
    "oven": "台",
    "toaster": "台",
    "sink": "个",
    "refrigerator": "台",
    "book": "本",
    "clock": "个",
    "vase": "个",
    "scissors": "把",
    "teddy bear": "个",
    "hair drier": "个",
    "toothbrush": "把"
]
