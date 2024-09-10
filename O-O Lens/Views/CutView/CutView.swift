import SwiftUI

struct CutView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black // 全屏黑色背景
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 30.0) {
                    HStack(spacing: 20.0){
                        Text("剪辑")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(Color.white)
                        Text("教学")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(Color.gray)
                        Spacer()
                    }
                   
                    NavigationLink(destination: SelectVideoView()) {
                        VStack(spacing: 12.0){
                            Image(systemName:"plus.square.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                            Text("新建剪辑")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [
                                Color(red: 247/255, green: 201/255, blue: 133/255), // #F7C985
                                Color(red: 229/255, green: 69/255, blue: 47/255)    // #E5452F
                            ]),
                            startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 15.0){
                        HStack(){
                            Text("我的草稿")
                                .font(.title2)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        HStack(){
                            VStack(){
                                Rectangle()
                                    .foregroundColor(Color(red: 217/255, green: 217/255, blue: 217/255))
                                    .frame(width:110,height:110)
                                    .cornerRadius(12)
                                Text("剪辑教学")
                            }
                        }
                    }.foregroundColor(Color.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            .navigationTitle("剪辑")
            .navigationBarHidden(true) // 隐藏导航栏标题
        }
    }
}


#Preview {
    CutView()
}
