//
//  HelloSwiftApp.swift
//  HelloSwift
//
//  Created by 虎澤謙 on 2023/11/17.
//

import SwiftUI

@main
struct HelloSwiftApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

func give1RndNumber(min: Int, max: Int, historyList: inout [Int]?) -> Int {//１個だけ生成
    var randomNum: Int = Int.random(in: min...max)
    print("今の届いたリスト: \(String(describing: historyList))")
    print("min: \(min), max: \(max)")
    if var unwrappedList = historyList{
        while unwrappedList.contains(randomNum) {//historyにある数字がでたらループ
            print("Already picked: \(randomNum)")
            randomNum = Int.random(in: min...max)
        }
        // Append the random number to the list
        unwrappedList.append(randomNum)
        
        // Update the original list with the modified one
        historyList = unwrappedList
    } else {
        // If the list is nil, create a new list with the random number
        historyList = [randomNum]
    }
    return randomNum
}

func give1RndNumberNoSave(min: Int, max: Int, historyList: [Int]?) -> Int {//履歴保持なし
    guard let historyList = historyList, !historyList.isEmpty else{ //guard文を覚える
        print("direct output")
        return Int.random(in: min...max)
    }
    //var randomNum: Int = Int.random(in: min...max) //ロール用に使うときにはまずhistoryを作る?
    print("今の届いたリストforRoll: \(String(describing: historyList))")
    print("min: \(min), max: \(max)")
    var randomNum: Int
    var attempts = 0
    repeat{
        randomNum = Int.random(in: min...max)
        attempts += 1
        /*if attempts > (max - min + 1){
            // Break the loop if all numbers are in remainedList
            // This prevents potential infinite loop
            assertionFailure("All numbers are in remainedList")
            return -1 // Or handle this case differently based on your requirements
        }*/
    }while historyList.contains(randomNum)//guardのおかげでforceUnwrapもいらない
    print("picked \(randomNum)")
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
    }/*else{
        for _ in 1...2{//amount無視
            assignedValue = contents.randomElement()!
            returnArray!.append(assignedValue)
        }
    }*/
    returnArray!.append(realAnswer)
    return returnArray!
}

func loadCSV(fileURL: URL) -> [[String]]? {
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

