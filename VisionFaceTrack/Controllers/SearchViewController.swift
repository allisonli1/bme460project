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
    var selectedVideos: [String] = []
    var playlistName: String = ""
    let API_KEY = "AIzaSyCfm9iBIi02F_6G8QhHZesCVbjmwvwwkxQ"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchTableView.delegate = self
        searchTableView.dataSource = self
        searchTableView.allowsMultipleSelection = true
        searchTerm.delegate = self
        
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
        
        let video = self.videos[indexPath.row]
        tableView.rowHeight = 120

        print("Makes the cell")
        cell.setVideo(video: video)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Unselect the row, and instead, show the state with a checkmark.
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        // Update the selected item to indicate whether the user packed it or not.
        let video = videos[indexPath.row]
        let newVideoID = video.videoID
        if (!self.selectedVideos.contains(newVideoID)) {
            self.selectedVideos.append(newVideoID)
            cell.accessoryType = .checkmark
        }
        else {
            for (idx, id) in self.selectedVideos.enumerated() {
                if (id == newVideoID) {
                    self.selectedVideos.remove(at: idx)
                }
                cell.accessoryType = .none
            }
        }

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
                                        let video = YouTubeResult(title:"", videoID:"", channel:"", description:"", imageURL:"")
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
}
