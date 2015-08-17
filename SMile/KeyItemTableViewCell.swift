//
//  KeyItemTableViewCell.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 17.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

protocol CellDelegate {
	func didClickOnCellInfoButton(cellIndex: Int)
}

class KeyItemTableViewCell: UITableViewCell, CellDelegate {
	
	
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
	
	
	
	
	
	
	@IBOutlet weak var ButtonKeyDetail: UIButton!
	
	var delegate: CellDelegate?
	var cellIndex: Int?
	
	// http://stackoverflow.com/questions/20655060/get-button-click-inside-ui-table-view-cell
	@IBAction func keyDetailButtonClicked(sender: UIButton) {
		self.delegate!.didClickOnCellInfoButton(cellIndex!)
	}
	

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	// impl to fullfil protocol
	func didClickOnCellInfoButton(cellIndex: Int) {
	}

}
