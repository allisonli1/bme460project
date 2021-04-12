//
//  Playlist.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

class Playlist: NSObject, NSCoding {
    var title: String
    var videos: [YouTubeResult]
    var videoIDs: [String]
    var duration: String
    
    struct PropertyKey {
        static let title = "title"
        static let videos = "videos"
        static let videoIDs = "videoIDs"
        static let duration = "duration"
    }
    
    //MARK: Archiving Paths
     
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("playlists")
    
    init(title: String, duration: String) {
        self.title = title
        self.videos = []
        self.videoIDs = []
        self.duration = duration
    }
    
    
    func setTitle(title: String) {
        self.title = title
    }
    
    func setDuration(duration: String) {
        self.duration = duration
    }
    
    func addVideo(video: YouTubeResult) {
        self.videos.append(video)
    }
    
    func addVideoID(videoID: String) {
        self.videoIDs.append(videoID)
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(videos, forKey: PropertyKey.videos)
        aCoder.encode(videoIDs, forKey: PropertyKey.videoIDs)
        aCoder.encode(duration, forKey: PropertyKey.duration)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String else {
            return nil
        }
        
        // Because photo is an optional property of Meal, just use conditional cast.
        let videos = aDecoder.decodeObject(forKey: PropertyKey.videos) as? [YouTubeResult]
        _ = aDecoder.decodeObject(forKey: PropertyKey.videoIDs) as? [String]
        
        guard let duration = aDecoder.decodeObject(forKey: PropertyKey.duration) as? String else {
            return nil
        }
        
        self.init(title: title, duration: duration)
        if let vids = videos {
            for v in vids {
                self.addVideo(video: v)
                self.addVideoID(videoID: v.videoID)
            }
        }
    }
}
