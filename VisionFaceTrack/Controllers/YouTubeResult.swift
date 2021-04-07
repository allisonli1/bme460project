//
//  YouTubeResult.swift
//  VisionFaceTrack
//
//  Created by Mitchell Hutmacher on 3/24/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

class YouTubeResult: NSObject, NSCoding {
    var title: String
    var videoID: String
    var channel: String
    var description1: String
    var imageURL: String
    var duration: String
    
    struct PropertyKey {
        static let title = "title"
        static let videoID = "videoID"
        static let channel = "channel"
        static let imageURL = "imageURL"
    }
    
    //MARK: Archiving Paths
     
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("youtuberesults")
    
    init(title: String, videoID: String, channel: String, description: String, imageURL: String, duration: String) {
        self.title = title
        self.videoID = videoID
        self.channel = channel
        self.description1 = description
        self.imageURL = imageURL
        self.duration = duration
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
        self.description1 = description
    }
    
    func setImageURL(imageURL: String) {
        self.imageURL = imageURL // 90x120 images
    }
    
    func setDuration(duration: String) {
        self.duration = duration
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(videoID, forKey: PropertyKey.videoID)
        aCoder.encode(channel, forKey: PropertyKey.channel)
        aCoder.encode(imageURL, forKey: PropertyKey.imageURL)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String else {
            return nil
        }
        
        guard let videoID = aDecoder.decodeObject(forKey: PropertyKey.videoID) as? String else {
            return nil
        }
        
        guard let channel = aDecoder.decodeObject(forKey: PropertyKey.channel) as? String else {
            return nil
        }
        
        guard let imageURL = aDecoder.decodeObject(forKey: PropertyKey.imageURL) as? String else {
            return nil
        }
        

        self.init(title: title, videoID: videoID, channel: channel, description: "", imageURL: imageURL, duration: "")
    }
}
