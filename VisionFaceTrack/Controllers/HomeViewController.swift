//
//  HomeViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 3/6/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    var videoList: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        
        
    }
    
    @IBAction func unwindToVideoList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditPlaylistViewController, let plist = sourceViewController.playlist {
            print("\(plist.title)")
            
            self.videoList.append(contentsOf: plist.videos)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "StartFaceDetection":
            guard let destViewController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let faceDetectionController = destViewController.topViewController as? FaceDetectionController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            print("\(self.videoList)")
            faceDetectionController.videoList = self.videoList
        
        case "CreatePlaylist":
            break
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
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
