import SwiftUI

struct Card: View {
    var item: Item
    
    var body: some View {
        VStack{
            Image(item.imageName)
                .resizable()
                .overlay {
                    TextOverlay(item: item)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            HStack(alignment: .center) {
                Text(item.size)
                Text("|")
                Text(item.duration)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
            }
            .font(.caption)
            .foregroundColor(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.keySentence) \(item.hasSpeaker ? "，有口播" : "")")
        .accessibilityCustomContent("日期", "\(item.dateVoice)")
        .accessibilityCustomContent("位置", "\(item.address)")
        .accessibilityCustomContent("时长", "\(item.durationVoice)") // importance: .default
        .accessibilityHint("轻点两下选择素材")
    }
    
}

struct TextOverlay: View {
    var item: Item
    
    var gradient: LinearGradient {
        .linearGradient(
            Gradient(colors: [
                Color(red: 100 / 255.0, green: 100 / 255.0, blue: 100 / 255.0).opacity(0.8),
                Color(red: 203 / 255.0, green: 203 / 255.0, blue: 203 / 255.0).opacity(0.65)
            ]),
            startPoint: .bottom,
            endPoint: .center
        )
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            Image("icon-check")
                .offset(x: -10, y: 10)
                .opacity(item.isSelected ? 1 : 0)
            Spacer()
            ZStack(alignment: .leading){
                gradient
                VStack(alignment: .leading, spacing: 5.0){
                    Text(item.date)
                        .font(.headline)
                    HStack(spacing: 2) {
                        Image(systemName:"location")
                            .resizable()
                            .frame(width: 12, height: 12)
                        Text(item.address)
                            .font(.caption)
                    }
                }
                .padding(10)
            }.frame(height: 68)
            
        }
        .foregroundStyle(.white)
    }
}

//#Preview {
//    
//    HStack(spacing: 10.0){
//        Card(item: cardItems[0])
//            .aspectRatio(170/266, contentMode: .fit)
//        Card(item: cardItems[1])
//            .aspectRatio(170/266, contentMode: .fit)
//    }.padding(10)
//}
