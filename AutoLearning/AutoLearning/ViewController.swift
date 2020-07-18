//
//  ViewController.swift
//  AutoLearning
//
//  Created by ShenYj on 2020/7/16.
//  Copyright © 2020 ShenYj. All rights reserved.
//

import Cocoa
import AVKit

class ViewController: NSViewController {
    
    // MARK: 辅助性
    private var requestTimeInterVal: TimeInterval {
        get {
            return InfoManager.shared.offsetSeconds
        }
    }
    private lazy var thread: Thread = {
        let thread = Thread(target: self, selector: #selector(loop), object: nil)
        return thread
    }()
    
    private lazy var autoLearnTimer: DispatchSourceTimer? = {
        let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue.global())
        timer.schedule(deadline: .now(), repeating: requestTimeInterVal)
        timer.setEventHandler { [weak self] in
            self?.loop()
        }
        return timer
    }()
    
    // MARK: 控件

    // 本门课程的学习进度
    @IBOutlet weak var learningLessonProgressIndicator: NSProgressIndicator!
    // 当前章节学习进度
    @IBOutlet weak var learningProgressIndicator: NSProgressIndicator!
    // token输入框
    @IBOutlet weak var inputTokenTextField: NSTextField!
    // 登录按钮
    @IBOutlet weak var LoginButton: NSButton!
    // log输出框
    @IBOutlet weak var userInfoTextView: NSTextView!
    // 切换课程
    @IBOutlet weak var selCourseButton: NSPopUpButton!
    // 播放倍速
    @IBOutlet weak var playSpeedSegment: NSSegmentedControl!
    // 开始学习按钮
    @IBOutlet weak var startButton: NSButton!
    // 停止学习按钮
    @IBOutlet weak var stopButton: NSButton!
    // 正在学习中的章节名称
    @IBOutlet weak var learningChapterLabel: NSTextField!
    // 章节列表
    @IBOutlet weak var chaptersTableView: NSTableView!
    
    
    // 播放按钮
    @IBOutlet weak var playButton: NSButton!
    
    // MARK: 数据
    
    // 登录后的用户信息
    var userInformation: String?
    
    // 收藏课程列表
    var collectLessons: Array<[String: Any]>? {
        didSet {
            selectLesson = nil
            learningProgressIndicator.doubleValue = 0
            learningLessonProgressIndicator.doubleValue = 0
        }
    }
    // 选中课程
    var selectLesson: [String: Any]?
    // 当前章节
    var selectChapter: [String: Any]?
    
    
    // Timer Suspend 状态记录
    private var isSusspended: Bool = true
    
    // 指定课程下的章节列表
    private var lessonChaptersList: Array<[String: Any]>?
    // 统计当前已阅时长 单位s
    private var seconds: Int = 0
    // 当前章节总时长  单位s
    private var totaolS: Int = 0
    // course_id
    private var course_id: Int = 0
    // lesson_id
    private var lesson_id: Int = 0
    // 当前章节读完
    private var currCourseChapterFinished: Bool = false
    // 课程章节列表切片
    private var unLearnedLessonChapters: Array<[String: Any]> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        selCourseButton.menu = NSMenu(title: "选择课程")
    }
    
    deinit {
        releaseTimer()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
}


// MARK: timer 接口
extension ViewController {
    private func startTimer() {
        if isSusspended {
            self.autoLearnTimer?.resume()
        }
        isSusspended = false
    }

    private func stopTimer() {
        if isSusspended {
            return
        }
        isSusspended = true
        DispatchQueue.main.async {
            self.autoLearnTimer?.suspend()
        }
        print("停止定时器")
    }
    private func releaseTimer() {
        if isSusspended {
            self.autoLearnTimer?.resume()
        }
        self.autoLearnTimer?.cancel()
    }
}

