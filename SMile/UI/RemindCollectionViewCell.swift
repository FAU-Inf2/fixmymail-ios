//
//  RemindCollectionViewCell.swift
//  SMile
//
//  Created by Andrea Albrecht on 08.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class RemindCollectionViewCell: UICollectionViewCell {

   
    @IBOutlet weak var images: UIImageView!
    
    
    @IBOutlet weak var labels: UILabel!
    
   /* override init(frame: CGRect) {
        Images = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height*2/3))
        labels = UILabel(frame: CGRect(x: 0, y: Images.frame.size.height, width: frame.size.width, height: frame.size.height/3))
        super.init(frame: frame)

        Images.contentMode = UIViewContentMode.ScaleAspectFit

        labels.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
        labels.textAlignment = .Center
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }*/
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
