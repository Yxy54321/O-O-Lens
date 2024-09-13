import Foundation

struct Item: Identifiable {
    var id = UUID()
    var date: String
    var dateVoice: String // read
    var address: String
    var size: String
    var duration: String
    var durationVoice: String // read
    var imageName: String
    var keySentence: String // read
    var hasSpeaker: Bool // read
    var isSelected: Bool = false
}

class CardsData: ObservableObject {
    @Published var cardItems: [Item] = [
        Item(date: "2024.6.24",
             dateVoice: "2024年6月24日",
             address: "上海市杨浦区四平路1386号",
             size:"12M", duration: "0:20",
             durationVoice: "20秒",
             imageName:"dog-main",
             keySentence: "在城市的街道旁边坐着一只小狗，旁边有行人经过", hasSpeaker: true,
             isSelected: false),
        Item(date: "2024.6.23",
             dateVoice: "2024年6月23日",
             address: "上海市浦东新区张江路200号",
             size:"45M", duration: "3:12",
             durationVoice: "3分12秒",
             imageName:"people-2",
             keySentence: "花店老板正在修剪她的花朵", hasSpeaker: true),
        Item(date: "2024.6.24",
             dateVoice: "2024年6月24日",
             address: "上海市浦东新区世纪大道100号",
             size:"90M", duration: "1:23",
             durationVoice: "1分23秒",
             imageName:"animal-1",
             keySentence: "一只黄狗和一只黑狗在店门口", hasSpeaker: true),
        Item(date: "2024.6.23",
             dateVoice: "2024年6月23日",
             address: "上海市徐汇区衡山路80号",
             size:"20M", duration: "0:45",
             durationVoice: "45秒",
             imageName:"flower",
             keySentence: "花店门口摆着五颜六色的花朵", hasSpeaker: false),
        Item(date: "2024.6.24",
             dateVoice: "2024年6月24日",
             address: "上海市杨浦区四平路1386号",
             size:"36M", duration: "0:34",
             durationVoice: "34秒",
             imageName:"people-1",
             keySentence: "两个人走在路上", hasSpeaker: true,
             isSelected: false),
        Item(date: "2024.6.24",
             dateVoice: "2024年6月24日",
             address: "上海市黄浦区福佑路300号",
             size:"33M" ,duration: "0:30",
             durationVoice: "30秒",
             imageName:"scenery-1",
             keySentence: "傍晚的桥被夕阳照耀", hasSpeaker: false),
    ]
    
    // 外部函数，修改某个 index 的具体内容
    func updateItem(at index: Int, with newItem: Item) {
        guard cardItems.indices.contains(index) else { return }
        cardItems[index] = newItem
    }
//    ---- 使用示例 ----
//    Button(action: {
//        // 示例：修改第一个 Item 的内容
//        var newItem = modelData.cardItems[0]
//        newItem.date = "2025.7.15"
//        newItem.address = "北京新地址"
//        modelData.updateItem(at: 0, with: newItem) // 使用外部函数修改内容
//    }) {
//        Text("Update First Item")
//    }
}

