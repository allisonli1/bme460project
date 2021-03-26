//
//  PositioningViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 3/6/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class PositioningViewController: UIViewController {
    @IBOutlet weak var angle: UILabel!
    @IBOutlet weak var yPos: UILabel!
    @IBAction func refresh(_ sender: Any) {
        // updateXPos()
    }
    var timer = Timer()
    
    weak var layerViewController: FaceDetectionController!
    // var fController = FaceDetectionController()
    var myAngle: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        /*
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            timer in self.updateAngle(timer: timer)
            
        }
 */
        
    }
    /*
    /*
    func getAngle(ang: CGFloat) {
        self.myAngle = ang
        // print(self.myAngle)
        let tempAngle: Float = Float(self.myAngle)
        //print(tempAngle)
        self.angle.text = "\(tempAngle)"
    } */
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    /*
    func updateAngle(headAngle: CGFloat) {
        // Disable the Save button if the text field is empty.
        let tempAngle: Float
        tempAngle = Float(headAngle)
        // tempAngle
        // angle.text = "\(headAngle)"
    }
    */
    
    
    func updateAngle(timer:Timer) {
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            print("do some background task")

            DispatchQueue.main.async {
                print("update some UI")
                if let hAngle = self.layerViewController.angleFromH {
                    print("Got an angle")
                } else {
                    print("No angle")
                }
                let tempAngle: Float = Float(self.myAngle)
                print(tempAngle)
                // self.angle.text = "\(tempAngle)"
            }
        }
    }
 
    */
    
}
