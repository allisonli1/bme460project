//
//  HomeViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 3/6/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var testImg: UIImageView!
    @IBOutlet weak var activate: UIButton!
    
    var currAn = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        testImg.image = UIImage(systemName: "octagon.fill")
        
        
    }
    
    
    @IBAction func animateImg(_ sender: UIButton) {
        UIView.animate(withDuration: 1, delay: 0, animations: {
            switch self.currAn {
            case 0:
                self.testImg.transform = CGAffineTransform(translationX: 100, y: 0)
                break
            case 1:
                self.testImg.transform = .identity
                break
            default:
                break
            }
            
        })
        self.currAn = 0
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
