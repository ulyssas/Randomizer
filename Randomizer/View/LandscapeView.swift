//
//  ExternalView.swift
//  Randomizer
//
//  Created by 虎澤謙 on 2024/04/05.
//

import SwiftUI

struct LandscapeView: View {
    @EnvironmentObject var configStore: SettingsStore // EnvironmentObjになった設定
    @EnvironmentObject var randomStore: RandomizerState
    @State private var showingAlert: Bool = false
    var body: some View {
        ZStack(){
            Button(action: {
                print("big number pressed")
                buttonNext()
            }){ 
                if randomStore.isFileSelected == true && configStore.allowLandscapeNames == true { // CSVあり
                    Text(randomStore.csvNameStore[0][randomStore.rollDisplaySeq![randomStore.rollListCounter-1]-1])
                        .fontSemiBoldRound(size: 320, rolling: randomStore.isTimerRunning)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .minimumScaleFactor(0.2)
                } else { // CSVなし（通常）
                    Text(verbatim: "\(randomStore.rollDisplaySeq![randomStore.rollListCounter-1])")
                        .fontSemiBoldRound(size: 320, rolling: randomStore.isTimerRunning)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .minimumScaleFactor(0.2)
                }
            }.disabled(randomStore.isButtonPressed)
                .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in//振ったら
                    if randomStore.isButtonPressed == false{
                        print("device shaken!")
                        buttonNext()
                    }
                }
            .alert("All drawn", isPresented: $showingAlert) {
                // アクションボタンリスト
            } message: {
                Text("press Start over to reset")
            }
        }
        .onAppear{
            initReset()
        }
    }
    
    func initReset() {//起動時に実行 No.0/表示: 0 もう Initすらいらないのか？
//        print("HistorySequence \(randomStore.historySeq as Any)\ntotal would be No.\(randomStore.drawLimit)")
    }
    
    func buttonNext() {
        guard !randomStore.isButtonPressed else { return } // isButtonPressed == trueなら帰る
        randomStore.isButtonPressed = true // 同時押しブロッカー
        if randomStore.drawCount >= randomStore.drawLimit{ // チェック
            self.showingAlert.toggle()
            randomStore.isButtonPressed = false
        }
        else{
            randomStore.randomNumberPicker(resetting: false, configStore: configStore)//まとめました
        }
    }
}

#Preview {
    LandscapeView()
        .environmentObject(SettingsStore())
        .environmentObject(RandomizerState.shared)
}
