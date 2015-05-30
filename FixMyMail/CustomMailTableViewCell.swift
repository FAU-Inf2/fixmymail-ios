//
//  CostumTableViewCell.swift
//  MailCoreTestSwift
//
//  Created by Martin on 07.05.15.
//  Copyright (c) 2015 Moritz Müller. All rights reserved.
//

import UIKit

class CustomMailTableViewCell: UITableViewCell {
    
    @IBOutlet var mailFrom: UILabel!
    @IBOutlet var mailBody: UILabel!
    var mail: Email!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
