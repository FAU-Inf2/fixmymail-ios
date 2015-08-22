//
//  KeyDetailTableViewCell.swift
//  SMile
//
//  Created by Sebastian Thürauf on 17.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class KeyDetailTableViewCell: UITableViewCell {
	
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var content: UILabel!
	

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
