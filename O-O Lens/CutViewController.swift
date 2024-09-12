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
        

        NotificationCenter.default.addObserver(self, selector: #selector(openEditPage), name: .openEditPage, object: nil)
    }
    

    @objc func openEditPage() {
        if let navController = navigationController {
                print("Navigation Controller exists: \(navController)")
            } else {
                print("Navigation Controller is nil")
            }
        

        let editViewController = EditViewController()
        editViewController.view.backgroundColor = .white
        navigationController?.pushViewController(editViewController, animated: true)
        
    }
}

// 定义通知名称
extension Notification.Name {
    static let openEditPage = Notification.Name("openEditPage")
}

