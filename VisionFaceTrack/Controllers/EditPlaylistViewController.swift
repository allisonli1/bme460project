//
//  EditPlaylistViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class EditPlaylistViewController: UIViewController {
    
    @IBOutlet weak var videoTable: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    var playlist: Playlist?
    var videos: [YouTubeResult] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        videoTable.delegate = self
        videoTable.dataSource = self
        videoTable.backgroundColor = UIColor.white
        if let playlist = playlist {
            videos.append(contentsOf: playlist.videos)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        let selectedVideos = videos
        
        // Set the playlist to be passed after the unwind segue.
        playlist = Playlist(title: "")
        for vid in selectedVideos {
            playlist?.addVideoID(videoID: vid.videoID)
            playlist?.addVideo(video: vid)
        }
        
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
        
        let video = self.videos[indexPath.row]
        tableView.rowHeight = 90

        print("Makes the cell")
        cell.setVideo(video: video)
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
    

    
}
