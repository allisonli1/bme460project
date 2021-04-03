//
//  Playlist.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

class Playlist {
    var title: String
    var videos: [String]
    
    
    init(title: String) {
        self.title = title
        self.videos = []
    }
    
    func setTitle(title: String) {
        self.title = title
    }
    
    func addVideo(videoID: String) {
        self.videos.append(videoID)
    }
}
