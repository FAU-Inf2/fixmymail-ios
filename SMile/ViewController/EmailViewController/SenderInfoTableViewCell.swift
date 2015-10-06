//
//  SenderInfoTableViewCell.swift
//  SMile
//
//  Created by Jan Weiß on 17.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class SenderInfoTableViewCell: UITableViewCell {

	@IBOutlet weak var fromButton: UIButton!
	@IBOutlet weak var toButton: UIButton!
	@IBOutlet weak var fromLabel: UILabel!
	@IBOutlet weak var toLabel: UILabel!
	@IBOutlet weak var ccLabel: UILabel!
	
	var message: MCOIMAPMessage?
	
	
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
	
	@IBAction func fromButtonTapped(sender: UIButton) {
	}
	
	@IBAction func toButtonTapped(sender: UIButton) {
	}
	
	
	
	
	
    
}
