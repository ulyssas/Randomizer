//
//  RandomizerState.swift
//  Randomizer
//
//  Created by 虎澤謙 on 2024/05/22.
//

import SwiftUI
import CoreData

// 参考：https://useyourloaf.com/blog/swiftui-supporting-external-screens/ aka inject it!

final class RandomizerState: ObservableObject{
    // main
    // AppStorageじゃなくする
    @AppStorage("minValue") var minBoxValueLock: Int = 1 // min->maxの順
    @AppStorage("maxValue") var maxBoxValueLock: Int = 50//Start Overを押すまでここにkeep
    @Published var drawCount: Int = 0       //今何回目か
    @Published var drawLimit: Int = 0       //何回まで引けるか
    @Published var realAnswer: Int = 0      //本当の答え
    
    // CoreDataアクセス用
    private var viewContext: NSManagedObjectContext {
        return DataController.shared.viewContext
    }
    
    // history&Shuffler
    @Published var historySeq: [Int]? = []      //履歴 ない時は0じゃなくてEmpty
    private var remainderSeq: Set<Int> = [0]    //弾いていって残った数字 ロール用
    @Published var rollDisplaySeq: [Int]? = [0] //ロール表示用に使う数字 ここが0だから初期化すると0
    @Published var rollListCounter: Int = 1     //ロールのリスト上を移動
    @Published var isTimerRunning: Bool = false
    @Published var isButtonPressed: Bool = false//同時押しを無効にする
    var rollTimer: Timer?
    var rollSpeed: Double = 25      //実際のスピードをコントロール 25はrollMaxSpeed
    let rollMinSpeed: Double = 0.4  //始めは早く段々遅く　の設定 デフォルトは4倍にして使います。
    let rollMaxSpeed: Double = 6
    
    // fileImporter
    // ここもAppStorageじゃなくしたい
    @AppStorage("openedFileName") var openedFileName = ""          //ファイル名表示用
    @AppStorage("isFileSelected") var isFileSelected: Bool = false
    @Published var csvNameStore = [[String]]()  //名前を格納する
    
    static let shared = RandomizerState() // 参考
    
    // ここでCoreDataからデータを復元する(Persistent)
    init() {
        self.loadHistory()
        self.loadCsvNames()
        
        if let historySeq = historySeq, !historySeq.isEmpty{
            drawCount = historySeq.count
            rollDisplaySeq?[0] = historySeq[drawCount - 1]
            print("current draw is \(drawCount)")
            print("current drawSEQ: \(String(describing: rollDisplaySeq))")
            print("NAMES is \(csvNameStore)")
            
        } else if self.maxBoxValueLock != csvNameStore.count{ // if loading csv has failed
            print("Sorry, but csv didn't load properly.")
            drawCount = 0 // just in case. history shouln't be there tho
            clearCsvNames()
            isFileSelected = false
        }else {
            drawCount = 0
        }
        // 設定
        drawLimit = maxBoxValueLock - minBoxValueLock + 1
    }
    
    func randomNumberPicker(resetting: Bool, configStore: SettingsStore){//アクションを一つにまとめた mode 1はNext, mode 2はリセット
        drawLimit = maxBoxValueLock - minBoxValueLock + 1
        
        // draw next number
        if !resetting{
            drawCount += 1
        }
        else{
            drawCount = 1
        }
        remainderSeq = Set<Int>()
        rollSpeed = interpolateQuadratic(t: 0,
                                         minValue: rollMinSpeed * Double(configStore.rollingSpeed + 3),
                                         maxValue: rollMaxSpeed * Double(configStore.rollingSpeed)) //速度計算 0?????
        rollListCounter = 1
        let remaining = drawLimit - drawCount + 1 // 残り
        print("\(remaining) numbers remaining")
        
        // MARK: Terrible code
        realAnswer = give1RndNumber(min: minBoxValueLock, max: maxBoxValueLock, historyList: historySeq)
        if configStore.isRollingOn && remaining > 1{ // give1Rndを通る道
            remainderSeq = giveRemainSeq(min: minBoxValueLock, max: maxBoxValueLock, historyList: historySeq, length: configStore.rollingCountLimit)
            rollDisplaySeq = giveRandomSeq(contents: remainderSeq, length: configStore.rollingCountLimit, realAnswer: realAnswer)
            // MARK: ↑
//            logging(realAnswer: realAnswer) // ログ　releaseでは消す これで相当遅くなっている
            startTimer(configStore: configStore)//ロール開始, これで履歴にも追加
        }else{//1番最後と、ロールを無効にした場合こっちになります
            configStore.giveRandomBgNumber()
            historySeq?.append(realAnswer) //履歴追加重たすぎる
            saveHistory(value: realAnswer) //履歴ほぞん
            rollDisplaySeq = [realAnswer]//答えだけ追加
            giveHaptics(impactType: "medium", ifActivate: configStore.isHapticsOn)
            isButtonPressed = false
        }
    }
    
