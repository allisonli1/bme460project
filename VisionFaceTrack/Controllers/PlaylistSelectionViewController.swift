//
//  PlaylistSelectionViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class PlaylistSelectionViewController: UIViewController {

    @IBOutlet weak var playlistTable: UITableView!
    var playlists =  [Playlist]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadSamplePlaylists()
        playlistTable.backgroundColor = UIColor.white
        playlistTable.delegate = self
        playlistTable.dataSource = self

        // Do any additional setup after loading the view.
    }
    
    
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "AddPlaylist":
            break
        case "ShowPlaylist":
            guard let playlistDetailViewController = segue.destination as? EditPlaylistViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
             
            guard let selectedPlaylistCell = sender as? PlaylistTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
             
            guard let indexPath = playlistTable.indexPath(for: selectedPlaylistCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
             
            let selectedPlaylist = playlists[indexPath.row]
            playlistDetailViewController.playlist = selectedPlaylist
        
        default:
            break
        }
        
        
    }
    
    
    //MARK: Actions
    @IBAction func unwindToPlaylistList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditPlaylistViewController, let plist = sourceViewController.playlist {
            print("\(plist.title)")

            if let selectedIndexPath = playlistTable.indexPathForSelectedRow {

                // Update an existing playlist.
                playlists[selectedIndexPath.row] = plist
                playlistTable.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // Add a new playlist.
                let newIndexPath = IndexPath(row: playlists.count, section: 0)

                playlists.append(plist)
                playlistTable.insertRows(at: [newIndexPath], with: .automatic)
            }

        }
        

    }
    
    //MARK: Private Methods
    private func loadSamplePlaylists() {
        
        let YTVideo1 = YouTubeResult(title:"Auli'i Cravalho - How Far I'll Go", videoID:"cPAbx5kgCJo", channel:"DisneyMusicVEVO", description:"", imageURL:"https://i.ytimg.com/vi/cPAbx5kgCJo/default.jpg", duration:"")
        
        let YTVideo2 = YouTubeResult(title:"Carmen Twillie, Lebo M. - Circle Of Life (Official Video from \"The Lion King\")", videoID:"GibiNy4d4gc", channel:"DisneyMusicVEVO", description:"", imageURL:"https://i.ytimg.com/vi/GibiNy4d4gc/default.jpg", duration:"")
        
        let YTVideo3 = YouTubeResult(title:"The Little Mermaid - Under the Sea (from The Little Mermaid) (Official Video)", videoID:"GC_mV1IpjWA", channel:"DisneyMusicVEVO", description:"", imageURL:"https://i.ytimg.com/vi/GC_mV1IpjWA/default.jpg", duration:"")
        
        let YTVideo4 = YouTubeResult(title:"Idina Menzel - Let It Go (from Frozen) (Official Video)", videoID:"YVVTZgwYwVo", channel:"DisneyMusicVEVO", description:"", imageURL:"https://i.ytimg.com/vi/YVVTZgwYwVo/default.jpg", duration:"")

        let playlist1 = Playlist(title: "Disney Music")
        playlist1.addVideo(video: YTVideo1)
        playlist1.addVideo(video: YTVideo2)
        playlist1.addVideo(video: YTVideo3)
        playlist1.addVideo(video: YTVideo4)
    
        playlist1.addVideoID(videoID: YTVideo1.videoID)
        playlist1.addVideoID(videoID: YTVideo2.videoID)
        playlist1.addVideoID(videoID: YTVideo3.videoID)
        playlist1.addVideoID(videoID: YTVideo4.videoID)
        
        playlists.append(playlist1)
        
    }
    

}

extension PlaylistSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "PlaylistTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PlaylistTableViewCell  else {
            fatalError("The dequeued cell is not an instance of PlaylistTableViewCell.")
        }
        
        let plist = self.playlists[indexPath.row]
        tableView.rowHeight = 80

        print("Makes the cell")
        cell.nameLabel.text = plist.title
        cell.numVideosLabel.text = "Videos: \(plist.videos.count)"
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
            playlists.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    

    
}