// MARK: 事件
extension ViewController {
    /// 登录事件
    @IBAction func loginFunc(_ sender: Any) {

        guard !inputTokenTextField.stringValue.isEmpty else {
            print("请填写token")
            updateShowMessage(extensionMsg: "请填写 token !", extensionColor: NSColor.red)
            return
        }
        // 记录Token
        InfoManager.shared.updateToken(newToken:inputTokenTextField.stringValue)
        // 登录
        NetManager.shared.login { [weak self] (loginSuccess) in
            if loginSuccess {
                print("登录成功")
                let showMessage = InfoManager.shared.showUserInfo()
                
                let attributeString = NSMutableAttributedString(string: showMessage)
                attributeString.addAttribute(.foregroundColor, value: NSColor.purple, range: NSRange.init(location: 0, length: attributeString.length))
                
                // 拉取收藏列表
                self?.getCollectLessons()
                
                self?.userInformation = InfoManager.shared.showUserInfo()
                self?.updateShowMessage(extensionMsg: nil)
            }
            else {
                print("登录失败")
                // 展示账号信息
                OperationQueue.main.addOperation {
                    self?.userInfoTextView.string.removeAll()
                    let attributeString = NSMutableAttributedString(string: "登录失败!")
                    attributeString.addAttribute(.foregroundColor, value: NSColor.red, range: NSRange.init(location: 0, length: attributeString.length))
                    self?.userInfoTextView.insertText(attributeString, replacementRange: NSRange.init(location: 0, length: 0))
                    self?.userInformation = nil
                }
            }
        }
    }
    
    // 获取收藏列表
    private func getCollectLessons() {
        NetManager.shared.collectLessons { [weak self] (result, collectLesson) in
            guard let collectLessons = collectLesson else {
                return
            }
            DispatchQueue.main.async {
                self?.collectLessons = collectLesson
                var lessonNameArr: Array<String> = []
                for element in collectLessons {
 
                    if let courseName = element["course_name"], ((courseName as? String) != nil) {
                        lessonNameArr.append(courseName as! String)
                    }
                    self?.selCourseButton.addItems(withTitles: lessonNameArr)
                    self?.selCourseButton.selectItem(at: -1)
                    self?.selectLesson = nil
                }
            }
        }
    }
    
    // 切换课程
    @IBAction func changeSelLesson(_ sender: NSPopUpButton) {
        
        guard let selLessonName = sender.selectedItem?.title else {
            self.selCourseButton.selectItem(at: -1)
            self.selectLesson = nil
            return
        }
        
        self.startButton.isEnabled = false
        self.stopButton.isEnabled = false
        self.LoginButton.isEnabled = false
        self.playSpeedSegment.isEnabled = true
        
        print("选择课程: [\(selLessonName)]  \(sender.indexOfSelectedItem)")
        let selLesson: [String: Any] = self.collectLessons![sender.indexOfSelectedItem]
        // 记录选中课程
        selectLesson = selLesson
        
        NetManager.shared.getLessonListChapters(course: selLesson) { [weak self] (result, lessonList) in
            guard let lessons = lessonList else {
                return
            }
            DispatchQueue.main.async {
                self?.startButton.isEnabled = true
                self?.LoginButton.isEnabled = true
                self?.lessonChaptersList = lessons
                self?.resetNewLessonInfo()
            }
        }
    }
    
    // 切换倍速
    @IBAction func changePlaySpeed(_ sender: NSSegmentedControl) {
        
        var defaultSpeed: Int = Int(InfoManager.shared.offsetSeconds)
        switch sender.selectedSegment {
        case 0:
            defaultSpeed = 3
        case 1:
            defaultSpeed = 5
        case 2:
            defaultSpeed = 10
        default:
            print("default")
        }
        InfoManager.shared.updatePlaySpeed(speed: defaultSpeed)
    }
    
    
    // 开始学习
    @IBAction func startToLearn(_ sender: Any) {
        startTimer()
        self.LoginButton.isEnabled = false
        self.playSpeedSegment.isEnabled = false
        self.selCourseButton.isEnabled = false
        self.startButton.isEnabled = false
        self.stopButton.isEnabled = true
        // 初始化课程章节信息, 筛选未学习课程进行自动学习
        resetNewLessonInfo()
        
    }
    
