//
//  KeyDetailViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 24.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class KeyDetailViewController: UIViewController {

	var keyItem: KeyItem?
	
	@IBOutlet weak var LabelKeyOwner: UILabel!
	@IBOutlet weak var LabelMailAddress: UILabel!
	@IBOutlet weak var LabelKeyID: UILabel!
	@IBOutlet weak var LabelValidThru: UILabel!
	
	@IBOutlet weak var TextfieldKeyOwner: UITextField!
	@IBOutlet weak var TextfieldMailAddress1: UITextField!
	@IBOutlet weak var TextfieldMailAddress2: UITextField!
	@IBOutlet weak var TextfieldMailAddress3: UITextField!
	@IBOutlet weak var TextfieldKeyID: UITextField!
	@IBOutlet weak var TextfieldValidThru: UITextField!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		self.TextfieldKeyOwner.text = keyItem?.keyOwner
		self.TextfieldMailAddress1.text = keyItem?.mailAddress
		self.TextfieldKeyID.text = keyItem?.keyID
		self.TextfieldValidThru.text = keyItem?.validThru.toLongDateString()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

	func makeKeyItem(keyItem: KeyItem) {
		self.keyItem = keyItem
	}
	
}
