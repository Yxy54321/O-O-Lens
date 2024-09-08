import UIKit
import SwiftUI

class CutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建 SwiftUI 主页面 A（CutView）
        let cutView = CutView()
        let hostingController = UIHostingController(rootView: cutView)
        
        // 添加到视图层次
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
        

        // 监听跳转到页面 C 的通知
        // NotificationCenter.default.addObserver(self, selector: #selector(openPageC), name: .openPageC, object: nil)
        // 跳转到横版剪辑页
    }
    
    // 跳转到 UIKit 的页面 C
//    @objc func openPageC() {
//        let pageCViewController = PageCViewController()
//        navigationController?.pushViewController(pageCViewController, animated: true)
         // 跳转到横版剪辑页
//    }
}

// 定义通知名称
extension Notification.Name {
    static let openPageC = Notification.Name("openPageC") // 改成跳转到横版剪辑页的名称
}

