//
//  NetManager.swift
//  AutoLearning
//
//  Created by ShenYj on 2020/7/16.
//  Copyright © 2020 ShenYj. All rights reserved.
//

import Foundation



internal class NetManager {
    
    static let shared: NetManager = NetManager()
    
    private let session: URLSession = URLSession.shared
    
    // 获取token
    private let InterfaceGetAccessToken: String = "https://www.bjjnts.cn/api/mobile/token"
    // 登录接口
    private let InterfaceLogin: String = "https://www.bjjnts.cn/api/mobile/user/center"
    // 收藏列表接口
    private let InterfaceCollectLessons: String = "https://www.bjjnts.cn/api/mobile/user/collects"
    // 课程章节列表接口
    private let InterfaceLessonList: String = "https://www.bjjnts.cn/api/mobile/courses"
    // 学习进度上报接口
    private let InterfaceLearnRecordReport: String = "https://www.bjjnts.cn/api/mobile/user/learning-record"
    // 流媒体地址接口
    private let InterfaceChapterVideoPath: String = "https://www.bjjnts.cn/api/mobile/courses/url"
}


extension NetManager {
    
    // MARK: 获取token
    func getAccessToken(idNumber: String, pwd: String, callback: @escaping ((_ success: Bool) -> Void) ) -> Void {
        
        let bodyJson = ["username": idNumber, "password": pwd]
        guard let body = try? JSONSerialization.data(withJSONObject: bodyJson, options: .fragmentsAllowed) else {
            print("序列化失败")
            return
        }
        post(path: InterfaceGetAccessToken, data: body) { (data, urlRespone, error) in
            guard let resData = data else {
                callback(false)
                return
            }
            
            print("获取token: \(resData)")
            guard let code = resData["code"] as? Int,
                let msg = resData["msg"] as? String,
                let ddata = resData["data"] as? [String: Any] else {
                    print("解析字段失败")
                    callback(false)
                    return
            }
            
            guard code == 200, msg == "success" else {
                print("获取token失败 \(msg)")
                callback(false)
                return
            }
            
            guard let token = ddata["access_token"] as? String ,
                let expiresIn = ddata["expires_in"] as? Int else {
                    print("解析字段失败")
                    callback(false)
                    return
            }
            
            print("过期时间: \(expiresIn)")
            // 记录Token
            InfoManager.shared.updateToken(newToken:token)
            callback(true)
        }
    }
    // MARK: 登录拉取用户信息
    func login(response: ((_ success: Bool) -> Void)? ) -> Void {
        get(path: InterfaceLogin) { (dataResponse, urlResponse, error) in
            
            guard let callback = response else {
                return
            }
            guard let resCode = dataResponse?["code"] as? Int,
                let data = dataResponse?["data"] as? [String: Any],
                let message = dataResponse?["msg"] else {
                    print(" 解析字段失败 ")
                    callback(false)
                    return
            }
            
            print(" || 💭💭🗯🗯🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🗯🗯💭💭 ||")
            print(" || 请求响应码: \(resCode)")
            print(" || 接返回 Message 信息: \(message)")
            // print(" || 接口返回 Data 数据: \(String(describing: data))")
            if resCode == 200 {
                InfoManager.shared.updateUserInfo(userInfo: data)
                callback(true)
            }
            else {
                callback(false)
            }
        }
    }
    
    // MARK: 获取收藏列表
    func collectLessons(response: @escaping ((_ success: Bool, _ colletLessons: Array<Dictionary<String, Any>>?) -> Void) ) -> Void {
        
        get(path: InterfaceCollectLessons) { (dataResponse, urlResponse, error) in
            
            guard let resCode = dataResponse?["code"] as? Int,
                let data = dataResponse?["data"] as? Array<[String: Any]>,
                let message = dataResponse?["msg"] else {
                    print(" 解析字段失败 ")
                    response(false, nil)
                    return
            }
            
            print(" || 💭💭🗯🗯🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🗯🗯💭💭 ||")
            print(" || 请求响应码: \(resCode)")
            print(" || 接返回 Message 信息: \(message)")
            // print(" || 接口返回 Data 数据: \(String(describing: data))")
            if resCode == 200 {
                response(true, data)
            }
            else {
                response(false, nil)
            }
        }
    }
    
    // MARK: 获取课程章节列表
    func getLessonListChapters( course: [String: Any], response: @escaping ((_ success: Bool, _ colletLessons: Array<Dictionary<String, Any>>?) -> Void) ) -> Void {
        
        let name = course["course_name"]
        let courseID: Int = course["course_id"] as! Int
        let path = "\(InterfaceLessonList)/\(courseID)?course_id=\(courseID)"
        print(" ==> 获取 [\(String(describing: name))] 课程章节列表: [\(path)]")
        get(path: path) { (dataResponse, urlResponse, error) in
            
            guard let resCode = dataResponse?["code"] as? Int,
                let data = dataResponse?["data"] as? [String: Any],
                let lessons = data["chapter_list"] as? Array<[String: Any]>,
                let message = dataResponse?["msg"] else {
                    print(" 解析字段失败 ")
                    response(false, nil)
                    return
            }
            
            print(" || 💭💭🗯🗯🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🚥🗯🗯💭💭 ||")
            print(" || 请求响应码: \(resCode)")
            print(" || 接返回 Message 信息: \(message)")
            // print(" || 接口返回 Data 数据: \(String(describing: data))")
            if resCode == 200 {
                response(true, lessons)
            }
            else {
                response(false, nil)
            }
        }
    }
    
