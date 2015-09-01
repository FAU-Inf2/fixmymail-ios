//
//  AttachmentCell.swift
//  SMile
//
//  Created by Moritz Müller on 01.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import Foundation

class AttachmentCell: UITableViewCell {
    
    @IBOutlet weak var imageViewPreview: UIImageView!
    @IBOutlet weak var labelFilename: UILabel!
    @IBOutlet weak var labelFileSize: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}