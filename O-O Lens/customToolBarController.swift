import UIKit
import SwiftUI

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {


    var decorationView: UIImageView?
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // 设置 TabBar 背景颜色和样式
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 38/255, green: 29/255, blue: 64/255, alpha: 1.0)  // 设置背景颜色为 #261D40

        // 自定义选中和未选中状态的文本颜色
        let normalItemAppearance = UITabBarItemAppearance()
        normalItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 129/255, green: 129/255, blue: 129/255, alpha: 1.0)]  // #818181 未选中
        normalItemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]  // 白色 选中

        // 将文字颜色应用到所有项
        appearance.stackedLayoutAppearance = normalItemAppearance
        appearance.inlineLayoutAppearance = normalItemAppearance
        appearance.compactInlineLayoutAppearance = normalItemAppearance

        // 为 UITabBar 添加圆角
        tabBar.layer.cornerRadius = 15
        tabBar.layer.masksToBounds = true

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        // 设置委托
        self.delegate = self
        
        // 创建并设置视图控制器
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let filmView = storyboard.instantiateViewController(withIdentifier: "ODV") as! VisionObjectRecognitionViewController

        filmView.tabBarItem = UITabBarItem(
            title: "摄像机",
            image: UIImage(named: "film_icon_unselected")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "film_icon_selected")?.withRenderingMode(.alwaysOriginal)
        )
        
        // 修改：将 CutViewController 嵌入到 UINavigationController 中
        let cutView = CutViewController()
        let cutNavigationController = UINavigationController(rootViewController: cutView)
        cutNavigationController.tabBarItem = UITabBarItem(
            title: "剪辑",
            image: UIImage(named: "cut_icon_unselected")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "cut_icon_selected")?.withRenderingMode(.alwaysOriginal)
        )

        let practiceView = PracticeViewController()
        let practiseNavigationController = UINavigationController(rootViewController: practiceView)
        practiseNavigationController.tabBarItem = UITabBarItem(
            title: "练习",
            image: UIImage(named: "practise_icon_unselected")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "practise_icon_selected")?.withRenderingMode(.alwaysOriginal)
        )
        
        viewControllers = [filmView, cutNavigationController,practiseNavigationController]
        
        
        // 监听隐藏和显示 tabBar 的通知
        NotificationCenter.default.addObserver(self, selector: #selector(hideTabBar), name: .hideTabBarNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showTabBar), name: .showTabBarNotification, object: nil)

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 设置 TabBar 的高度和位置
        var tabFrame = tabBar.frame
        tabFrame.size.height = 100  // 增加 TabBar 高度

        tabFrame.origin.y = view.frame.size.height - 98  // 保持在屏幕底部
        tabBar.frame = tabFrame
        
        updateDecorationView()
    }
    
    func updateDecorationView() {
        // 移除之前的装饰图形
        decorationView?.removeFromSuperview()
        // 获取当前选中的 UITabBarItem 的位置
        guard let selectedIndex = tabBar.items?.firstIndex(of: tabBar.selectedItem!) else { return }

        let itemWidth = tabBar.frame.width / CGFloat(tabBar.items!.count)
        let xOffset = itemWidth * CGFloat(selectedIndex)
        
        // 创建装饰图形
        let decorationImage = UIImage(named: "decoration_icon.png")
        decorationView = UIImageView(image: decorationImage)
        decorationView?.frame = CGRect(
            x: xOffset + (itemWidth - decorationImage!.size.width) / 2,
            y: tabBar.frame.origin.y, // 在这里调整距离
            width: decorationImage!.size.width,
            height: decorationImage!.size.height
        )
        decorationView?.contentMode = .scaleAspectFit
        
        // 添加装饰图形到视图中
        view.addSubview(decorationView!)
    }

    // 当选中的 UITabBarItem 发生改变时，更新装饰图形的位置
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateDecorationView()
    }
    
    // @objc 方法用于隐藏 tabBar 和装饰元素
    @objc func hideTabBar() {
        self.tabBar.isHidden = true
        decorationView?.isHidden = true 
    }

    // @objc 方法用于显示 tabBar 和装饰元素
    @objc func showTabBar() {
        self.tabBar.isHidden = false
        decorationView?.isHidden = false
    }
}

extension Notification.Name {
    static let hideTabBarNotification = Notification.Name("hideTabBarNotification")
    static let showTabBarNotification = Notification.Name("showTabBarNotification")
}

// ---- 显示/隐藏 Tabbar 方式 ----
// 隐藏 TabBar
// NotificationCenter.default.post(name: .hideTabBarNotification, object: nil)
// 显示 TabBar
// NotificationCenter.default.post(name: .showTabBarNotification, object: nil)