    // MARK: 上报学习进度
    func learnRecordUpdate( course: [String: Any], lessionID: Int, lessionDuration: Int, callback: @escaping ((_ success: Bool) -> Void) ) -> Void  {
        
        let courseID: Int = course["course_id"] as! Int
        
        guard var request = requestInstance(path: InterfaceLearnRecordReport) else {
            callback(false)
            return
        }
        request.httpMethod = "POST"
        
        var list: Array<String> = Array()
        list.append("course_id=\(courseID)")
        list.append("lesson_id=\(lessionID)")
        list.append("duration=\(lessionDuration)")
        list.append("learn_duration=\(lessionDuration)")
        let stringBody: String = list.joined(separator: "&")
        
        
        
        post(path: InterfaceLearnRecordReport, data: stringBody.data(using: .utf8)) { (data, urlRespone, error) in
            guard let resData = data else {
                callback(false)
                return
            }
            guard let message = resData["msg"] else {
                print("解析字段失败")
                callback(false)
                return
            }
            
            if message as! String == "添加成功" {
                callback(true)
                return
            }
            print("上报结果: \(message)")
            callback(false)
        }
        
    }
    
    // MARK: 获取流媒体地址
    func chapterVideoPath( courseID: Int, lessionID: Int, callback: @escaping ((_ success: Bool, _ realVideoPath: String?) -> Void) ) {
        
        let videoUrl = "\(InterfaceChapterVideoPath)/\(courseID)/\(lessionID)"
        get(path: videoUrl) { (dataResponse, urlResponse, error) in
            
            guard let data = dataResponse?["data"] as? [String: Any],
                let realPath = data["url"] as? String,
                let code = dataResponse?["code"] as? Int, code == 200 else {
                    print(" 解析字段失败 ")
                    callback(false, nil)
                    return
            }
            callback(true, realPath)
        }
    }
}



extension NetManager {
    
    // 实例化request
    private func requestInstance(path: String, timeoutInterval: TimeInterval = InfoManager.shared.offsetSeconds) -> URLRequest? {
        guard let linkstr = path.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
            return nil
        }
        let url = URL.init(string: linkstr)
        var request = URLRequest.init(url: url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: timeoutInterval)
        request.addValue("www.bjjnts.cn", forHTTPHeaderField: "Host")
        request.addValue("https://servicewechat.com/wxf2bc5d182269cdf1/8/page-frame.html", forHTTPHeaderField: "Referer")
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/7.0.14(0x17000e25) NetType/4G Language/zh_CN", forHTTPHeaderField: "User-Agent")
//        request.addValue("Bearer \(InfoManager.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
//        print("=============================== Header ================================")
//        print("Header: \(request.allHTTPHeaderFields ?? [:]) ")
        return request
    }
    
    // 请求公共处理 (GET请求)
    private func get( path: String, completionHandler: @escaping (([String: Any]?, URLResponse?, Error?) -> Void) ) -> Void {
        guard var request = requestInstance(path: path) else {
            completionHandler(nil, nil, nil)
            return
        }
        request.httpMethod = "GET"
        request.addValue("Bearer \(InfoManager.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) { ( data, urlRespone, error) in
            
            guard let resData = data else {
                completionHandler(nil, urlRespone, error)
                return
            }
            guard case let res as [String: Any] = try? JSONSerialization.jsonObject(with: resData, options: .mutableContainers) else {
                completionHandler(nil, urlRespone, error)
                return;
            }
            completionHandler(res, urlRespone, error)
        }
        task.resume()
    }
    // 请求公共处理 (POST请求)
    private func post( path: String, data: Data? = nil, completionHandler: @escaping (([String: Any]?, URLResponse?, Error?) -> Void) ) -> Void {
        
        guard var request = requestInstance(path: path) else {
            completionHandler(nil, nil, nil)
            return
        }
        
        if InfoManager.shared.accessToken != nil {
            request.addValue("Bearer \(InfoManager.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { ( data, urlRespone, error) in
            
            guard let resData = data else {
                completionHandler(nil, urlRespone, error)
                return
            }
            guard case let res as [String: Any] = try? JSONSerialization.jsonObject(with: resData, options: .mutableContainers) else {
                completionHandler(nil, urlRespone, error)
                return;
            }
            completionHandler(res, urlRespone, error)
        }
        task.resume()
    }
}

