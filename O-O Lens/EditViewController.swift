import UIKit
import AVFoundation

class EditViewController: UIViewController, TimelinePlayStatusReceiver {

    var videoTimelineView:VideoTimelineView!
    let playerView = UIView()
    var playerLayer:AVPlayerLayer!
    let playButton = UIButton()
    let splitButton = UIButton()

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        ///Prepare videoTimelineView
        ///时间轴+trim knob
        let asset = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "movie1", ofType:"mov")!))
        
        videoTimelineView = VideoTimelineView()
        videoTimelineView.frame = layout().timeline//?
        videoTimelineView.new(asset:asset)
        videoTimelineView.playStatusReceiver = self
        
        videoTimelineView.repeatOn = true//?
        videoTimelineView.setTrimIsEnabled(true)//?
        videoTimelineView.setTrimmerIsHidden(false)//?
        view.addSubview(videoTimelineView)
        
        videoTimelineView.moveTo(0, animate:false)
        videoTimelineView.setTrim(start:5, end:10, seek:nil, animate:false)

        
        
        ///Prepare playerView
        let player = videoTimelineView.player!
//        //like below
//        //let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
//        //videoTimelineView.player = player
//        
//        let playerFrame = layout().player
//        playerLayer = AVPlayerLayer(player: player)
//        playerLayer.frame.size = playerFrame.size
//        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        player.actionAtItemEnd   = AVPlayer.ActionAtItemEnd.none
        
//        playerView.frame = playerFrame
//        playerView.layer.addSublayer(playerLayer)
//        view.addSubview(playerView)
        
        
        
        
        ///Prepare playButton
        playButton.frame = layout().button
        playButton.addTarget(self,action:#selector(self.playButtonAction), for:.touchUpInside)
        setPlayButtonImage()
        view.addSubview(playButton)
        
        splitButton.frame=layout().splitbutton
        splitButton.setImage(UIImage(named: "split")?.resized(to: CGSize(width: 60, height: 60)), for: .normal)
        splitButton.addTarget(self,action:#selector(self.splitButtonAction), for:.touchUpInside)
        view.addSubview(splitButton)
        
    }
    
    override func viewDidLayoutSubviews() {
        videoTimelineView.frame = layout().timeline
//        playerView.frame = layout().player
//        playerLayer.frame.size = playerView.frame.size
        playButton.frame = layout().button
        videoTimelineView.viewDidLayoutSubviews()
    }

    func layout() -> (timeline:CGRect, player:CGRect, button:CGRect,splitbutton:CGRect) {
        let timeline = CGRect(x: 0,y:view.frame.size.height * 0.25, width:view.frame.size.width, height:view.frame.size.height / 3)
        let player = CGRect(x:0, y:40, width:view.frame.size.width, height:view.frame.size.height * 0.4)
//        let button = CGRect(x:(view.frame.size.width - 60) / 2, y:view.frame.size.height - 60, width:60, height:60)
        
        let button = CGRect(x:(view.frame.size.width - 60) / 2, y:0, width:60, height:60)
        
        let splitbutton = CGRect(x:(view.frame.size.width - 240) / 2, y:0, width:60, height:60)
        
        return (timeline, player, button,splitbutton)
    }
    
    ///button actions

    @objc func splitButtonAction() {
        videoTimelineView.timelineView.scroller.splitTrimAtCurrentTime()
    }
    
    var playButtonStatus:Bool = false
    @objc func playButtonAction() {
        playButtonStatus = !playButtonStatus
        if playButtonStatus {
            videoTimelineView.play()
        } else {
            videoTimelineView.stop()
        }
        setPlayButtonImage()
    }
    
    func setPlayButtonImage() {
        if playButtonStatus {
            self.playButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .light, scale: .medium)), for: .normal)
        } else {
            self.playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .light, scale: .medium)), for: .normal)
        }
    }
    
    func videoTimelineStopped() {
        playButtonStatus = false
        setPlayButtonImage()
    }
    
    func videoTimelineMoved() {
        let time = videoTimelineView.currentTime
        print("time: \(time)")
    }
    
    func videoTimelineTrimChanged() {
        let trim = videoTimelineView.currentTrim()
        print("start time: \(trim.start)")
        print("end time: \(trim.end)")
    }

    
}

