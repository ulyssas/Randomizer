//
//  MainFunctions.swift
//  Randomizer
//
//  Created by 虎澤謙 on 2024/04/05.
//

import SwiftUI
import UIKit

func give1RndNumber(min: Int, max: Int, historyList: [Int]?) -> Int {//履歴保持なし
    guard let historyList = historyList, !historyList.isEmpty else{ //guard文を覚える
        //print("give1rnd direct output")
        return Int.random(in: min...max)
    }
    //var randomNum: Int = Int.random(in: min...max) //ロール用に使うときにはまずhistoryを作る?
    //print("今の届いたリストforRoll: \(String(describing: historyList))")//ログが多いと遅くなる
    //print("min: \(min), max: \(max)")
    var randomNum: Int
    var attempts = 0
    repeat{
        randomNum = Int.random(in: min...max)
        attempts += 1
//        if attempts > (max - min + 1){
//            // Break the loop if all numbers are in remainedList
//            // This prevents potential infinite loop
//            assertionFailure("All numbers are in remainedList")
//            return -1 // Or handle this case differently based on your requirements
//        }
    }while historyList.contains(randomNum)//guardのおかげでforceUnwrapもいらない
    //print("picked \(randomNum)")
    return randomNum
}

func giveRandomSeq(contents: [Int]!, length: Int, realAnswer: Int) -> [Int]{//ロールの数列生成
    var assignedValue: Int = 0
    var returnArray: [Int]? = [Int]()
    let listLength: Int = contents.count//リストの長さ
    if listLength > 1{
        for i in 1...length-1{
            assignedValue = contents.randomElement()!//ランダムに1つ抽出
            if i > 1{//1回目以降は
                while assignedValue == returnArray![i-2]{//0換算で-1, その一個前だから-2
                    assignedValue = contents.randomElement()!
                }
            }
            returnArray!.append(assignedValue)
        }
        returnArray!.append(realAnswer)
    }
    return returnArray!
}

func interpolateQuadratic(t: Double, minValue: Double, maxValue: Double) -> Double { // 二次関数
    let clampedT = max(0, min(1, t))//0から1の範囲で制限
    return (1 - clampedT) * maxValue + clampedT * minValue
}

func firstLang() -> String {
    let prefLang = Locale.preferredLanguages.first
    return prefLang!
}

func setMessageReset(language: String) -> String {
    if language.hasPrefix("ja"){
        return "やり直しを押して変更を適用"
    }
    else {
        return "press Start Over to apply changes"
    }
}

func setMessageErrorLoad(language: String) -> String {
    if language.hasPrefix("ja"){
        return "ファイルを読み込めませんでした。\n「このiPhone内」から選択してください。"
    }
    else {
        return "Error loading files. \nPlease load files from local storage."
    }
}

func giveHaptics(impactType: String, ifActivate: Bool){
    if ifActivate == false{
        return
    }
    else if impactType == "soft"{
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()//Haptic Feedback
        //AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {} // AudioToolbox
    }
    else if impactType == "medium"{
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()//Haptic Feedback
    }
}

func loadCSV(fileURL: URL) -> [[String]]? { // AI written code
    do {
        // CSVファイルの内容を文字列として読み込む
        var csvString = try String(contentsOf: fileURL, encoding: .utf8)
        
        // キャリッジリターン文字を改行文字に変換
        csvString = csvString.replacingOccurrences(of: "\r", with: "")
        
        // 改行とカンマでCSVを分割し、行と列を取得
        var rows = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        var columns = rows[0].components(separatedBy: ",")
        
        // 転置が必要な場合は行と列を入れ替える
        if rows.count < columns.count {
            (rows, columns) = (columns, rows)
        }
        
        // 転置した結果を格納する配列
        var transposedCSV = [[String]]()
        
        // 各列ごとに行を作成して転置
        for columnIndex in 0..<columns.count {
            var transposedRow = [String]()
            for rowIndex in 0..<rows.count {
                let rowData = rows[rowIndex].components(separatedBy: ",")
                
                // IndexOutOfRangeを防ぐために、rowDataの要素数がcolumnIndex未満の場合は空文字列を追加
                if columnIndex < rowData.count {
                    transposedRow.append(rowData[columnIndex])
                } else {
                    transposedRow.append("") // もしくはエラーハンドリングを追加
                }
            }
            transposedCSV.append(transposedRow)
        }
        
        return transposedCSV
    } catch {
        // エラーが発生した場合はnilを返す
        print("Error reading CSV file: \(error)")
        return nil
    }
}

func giveRandomBackground(conf: Int, current: Int) -> Int{
    if 0...5 ~= conf{//confが0以上3以下なら　つまりconfをそのままgradPickerに
        return conf//currentを直接編集しない
    }else{
        var randomNumber: Int
        repeat{
            randomNumber = Int.random(in: 0...5)//0...3は自分で色と対応させる
        }while current == randomNumber
        return randomNumber
    }
}

func returnColorCombo(index: Int) -> [Color] {
    let colorList: [[Color]] = [
        [Color.blue, Color.purple], // Default
        [Color.blue, Color.red], // Twilight
        [Color.red, Color.green], // Mountain
        [Color.green, Color.blue], // Ocean
        [Color.mint, Color.indigo], // Sky
        [Color.black, Color.green] // 実験体
    ]
    return colorList[index]
}

final class SettingsBridge: ObservableObject{
    @AppStorage("Haptics") var isHapticsOn: Bool = true
    @AppStorage("rollingAnimation") var isRollingOn: Bool = true
    @AppStorage("rollingAmount") var rollingCountLimit: Int = 20//数字は25個だけど最後の数字が答え
    @AppStorage("rollingSpeed") var rollingSpeed: Int = 4//1から7まで
    @AppStorage("currentGradient") var gradientPicker: Int = 0    //今の背景の色設定用　設定画面ではいじれません
    @AppStorage("configBackgroundColor") var configBgColor = 0 //0はデフォルト、この番号が大きかったらランダムで色を
}

final class ExternalBridge: ObservableObject{ // ContentViewで使える？
    @Published var externalNumber: String = ""
    @Published var isShowingOnExternal: Bool = false
}