    // 停止自动学习
    @IBAction func stopToAutoLearn(_ sender: Any) {
        DispatchQueue.main.async {
            self.LoginButton.isEnabled = true
            self.startButton.isEnabled = true
            self.playSpeedSegment.isEnabled = true
            self.selCourseButton.isEnabled = true
        }
        self.stopTimer()
    }
    
    // 播放视频
    @IBAction func startToPlay(_ sender: Any) {
        
        guard let selLesson = self.selectLesson else { return }
        guard let selChapter = self.selectChapter,
            let chapterID = selChapter["lesson_id"] as? Int else { return }
        NetManager.shared.chapterVideoPath(course: selLesson, lessionID: chapterID) { [weak self] (result, path) in
            guard result == true, path != nil, let videoURL = URL(string: path!) else {
                return
            }
            DispatchQueue.main.async {
                let player = AVPlayerView(frame: NSRect.init(x: 0, y: 10, width: 400, height: 400))
                player.player = AVPlayer(url: videoURL)
                self?.view.addSubview(player)
                player.player?.play()
            }
            
        }
    }
//    func controlTextDidChange(_ obj: Notification) {
//        guard selCourseButton.selectedTag() > -1 else {
//            return
//        }
//        selCourseButton.selectItem(at: -1)
//    }
}


// MARK: 自动学习相关任务
extension ViewController {
    
    // 初始化一些参数
    private func initCurrChapterParameters(currentChapter: [String: Any]) -> Void {
        
        guard let lesson_id = currentChapter["lesson_id"] as? Int,
            let totalDuration = currentChapter["duration"] as? Int,
            let course_id = self.selectLesson?["course_id"] as? Int else {
                return
        }
        
        let string = " ==> 当前章节:[\(currentChapter["lesson_name"] ?? "")] - lesson_id: \(lesson_id) - course_id:\(course_id) - 本章节时长:\(totalDuration)s "
        print(string)
        
        self.seconds = 60
        self.totaolS = totalDuration
        self.lesson_id = lesson_id
        self.course_id = course_id
        self.learningChapterLabel.stringValue = currentChapter["lesson_name"] as? String ?? ""
        
    }
    
    // 初始化一门课程信息, 已学习, 未学习等数据
    func resetNewLessonInfo() {
        
        self.chaptersTableView.reloadData()
        self.selectChapter = nil
        guard let courseChapterList = self.lessonChaptersList else { return }
        let unLearned = courseChapterList.filter { (element) -> Bool in
            if let hasLearn: Int = element["statistic_status"] as? Int, hasLearn == 1 {
                return false
            }
            return true
        }
        print("=====>: 总章节数: [\(courseChapterList.count)] 已学习: [\(courseChapterList.count - unLearned.count)] 未学习章节数: [\(unLearned.count)]")
        
        let lessonProgress: Double = Double(courseChapterList.count - unLearned.count) / Double(courseChapterList.count)
        self.learningLessonProgressIndicator.doubleValue = lessonProgress
        
        var unLearnedReversed = Array(unLearned.reversed())
        guard let currWillBeLearned = unLearnedReversed.popLast() else {
            print("   >>>>>  初始化课程信息: 已经全部学习完  <<<<<    ")
            self.learningChapterLabel.stringValue = ""
            self.playSpeedSegment.isEnabled = true
            self.selCourseButton.isEnabled = true
            self.LoginButton.isEnabled = true
            self.startButton.isEnabled = true
            
            self.stopTimer()
            return
        }
        
        self.selectChapter = currWillBeLearned
        self.unLearnedLessonChapters = unLearnedReversed
        initCurrChapterParameters(currentChapter: currWillBeLearned)
    }
    
