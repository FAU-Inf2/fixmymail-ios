//
//  FeedbackViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class FeedbackViewController: UIViewController {

	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var buttonFeedback: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let html = NSBundle.mainBundle().URLForResource("Feedback", withExtension: "html") {
			let attributedString = NSAttributedString(fileURL: html, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil, error: nil)
			self.textView.attributedText = attributedString
		}
		

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBAction func buttonFeedbackTapped(sender: UIButton) {
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
