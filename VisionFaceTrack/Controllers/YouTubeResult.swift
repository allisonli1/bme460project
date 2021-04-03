//
//  YouTubeResult.swift
//  VisionFaceTrack
//
//  Created by Mitchell Hutmacher on 3/24/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

class YouTubeResult {
    var title: String
    var videoID: String
    var channel: String
    var description: String
    var imageURL: String
    
    init(title: String, videoID: String, channel: String, description: String, imageURL: String) {
        self.title = title
        self.videoID = videoID
        self.channel = channel
        self.description = description
        self.imageURL = imageURL
    }
    
    func setTitle(title: String) {
        self.title = title
    }
    
    func setVideoID(videoID: String) {
        self.videoID = videoID
    }
    
    func setChannel(channel: String) {
        self.channel = channel
    }
    
    func setDescription(description: String) {
        self.description = description
    }
    
    func setImageURL(imageURL: String) {
        self.imageURL = imageURL // 90x120 images
    }
}
