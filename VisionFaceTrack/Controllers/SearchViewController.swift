//
//  SearchViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import Alamofire

class SearchViewController: UIViewController, UITextFieldDelegate {
    
    var videos = [YouTubeResult]()
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchTerm: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var selectedVideos: [YouTubeResult] = []
    var selected: [Bool]!
    var playlistName: String = ""
    let API_KEY = "AIzaSyCfm9iBIi02F_6G8QhHZesCVbjmwvwwkxQ"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchTableView.delegate = self
        searchTableView.dataSource = self
        searchTableView.allowsMultipleSelection = true
        searchTerm.delegate = self
        searchTableView.backgroundColor = UIColor.white
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        search()
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func newSearch(_ sender: UIButton) {
        resetTable()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        searchButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        if (!text.isEmpty) {
            searchButton.isEnabled = true
        }
    }
    
    func resetAccessoryType() {
        for section in 0...(self.searchTableView.numberOfSections - 1) {
            for row in 0...(self.searchTableView.numberOfRows(inSection: section) - 1) {
                let cell = self.searchTableView.cellForRow(at: IndexPath(row: row, section: section))
                cell?.accessoryType = .none
            }
        }
    }
    
    func resetTable() {
        if (self.searchTableView.numberOfRows(inSection: 0) > 0) {
            resetAccessoryType()
        }
        searchTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            return
        }
            
    }
    
    
    @IBAction func cancelSearch(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    

}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "SearchTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SearchTableViewCell  else {
            fatalError("The dequeued cell is not an instance of SearchTableViewCell.")
        }
        tableView.rowHeight = 90
        
        let video = self.videos[indexPath.row]
        print("Makes the cell")
        cell.setVideo(video: video)
        
        var hasVideo = false
        let newVideoID = video.videoID
        for vid in selectedVideos {
            if (vid.videoID == newVideoID) {
                hasVideo = true
            }
        }
        
        if selected[indexPath.row] {
            if (!hasVideo) {
                self.selectedVideos.append(video)
                cell.accessoryType = .checkmark
            }
        } else {
            if (hasVideo) {
                for (idx, vid) in self.selectedVideos.enumerated() {
                    if (vid.videoID == newVideoID) {
                        self.selectedVideos.remove(at: idx)
                    }
                }
            }
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selected[indexPath.row] = !selected[indexPath.row]
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
}

extension SearchViewController {
    fileprivate func search() {
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
                                            let tempTitle = snip["title"] as! String
                                            let realTitle = tempTitle.replacingOccurrences(of: "&#39;", with: "'").replacingOccurrences(of: "&quot;", with: "\"")
                                            video.setTitle(title: realTitle)
                                            video.setChannel(channel: snip["channelTitle"] as! String)
                                            video.setDescription(description: snip["description"] as! String)
                                            if let thumbnails = snip["thumbnails"] as? [String: Any] {
                                                if let imURL = thumbnails["default"] as? [String: Any] {
                                                    video.setImageURL(imageURL: imURL["url"] as! String)
                                                }
                                            }
                                        }
                                        if let contentDetails = i["contentDetails"] as? [String: Any] {
                                            video.setDuration(duration: contentDetails["duration"] as! String)
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
                                print("Thumbnail URL: \(x.imageURL)")
                                print("videoID: \(x.videoID)\n")
                                print("duration: \(x.duration)\n")
                                j += 1
                            }
                            self.selected = [Bool](repeating: false, count: self.videos.count)
                        }

        }
    }
}
