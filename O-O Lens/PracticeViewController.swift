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
    }

}
