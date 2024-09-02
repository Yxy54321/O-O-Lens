import AVFoundation
import AudioToolbox
import Foundation
import Speech

class SpeechManager: NSObject, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))!
    private let audioEngine = AVAudioEngine()
    private let request = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isListening: Bool = false // 用于跟踪当前是否在监听
    
    // 引用 VisionObjectRecognitionViewController
        weak var objectDetectionController: VisionObjectRecognitionViewController?
    
    
    init(objectDetectionController: VisionObjectRecognitionViewController?) {
        super.init()
        speechRecognizer.delegate = self
        synthesizer.delegate = self
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
        self.objectDetectionController=objectDetectionController
    }
    
    // Start recognizing speech
    func startListening(completion: @escaping (String?) -> Void) {
        if isListening {
               stopListening() // 如果正在监听，先停止
           }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
                // 请求权限
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    DispatchQueue.main.async {
                        switch authStatus {
                        case .authorized:
                            // 用户授予了权限，重新调用 startListening
                            self.startListening(completion: completion)
                        case .denied, .restricted, .notDetermined:
                            // 用户拒绝了权限请求，设备限制或未决定
                            print("Speech recognition authorization failed.")
                            completion(nil)
                        @unknown default:
                            // 处理未知的授权状态
                            print("Unknown authorization status.")
                            completion(nil)
                        }
                    }
                }
                return
            }
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        try! audioEngine.start()
        
        isListening = true // 设置为正在监听
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                completion(bestString)
                
            } else if let error = error {
                print("Error recognizing speech: \(error)")
                completion(nil)
            }
        }
    }
    
    // Stop recognizing speech
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0) // 移除 tap
        request.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false // 设置为未监听
    }
    
    // Synthesize speech from text
    func speak(text: String, rate: Float = 0.5) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = rate // 使用传入的语速值或默认值
        synthesizer.speak(utterance)
    }

    
    // Handle end of speech synthesis
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let objectDetectionController = self.objectDetectionController,
           objectDetectionController.asked && objectDetectionController.answered && !objectDetectionController.selected {//doubletaped
            
            startListening { [weak self] text in
                if((text) != nil){
                    for (key, value) in yoloLabels {
                        if let text = text, text.contains(value) {
                            objectDetectionController.tracking = key
                            objectDetectionController.selected = true
                            self?.stopListening()
                            return
                        }
                    }
                }
            }
        }
    }
}
