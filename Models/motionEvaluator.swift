import CoreMotion
import AVFoundation
import UIKit
import AudioToolbox

struct ShotPreset {
    let musicFile: String
    let beatPoints: [TimeInterval]
    let operations: [CameraOperation]
    var checks:[Bool]
    var actualOperations: [(time: TimeInterval, operation: CameraOperation)] = []
}

enum CameraOperation {
    case zoomIn
    case zoomOut
    case rotate
    case pan
    case none
}

struct DetectedAction {
    let operation: CameraOperation
    let time: TimeInterval
    let isMatched: Bool
}


let shotPresets = ShotPreset(
           musicFile: "supernatral.mp3",
           beatPoints: [0.85, 2, 3.15 , 0.85+3*1.15 , 0.85+4*1.15 , 0.85+5*1.15, 0.85+6*1.15, 0.85+7*1.15, 0.85+8*1.15, 0.85+9*1.15, 0.85+10*1.15, 0.85+11*1.15, 0.85+12*1.15, 0.85+13*1.15, 0.85+14*1.15], // 示例节奏点
           operations: [.zoomIn, .zoomOut, .zoomIn, .zoomOut,.zoomIn, .zoomOut, .zoomIn, .zoomOut,.zoomIn, .zoomOut, .zoomIn, .zoomOut,.zoomIn, .zoomOut, .zoomIn],
           checks:[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]//是否踩点
       )


class CameraMotionEvaluator: NSObject, AVAudioPlayerDelegate {
    public var recording = false
    private let motionManager = CMMotionManager()
    private var previousBoundingBox: CGRect?
    private var motionData: CMDeviceMotion?
    private var startTime: Date?
    public var shotPreset: ShotPreset
    private let audioController = AudioController()
    private var comingindex = 0
    var isMatchingOperation: Bool = false

    
    
    override init() {
        self.shotPreset = shotPresets
        super.init()
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            self.motionData = motion
        }
        
    }
    
    private var vibPlayed = false
    
    private func checkMatchingOperation(at time: TimeInterval, operation: CameraOperation) {
        if comingindex<shotPreset.checks.count {
            
            //节奏点到达前0.3s播放震动
            if comingindex<shotPreset.checks.count && !vibPlayed &&  shotPreset.beatPoints[comingindex] - time <= 0.3 {
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
                feedbackGenerator.impactOccurred()
                vibPlayed=true
            }
            
            //有效判定时间为0.1s
            if comingindex<shotPreset.checks.count && abs(shotPreset.beatPoints[comingindex] - time) <= 0.1 && shotPreset.operations[comingindex] == operation {
                print(comingindex)
                shotPreset.checks[comingindex]=true
                audioController.playHintSound(file: "bingo.wav")
                comingindex=comingindex+1
                vibPlayed=false
            }
            else if (time-shotPreset.beatPoints[comingindex]>0.1){
                print(comingindex)
                print(time)
                shotPreset.checks[comingindex]=false
                comingindex=comingindex+1
                vibPlayed=false
                audioController.playHintSound(file: "miss.wav")
            }
            
        }
    }

    func startRecording() {

        for (index) in shotPreset.checks.indices {
                shotPreset.checks[index]=false
        }
        recording=true
        comingindex=0
        startTime = Date()
        //注释掉则无bgm
        //audioController.playBackgroundMusic(file: "supernatural.mp3")
    }
    
    func endRecording() {
        // 停止音乐和运动更新
        audioController.stopMusic()
        motionManager.stopDeviceMotionUpdates()

        // 生成评价报告
        let evaluationReport = evaluatePerformance()
        print(evaluationReport)
        
        // 在这里添加更多处理，如保存报告或提示用户
    }
    
    func evaluateMotion(for currentBoundingBox: CGRect?) {
        var detected = false
        guard let startTime = startTime else { return }
        let currentTime = Date().timeIntervalSince(startTime)

        if let currentBox = currentBoundingBox {
            // Evaluate translation (pan) or zoom based on bounding box change
            if let previousBox = previousBoundingBox {
                let deltaX = currentBox.origin.x - previousBox.origin.x
                let deltaY = currentBox.origin.y - previousBox.origin.y
                let deltaWidth = currentBox.width - previousBox.width
                let deltaHeight = currentBox.height - previousBox.height

                var detectedOperation: CameraOperation?

                if abs(deltaX) > 3 || abs(deltaY) > 3 {
                    detectedOperation = .pan
                }
                if deltaWidth > 3 && deltaHeight > 3 {
                    detectedOperation = .zoomIn
                } else if deltaWidth < -3 && deltaHeight < -3 {
                    detectedOperation = .zoomOut
                }

                if let detectedOperation = detectedOperation {
                    detected = true
                    checkMatchingOperation(at: currentTime, operation: detectedOperation)
                    shotPreset.actualOperations.append((time: currentTime, operation: detectedOperation))
                }
            }
            previousBoundingBox = currentBox
        }

        // Evaluate rotation and other motions using device motion data
        if let motion = motionData {
            let rotationRate = motion.rotationRate
            if abs(rotationRate.x) > 1 || abs(rotationRate.y) > 1 || abs(rotationRate.z) > 1 {
                let detectedOperation = CameraOperation.rotate
                detected = true
                checkMatchingOperation(at: currentTime, operation: detectedOperation)
                shotPreset.actualOperations.append((time: currentTime, operation: detectedOperation))
            }
        }

        if !detected {
            checkMatchingOperation(at: currentTime, operation: .none)
        }
    }


    func evaluatePerformance() -> String {
        var evaluationReport = ""
        for (index, presetOperation) in shotPreset.operations.enumerated() {
            let presetTime = shotPreset.beatPoints[index]
            if shotPreset.checks[index] {
                evaluationReport += "Matched \(presetOperation) at \(presetTime). "
            } else {
                evaluationReport += "Missed \(presetOperation) at \(presetTime). "
            }
        }
        return evaluationReport
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 在音频播放结束时结束录制
        endRecording()
    }
}

class AudioController: NSObject, AVAudioPlayerDelegate {
    var backgroundMusicPlayer: AVAudioPlayer?
    var hintSoundPlayer: AVAudioPlayer?
    weak var delegate: AVAudioPlayerDelegate?

    func playBackgroundMusic(file: String) {
            if let asset = NSDataAsset(name: file) {
                do {
                    backgroundMusicPlayer = try AVAudioPlayer(data: asset.data)
                    backgroundMusicPlayer?.volume = 1.0
                    backgroundMusicPlayer?.delegate = self
                    backgroundMusicPlayer?.play()
                } catch {
                    print("Error playing background music: \(error)")
                }
            } else {
                print("Error: Audio asset not found")
            }
        }

        func playHintSound(file: String) {
            if let asset = NSDataAsset(name: file) {
                do {
                    hintSoundPlayer = try AVAudioPlayer(data: asset.data)
                    
                    hintSoundPlayer?.play()
                } catch {
                    print("Error playing hint sound: \(error)")
                }
            } else {
                print("Error: Audio asset not found")
            }
        }


    func stopMusic() {
        backgroundMusicPlayer?.stop()
        hintSoundPlayer?.stop()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 在背景音乐播放结束时通知 CameraMotionEvaluator
        if player == backgroundMusicPlayer {
            (delegate as? CameraMotionEvaluator)?.audioPlayerDidFinishPlaying(player, successfully: flag)
        }
    }
}
