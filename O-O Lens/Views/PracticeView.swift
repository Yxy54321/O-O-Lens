import SwiftUI

struct PracticeView: View {
    var body: some View {
        
    ZStack {
        Color.black // 全屏黑色背景
            .edgesIgnoringSafeArea(.all)
        VStack(spacing: 30.0) {
            HStack(){
                HStack(spacing: 20.0){
                    Text("练习")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(Color.white)
                    Text("成就")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(Color.gray)
                }
                Spacer()
                HStack(){
                    Text("头像").foregroundColor(Color.white)
                }
            }
           
            NavigationLink(destination: SelectVideoView()) {
                Image("quick-start-ptc")
                    .resizable()
                    .aspectRatio(356/120, contentMode: .fit)
                // 改成button跳转哈
            }
            
            VStack(alignment: .leading, spacing: 15.0){
                HStack(){
                    Text("趣味练习")
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
            
            VStack(alignment: .leading, spacing: 15.0){
                HStack(){
                    Text("基本运镜练习")
                        .font(.title2)
                        .fontWeight(.medium)
                    Spacer()
                }
                HStack(){
                    BasicCard(img:"basic-1",text:"平移")
                    Spacer()
                    BasicCard(img:"basic-2",text:"摇镜头")
                    Spacer()
                    BasicCard(img:"basic-3",text:"推进")
                }
                HStack(){
                    BasicCard(img:"basic-4",text:"拉远")
                    Spacer()
                    BasicCard(img:"basic-5",text:"跟随")
                    Spacer()
                    BasicCard(img:"basic-6",text:"环绕镜头")
                }
            }.foregroundColor(Color.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
        
    }
}

private struct BasicCard:View {
    var img: String
    var text: String
    var body: some View {
        Button(action: {
            //
        }){
            VStack(alignment: .leading){
                Image(img)
                Text(text)
            }
        }
    }
}

#Preview {
    PracticeView()
}
