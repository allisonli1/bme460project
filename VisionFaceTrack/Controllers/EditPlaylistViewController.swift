//
//  EditPlaylistViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class EditPlaylistViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var videoTable: UITableView!
    @IBOutlet weak var playlistName: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    var playlist: Playlist?
    var videos: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        playlistName.delegate = self
        videoTable.delegate = self
        videoTable.dataSource = self
        if let playlist = playlist {
            playlistName.text = playlist.title
            videos.append(contentsOf: playlist.videos)
        }
        

        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
//        guard let button = sender as? UIBarButtonItem, button === saveButton else {
//            return
//        }
        
        let title = playlistName.text ?? "No Name"
        let selectedVideos = videos
        
        // Set the meal to be passed to MealTableViewController after the unwind segue.
        playlist = Playlist(title: title)
        for vid in selectedVideos {
            playlist?.addVideo(videoID: vid)
        }
        
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    

    //MARK: Actions
    @IBAction func getPlaylistResults(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? SearchViewController {
            let selectedVideos = sourceViewController.selectedVideos
            
            for vid in selectedVideos {
                self.playlist?.addVideo(videoID: vid)
            }
            self.videos.append(contentsOf: selectedVideos)
            self.videoTable.reloadData()
            
        }
    }
    
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddPlaylistMode = presentingViewController is UINavigationController
        
        if (isPresentingInAddPlaylistMode) {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The EditPlaylistViewController is not inside a navigation controller.")
        }
    }
    
}

extension EditPlaylistViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "VideoTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? VideoTableViewCell  else {
            fatalError("The dequeued cell is not an instance of VideoTableViewCell.")
        }
        
        let videoID = self.videos[indexPath.row]
        tableView.rowHeight = 120

        print("Makes the cell")
        cell.videoID.text = videoID
        return cell
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
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
    

    
}
