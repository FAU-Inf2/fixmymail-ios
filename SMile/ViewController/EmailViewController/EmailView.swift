//
//  EmailView.swift
//  SMile
//
//  Created by Jan Weiß on 17.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

protocol EmailViewDelegate: NSObjectProtocol {
    func handleMailtoWithRecipients(recipients: [String], andSubject subject: String, andHTMLString html: String) -> Void
}

class EmailView: UIView, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, HTMLRenderBridgeDelegate, UIWebViewDelegate {
    
    var embededHeaderView: UITableView!
    var calculationView: UIView!
    var webView: UIWebView!
    var message: MCOIMAPMessage
    var email: Email
    var folder: String!
    var loadingSpinner: UIActivityIndicatorView!
    var messageHeaderInfo = [String: String]()
    var cellSenderHeight: CGFloat!
    var cellSubjectHeight: CGFloat!
    var messageContent: String = ""
    var htmlRenderBridge = HTMLRenderDelegateBridge()
    var imapPartCache = [String: NSData]()
    var ccStringHeight: CGFloat!
    var toStringHeight: CGFloat!
    var fromStringHeight: CGFloat!
    var emailViewDelegate: EmailViewDelegate?
    var plainHTMLContent: String!
    
    
    init(frame: CGRect, message: MCOIMAPMessage, email: Email) {
        self.email = email
        self.message = message
        super.init(frame: frame)
        
        self.htmlRenderBridge.delegate = self
        
        self.webView = UIWebView(frame: frame)
        self.webView.scalesPageToFit = true
        self.webView.delegate = self
        self.addSubview(self.webView)
        
        let spinnerSize = self.frame.width / 4
        let center = self.center
        self.loadingSpinner = UIActivityIndicatorView()
        self.loadingSpinner.frame.size = CGSizeMake(spinnerSize, spinnerSize)
        self.loadingSpinner.center = center
        self.loadingSpinner.hidden = true
        self.addSubview(self.loadingSpinner)
        self.bringSubviewToFront(self.loadingSpinner)
        self.sendSubviewToBack(self.webView)
        
        self.bringSubviewToFront(self.webView.scrollView)
        self.messageHeaderInfo = self.getHeaderInformationFromMCOAbstractMessage(self.message)
        
        self.createHeaderView()
        self.layoutWebViewSubviews()
        
        self.webView.scrollView.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.Initial, context: nil)
        
