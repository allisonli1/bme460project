//
//  AngleInfoViewController.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 3/20/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class AngleInfoViewController: UIPageViewController {


    weak var layerViewController: FaceDetectionController!

    fileprivate lazy var pages: [UIViewController] = {
        return [
            self.getViewController(withIdentifier: "TiltViewController"),
            self.getViewController(withIdentifier: "VerticalViewController")
        ]
    }()
    
    var currentIndex: Int {
        guard let vc = viewControllers?.first else { return 0 }
        return pages.firstIndex(of: vc) ?? 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        
        if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    
    fileprivate func getViewController(withIdentifier identifier: String) -> UIViewController {
        return UIStoryboard(name: "FaceDetection", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }

    func changeLiveLabel(textLeft: String, textRight: String, type: Int) {
        if (type == currentIndex) {
            if (type == 0) { // tilt
                let tempVC = pages[currentIndex] as? TiltViewController
                tempVC?.changeLiveLabel(text: textLeft)
            }
            else if (type == 1) { // verticalLeft
                let tempVC = pages[currentIndex] as? VerticalViewController
                tempVC?.changeLiveLabel(textLeft: textLeft, textRight: textRight)
            }
        }
    }
    
    func changeCalibratedLabel(textLeft: String, textRight: String, type: Int) {
        if (type == currentIndex) {
            if (type == 0) { // tilt
                let tempVC = pages[currentIndex] as? TiltViewController
                tempVC?.changeCalibratedLabel(text: textLeft)
            }
            else if (type == 1) { // vertical
                let tempVC = pages[currentIndex] as? VerticalViewController
                tempVC?.changeCalibratedLabel(textLeft: textLeft, textRight: textRight)
            }
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

extension AngleInfoViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else { return nil }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else { return nil }
        guard pages.count > previousIndex else { return nil }
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else { return nil }
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < pages.count else { return nil }
        guard pages.count > nextIndex else { return nil }
        return pages[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
      return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
      return 0
    }
}
