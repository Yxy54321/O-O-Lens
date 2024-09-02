


import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Text("选择素材").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                }
                HStack(spacing: 10.0){
                    Card(item: cardItems[0])
                        .aspectRatio(170/266, contentMode: .fit)
                    Card(item: cardItems[1])
                        .aspectRatio(170/266, contentMode: .fit)
                }
                Card(item: cardItems[2])
                    .padding(.top)
                    .aspectRatio(358/233, contentMode: .fit)
                HStack(spacing: 10.0){
                    Card(item: cardItems[3])
                        .aspectRatio(170/266, contentMode: .fit)
                    Card(item: cardItems[4])
                        .aspectRatio(170/266, contentMode: .fit)
                }.padding(.top)
            }.padding(10)
        }
    }
}

