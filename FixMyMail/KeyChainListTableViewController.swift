//
//  KeyChainListTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit







class KeyChainListTableViewController: UITableViewController {
	
	var keyItemList = [KeyItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadInitialData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
		
		cell.nameTextField.text = keyItem.keyOwner
		cell.mailTextField.text = keyItem.mailAddress
		cell.keyIdTextField.text = keyItem.keyID
		
		switch keyItem.keyType {
			case "SMIME":
				cell.pgpTextField.text = ""
			case "PGP":
				cell.smimeTextField.text = ""
			default:
				cell.pgpTextField.text = ""
				cell.smimeTextField.text = ""
		}
		
		if !keyItem.isSecretKey {
			cell.secretKeyTextField.text = ""
		}
		
		if !keyItem.isPublicKey {
			cell.publicKeyTextField.text = ""
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

		var key1 = KeyItem(keyOwner: "Max Mustermann", mailAddress: "max.musterman@gmail.com", keyID: "XXXXXXXX", isSecretKey: true, isPublicKey: true, keyType: "PGP", created: NSDate(), validThru: (NSDate(dateString: "2016-06-30")))
		var key2 = KeyItem(keyOwner: "Maximilianus Mustermann", mailAddress: "maxi.mus@web.de", keyID: "XXXXXXXX", isSecretKey: false, isPublicKey: true, keyType: "PGP", created: NSDate(), validThru: (NSDate(dateString: "2016-09-03")))
		var key3 = KeyItem(keyOwner: "Max Mustermann", mailAddress: "m.m@hotmail.com", keyID: "XXXXXXXX", isSecretKey: true, isPublicKey: true, keyType: "SMIME", created: NSDate(), validThru: (NSDate(dateString: "2017-03-12")))
		
		keyItemList.append(key1)
		keyItemList.append(key2)
		keyItemList.append(key3)
	}

}
