//
//  CostumTableViewCell.swift
//  MailCoreTestSwift
//
//  Created by Martin on 07.05.15.
//  Copyright (c) 2015 Moritz Müller. All rights reserved.
//

import UIKit


protocol TableViewCellDelegate {
    func deleteEmail(mail: Email)
    func archiveEmail(mail: Email)
}

class CustomMailTableViewCell: UITableViewCell {
    
    @IBOutlet var mailFrom: UILabel!
    @IBOutlet var mailSubject: UILabel!
    @IBOutlet var unseendot: UIImageView!
	@IBOutlet weak var dateLabel: UILabel!
    @IBOutlet var mailBody: UILabel!
	
    var mail: Email!
    var delegate: TableViewCellDelegate?
    var height: CGFloat!
    
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false
    var archiveOnDragRelease = false
    var remindMeOnDragRelease = false
    
    var panGestureRecognizer: UIPanGestureRecognizer!
    var deleteIMGView = UIImageView(image: UIImage(named: "Trash.png"))
    var archiveIMGView = UIImageView(image: UIImage(named: "archive.png"))
    var subviewDeleteSwipeFromRightToLeft = UIView()
    var subviewArchiveSwipeFromLeftToRight = UIView()
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "panHandler:")
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    //horizontal swipe gesture methods
    func panHandler (recognizer: UIPanGestureRecognizer) {
        //init delete subview on the right
        deleteIMGView.frame = CGRect(x: 15, y: (height-25)/2, width: 20, height: 25)
        subviewDeleteSwipeFromRightToLeft.frame = CGRect(x: bounds.size.width, y: 0, width: self.bounds.width, height: height)
        subviewDeleteSwipeFromRightToLeft.addSubview(deleteIMGView)
        addSubview(subviewDeleteSwipeFromRightToLeft)

        //init archive subview on the left
        archiveIMGView.frame = CGRect(x: UIScreen.mainScreen().bounds.width - 40, y: (height-35)/2, width: 25, height: 35)
        subviewArchiveSwipeFromLeftToRight.frame = CGRect(x: -bounds.size.width, y: 0, width: self.bounds.width, height: height)
        subviewArchiveSwipeFromLeftToRight.addSubview(archiveIMGView)
        addSubview(subviewArchiveSwipeFromLeftToRight)
        
        if recognizer.state == .Began {
            // when the gesture begins, record the current center location
            originalCenter = center
        }
        
        if recognizer.state == .Changed {
            let translation = recognizer.translationInView(self)
            center = CGPointMake(originalCenter.x + translation.x, originalCenter.y)
            deleteOnDragRelease = frame.origin.x < -frame.size.width / 5.0
            archiveOnDragRelease = frame.origin.x > frame.size.width / 7.0
            remindMeOnDragRelease = frame.origin.x > frame.size.width / 2
            
            // indicate when the user has pulled the item far enough to invoke the given action
            subviewDeleteSwipeFromRightToLeft.backgroundColor = deleteOnDragRelease ? UIColor.redColor() : UIColor.grayColor()
            subviewArchiveSwipeFromLeftToRight.backgroundColor = archiveOnDragRelease ? UIColor.greenColor() : UIColor.grayColor()
            
            if remindMeOnDragRelease {
                archiveIMGView.hidden = true
                subviewArchiveSwipeFromLeftToRight.backgroundColor = UIColor.yellowColor()
            }else {
                archiveIMGView.hidden = false
            }
        }
        
        if recognizer.state == .Ended {
            let originalFrame = CGRect(x: 0, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            let fullLeftFrame = CGRect(x: -bounds.size.width, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            let fullRightFrame = CGRect(x: bounds.size.width, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            
            if !deleteOnDragRelease && !archiveOnDragRelease && !remindMeOnDragRelease {
                //snap back to original location
                UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
                return
            }
            
            if deleteOnDragRelease {
                if delegate != nil {
                    //delete this email
                    UIView.animateWithDuration(0.2, animations: {self.frame = fullLeftFrame})
                    delegate!.deleteEmail(mail)
                }
            }

            if remindMeOnDragRelease {
                UIView.animateWithDuration(0.2, animations: {self.frame = fullRightFrame})
                NSLog("REMIND ME")
            } else if archiveOnDragRelease {
                if delegate != nil {
                    //archive this email
                    UIView.animateWithDuration(0.2, animations: {self.frame = fullRightFrame})
                    delegate!.archiveEmail(mail)
                }
            }
        }
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translationInView(superview!)
            
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
        }
        return false
    }
}
