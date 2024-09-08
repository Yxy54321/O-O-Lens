import SwiftUI

struct CutView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black // 全屏黑色背景
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    NavigationLink(destination: SelectVideoView()) {
                        Text("新建剪辑")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(.top, 80.0)
            }
            .navigationTitle("剪辑")
//            .navigationBarHidden(true) // 隐藏导航栏标题
        }
    }
}


#Preview {
    CutView()
}
