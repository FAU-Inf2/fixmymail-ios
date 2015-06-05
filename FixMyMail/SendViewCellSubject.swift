//
//  SendViewTableCell.swift
//  FixMyMail
//
//  Created by Moritz Müller on 02.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class SendViewCellSubject: UITableViewCell {
    @IBOutlet weak var txtText: TextfieldWithPadding!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(false, animated: false)
    }
    
}
