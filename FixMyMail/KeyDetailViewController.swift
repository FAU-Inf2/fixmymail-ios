//
//  KeyDetailViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 24.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class KeyDetailViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		self.Label1.text = keyItem!.keyOwner
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

	@IBOutlet weak var button1: UIButton!
	
	@IBOutlet weak var Label1: UILabel!
	
	var keyItem: KeyItem?
	
	
	
	func makeKeyItem(keyItem: KeyItem) {
		self.keyItem = keyItem
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
