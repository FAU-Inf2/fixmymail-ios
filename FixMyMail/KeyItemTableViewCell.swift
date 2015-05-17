//
//  KeyItemTableViewCell.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 17.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class KeyItemTableViewCell: UITableViewCell {
	
	
	@IBOutlet weak var LabelKeyOwner: UILabel!
	@IBOutlet weak var LabelMailAddress: UILabel!
	@IBOutlet weak var LabelSecretKey: UILabel!
	@IBOutlet weak var LabelPublicKey: UILabel!
	@IBOutlet weak var LabelSMIME: UILabel!
	@IBOutlet weak var LabelPGP: UILabel!
	@IBOutlet weak var LabelKeyID: UILabel!
	@IBOutlet weak var LabelValidThru: UILabel!
	@IBOutlet weak var LabelValid1: UILabel!
	@IBOutlet weak var LabelValid2: UILabel!
	@IBOutlet weak var LabelValid3: UILabel!
	@IBOutlet weak var LabelValid4: UILabel!
	@IBOutlet weak var LabelValid5: UILabel!
	
	

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
