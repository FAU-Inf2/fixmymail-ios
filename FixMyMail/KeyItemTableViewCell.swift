//
//  KeyItemTableViewCell.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 17.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class KeyItemTableViewCell: UITableViewCell {
	
	
	@IBOutlet weak var nameTextField: UITextField!

	@IBOutlet weak var mailTextField: UITextField!
	
	@IBOutlet weak var secretKeyTextField: UITextField!
	
	@IBOutlet weak var publicKeyTextField: UITextField!
	
	@IBOutlet weak var smimeTextField: UITextField!
	
	@IBOutlet weak var pgpTextField: UITextField!
	
	@IBOutlet weak var keyIdTextField: UITextField!
	
	
	
	
	
	
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
