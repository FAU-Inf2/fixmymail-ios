import UIKit
import CoreData

class MailViewController: UIViewController {
    @IBOutlet weak var lblFrom: UILabel!
    @IBOutlet weak var lblTo: UILabel!
    @IBOutlet weak var lblSubject: UILabel!
    @IBOutlet weak var tvTxt: UITextView!
    private var mailPos: Int = 0
    private var mailcount: Int = 0
    
    func showMail (position: Int) {
        var managedObjectContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                
                let acc: EmailAccount = emailAccounts[0] as! EmailAccount
                
                var emails: [Email] = acc.emails.allObjects as! [Email]
                
                mailcount = emails.count
                
                var email: Email = emails.removeAtIndex(mailPos)
                
                let parser = MCOMessageParser(data: email.data)
                
                let headers = parser.header
                
                var from = headers.from.displayName + " <" + headers.from.mailbox + ">"
                
                self.lblFrom.text = "From: " + from
                
                self.lblTo.text = "To: "
                
                let recipients = headers.to
                
                var i = 0
                
                for address in recipients {
                    if (address as! MCOAddress).displayName != nil && (address as! MCOAddress).mailbox != nil {
                        if i++ != 0 {self.lblTo.text = self.lblTo.text! + ", "}
                        self.lblTo.text = self.lblTo.text! + (address as! MCOAddress).displayName + " <" + (address as! MCOAddress).mailbox + ">"
                    }
                }
                
                let subject = headers.subject
                
                self.lblSubject.text = "Subject: " + subject
                
                let text = parser.plainTextBodyRendering()
                
                self.tvTxt.text = text
                
                emails.insert(email, atIndex: mailPos)
            }
        }
    }
    
    @IBAction func butPrevious(sender: AnyObject) {
        if mailPos == 0 {
            return
        }
        mailPos -= 1
        showMail(mailPos)
    }
    @IBAction func butNext(sender: AnyObject) {
        if mailPos == mailcount - 1 {
            return
        }
        mailPos += 1
        showMail(mailPos)
    }
    
    override func viewDidLoad() {
        
        showMail(mailPos)
        
        /*let session = MCOIMAPSession()
        session.hostname = acc.imapHostname
        session.port = acc.imapPort
        session.username = acc.username
        session.password = acc.password
        session.authType = MCOAuthType.SASLPlain
        session.connectionType = MCOConnectionType.TLS
        
        let headerOp = session.fetchMessageOperationWithFolder("INBOX", uid: 0)
        
        headerOp.start({(error, data) in
        if error != nil {
        NSLog("could not recieve mail: %@", error)
        return
        }
        
        let parser = MCOMessageParser(data: data)
        
        let headers = parser.header
        
        var from = headers.from.displayName + " <" + headers.from.mailbox + ">"
        
        self.lblFrom.text = "From: " + from
        
        self.lblTo.text = "To: "
        
        let recipients = headers.to
        
        var i = 0
        
        for address in recipients {
        let to: MCOAddress = address as! MCOAddress
        if i++ != 0 {self.lblTo.text = self.lblTo.text! + ", "}
        self.lblTo.text = self.lblTo.text! + to.displayName + " <" + to.mailbox + ">"
        }
        
        let subject = headers.subject
        
        self.lblSubject.text = "Subject: " + subject
        
        let text = parser.plainTextBodyRendering()
        
        self.lblTxt.text = text
        
        })*/
        
        super.viewDidLoad()
        
    }
}