    // 设置一个未学习章节
    func changeNextChapter() -> Void {
        self.chaptersTableView.reloadData()
        guard let currWillBeLearned = self.unLearnedLessonChapters.popLast() else {
            print("   >>>>>   设置一个未学习章节: 已经全部学习完  <<<<<   ")
            AudioTool.sharedManager.playSystemSound()
            
            DispatchQueue.main.async {
                self.learningChapterLabel.stringValue = ""
                self.playSpeedSegment.isEnabled = true
                self.selCourseButton.isEnabled = true
                self.LoginButton.isEnabled = true
                self.startButton.isEnabled = true
            }
            self.stopTimer()
            return
        }
        print(" 切换下一章节  剩余未学习课程: [\(self.unLearnedLessonChapters.count)] ")
        // 初始化当前这门课程的进度
        initCurrChapterParameters(currentChapter: currWillBeLearned)
    }
    
    // 定时器方法
    @objc func loop() -> Void {
        
        print("loop")
        guard self.totaolS != 0 else {
            print(" < 当前章节学习完成 > ")
            AudioTool.sharedManager.vibrate()
            changeNextChapter()
            return
        }
        
        guard let selectedLesson = self.selectLesson else {
            return
        }
        
        NetManager.shared.learnRecordUpdate(course: selectedLesson, lessionID: lesson_id, lessionDuration: seconds) { [weak self] (result) in
            
            guard result == true else {
                return
            }
            // 章节进度
            let progress: Float = Float(self!.seconds) / Float(self!.totaolS)
            // 本门课程整体进度
            
            var lessonProgress: Double = 0.0
            if let unLearnCount = self?.unLearnedLessonChapters.count, let totalCount = self?.lessonChaptersList?.count {
                lessonProgress = Double(totalCount - unLearnCount) / Double(totalCount)
            }
            
            print(" ============>:  剩余未学习课程: [\(self?.unLearnedLessonChapters.count ?? 0)] [【\(Date.init(timeIntervalSinceNow: 0))】 当前章节观看进度: \(progress * 100) %] ")
            DispatchQueue.main.async {
                self?.learningProgressIndicator.doubleValue = Double(progress)
                self?.learningLessonProgressIndicator.doubleValue = lessonProgress
            }
            guard var sec = self?.seconds, let total = self?.totaolS else {
                return
            }
            if sec >= total {
                print("最后一次上报结束")
                self?.course_id = 0
                self?.lesson_id = 0
                self?.seconds = 0
                self?.totaolS = 0
                return
            }

            sec += 60
            if sec > total {
                sec = total
            }
            self?.seconds = sec
        }
    }
}


extension ViewController {
    
    private func updateShowMessage(extensionMsg: String?, extensionColor: NSColor = NSColor.black) {
        var userMessage = ""
        if self.userInformation != nil {
            userMessage = "\(self.userInformation!)\n"
        }
        
        var exMsg = ""
        if extensionMsg != nil {
            exMsg = extensionMsg!
        }
        
        DispatchQueue.main.async {
            self.userInfoTextView.string.removeAll()
            let userInfoAttributeString = NSMutableAttributedString(string: userMessage)
            userInfoAttributeString.addAttribute(.foregroundColor, value: NSColor.purple, range: NSRange.init(location: 0, length: userInfoAttributeString.length))
            self.userInfoTextView.insertText(userInfoAttributeString, replacementRange: NSRange.init(location: 0, length: 0))
            
            let extensionAttributeMsg = NSMutableAttributedString(string: exMsg)
            extensionAttributeMsg.addAttribute(.foregroundColor, value: extensionColor, range: NSRange.init(location: 0, length: extensionAttributeMsg.length))
            self.userInfoTextView.insertText(extensionAttributeMsg, replacementRange: NSRange.init(location: userInfoAttributeString.length, length: 0))
        }
    }
}


extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.lessonChaptersList?.count ?? 0
    }
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let chapter = self.lessonChaptersList?[row] else { return nil }
        if tableColumn?.title == "已读" {
            if let hasLearned = chapter["statistic_status"] as? Int, hasLearned == 1 {
                return "✔️"
            }
            if unLearnedLessonChapters.contains(where: { (element) -> Bool in
                return (element["lesson_name"] as! String) == (chapter["lesson_name"] as! String)
            }) {
                return "❌"
            }
            return "✔️"
        }
        return chapter["lesson_name"]
    }
}

let reusedID = "reusedID"

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        print("\(tableColumn.dataCell)")
    }
    
}
