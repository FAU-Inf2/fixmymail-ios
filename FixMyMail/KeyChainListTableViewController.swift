//
//  KeyChainListTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit







class KeyChainListTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
	
	var keyItemList = [KeyItem]()
	var myGrayColer = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
	let myOpacity:CGFloat = 0.1
	let monthsInYear: Int = 12
	let monthsForFullValidity: Int = 6

    override func viewDidLoad() {
        super.viewDidLoad()
		
		//Load some KeyItems
		loadInitialData()
		
		
		tableView.registerNib(UINib(nibName: "KeyItemTableViewCell", bundle: nil),forCellReuseIdentifier:"ListPrototypCell")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.keyItemList.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListPrototypCell", forIndexPath: indexPath) as! KeyItemTableViewCell

        // Configure the cell...
		
		var keyItem = self.keyItemList[indexPath.row]
		
		// Fill data to labels
		cell.LabelKeyOwner.text = keyItem.keyOwner
		cell.LabelMailAddress.text = keyItem.mailAddress
		cell.LabelKeyID.text = keyItem.keyID
		
		// Set the right lables for the key type
		switch keyItem.keyType {
			case "SMIME":
				cell.LabelPGP.alpha = myOpacity
			case "PGP":
				cell.LabelSMIME.alpha = myOpacity
			default:
				cell.LabelSMIME.alpha = myOpacity
				cell.LabelPGP.alpha = myOpacity
		}
		
		if !keyItem.isSecretKey {
			cell.LabelSecretKey.alpha = myOpacity
		}
		
		if !keyItem.isPublicKey {
			cell.LabelPublicKey.alpha = myOpacity
		}
		
		
		
		// Set the valid thru bar
		
		cell.LabelValid1.text = ""
		cell.LabelValid2.text = ""
		cell.LabelValid3.text = ""
		cell.LabelValid4.text = ""
		cell.LabelValid5.text = ""
		
		
		let currentDate = NSDate()
		if keyItem.validThru.year() >= currentDate.year() {
			if (keyItem.validThru.month() + (keyItem.validThru.year() - currentDate.year()) * monthsInYear) >= (currentDate.month() + monthsForFullValidity) {
				cell.LabelValid1.backgroundColor = UIColor.greenColor()
				cell.LabelValid2.backgroundColor = UIColor.greenColor()
				cell.LabelValid3.backgroundColor = UIColor.greenColor()
				cell.LabelValid4.backgroundColor = UIColor.greenColor()
				cell.LabelValid5.backgroundColor = UIColor.greenColor()
				
			} else {
				cell.LabelValid1.backgroundColor = UIColor.yellowColor()
				cell.LabelValid2.backgroundColor = UIColor.yellowColor()
				cell.LabelValid3.backgroundColor = UIColor.yellowColor()
				cell.LabelValid4.backgroundColor = UIColor.lightGrayColor()
				cell.LabelValid5.backgroundColor = UIColor.lightGrayColor()
				
			}
		
		} else {
			cell.LabelValid1.backgroundColor = UIColor.redColor()
			cell.LabelValid2.backgroundColor = UIColor.lightGrayColor()
			cell.LabelValid3.backgroundColor = UIColor.lightGrayColor()
			cell.LabelValid4.backgroundColor = UIColor.lightGrayColor()
			cell.LabelValid5.backgroundColor = UIColor.lightGrayColor()
		}
		
		
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
	
	
	
	func loadInitialData() {

		var key1 = KeyItem(keyOwner: "Max Mustermann", mailAddress: "max.musterman@gmail.com", keyID: "XXXXXXXX", isSecretKey: true, isPublicKey: true, keyType: "PGP", created: NSDate(), validThru: (NSDate(dateString: "2014-06-30")))
		var key2 = KeyItem(keyOwner: "Maximilianus Mustermann", mailAddress: "maxi.mus@web.de", keyID: "XXXXXXXX", isSecretKey: false, isPublicKey: true, keyType: "PGP", created: NSDate(), validThru: (NSDate(dateString: "2015-9-03")))
		var key3 = KeyItem(keyOwner: "Max Mustermann", mailAddress: "m.m@hotmail.com", keyID: "XXXXXXXX", isSecretKey: true, isPublicKey: true, keyType: "SMIME", created: NSDate(), validThru: (NSDate(dateString: "2017-03-12")))
		
		keyItemList.append(key3)
		keyItemList.append(key2)
		keyItemList.append(key1)
	}

}
