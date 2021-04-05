//
//  VideoSelectionMainViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import youtube_ios_player_helper
import Alamofire

class VideoSelectionMainViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchTerm: UITextField!
    @IBOutlet weak var youtubeView: YTPlayerView!
    let API_KEY = "AIzaSyCfm9iBIi02F_6G8QhHZesCVbjmwvwwkxQ"
    var videos: [YouTubeResult] = []
    var videoQueue: [String] = []
    var videoQueuePos: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchTerm.delegate = self
        youtubeView.delegate = self.youtubeView.delegate
        if (self.videoQueue.count == 0) {
            youtubeView.load(withVideoId: "cBd7eQ3UXOE", playerVars: ["playsinline":"1"])
        }
        else {
            print("videoQueue: \(self.videoQueue)")
            // playerView.cuePlaylist(byVideos: [self.videoQueue[0]], index: 1, startSeconds: 1)
            // playerView.load(withVideoId: self.videoQueue[0], playerVars: ["playsinline":"1"])
            youtubeView.cuePlaylist(byVideos: self.videoQueue, index: Int32(self.videoQueuePos), startSeconds: 0)
            self.videoQueuePos += self.videoQueue.count
            //playerView.loadPlaylist(byVideos: [self.videoQueue[1]], index: 1, startSeconds: 1)
            print("Current Playlist: \(youtubeView.playlist())")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Goes into viewDidAppear")
        print("videoQueue: \(self.videoQueue)")
        // playerView.load(withVideoId: self.videoQueue[0], playerVars: ["playsinline":"1"])
        youtubeView.cuePlaylist(byVideos: self.videoQueue, index: 0, startSeconds: 1)
        //playerView.loadPlaylist(byVideos: [self.videoQueue[1]], index: 1, startSeconds: 1)
        self.videos = []
        print("Current Playlist: \(youtubeView.playlist())")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "MainToSearch":
            guard let destViewController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let searchResultsController = destViewController.topViewController as? SearchViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            searchResultsController.videos = self.videos
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }

        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        search()
        return true
    }
    
    
    //MARK: Actions
    @IBAction func getSearchedVideos(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? SearchViewController {
            let selectedVideos = sourceViewController.selectedVideos
            
            // self.videoQueue.append(contentsOf: selectedVideos)
            print("\(videoQueue)")
            youtubeView.cuePlaylist(byVideos: self.videoQueue, index: 0, startSeconds: 1)
            //playerView.loadPlaylist(byVideos: [self.videoQueue[1]], index: 1, startSeconds: 1)
            self.videos = []
            print("Current Playlist: \(youtubeView.playlist())")
            
        }
    }
    
    fileprivate func search() {
        youtubeView.stopVideo()
        self.videos.removeAll()
        print("Gets before AF Request")
        AF.request("https://www.googleapis.com/youtube/v3/search",
                   method: .get, parameters: ["key": API_KEY,
                                              "part": "snippet",
                                              "q":String(describing: searchTerm.text!),
                                              "maxResults": 25,
                                              "type": "video",
                                              "safeSearch":"strict"])
                    .responseJSON { response in
                        print("Gets into AF Request")
                        if let value = response.value as? [String: AnyObject] {
                            for (_, key_value) in value.enumerated() {
                                if let arr = key_value.value as? [[String: Any]] {
                                    for i in arr {
                                        let video = YouTubeResult(title:"", videoID:"", channel:"", description:"", imageURL:"", duration:"")
                                        if let snip = i["snippet"] as? [String: Any] {
                                            video.setTitle(title: snip["title"] as! String)
                                            video.setChannel(channel: snip["channelTitle"] as! String)
                                            video.setDescription(description: snip["description"] as! String)
                                            if let thumbnails = snip["thumbnails"] as? [String: Any] {
                                                if let imURL = thumbnails["default"] as? [String: Any] {
                                                    video.setImageURL(imageURL: imURL["url"] as! String)
                                                }
                                            }
                                        }
                                        if let id = i["id"] as? [String: Any] {
                                            if id["kind"] as! String == "youtube#video" {
                                                video.setVideoID(videoID: id["videoId"] as! String)
                                            }
                                        }
                                        self.videos.append(video)
                                    }
                                }
                            }
                            print("\n")
                            var j = 1
                            for x in self.videos{
                                print("Number: \(j)")
                                print("Video Title: \(x.title)")
                                print("Channel: \(x.channel)")
                                if x.description.count > 25 {
                                    let lowerBound = String.Index(encodedOffset: 0)
                                    let upperBound = String.Index(encodedOffset: 24)
                                    print("Description: \(x.description[lowerBound..<upperBound])...")
                                }
                                else {
                                    print("Description: \(x.description)")
                                }
                                print("Thumbnail URL: \(x.imageURL)")
                                print("videoID: \(x.videoID)\n")
                                j += 1
                            }
                            
                        }

        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
