//
//  KeyItemTableViewCell.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 17.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

protocol CellDelegate {
	func didClickOnCellAtIndex(cellIndex: Int, withData: AnyObject)
}

class KeyItemTableViewCell: UITableViewCell, CellDelegate {
	
	
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
	
	@IBOutlet weak var ButtonKeyDetail: UIButton!
	
	var delegate: CellDelegate?
	var cellIndex: Int?
	
	// http://stackoverflow.com/questions/20655060/get-button-click-inside-ui-table-view-cell
	@IBAction func keyDetailButtonClicked(sender: UIButton) {
		self.delegate?.didClickOnCellAtIndex(cellIndex!, withData: self)
	}
	

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	func didClickOnCellAtIndex(cellIndex: Int, withData: AnyObject) {
		
	}

}
