//
//  SavePlaylistViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/6/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import Alamofire


class SavePlaylistViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var saveVideoTable: UITableView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var totDurLabel: UILabel!
    @IBOutlet weak var addVidsButton: UIButton!
    
    let API_KEY = "AIzaSyCfm9iBIi02F_6G8QhHZesCVbjmwvwwkxQ"
    var totDur: Int = 0;
    
    var playlist: Playlist?
    var videos: [YouTubeResult] = []
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        nameTextField.delegate = self
        saveVideoTable.delegate = self
        saveVideoTable.dataSource = self
        saveVideoTable.dragDelegate = self
        saveVideoTable.dragInteractionEnabled = true
        saveVideoTable.backgroundColor = UIColor.white
        
        totDurLabel.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 20)
        
        nameTextField.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 30)
        nameTextField.textColor = UIColor.black
        nameTextField.backgroundColor = UIColor.white
        totDurLabel.textColor = UIColor.systemGray
        
        addVidsButton.layer.cornerRadius = 20
        addVidsButton.layer.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1).cgColor
        addVidsButton.setTitleColor(UIColor.white, for: .normal)
        addVidsButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 35)
        
        if let playlist = playlist {
            videos.append(contentsOf: playlist.videos)
            nameTextField.text = playlist.title
            self.updateTotDur()
        }
        else {
            if (self.videos.count != 0) {
                getDurs()
            }
            else {
                totDurLabel.text = "Total Duration: 0 minutes"
            }
        }
        if (nameTextField.text!.isEmpty) {
            saveButton.isEnabled = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getDurs()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        let selectedVideos = videos
        
        // Set the playlist to be passed after the unwind segue.
        playlist = Playlist(title: "", duration: "\(self.totDur)")
        if let newTitle = nameTextField.text {
            playlist?.setTitle(title: newTitle)
        }
        for vid in selectedVideos {
            playlist?.addVideoID(videoID: vid.videoID)
            playlist?.addVideo(video: vid)
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        if (textField.hasText) {
            saveButton.isEnabled = true
        }
        return true
    }
    
    //MARK: Actions
    @IBAction func getPlaylistResults(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? SearchViewController {
            let selectedVideos = sourceViewController.selectedVideos
            
            for vid in selectedVideos {
                self.playlist?.addVideoID(videoID: vid.videoID)
                self.playlist?.addVideo(video: vid)
            }
            self.videos.append(contentsOf: selectedVideos)
            self.saveVideoTable.reloadData()
            
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        let isPresentingInAddPlaylistMode = presentingViewController is UINavigationController
        
        if (isPresentingInAddPlaylistMode) {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The SavePlaylistViewController is not inside a navigation controller.")
        }
        
    }
    

}

extension SavePlaylistViewController: UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "VideoTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? VideoTableViewCell  else {
            fatalError("The dequeued cell is not an instance of VideoTableViewCell.")
        }
        
        let video = self.videos[indexPath.row]
        tableView.rowHeight = 135

        print("Makes the cell")
        cell.setVideo(video: video)
        cell.titleLabel.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 25)
        cell.channelLabel.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 20)
        return cell
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            videos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = self.videos[indexPath.row]
        return [ dragItem ]
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Update the model
        let mover = self.videos.remove(at: sourceIndexPath.row)
        self.videos.insert(mover, at: destinationIndexPath.row)
    }

}

extension SavePlaylistViewController {
    func getDurs() {
        var vidIDs = ""
        for video in self.videos {
            vidIDs += video.videoID + ","
        }
        vidIDs = String(vidIDs.dropLast())
        // print("vidIDs: \(vidIDs)")
        AF.request("https://www.googleapis.com/youtube/v3/videos",
                   method: .get, parameters: ["key": API_KEY,
                                              "part":"contentDetails",
                                              "id":vidIDs])
            .responseJSON { response in
                        if let value = response.value as? [String: AnyObject] {
                            for (_, key_value) in value.enumerated() {
                                //print("key_value: \(key_value)")
                                if let arr = key_value.value as? [[String: Any]] {
                                    // print("arr: \(arr)")
                                    for i in arr {
                                        // print("i: \(i)")
                                        let thisID = i["id"] as? String
                                        if let contDet = i["contentDetails"] as? [String: Any] {
                                            // print("contDet: \(contDet)")
                                            // print("contDet[\"duration\"]: \(contDet["duration"]!)") // WORKS
                                            let time_in_sec = self.convertPTtoSec(PT:contDet["duration"] as! String)
                                            for vid in self.videos {
                                                if vid.videoID == thisID {
                                                    vid.setDuration(duration:time_in_sec)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        self.updateTotDur()
                    }
        print("Gets out of AF.request response")
    }
    
    func updateTotDur() {
        // Reset total duration of playlist to 0, helps if just updating from a non-zero val
        self.totDur = 0;
        for video in self.videos {
            // If the duration is there and is an int, add it to totDur
            if let num = Int(video.duration) {
                self.totDur += num
            }
        }
        print("totDur: \(totDur)")
        let hours = Int(totDur/3600)
        let mins = Int((totDur - 3600*hours)/60)
        let secs = Int((totDur - 3600*hours - 60*mins))
        // print("\(hours) hours, \(mins) mins, \(secs) secs")
        var dispDur = ""
        if hours > 0 {
            dispDur += String(hours) + " hours, "
        }
        if mins > 0 {
            dispDur += String(mins) + " minutes, "
        }
        if secs > 0 {
            dispDur += String(secs) + " seconds"
        }
        // print(dispDur)
        totDurLabel.text = "Playlist Duration: " + dispDur
    }
    
    
    func convertPTtoSec(PT: String) -> String{
        // Format: "PT" + minutes + "M" + seconds + "S"
        // Take away the PT
        let PT = PT.replacingOccurrences(of: "PT", with: "")
        // print("PT after PT remove: \(PT)")
        
        // If H, M, S
        var separators = CharacterSet.init()// [String]()
        if PT.contains("H") {
            separators.insert("H")
        }
        if PT.contains("M") {
            separators.insert("M")
        }
        if PT.contains("S") {
            separators.insert("S")
        }
        var arr = PT.components(separatedBy: separators)
        // print("separators: \(separators)")
        // print("arr after separators split: \(arr)")
        for (i, x) in arr.enumerated() {
            if x == "" {
                arr.remove(at: i)
            }
        }
        // print("arr: \(arr)")
        // Add in potential fields for hours, minutes, seconds
        while arr.count < 3 {
            arr.insert("", at: 0)
        }
        let mults = [3600, 60, 1]
        var ret = 0
        
        // Multiply by 3600 for hours, 60 for minutes, 1 for seconds
        for i in 0...2 {
            if let x = Int(arr[i]) {
                ret += x*mults[i]
            }
        }
        // print("arr: \(arr)\nret: \(ret)")
        return String(ret)
    }
}

