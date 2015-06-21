//
//  SendViewCellText.swift
//  FixMyMail
//
//  Created by Moritz Müller on 08.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class SendViewCellWithTextView: UITableViewCell {
    
    @IBOutlet weak var textViewMailBody: UITextView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(false, animated: false)
    }
    
}
