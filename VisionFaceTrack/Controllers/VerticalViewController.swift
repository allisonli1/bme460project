//
//  VerticalViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 3/21/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class VerticalViewController: UIViewController {

    @IBOutlet weak var liveLeft: UILabel!
    @IBOutlet weak var liveRight: UILabel!
    @IBOutlet weak var calibratedLeft: UILabel!
    @IBOutlet weak var calibratedRight: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        liveLeft.text = "N/A"
        liveRight.text = "N/A"
        calibratedLeft.text = "N/A"
        calibratedRight.text = "N/A"
    }
    
    func changeLiveLabel(textLeft: String, textRight: String) {
        liveLeft.text = textLeft
        liveRight.text = textRight
    }
    
    func changeCalibratedLabel(textLeft: String, textRight: String) {
        calibratedLeft.text = textLeft
        calibratedRight.text = textRight
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
