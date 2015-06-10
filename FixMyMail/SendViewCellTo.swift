//
//  SendViewCellSuggestion.swift
//  FixMyMail
//
//  Created by Moritz Müller on 02.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import Foundation

class SendViewCellTo: UITableViewCell {
    
    @IBOutlet weak var txtTo: UITextField!
    @IBOutlet weak var lblTo: UILabel!
    @IBOutlet weak var txtSuggestion: UITextField!
    var emails: NSArray = []
    
    @IBAction func ConfirmEmail(sender: AnyObject) {
        var txtAddresses: String = ""
        var add:Array = txtTo.text.componentsSeparatedByString(",")
        if(add.count > 1) {
            add.removeAtIndex(add.count-1)
            for var index = 0; index < add.count; ++index{
                txtAddresses += add[index] as String
                txtAddresses += ", "
            }
            txtAddresses += txtSuggestion.text
            txtTo.text = txtAddresses
            txtSuggestion.text = ""
        }
        else if(!(txtSuggestion.text == nil)) {
            txtTo.text = txtSuggestion.text
            txtSuggestion.text=""
        }
    }
    
    @IBAction func EmailAddressEntered(sender: AnyObject) {
        var email: String = txtTo.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        var i: Int = count(email)
        println("Toaddress: \(txtTo.text)")
        if(email == "") {
            txtSuggestion.text = ""
        }
        else if(email == txtSuggestion.text) {}
        else if(email.rangeOfString(",") != nil) {
            var add: NSArray = email.componentsSeparatedByString(",")
            i=count(add.lastObject!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                as String)
            if(i != 0){
                checkforsimilarEmail(i, email: add.lastObject!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) as String)
            }
        }
        else{
            checkforsimilarEmail(i, email:email as String)
        }
    }
    
    func checkforsimilarEmail(i: Int, email: String){
        println("Toaddress: \(email)")
        for results in emails {
            if(i > count(results.email)) {
                continue
            }
            let index: String.Index = advance(results.email!.startIndex, i)
            var substring: String = results.email!.substringToIndex(index)
            if(substring == email) {
                txtSuggestion.text = results.email
                break
            }
            txtSuggestion.text = ""
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(false, animated: false)
    }
    
}
