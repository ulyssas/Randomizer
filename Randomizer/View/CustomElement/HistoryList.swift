//
//  HistoryList.swift
//  Randomizer
//
//  Created by 虎澤謙 on 2024/12/16.
//

import SwiftUI

struct HistoryList: View{
    let historySeq: [Int]
//    @State private var lazyVStackKey: UUID = UUID()
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(historySeq.indices, id: \.self){ index in
                    HStack(){
                        Text("No.\(index+1)")
                            .fontLight(size: 25)
                        Spacer()
                        Text("\(historySeq[index])")
                            .fontSemiBold(size: 42)
                            .frame(
                                height: 42,
                                alignment: .trailing)
                            .minimumScaleFactor(0.2)
                    }.padding(.horizontal, 20)
//                    Divider().background(Color.gray.opacity(0.5)) // glitchy
                }
            }
        }
    }
}
