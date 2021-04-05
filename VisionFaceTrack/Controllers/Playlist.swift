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
    var videos: [YouTubeResult]
    var videoIDs: [String]
    
    
    init(title: String) {
        self.title = title
        self.videos = []
        self.videoIDs = []
    }
    
    func setTitle(title: String) {
        self.title = title
    }
    
    func addVideo(video: YouTubeResult) {
        self.videos.append(video)
    }
    
    func addVideoID(videoID: String) {
        self.videoIDs.append(videoID)
    }
}
