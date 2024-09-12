import UIKit

class TimelineScroller: UIScrollView {
   
    var parentView:TimelineView? = nil
    let frameImagesView = FrameImagesView()
    let measure = TimelineMeasure()
    var trimViews: [TrimView] = []
  
    
    
    
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        self.isScrollEnabled = true
        self.isDirectionalLockEnabled = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.bounces = false
        self.decelerationRate = .fast
        self.isMultipleTouchEnabled = true
        self.delaysContentTouches = false
        self.frameImagesView.parentScroller = self
        self.addSubview(frameImagesView)
        self.measure.parentScroller = self
        self.measure.frameImagesView = self.frameImagesView
        self.measure.backgroundColor = .clear
    }
    
    func addTrimView() {
       let newTrimView = TrimView()
       newTrimView.configure(parentView!, scroller: self)
       self.trimViews.append(newTrimView)
       newTrimView.frame = self.bounds
   }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("TimelineScroller init(coder:) has not been implemented")
    }
    
    func configure(parent: TimelineView) {
        parentView = parent
        addTrimView() // 默认添加一个 TrimView 实例
    }
    
    // 分割现有的 TrimView
    func splitTrimAtCurrentTime() {
        guard let parentView = parentView else { return }

        let currentTime = parentView.centerLine.currentTime

        var currentTrimView: TrimView?

        // 使用 for 循环遍历所有 TrimView，找到包含 currentTime 的那一个
        for trimView in trimViews {
            if trimView.startKnob.knobTimePoint <= currentTime && trimView.endKnob.knobTimePoint >= currentTime {
                currentTrimView = trimView
                break
            }
        }

        // 如果没有找到包含 currentTime 的 TrimView，则退出
        guard let trimViewToSplit = currentTrimView else {
            return
        }

        // 根据当前时间创建一个新的 TrimView
        let newTrimView = TrimView()
        newTrimView.movieDuration = currentTrimView!.movieDuration
        newTrimView.mainView = currentTrimView!.mainView
        newTrimView.configure(parentView, scroller: self)
        newTrimView.frame = self.bounds
        
        // 新的 TrimView 负责当前时间到结束的部分
        let newStartTime = currentTime
        let oldEndTime = currentTrimView?.endKnob.knobTimePoint
        currentTrimView?.endKnob.knobTimePoint = newStartTime
        
        newTrimView.startKnob.knobTimePoint = newStartTime
        newTrimView.endKnob.knobTimePoint = oldEndTime!
        //important

        self.trimViews.append(newTrimView)
        self.parentView?.addSubview(newTrimView)
        
        // 更新布局
        self.parentView?.coordinate()
    }
    
    func layoutTrimViews() {
        for trimView in trimViews {
            trimView.layout()
        }
    }
    
    func reset() {
        frameImagesView.reset()
    }
    
    var ignoreScrollViewDidScroll:Bool = false
    func setContentWidth(_ width:CGFloat) {
        setContentWidth(width, setOrigin:true)
    }
    
    func setContentWidth(_ width: CGFloat, setOrigin:Bool) {
        ignoreScrollViewDidScroll = true
        self.contentSize = CGSize(width:width + self.frame.size.width, height:self.frame.size.height)
        frameImagesView.frame.size.width = width
        //measure.frame.size.width = width
        
        if setOrigin {
            let halfVisibleWidth = self.frame.size.width / 2
            //frameImagesView.frame.size.height = self.frame.size.height
            frameImagesView.frame.origin.x = halfVisibleWidth
        }
        //measure.frame.origin.x = halfVisibleWidth
        measure.setNeedsDisplay()
        frameImagesView.displayFrames()
    }
    
    var measureHeight:CGFloat = 5
    func coordinate() {
        
        let measureMin:CGFloat = 10
        
        let wholeHeight = self.frame.size.height
        measureHeight = wholeHeight * 0.2
        if measureHeight < measureMin {
            measureHeight = measureMin
        }
        frameImagesView.frame.size.height = wholeHeight - measureHeight
        if frameImagesView.animating == false {
            frameImagesView.frame.origin = CGPoint(x: self.frame.size.width / 2,y: measureHeight)
        }
        measure.frame.size.height = measureHeight
        //frameImagesView.layout()x
        
        for trimView in trimViews {
            trimView.frame = self.frame
        }
    }

    func visibleRect() -> CGRect {
        var visibleRect = frame
        visibleRect.origin = contentOffset
        if contentSize.width < frame.size.width {
            visibleRect.size.width = contentSize.width
        }
        if contentSize.height < frame.size.height {
            visibleRect.size.height = contentSize.height
        }
        if zoomScale != 1 {
            let theScale = 1.0 / zoomScale;
            visibleRect.origin.x *= theScale;
            visibleRect.origin.y *= theScale;
            visibleRect.size.width *= theScale;
            visibleRect.size.height *= theScale;
        }
        return visibleRect
    }
    
    
    //MARK: - scroll
    func setScrollPoint(_ scrollPoint:CGFloat) {
        let offset = (scrollPoint * frameImagesView.frame.size.width) + (self.frame.size.width / 2)
        
        self.contentOffset.x = offset - (self.frame.size.width / 2)
    }
    
    
    //MARK: - Touch Events
    var allTouches = [UITouch]()
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if !allTouches.contains(touch) {
                allTouches += [touch]
            }
            if !parentView!.allTouches.contains(touch) {
                parentView!.allTouches += [touch]
            }
        }
        
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if parentView!.allTouches.count == 2 {
            if parentView!.pinching {
                parentView!.updatePinch()
            } else {
                parentView!.startPinch()
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if let index = allTouches.firstIndex(of:touch) {
                allTouches.remove(at: index)
            }
            if let index = parentView!.allTouches.firstIndex(of:touch) {
                parentView!.allTouches.remove(at: index)
            }
        }
        if parentView!.pinching && parentView!.allTouches.count < 2 {
            parentView!.endPinch()
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            if let index = allTouches.firstIndex(of:touch) {
                allTouches.remove(at: index)
            }
            if let index = parentView!.allTouches.firstIndex(of:touch) {
                parentView!.allTouches.remove(at: index)
            }
        }
        
        if parentView!.pinching {
            parentView!.endPinch()
        }
    }
}

