//
//  SavePlaylistViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/6/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class SavePlaylistViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var saveVideoTable: UITableView!
    @IBOutlet weak var nameTextField: UITextField!
    
    var playlist: Playlist?
    var videos: [YouTubeResult] = []
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        saveVideoTable.delegate = self
        saveVideoTable.dataSource = self
        saveVideoTable.dragDelegate = self
        saveVideoTable.dragInteractionEnabled = true
        saveVideoTable.backgroundColor = UIColor.white
        if let playlist = playlist {
            videos.append(contentsOf: playlist.videos)
            nameTextField.text = playlist.title
        }
        saveButton.isEnabled = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        let selectedVideos = videos
        
        // Set the playlist to be passed after the unwind segue.
        playlist = Playlist(title: "")
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

