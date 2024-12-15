//本コード

import SwiftUI

struct ContentView: View {
    // 設定画面用
    @EnvironmentObject var configStore: SettingsStore // EnvironmentObjになった設定
    
    // 横画面と共用します ほぼ全ての変数が入っている
    @EnvironmentObject var randomStore: RandomizerState

    // 横画面検出(横にしたら縦の大きさ(Vertical)はみんな .compact)
    @Environment(\.verticalSizeClass) private var vSizeClass
    
    var body: some View {
        ZStack{
            if #available(iOS 17, *){
                // for iOS 17 and up LinearGradient supports color animation
                LinearGradient(gradient: Gradient(colors: configStore.giveBackground()),
                               startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut, value: configStore.giveBackground())
            } else {
                // My workaround
                // Color animation works so "two color animation" == "gradient animation"
                AnimGradient(gradient: Gradient(colors: configStore.giveBackground()))
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut, value: configStore.giveBackground())
            }
            if vSizeClass == .regular { // 画面回転検知
                PortraitView()
            } else {
                LandscapeView()
            }
        }
        .onAppear{//起動時に一回だけ実行となる このContentViewしかないから
            if configStore.configBgNumber > configStore.colorList.count-1{ // crash guard
                configStore.configBgNumber = 20 // hardcoded
                configStore.giveRandomBgNumber()
            }
            // csvSaveの方もcrash guardつける
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore()) // environmentObjかけてるとプレビューできない
        .environmentObject(RandomizerState.shared)
}