        self.preFetchAttachments()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            self.loadingSpinner.startAnimating()
            self.loadingSpinner.hidden = false
            self.loadHTMLView()
        })
    }

    
    required init(coder aDecoder: NSCoder) {
        self.email = aDecoder.decodeObjectForKey("Email") as! Email
        self.message = aDecoder.decodeObjectForKey("MCOIMAPMessage") as! MCOIMAPMessage
        super.init(coder: aDecoder)
        
    }
    
    
    private func createHeaderView() -> Void {
        let boldFont = UIFont.boldSystemFontOfSize(20.0)
        let standardFont = UIFont.systemFontOfSize(17.0)
        let width: CGFloat = CGFloat(self.frame.size.width - 8.0 - 8.0)
        
        self.ccStringHeight = self.messageHeaderInfo["cc"] != nil ? self.messageHeaderInfo["cc"]!.heightForWith(width, usingFont: standardFont) : 0.0
        self.toStringHeight = self.messageHeaderInfo["to"] != nil ? self.heightForView(self.messageHeaderInfo["to"]!, font: standardFont, width: width): 0.0
        self.fromStringHeight = self.messageHeaderInfo["from"]!.heightForWith(width, usingFont: boldFont)
        self.cellSenderHeight = 8.0 + 2.0 + 2.0 + 8.0 + self.ccStringHeight + self.toStringHeight + self.fromStringHeight
        
        let subjectStringHeight: CGFloat = self.messageHeaderInfo["subject"] != nil ? self.messageHeaderInfo["subject"]!.heightForWith(width, usingFont: boldFont) : "".heightForWith(width, usingFont: boldFont)
        let dateStringHeight: CGFloat = self.messageHeaderInfo["date"]!.heightForWith(width, usingFont: standardFont)
        self.cellSubjectHeight = 8.0 + 8.0 + subjectStringHeight + dateStringHeight
        
        self.embededHeaderView = UITableView(frame: CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.cellSenderHeight + self.cellSubjectHeight))
        self.embededHeaderView.dataSource = self
        self.embededHeaderView.delegate = self
        self.embededHeaderView.registerNib(UINib(nibName: "SenderInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "senderInfoCell")
        self.embededHeaderView.registerNib(UINib(nibName: "SubjectInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "subjectInfoCell")
        self.embededHeaderView.scrollEnabled = false
        self.webView.scrollView.addSubview(self.embededHeaderView)
        self.webView.scrollView.bringSubviewToFront(self.embededHeaderView)
        
        self.calculationView = UIView(frame: self.embededHeaderView.frame)
        self.calculationView.backgroundColor = UIColor.clearColor()
        self.addSubview(self.calculationView)
        self.sendSubviewToBack(self.calculationView)
    }
    
    
    private func layoutWebViewSubviews() {
        super.layoutSubviews()
        
        for view in self.webView.scrollView.subviews {
            if view is UIView {
                var subview = view as! UIView
                if subview.isEqual(self.embededHeaderView) {
                    continue
                }
                var newFrame = subview.frame
                newFrame.origin.y = CGRectGetHeight(self.embededHeaderView.frame)
                subview.frame = newFrame
            }
        }
    }
    
    
    deinit {
        self.webView.scrollView.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    //MARK: - UIWebviewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if navigationType == UIWebViewNavigationType.LinkClicked {
            if request.URL?.scheme == "mailto" {
                if self.emailViewDelegate != nil && self.emailViewDelegate!.respondsToSelector("handleMailtoWithRecipients:andSubject:andHTMLString:") {
                    self.emailViewDelegate!.handleMailtoWithRecipients([request.URL?.resourceSpecifier ?? ""], andSubject: (self.embededHeaderView.cellForRowAtIndexPath(NSIndexPath(forItem: 1, inSection: 0)) as! SubjectInfoTableViewCell).subjectLabel.text ?? "",andHTMLString: EmailCache.sharedInstance.getHTMLStringWithUniqueEmailID("\(self.message.uid)") ?? "")
                }
            } else if UIApplication.sharedApplication().canOpenURL(request.URL!) {
                UIApplication.sharedApplication().openURL(request.URL!)
            }
            return false
        }
        
        return true
    }
    
    //MARK: - Key-Value-Observing
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        var newFrame: CGRect = self.calculationView.frame
        newFrame.origin.y = -CGRectGetMinY(self.webView.convertRect(self.embededHeaderView.frame, toView: self.webView.scrollView))
        self.calculationView.frame = newFrame
        
        var newEmbededFrame: CGRect = self.embededHeaderView.frame
        newEmbededFrame.size = self.calculationView.frame.size
        newEmbededFrame.origin.x = self.webView.scrollView.contentOffset.x
        self.embededHeaderView.frame = newEmbededFrame
    }
    
    //MARK: - TableView functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return self.cellSenderHeight
        } else {
            return self.cellSubjectHeight
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            var senderInfoCell: SenderInfoTableViewCell = tableView.dequeueReusableCellWithIdentifier("senderInfoCell", forIndexPath: indexPath) as! SenderInfoTableViewCell
            
            senderInfoCell.fromLabel.text = self.messageHeaderInfo["from"]
            
            let ccLabelString: String? = self.messageHeaderInfo["cc"] != nil ? self.messageHeaderInfo["cc"]! : nil
            if ccLabelString == nil {
                senderInfoCell.ccLabel.frame.size = CGSizeZero
                senderInfoCell.ccLabel.text = ""
            } else {
                senderInfoCell.ccLabel.frame.size = CGSizeMake(senderInfoCell.ccLabel.frame.size.width, self.ccStringHeight)
                senderInfoCell.ccLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
                senderInfoCell.ccLabel.text = ccLabelString!
            }
            
            let toLabelString = self.messageHeaderInfo["to"] != nil ? self.messageHeaderInfo["to"]! : "To:"
            senderInfoCell.toLabel.frame.size = CGSizeMake(senderInfoCell.toLabel.frame.size.width, self.toStringHeight)
            senderInfoCell.toLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
            senderInfoCell.toLabel.text = toLabelString
            
            senderInfoCell.accessoryType = .None
            senderInfoCell.selectionStyle = UITableViewCellSelectionStyle.None
            return senderInfoCell
        } else {
            var subjectInfoCell: SubjectInfoTableViewCell = tableView.dequeueReusableCellWithIdentifier("subjectInfoCell", forIndexPath: indexPath) as! SubjectInfoTableViewCell
            
            let subjectLabelString = self.messageHeaderInfo["subject"] != nil ? self.messageHeaderInfo["subject"]! : ""
            subjectInfoCell.subjectLabel.text = subjectLabelString
            
            subjectInfoCell.dateLabel.text = self.messageHeaderInfo["date"]
            
            subjectInfoCell.accessoryType = .None
            subjectInfoCell.selectionStyle = UITableViewCellSelectionStyle.None
            return subjectInfoCell
        }
    }
    
    //MARK: - MailCore Message Helper
    
    private func getHeaderInformationFromMCOAbstractMessage(message: MCOAbstractMessage) -> [String: String] {
        var returnDict = [String: String]()
        var header : MCOMessageHeader = message.header
        
        var fromString: String = (header.from.displayName != nil) ? header.from.displayName : header.from.mailbox
        returnDict["from"] = "From: \(fromString)"
        
        var toString: String? = self.addressStringFromArray(header.to)
        if let to = toString {
            returnDict["to"] = "To: \(to)"
        } else {
            returnDict["to"] = toString
        }
        
        var ccString: String? = self.addressStringFromArray(header.cc)
        if let cc = ccString {
            returnDict["cc"] = "CC: \(cc)"
        } else {
            returnDict["cc"] = ccString
        }
        
        var subjectString: String? = header.subject != "" ? header.subject : nil
        returnDict["subject"] = subjectString
        
        var dateString = NSDateFormatter.localizedStringFromDate(header.date, dateStyle: .MediumStyle, timeStyle: .MediumStyle)
        returnDict["date"] = dateString
        
        return returnDict
    }
    
    private func heightForView(text:String, font: UIFont, width: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
    
    private func addressStringFromArray(array :[AnyObject]?) -> String? {
        if array == nil || array!.count == 0 {
            return nil
        }
        
        var addArray = NSMutableArray()
        for element in array! {
            if element is MCOAddress {
                let address = element as! MCOAddress
                if address.displayName != "" && address.displayName != nil {
                    addArray.addObject(address.displayName)
                } else {
                    addArray.addObject(address.mailbox)
                }
            }
        }
        
        return addArray.componentsJoinedByString(", ")
    }
    
    private func loadHTMLView() -> Void {
        let htmlContent = EmailCache.sharedInstance.getHTMLStringWithUniqueEmailID("\(self.message.uid)")
        if htmlContent != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.webView.loadHTMLString(htmlContent, baseURL: nil)
                self.loadingSpinner.hidden = true
                self.loadingSpinner.stopAnimating()
            })
        } else {
            var messageParser: MCOMessageParser = MCOMessageParser(data: self.email.data)
            var htmlContent: String? = messageParser.htmlRenderingWithDelegate(self.htmlRenderBridge) as String?
            
            if htmlContent == nil {
                self.messageContent = ""
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.webView.loadHTMLString("", baseURL: nil)
                    self.loadingSpinner.hidden = true
                    self.loadingSpinner.stopAnimating()
                })
                return
            }
            self.plainHTMLContent = htmlContent
            
            var htmlString = String()
            let jsURL = NSBundle.mainBundle().URLForResource("MCOMessageViewScript", withExtension: "js")
            

            if self.email.toAccount.imapHostname == "imap.web.de" {
                let content: NSString = htmlContent! as NSString
                let deleteRange: NSRange = content.rangeOfString("<body>\n<div style=\"font-family: Verdana;font-size: 12.0px;\">")
                if deleteRange.location != NSNotFound {
                    htmlContent = content.stringByReplacingOccurrencesOfString(("<body>\n<div style=\"font-family: Verdana;font-size: 12.0px;\">"), withString: ("<body>\n<div style=\"font-family: Helvetica;font-size: 50.0px;\">"))
                }
            }
                htmlString += "<html><head><script src=\"\(jsURL!.absoluteString)\"></script><style type='text/css'>body{ font-family: 'Helvetica Neue', Helvetica, Arial; margin:0; padding:30px;}\\hr {border: 0; height: 1px; background-color: #bdc3c7;}\\.show { display: none;}.hide:target + .show { display: inline;} .hide:target { display: none;} .content { display: none;} .hide:target ~ .content { display:inline;}\\</style></head><body><div style=\"font-family: Helvetica;font-size: 50.0px;\">\(htmlContent!)</div></body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'></iframe></html>"
            
            EmailCache.sharedInstance.emailContentCache["\(self.message.uid)"] = htmlString
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.webView.loadHTMLString(htmlString, baseURL: nil)
                self.loadingSpinner.hidden = true
                self.loadingSpinner.stopAnimating()
            })
        }
    }
    
    private func getDataOfIMAPPart(imapPart: MCOIMAPPart, withMessage message: MCOAbstractMessage, andwithFolder folder: String) -> NSData {
        var returnData: NSData!
        let partId = imapPart.uniqueID
        if EmailCache.sharedInstance.getIMAPPartDataWithUniquePartID("\(self.message.uid).\(partId)") != nil {
            return EmailCache.sharedInstance.getIMAPPartDataWithUniquePartID("\(self.message.uid).\(partId)")!
        }
        
        var fetchContentOperation: MCOIMAPFetchContentOperation = getSession(self.email.toAccount).fetchMessageAttachmentOperationWithFolder(folder, number: self.message.uid, partID: imapPart.partID, encoding: imapPart.encoding)
        fetchContentOperation.progress = { (current, maximum) -> Void in
            println("progress content: \(current)/\(maximum)")
        }
        
        self.loadingSpinner.startAnimating()
        self.loadingSpinner.hidden = false
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            fetchContentOperation.start({ (error, data) -> Void in
                if error != nil {
                    println(error)
                } else {
                    EmailCache.sharedInstance.imapPartCache["\(self.message.uid).\(imapPart.partID)"] = data
                    returnData = data
                }
            })
        })
        
        self.loadingSpinner.stopAnimating()
        self.loadingSpinner.hidden = true
        
        return returnData
    }
    
    private func preFetchAttachments() -> Void {
        if self.message.attachments().count > 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            dispatch_apply(self.message.attachments().count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { (i) -> Void in
                let part: MCOIMAPPart = self.message.attachments()[i] as! MCOIMAPPart
                var partFetchOp: MCOIMAPFetchContentOperation = getSession(self.email.toAccount).fetchMessageAttachmentOperationWithFolder(self.email.folder, number: self.message.uid, partID: part.partID, encoding: part.encoding)
                partFetchOp.start({ (error, data) -> Void in
                    if i == (self.message.attachments().count - 1) {
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                    if error != nil {
                        println(error)
                    } else {
                        EmailCache.sharedInstance.imapPartCache["\(self.message.uid).\(part.partID)"] = data
                    }
                })
            })
        })
    }
    
    //MARK: - HTMLRenderBridgeDelegate
    
    func abstractMessage(message: MCOAbstractMessage!, canPreviewPart part: MCOAbstractPart!) -> Bool {
        return false
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, templateForMainHeader header: MCOMessageHeader!) -> String! {
        return ""
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, templateForImage header: MCOAbstractPart!) -> String! {
        return ""
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, templateForAttachment part: MCOAbstractPart!) -> String! {
        return ""
    }
    
    func abstractMessageTemplateForMessage(msg: MCOAbstractMessage!) -> String! {
        return "{{BODY}}"
    }
    
    func abstractMessageTemplateForAttachmentSeparator(msg: MCOAbstractMessage!) -> String! {
        return ""
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, dataForIMAPPart part: MCOIMAPPart!, folder: String!) -> NSData! {
        return self.getDataOfIMAPPart(part, withMessage: msg, andwithFolder: folder)
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, prefetchAttachmentIMAPPart part: MCOIMAPPart!, folder: String!) {
        
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, prefetchImageIMAPPart part: MCOIMAPPart!, folder: String!) {
        
    }
    
    
    
}

extension String {
    
    func heightForWith(width: CGFloat, usingFont font : UIFont) -> CGFloat {
        var context: NSStringDrawingContext = NSStringDrawingContext()
        let labelSize = CGSizeMake(width, CGFloat(FLT_MAX))
        let rect: CGRect = self.boundingRectWithSize(labelSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: context)
        return rect.size.height
    }
    
}
