//
//  TextfieldWithPadding.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 31.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class TextfieldWithPadding: UITextField {

	
	override func textRectForBounds(bounds: CGRect) -> CGRect {
		return CGRectInset(bounds, 15.0, 0)
	}
	
	override func editingRectForBounds(bounds: CGRect) -> CGRect {
		return self.textRectForBounds(bounds)
	}
	
	override func shouldChangeTextInRange(range: UITextRange, replacementText text: String) -> Bool {
		if text == "YES"{
			return true
		}
		return false
	}
		

	
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
