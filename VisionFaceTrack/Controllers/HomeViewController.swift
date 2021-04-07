//
//  HomeViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 3/6/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var startSessionButton: UIButton!
    @IBOutlet weak var seePlaylistsButton: UIButton!
    var videoList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up Butons
        startSessionButton.layer.cornerRadius = 20
        startSessionButton.layer.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1).cgColor
        startSessionButton.setTitleColor(UIColor.white, for: .normal)
        startSessionButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Thin", size: 35)
        
        seePlaylistsButton.layer.cornerRadius = 20
        seePlaylistsButton.layer.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1).cgColor
        seePlaylistsButton.setTitleColor(UIColor.white, for: .normal)
        seePlaylistsButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Thin", size: 35)
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "StartSession":
            break
        case "CreatePlaylist":
            break
        case "AddNewPlaylist":
            break
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }

        
    }
    
    @IBAction func backHome(_ unwindSegue: UIStoryboardSegue) {
        
    }
}
