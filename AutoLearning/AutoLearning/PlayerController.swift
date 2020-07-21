//
//  PlayerController.swift
//  AutoLearning
//
//  Created by ShenYj on 2020/7/19.
//  Copyright © 2020 ShenYj. All rights reserved.
//

import Foundation
import Cocoa
import AVKit

class PlayerController: NSViewController {
    
    @IBOutlet weak var playerView: AVPlayerView!
    
    private var videoPath: URL?

    internal var videoInfo: [String: Any]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        guard let courseID = videoInfo?["courseID"] as? Int, let chapterID = videoInfo?["chapterID"] as? Int else {
            print("获取课程ID和章节ID信息失败")
            return
        }
        NetManager.shared.chapterVideoPath(courseID: courseID, lessionID: chapterID) { (result, path) in
            guard result == true, path != nil, let videoURL = URL(string: path!) else {
                return
            }
            
            self.playerView.player = AVPlayer(url: videoURL)
            self.playerView.player?.play()
        }
    }
}
