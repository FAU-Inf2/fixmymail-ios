//
//  File.swift
//  FixMyMail
//
//  Created by Moritz Müller on 24.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class ToolBar: UIViewController {
    
    var rootView: ViewController!
    @IBOutlet weak var toolBar: UIToolbar!
    
    @IBAction func writeMail(sender: UIBarButtonItem) {
        rootView.navigationController?.pushViewController(MailSendViewController(nibName: "MailSendViewController", bundle: nil), animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
