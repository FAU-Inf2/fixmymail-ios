//
//  SideBarSubFolderTableViewCell.swift
//  FixMyMail
//
//  Created by Jan Weiß on 22.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class SideBarSubFolderTableViewCell: UITableViewCell {

    @IBOutlet weak var menuImg: UIImageView!
    @IBOutlet weak var menuLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
