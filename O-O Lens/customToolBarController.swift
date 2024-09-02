import UIKit
import SwiftUI

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {

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
            title: "Film",
            image: UIImage(named: "film_icon_unselected")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "film_icon_selected")?.withRenderingMode(.alwaysOriginal)
        )
        
        let cutView = UIHostingController(rootView: ContentView())
        cutView.tabBarItem = UITabBarItem(
            title: "Cut",
            image: UIImage(named: "cut_icon_unselected")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "cut_icon_selected")?.withRenderingMode(.alwaysOriginal)
        )
        
        let practiseView = storyboard.instantiateViewController(withIdentifier: "PVC") as! PracticeViewController
        practiseView.tabBarItem = UITabBarItem(
            title: "Practise",
            image: UIImage(named: "practise_icon_unselected")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "practise_icon_selected")?.withRenderingMode(.alwaysOriginal)
        )
        
        viewControllers = [filmView, cutView, practiseView]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 设置 TabBar 的高度和位置
        var tabFrame = tabBar.frame
        tabFrame.size.height = 100  // 增加 TabBar 高度
        tabFrame.origin.y = view.frame.size.height - 100  // 保持在屏幕底部
        tabBar.frame = tabFrame
    }
}
