//
//  TestViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 3/20/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit


class TiltViewController: UIViewController {
    
    @IBOutlet weak var liveTilt: UILabel!
    @IBOutlet weak var calibratedTilt: UILabel!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        liveTilt.text = "N/A"
        calibratedTilt.text = "N/A"
    }
    
    func changeLiveLabel(text: String) {
        liveTilt.text = text
    }
    
    func changeCalibratedLabel(text: String) {
        calibratedTilt.text = text
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
