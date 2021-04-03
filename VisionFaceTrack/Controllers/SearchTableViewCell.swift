//
//  SearchTableViewCell.swift
//  VisionFaceTrack
//
//  Created by Allison Li on 4/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class SearchTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setVideo(video: YouTubeResult) {
        loadURL(url: NSURL(string: video.imageURL)! as URL)
        self.titleLabel.text = video.title
        self.descLabel.text = video.description
    }
    
    func loadURL(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.thumbnailImage.image = image
                    }
                }
            }
        }
    }

}
