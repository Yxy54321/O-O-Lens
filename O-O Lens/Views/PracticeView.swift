import SwiftUI

struct PracticeView: View {
    var body: some View {
        
    ZStack {
        Color.black // 全屏黑色背景
            .edgesIgnoringSafeArea(.all)
        VStack(spacing: 20.0) {
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
                HStack(spacing: 11.0){
                    Image("avatar-notice")
                    Image("avatar-man")
                }
            }
           
            Button(action: {
                // 跳转
                NotificationCenter.default.post(name: .openKadianPage, object: nil)
            }) {
                Image("quick-start-ptc")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width - 32) // 设置合理的宽度
                    .cornerRadius(10)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("快速开始")


            
            VStack(alignment: .leading, spacing: 15.0){
                HStack(){
                    Text("趣味练习")
                        .font(.title2)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10.0){
                        FunCard(img:"funFilm-1",text:"宠物音乐卡点运镜")
                        FunCard(img:"funFilm-2",text:"表情管理大师")
                        FunCard(img:"funFilm-3",text:"萌宠摇镜头")
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
            NotificationCenter.default.post(name: .openKadianPage, object: nil)
        }){
            VStack(alignment: .leading){
                Image(img)
                Text(text)
                    .foregroundColor(Color(red: 217/255, green: 217/255, blue: 217/255))
                    .font(.system(size: 13))
            }
        }
    }
}

private struct FunCard:View {
    var img: String
    var text: String
    var body: some View {
        Button(action: {
            //
        }){
            VStack(alignment: .leading){
                Image(img)
                    .aspectRatio(157/88, contentMode: .fill)
                Text(text)
                    .foregroundColor(Color(red: 217/255, green: 217/255, blue: 217/255))
                    .font(.system(size: 13))
            }
        }
    }
}


#Preview {
    PracticeView()
}
