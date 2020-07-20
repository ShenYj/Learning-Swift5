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
    
}

extension NetManager {
    
    // MARK: 登录
    func login(response: ((_ success: Bool) -> Void)? ) -> Void {
        request(path: InterfaceLogin) { (dataResponse, urlResponse, error) in
            
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
        
        request(path: InterfaceCollectLessons) { (dataResponse, urlResponse, error) in
            
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
        request(path: path) { (dataResponse, urlResponse, error) in
            
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
        
        request.httpBody = stringBody.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { ( data, urlRespone, error) in
            guard let resData = data else {
                callback(false)
                return
            }
            guard case let res as [String: Any] = try? JSONSerialization.jsonObject(with: resData, options: .mutableContainers) else {
                callback(false)
                return;
            }
            
            guard let message = res["msg"] else {
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
        task.resume()
    }
    
    // MARK: 获取流媒体地址
    func chapterVideoPath( courseID: Int, lessionID: Int, callback: @escaping ((_ success: Bool, _ realVideoPath: String?) -> Void) ) {
       
        let videoUrl = "\(InterfaceChapterVideoPath)/\(courseID)/\(lessionID)"
        request(path: videoUrl) { (dataResponse, urlResponse, error) in
            
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
        request.addValue("Bearer \(InfoManager.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/7.0.14(0x17000e25) NetType/4G Language/zh_CN", forHTTPHeaderField: "User-Agent")
        request.httpMethod = "GET"
//        print("=============================== Header ================================")
//        print("Header: \(request.allHTTPHeaderFields ?? [:]) ")
        return request
    }
    
    // 请求公共处理 (GET请求)
    private func request( path: String, completionHandler: @escaping (([String: Any]?, URLResponse?, Error?) -> Void) ) -> Void {
        guard let request = requestInstance(path: path) else {
            completionHandler(nil, nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { ( data, urlRespone, error) in
            
            guard let resData = data else {
                completionHandler(nil, urlRespone, error)
                return
            }
            //print("=============================== 开始解析返回值 ================================")
            guard case let res as [String: Any] = try? JSONSerialization.jsonObject(with: resData, options: .mutableContainers) else {
                completionHandler(nil, urlRespone, error)
                return;
            }
            // print("原始返回数据: \(res)")
            completionHandler(res, urlRespone, error)
        }
        task.resume()
    }
    
}

