//
//  CutViewController.swift
//  O-O Lens
//
//  Created by lankai on 2024/9/1.
//
import UIKit
import Foundation
import SwiftUI

class PracticeViewController: UIViewController{
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let practiceView = PracticeView()
        let hostingController = UIHostingController(rootView: practiceView)
        
        // 添加到视图层次
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(openKadianPage), name: .openKadianPage, object: nil)
    }
    
    @objc func openKadianPage() {
        if let navController = navigationController {
                print("Navigation Controller exists: \(navController)")
            } else {
                print("Navigation Controller is nil")
            }
        
// todo: 改成跳转卡点页
        print("卡点页")
//        let editViewController = EditViewController()
//        editViewController.view.backgroundColor = .white
//        navigationController?.pushViewController(editViewController, animated: true)
        
    }

}


extension Notification.Name {
    static let openKadianPage = Notification.Name("openKadianPage")
}

