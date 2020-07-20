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

    internal var videoInfo: [String: Any]? {
        didSet {
            guard let courseID = videoInfo?["courseID"] as? Int, let chapterID = videoInfo?["chapterID"] as? Int else { return }
            NetManager.shared.chapterVideoPath(courseID: courseID, lessionID: chapterID) { (result, path) in
                guard result == true, path != nil, let videoURL = URL(string: path!) else {
                    return
                }
                self.playerView.player = AVPlayer(url: videoURL)
                self.playerView.player?.play()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
