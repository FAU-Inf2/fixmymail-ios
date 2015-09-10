//
//  RemindViewController.swift
//  SMile
//
//  Created by Andrea Albrecht on 08.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class RemindViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    var mail: Email?
    var collectionView: UICollectionView!
    var blurimage: UIImage?
    
    var textData: [String] = ["Later Today","ThisEvening", "Tomorrow", "This Weekend", "Next Week", "In One Month", "", "","Pick a Date"]
    var Images:[String] = ["Hourglass-64.png","Waxing Gibbous Filled-64.png","Cup-64.png","Sun-64.png","Toolbox-64.png","Plus 1 Month-64.png","","","Calendar-64.png"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
       // layout.itemSize = CGSize(width: 100, height: 110)
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        self.view.backgroundColor = UIColor(patternImage: blurimage!)
        var blur = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
        var blurView = UIVisualEffectView(effect: blur)
        blurView.frame = collectionView.frame
        collectionView.backgroundColor = UIColor.clearColor()
        self.view.addSubview(blurView)
        self.view.addSubview(collectionView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        collectionView.registerClass(RemindCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.registerNib(UINib(nibName: "RemindCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! RemindCollectionViewCell
        var index = textData[0]
        cell.labels.text = textData[indexPath.row]
        cell.labels.textAlignment = .Center
        //cell.labels.textColor = UIColor.blackColor()
        cell.images.image = UIImage(named: Images[indexPath.row])
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSize(width: collectionView.frame.size.width/3, height: collectionView.frame.size.width/3)
        
    }
    
    /*func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        switch (indexPath.row){
        case 0: //Later Today
            println("0")
        case 1: //This Evening
            println("1")
        case 2: //Tomorrow Morning
            println("2")
        case 3: //This Weekend
            println("3")
        case 4: //Next Week
            println("4")
        case 5: //In 1 Month
            println("")
        case 8: //Pick a Date
            println("8")
        default:
            println("other")
        }
    }*/
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var cell = collectionView.cellForItemAtIndexPath(indexPath)
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
