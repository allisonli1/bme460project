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
    @IBOutlet weak var playlistLabel: UILabel!
    @IBOutlet weak var makePlaylistButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        playlistTable.backgroundColor = UIColor.white
        playlistTable.delegate = self
        playlistTable.dataSource = self
        playlistLabel.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 45)
        playlistLabel.textColor = UIColor.black
        playlistLabel.backgroundColor = UIColor.white
        
        makePlaylistButton.layer.cornerRadius = 20
        makePlaylistButton.layer.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1).cgColor
        makePlaylistButton.setTitleColor(UIColor.white, for: .normal)
        makePlaylistButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 35)
        
        playlistTable.separatorStyle = .none
        
        if let savedPlaylists = loadPlaylists() {
            print("HERE")
            playlists += savedPlaylists
        }
        else {
            loadSamplePlaylists()
        }

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
            guard let playlistDetailViewController = segue.destination as? (EditPlaylistViewController) else {
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
            playlistDetailViewController.editMode = true
        case "ShowSavedPlaylist":
            guard let playlistDetailViewController = segue.destination as? (SavePlaylistViewController) else {
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
        if let sourceViewController = sender.source as? SavePlaylistViewController, let plist = sourceViewController.playlist {
            print("\(plist.title)")
            print("\(plist.duration)")
            if let selectedIndexPath = playlistTable.indexPathForSelectedRow {

                // Update an existing playlist.
                playlists[selectedIndexPath.row] = plist
                playlistTable.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // Add a new playlist.
                let newIndexPath = IndexPath(row: playlists.count, section: 0)

                playlists.append(plist)
                playlistTable.insertRows(at: [newIndexPath], with: .none)
            }
            
            savePlaylists()

        }
        

    }
    
    @IBAction func unwindFromCancel(sender: UIStoryboardSegue) {
        
    }
    
    //MARK: Private Methods
    private func loadSamplePlaylists() {
        
        let YTVideo1 = YouTubeResult(title:"Auli'i Cravalho - How Far I'll Go", videoID:"cPAbx5kgCJo", channel:"DisneyMusicVEVO", description:"", imageURL:"https://i.ytimg.com/vi/cPAbx5kgCJo/hqdefault.jpg", duration:"")
        
        let YTVideo2 = YouTubeResult(title:"Carmen Twillie, Lebo M. - Circle Of Life (Official Video from \"The Lion King\")", videoID:"GibiNy4d4gc", channel:"DisneyMusicVEVO", description:"", imageURL:"https://i.ytimg.com/vi/GibiNy4d4gc/hqdefault.jpg", duration:"")
        
        let YTVideo3 = YouTubeResult(title:"The Little Mermaid - Under the Sea (from The Little Mermaid) (Official Video)", videoID:"GC_mV1IpjWA", channel:"DisneyMusicVEVO", description:"", imageURL:"https://i.ytimg.com/vi/GC_mV1IpjWA/hqdefault.jpg", duration:"")
        
        let YTVideo4 = YouTubeResult(title:"Idina Menzel - Let It Go (from Frozen) (Official Video)", videoID:"YVVTZgwYwVo", channel:"DisneyMusicVEVO", description:"", imageURL:"https://i.ytimg.com/vi/YVVTZgwYwVo/hqdefault.jpg", duration:"")

        let playlist1 = Playlist(title: "Disney Music", duration: "836")
        playlist1.addVideo(video: YTVideo1)
        playlist1.addVideo(video: YTVideo2)
        playlist1.addVideo(video: YTVideo3)
        playlist1.addVideo(video: YTVideo4)
    
        playlist1.addVideoID(videoID: YTVideo1.videoID)
        playlist1.addVideoID(videoID: YTVideo2.videoID)
        playlist1.addVideoID(videoID: YTVideo3.videoID)
        playlist1.addVideoID(videoID: YTVideo4.videoID)
        
        playlists.append(playlist1)
        self.savePlaylists()
        
    }
    
    private func savePlaylists() {
        print("Saving Playlists")
        _ = NSKeyedArchiver.archiveRootObject(playlists, toFile: Playlist.ArchiveURL.path)
        
    }
    
    private func loadPlaylists() -> [Playlist]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Playlist.ArchiveURL.path) as? [Playlist]
    }
    
    func totDurToString(totDur: Int) -> String {
        // Reset total duration of playlist to 0, helps if just updating from a non-zero val
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
        return dispDur
    }
    
    
    

}

extension PlaylistSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
        print("Duration: \(plist.duration)")
        tableView.rowHeight = 160

        print("Makes the cell")
        cell.nameLabel.text = plist.title
        cell.nameLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 30)
        cell.numVideosLabel.text = "Videos: \(plist.videos.count)"
        cell.numVideosLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 20)
        cell.nameLabel.textColor = UIColor.white
        cell.numVideosLabel.textColor = UIColor.white
        cell.totDurLabel.text = "Playlist Duration: " + totDurToString(totDur: Int(plist.duration) ?? 0)
        cell.totDurLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 20)
        cell.totDurLabel.textColor = UIColor.white
        cell.containerView.layer.cornerRadius = 20
        cell.containerView.layer.shadowOpacity = 0.6
        cell.containerView.layer.shadowRadius = 4
        cell.containerView.layer.shadowColor = UIColor(red: 0.930, green: 0.569, blue: 0.730, alpha: 1).cgColor
        cell.containerView.layer.shadowOffset = CGSize(width: 6, height: 6)
        cell.containerView.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1)
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
            savePlaylists()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    

    
}
