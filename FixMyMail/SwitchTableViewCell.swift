//
//  SwitchTableViewCell.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 10.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {

	@IBOutlet weak var label: UILabel!
	
	@IBOutlet weak var activateSwitch: UISwitch!
	
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
