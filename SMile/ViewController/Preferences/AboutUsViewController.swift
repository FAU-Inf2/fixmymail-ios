//
//  AboutUsViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 17.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class AboutUsViewController: UIViewController {

	@IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		if let html = NSBundle.mainBundle().URLForResource("AboutUs", withExtension: "html") {
			let attributedString = try? NSAttributedString(URL: html, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
			self.textView.attributedText = attributedString
		}
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

}
