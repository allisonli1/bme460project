//
//  TestViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 3/20/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit


class TiltViewController: UIViewController {
    

    @IBOutlet weak var angle: UILabel!
    // var num: String?
    var numIndex: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        angle.text = "hi"
        // Do any additional setup after loading the view.
    }
    
    func changeLabel(text: String, type: Int) {
        let numAsInt = Int(num!)
        if (type == numAsInt) {
            angle.text = text
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
