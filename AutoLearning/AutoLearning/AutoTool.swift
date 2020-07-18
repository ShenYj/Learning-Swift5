//
//  AutoTool.swift
//  AutoLearning
//
//  Created by ShenYj on 2020/7/16.
//  Copyright © 2020 ShenYj. All rights reserved.
//

import Foundation
import AudioToolbox

internal class AudioTool {
    
    static let sharedManager: AudioTool = AudioTool()
    
    // 播放系统声音
    func playSystemSound() {
        AudioServicesPlaySystemSound(1005)
    }

    // 播放提醒声音
    func playAlertSound() {
        AudioServicesPlayAlertSound(1006)
    }
    
    // 震动
    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}
