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
	@IBOutlet weak var LabelKeyID: UILabel!
	@IBOutlet weak var LabelValidThru: UILabel!
	@IBOutlet weak var secKey: UIImageView!
	@IBOutlet weak var pubKey: UIImageView!
	@IBOutlet weak var smime: UIImageView!
	@IBOutlet weak var pgp: UIImageView!
	@IBOutlet weak var validIndicator1: UIImageView!
	@IBOutlet weak var validIndicator2: UIImageView!
	@IBOutlet weak var validIndicator3: UIImageView!
	@IBOutlet weak var validIndicator4: UIImageView!
	@IBOutlet weak var validIndicator5: UIImageView!
	
	
	

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	

}
