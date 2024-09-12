import SwiftUI
import UIKit


struct EditViewControllerRepresentable: UIViewControllerRepresentable {
    
    // 这里是创建 UIViewController 实例的方法
    func makeUIViewController(context: Context) -> EditViewController {
        return EditViewController() // 创建并返回一个 EditViewController 实例
    }
    
    // 这里是更新 UIViewController 的方法
    func updateUIViewController(_ uiViewController: EditViewController, context: Context) {
        // 在需要更新 UIViewController 时实现
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Text("选择素材")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // 添加“开始剪辑”按钮
                        // 使用 EditViewControllerRepresentable 作为目标视图
                                               NavigationLink(destination: EditViewControllerRepresentable()) {
                                                   Text("开始剪辑")
                                                       .fontWeight(.bold)
                        }
                        .padding(.trailing, 10)
                    }
                    HStack(spacing: 10.0) {
                        Card(item: cardItems[0])
                            .aspectRatio(170/266, contentMode: .fit)
                        Card(item: cardItems[1])
                            .aspectRatio(170/266, contentMode: .fit)
                    }
                    Card(item: cardItems[2])
                        .padding(.top)
                        .aspectRatio(358/233, contentMode: .fit)
                    HStack(spacing: 10.0) {
                        Card(item: cardItems[3])
                            .aspectRatio(170/266, contentMode: .fit)
                        Card(item: cardItems[4])
                            .aspectRatio(170/266, contentMode: .fit)
                    }
                    .padding(.top)
                }
                .padding(10)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
