import SwiftUI

struct SelectVideoView: View {
    @Environment(\.presentationMode) var presentationMode // 用于手动触发返回操作
    @ObservedObject var cardsData = CardsData() // 使用 @ObservedObject 管理数据
    @State private var selectedTag: String? = "tag-all-selected" // 记录当前选中的图像
    
    var body: some View {
        VStack(spacing: 20.0){
            HStack(alignment: .bottom){
                // 自定义返回按钮，通过 presentationMode 返回页面 A
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss() // 返回页面 A
                    NotificationCenter.default.post(name: .showTabBarNotification, object: nil)
                    for index in cardsData.cardItems.indices {
                        cardsData.cardItems[index].isSelected = false
                    }
                }) {
                    Image("back") // 返回按钮图标
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("返回")
                
                Spacer()
                
                // 跳转到 UIKit 页面 C
                Button(action:{
                    NotificationCenter.default.post(name: .openEditPage, object: nil)
                }) {
                    Text("确认")
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 152/255, green: 133/255, blue: 247/255),  // #9885F7
                                    Color(red: 116/255, green: 47/255, blue: 229/255)    // #742FE5
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 10.0)
            
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Text("选择素材").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8.0){
                            Tag(img:"tag-all-selected", selectedTag: $selectedTag)
                                .accessibilityLabel("全部")
                            Tag(img:"tag-people", selectedTag: $selectedTag)
                                .accessibilityLabel("人物")
                            Tag(img:"tag-scenery", selectedTag: $selectedTag)
                                .accessibilityLabel("风景")
                            Tag(img:"tag-animal", selectedTag: $selectedTag)
                                .accessibilityLabel("动物")
                            Tag(img:"tag-food", selectedTag: $selectedTag)
                                .accessibilityLabel("食物")
                        }
                    }.accessibilityLabel("筛选素材")
                    
                    if selectedTag == "tag-all-selected" {
                        HStack(spacing: 10.0){
                            Card(item: $cardsData.cardItems[0])
                                .aspectRatio(170/266, contentMode: .fit)
                            Card(item: $cardsData.cardItems[1])
                                .aspectRatio(170/266, contentMode: .fit)
                        }
                        Card(item: $cardsData.cardItems[2])
                            .padding(.top)
                            .aspectRatio(358/233, contentMode: .fit)
                        HStack(spacing: 10.0){
                            Card(item: $cardsData.cardItems[3])
                                .aspectRatio(170/266, contentMode: .fit)
                            Card(item: $cardsData.cardItems[4])
                                .aspectRatio(170/266, contentMode: .fit)
                        }.padding(.top)
                    } else if selectedTag == "tag-people" {
                        HStack(spacing: 10.0){
                            Card(item: $cardsData.cardItems[1])
                                .aspectRatio(170/266, contentMode: .fit)
                            Card(item: $cardsData.cardItems[4])
                                .aspectRatio(170/266, contentMode: .fit)
                        }
                    }
                    
                }.padding(.horizontal, 10)
            }
        }.background(Color.black)
            .foregroundColor(Color.white)
            .navigationBarHidden(true) // 隐藏默认导航栏
            .onAppear {
                // 页面 B 出现时，隐藏 TabBar
                NotificationCenter.default.post(name: .hideTabBarNotification, object: nil)
            }
    }
}


private struct Tag:View {
    var img: String
    @Binding var selectedTag: String?
    var body: some View {
        Button(action: {
            selectedTag = img // 点击时更新选中的图像
        }){
            VStack(alignment: .leading){
                Image(img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 86, height: 31)
                    .opacity(selectedTag == img ? 1.0 : 0.4)
            }
        }
    }
}

//#Preview {
//    SelectVideoView()
//}
