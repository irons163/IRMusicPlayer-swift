//
//  StatusClass.swift
//  IRMusicPlayer-swift
//
//  Created by Phil on 2021/2/18.
//  Copyright © 2021 Phil. All rights reserved.
//

import Foundation

class StatusClass {
    static let shared = StatusClass()
    
    var isAudioPlaying: Bool = false
    
    private init() { }
}

