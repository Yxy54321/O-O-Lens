import UIKit
import AVFoundation

class EditViewController: UIViewController, TimelinePlayStatusReceiver {
    
    
    var videoTimelineView:VideoTimelineView!
    let playerView = UIView()
    var playerLayer:AVPlayerLayer!
    
    let playButton = UIButton()
    let backButton = UIButton()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 强制横屏
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.orientationLock = .landscape
        
        // 立即将设备切换到横屏
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 恢复竖屏
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.orientationLock = .portrait
        
        // 立即将设备切换到竖屏
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    override func viewDidLoad() {

        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        // 创建一个用于背景的 UIView
            let backgroundView = UIView()

        
        ///Prepare videoTimelineView
        ///时间轴+trim knob
        let asset = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "media", ofType:"mp4")!))
        
        let layout=layout()
        
        videoTimelineView = VideoTimelineView()
        videoTimelineView.frame = layout.timeline//?
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
        
        
        
        
        ///Prepare play\redo\shiftButton
        playButton.frame = layout.button
        playButton.addTarget(self,action:#selector(self.playButtonAction), for:.touchUpInside)
        setPlayButtonImage()
        view.addSubview(playButton)
        
        // 创建 redo 和 shift 按钮
        let redoButton = UIButton()
        let shiftButton = UIButton()
        let shareButton = UIButton()
        
        // 设置按钮图片
        redoButton.setImage(UIImage(named: "redo"), for: .normal)
        shiftButton.setImage(UIImage(named: "shift"), for: .normal)
        shareButton.setImage(UIImage(named: "share"), for: .normal)
        redoButton.imageView?.contentMode = .scaleAspectFit
        shiftButton.imageView?.contentMode = .scaleAspectFit
        shareButton.imageView?.contentMode = .scaleAspectFit
        
        // 禁用按钮的自动生成约束
        redoButton.translatesAutoresizingMaskIntoConstraints = false
        shiftButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 将按钮添加到视图中
        view.addSubview(redoButton)
        view.addSubview(shiftButton)
        view.addSubview(shareButton)
        
        // 获取屏幕宽度，用于设置按钮间距
        let screenWidth = UIScreen.main.bounds.width
        
        // 设置 Auto Layout 约束
        NSLayoutConstraint.activate([
            // redoButton 约束
            redoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            redoButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -50), // 距离屏幕中心线左侧 40 点
            redoButton.widthAnchor.constraint(equalToConstant: 30), // 按钮宽度
            redoButton.heightAnchor.constraint(equalToConstant: 30), // 按钮高度

            // shiftButton 约束
            shiftButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            shiftButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 50), // 距离屏幕中心线右侧 40 点
            shiftButton.widthAnchor.constraint(equalToConstant: 30), // 按钮宽度
            shiftButton.heightAnchor.constraint(equalToConstant: 30), // 按钮高度
            
            // shareButton 约束
            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0), // 距离屏幕上方 0 点
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), // 距离右边缘 20 点
            shareButton.widthAnchor.constraint(equalToConstant: 40), // 按钮宽度
            shareButton.heightAnchor.constraint(equalToConstant: 40) // 按钮高度
        ])
        
        
        //返回上一页
    
        backButton.frame = layout.backbutton
        backButton.setImage(UIImage(named: "back")?.resized(to: CGSize(width: 40, height: 40)), for: .normal)
        backButton.addTarget(self,action:#selector(self.backButtonAction), for:.touchUpInside)
        view.addSubview(backButton)


        
        // 设置背景视图的 frame，覆盖整个屏幕
        backgroundView.frame = CGRect(x: 0, y: 0, width:1000, height:1000)
        
        // 设置背景颜色为 #121212
        backgroundView.backgroundColor = UIColor(red: 18/255.0, green: 18/255.0, blue: 18/255.0, alpha: 1.0)
        
        // 将背景视图添加到主视图的最底层
        self.view.addSubview(backgroundView)
        self.view.sendSubviewToBack(backgroundView)

        // 添加紫色背景图作为 toolbar 背景
        let purpleBackgroundView = UIImageView()
        purpleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        purpleBackgroundView.image = UIImage(named: "purple_background") // 设置背景图片
        purpleBackgroundView.contentMode = .scaleToFill
        purpleBackgroundView.clipsToBounds = true // 防止图片超出视图边界
//        purpleBackgroundView.layer.borderWidth = 2.0
//        purpleBackgroundView.layer.borderColor = UIColor.white.cgColor
        view.addSubview(purpleBackgroundView)

        
        

        // 使用 UIStackView 来排列按钮
        let backwardButton = createButton(named: "backward", action: #selector(backwardButtonAction))
        let forwardButton = createButton(named: "forward", action: #selector(self.forwardButtonAction))
        let splitButton = createButton(named: "split", action: #selector(self.splitButtonAction))
        let deleteButton = createButton(named: "delete", action: #selector(self.deleteButtonAction))
        let textButton = createButton(named: "text", action: #selector(self.textButtonAction))
        let audioButton = createButton(named: "audio", action: #selector(self.audioButtonAction))

        let buttonStackView = UIStackView(arrangedSubviews: [backwardButton, forwardButton, splitButton, deleteButton, textButton, audioButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .equalSpacing
        buttonStackView.alignment = .center
        buttonStackView.spacing = 100
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)
        
        // 使用 Auto Layout 设置 purpleBackgroundView 的约束
        NSLayoutConstraint.activate([
            purpleBackgroundView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
            purpleBackgroundView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
            purpleBackgroundView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 105),
            purpleBackgroundView.heightAnchor.constraint(equalToConstant: 170)
        ])

        // 设置按钮栏的自动布局，使其位于 purpleBackgroundView 的中心
        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: purpleBackgroundView.centerXAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: purpleBackgroundView.centerYAnchor,constant: -40),
            buttonStackView.trailingAnchor.constraint(equalTo: purpleBackgroundView.trailingAnchor, constant: -50),
            buttonStackView.leadingAnchor.constraint(equalTo: purpleBackgroundView.trailingAnchor, constant: 50)
        ])
    }

    func createButton(named: String, action: Selector) -> UIButton {
        let button = UIButton()
          
          // 设置按钮图片
          button.setImage(UIImage(named: named), for: .normal)
          
          // 确保图片保持比例
          button.imageView?.contentMode = .scaleAspectFit
          
          // 禁用自动生成的约束
          button.translatesAutoresizingMaskIntoConstraints = false
          
          // 添加点击事件
          button.addTarget(self, action: action, for: .touchUpInside)
          
          // 设置按钮宽度和高度的约束
          NSLayoutConstraint.activate([
              button.widthAnchor.constraint(equalToConstant: 70),
              button.heightAnchor.constraint(equalToConstant: 70)
          ])
          
          return button
    }
    
    
    override func viewDidLayoutSubviews() {
        videoTimelineView.frame = layout().timeline
//        playerView.frame = layout().player
//        playerLayer.frame.size = playerView.frame.size
        playButton.frame = layout().button
        videoTimelineView.viewDidLayoutSubviews()
    }

    func layout() -> (timeline:CGRect, player:CGRect, button:CGRect,backbutton:CGRect
                      ,purpleBackground: CGRect, backwardButton: CGRect, forwardButton: CGRect, splitButton: CGRect, deleteButton: CGRect, textButton: CGRect, audioButton: CGRect) {
        let timeline = CGRect(x: 0,y:view.frame.size.height * 0.3, width:view.frame.size.width, height:view.frame.size.height / 3.5)
        let player = CGRect(x:0, y:40, width:view.frame.size.width, height:view.frame.size.height * 0.4)
//let button = CGRect(x:(view.frame.size.width - 60) / 2, y:view.frame.size.height - 60, width:60, height:60)
        let button = CGRect(x:(view.frame.size.width - 60) / 2, y:30, width:60, height:60)
        
        let backbutton = CGRect(x:20, y:30, width:60, height:60)
        
        //toolbar buttons
        // 紫色背景的frame
        let purpleBackground = CGRect(x: 20, y: view.frame.size.height - 100, width: view.frame.size.width - 40, height: 80)

        // 按钮的frame
        let buttonY: CGFloat = purpleBackground.origin.y + 10 // 按钮相对紫色背景的Y轴位置

        let backwardButton = CGRect(x: 30, y: buttonY, width: 40, height: 40)
        let forwardButton = CGRect(x: backwardButton.maxX + 20, y: buttonY, width: 40, height: 40)
        let splitButton = CGRect(x: forwardButton.maxX + 20, y: buttonY, width: 40, height: 40)
        let deleteButton = CGRect(x: splitButton.maxX + 20, y: buttonY, width: 40, height: 40)
        let textButton = CGRect(x: deleteButton.maxX + 20, y: buttonY, width: 40, height: 40)
        let audioButton = CGRect(x: textButton.maxX + 20, y: buttonY, width: 40, height: 40)
        
        return (timeline, player, button, backbutton,purpleBackground, backwardButton, forwardButton, splitButton, deleteButton, textButton, audioButton)
    }
    
    
    
    
    ///button actions

    @objc func backButtonAction() {
        navigationController?.popViewController(animated: true)
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
    
    //toolbar button actions
    @objc func backwardButtonAction() {
        // 后退按钮被点击时的操作逻辑
        print("Backward button clicked")
    }

    @objc func forwardButtonAction() {
        // 前进按钮被点击时的操作逻辑
        print("Forward button clicked")
    }

    @objc func splitButtonAction() {
        videoTimelineView.timelineView.scroller.splitTrimAtCurrentTime()
    }

    @objc func deleteButtonAction() {
        // 删除按钮被点击时的操作逻辑
        print("Delete button clicked")
    }

    @objc func textButtonAction() {
        // 文字按钮被点击时的操作逻辑
        print("Text button clicked")
    }

    @objc func audioButtonAction() {
        // 音频按钮被点击时的操作逻辑
        print("Audio button clicked")
    }

    func setPlayButtonImage() {
        if playButtonStatus {
            // 设置播放状态时的图片 (stop 图标)
            self.playButton.setImage(UIImage(named: "stop"), for: .normal)
        } else {
            // 设置暂停状态时的图片 (play 图标)
            self.playButton.setImage(UIImage(named: "play"), for: .normal)
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

