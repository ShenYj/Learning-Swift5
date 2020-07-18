//
//  InfoManager.swift
//  AutoLearning
//
//  Created by ShenYj on 2020/7/16.
//  Copyright © 2020 ShenYj. All rights reserved.
//

import Foundation


internal class InfoManager {
    
    // MARK: 对外暴露
    
    // 全局访问单例
    static let shared: InfoManager = InfoManager()
    // 对外访问- token
    internal var accessToken: String? {
        get {
            return token
        }
    }
    // 对外访问- 控制倍速
    internal var offsetSeconds: Double {
        get {
            return Double(offsetSec)
        }
    }
    // 收藏课程数量
    internal var collectLessonCount: Int = 0
    // 收藏课程数量
    internal var telephoneNumber: String?
    // 真实姓名
    internal var realName: String?
    // userID
    internal var userIDName: String?
    // rid
    internal var userID: Int?
    
    // MARK: 私有属性
    
    // 用户Token
    private var token: String?
    // 倍速 3/5/10
    private var offsetSec: Int = 5
    
}

// MARK: 对外接口 setter
extension InfoManager {
    
    // 设置Token
    internal func updateToken(newToken: String?) {
        token = newToken
    }
    // 设置倍速
    internal func updatePlaySpeed(speed: Int) {
        offsetSec = speed
    }
    // 设置用户信息
    internal func updateUserInfo(userInfo: [String: Any]) {
        if let coltLessonCount = userInfo["collect_course_num"] as? Int {
            collectLessonCount = coltLessonCount
        }
        if let mobile = userInfo["phone"] as? String {
            telephoneNumber = mobile
        }
        if let name = userInfo["realname"] as? String {
            realName = name
        }
        if let idNum = userInfo["rid"] as? Int {
            userID = idNum
        }
        if let username = userInfo["username"] as? String {
            userIDName = username
        }
        print(" \(userInfo) ")
        print(" 👽 ")
        print(" 收藏课程数量: \(collectLessonCount)")
        print(" 手机号: \(telephoneNumber ?? "")")
        print(" 真实姓名: \(realName ?? "")")
        print(" rid: \(userID ?? 0)")
        print(" userName: \(userIDName ?? "")")
    }
}


// MARK: 读取信息 getter
extension InfoManager {
    
    // 展示登录账号信息
    internal func showUserInfo() -> String {
        var information: String = ""
        information.append("=================================\n")
        information.append("|| 👴 姓名: \(realName ?? "")\n")
        information.append("|| 📱 手机号: \(telephoneNumber ?? "")\n")
        information.append("|| 🚦 rid: \(userID ?? 0)\n")
        information.append("|| 🗿 ID: \(userIDName ?? "")\n")
        information.append("|| 🎖 收藏课程数量: \(collectLessonCount)\n")
        information.append("=================================\n")
        return information
    }
    
}