    //MARK: TIMER タイマーに使用される関数
    func startTimer(configStore: SettingsStore) {
        isTimerRunning = true
        rollTimer = Timer.scheduledTimer(withTimeInterval: 1 / rollSpeed, repeats: true) { timer in
            self.timerCountHandler(configStore: configStore)
        }
    }

    func timerCountHandler(configStore: SettingsStore){
        if self.rollListCounter + 1 >= configStore.rollingCountLimit {
            self.stopTimer()
            self.rollListCounter += 1
            configStore.giveRandomBgNumber()
            self.historySeq?.append(self.realAnswer)//"?"//現時点でのrealAnswer
            saveHistory(value: realAnswer) // こっちも保存
            giveHaptics(impactType: "medium", ifActivate: configStore.isHapticsOn)
            self.isButtonPressed = false
            return
        }
        else{
            giveHaptics(impactType: "soft", ifActivate: configStore.isHapticsOn)
            
            let t: Double = Double(self.rollListCounter) / Double(configStore.rollingCountLimit)//カウントの進捗
            self.rollSpeed = interpolateQuadratic(t: t, minValue: self.rollMinSpeed * Double(configStore.rollingSpeed + 3), maxValue: self.rollMaxSpeed * Double(configStore.rollingSpeed)) //速度計算
            // print("Now rolling aty \(rollSpeed), t is \(t)")
            self.updateTimerSpeed(configStore: configStore)
            self.rollListCounter += 1
        }
    }
    
    func stopTimer() {
        self.isTimerRunning = false
        self.rollTimer?.invalidate()//タイマーを止める。
        self.rollTimer = nil
    }

    func updateTimerSpeed(configStore: SettingsStore) {
        if self.isTimerRunning == true {
            self.rollTimer?.invalidate()
            self.rollTimer = Timer.scheduledTimer(withTimeInterval: 1 / self.rollSpeed, repeats: true) { timer in
                self.timerCountHandler(configStore: configStore)
            }
        }
    }

    //MARK: CoreDataHISTORY
    // 保存された履歴読み込み
    func loadHistory(){
        let fetchRequest: NSFetchRequest<HistoryDataSeq> = HistoryDataSeq.fetchRequest()
        do {
            let items = try viewContext.fetch(fetchRequest)
            if items.isEmpty {
                print("HISTORY: No items found")
                historySeq = []
            } else {
                historySeq = items.map { Int($0.value) }
            }
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    // 履歴保存
    private func saveHistory(value: Int) {
        let new = HistoryDataSeq(context: viewContext)
        new.value = Int64(value)
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    // 使わない
    private func deleteOneHistory(item: HistoryDataSeq){
        viewContext.delete(item)
        do{
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    // 履歴削除 外からも消します
    func clearHistory(){
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = HistoryDataSeq.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
            historySeq = []
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    //MARK: CoreDataNAMES
    // 保存された名前読み込み
    // CSVの一列目だけを保存/読み込み
    private func loadCsvNames(){
        let fetchRequest: NSFetchRequest<CsvNamesSeq> = CsvNamesSeq.fetchRequest()
        do {
            let items = try viewContext.fetch(fetchRequest)
            if items.isEmpty {
                print("CSV: No items found")
                isFileSelected = false // DONT CRASH
                csvNameStore = []
            } else {
                print(items)
                let loadedCsvName = items.map { String($0.name!) }
                csvNameStore.append(loadedCsvName)
                print(csvNameStore)
            }
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    // 一列目のみ保存
    func saveCsvNames(csvNames: [[String]]){
        let batchInsert = NSBatchInsertRequest(entity: CsvNamesSeq.entity(), objects: csvNames[0].map { ["name": String($0)] })
        do {
            print("Saving CSV Names")
            try viewContext.execute(batchInsert)
            try viewContext.save()
        } catch {
            print("Failed to batch insert history sequences: \(error.localizedDescription)")
        }
    }
    
    // 名前削除 外からも消します
    func clearCsvNames(){
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CsvNamesSeq.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
            csvNameStore = [[String]]()
            print("successfully cleared csv")
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func logging(realAnswer: Int) {
        print("///////////////DEBUG SECTION")
        print("Randomly picked remain: \(remainderSeq)")
        print("displaySeq: \(rollDisplaySeq as Any)")//ロール中は押せない
        print("HistorySequence is \(historySeq as Any)")
        print("current draw is \(realAnswer) and No.\(drawCount)")
        print("total is \(drawLimit)")
        print("///////////////END OF DEBUG SECTION")
    }
}
