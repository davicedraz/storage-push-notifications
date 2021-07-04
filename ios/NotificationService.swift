import UserNotifications
import OneSignal
import os.log

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request;
        self.contentHandler = contentHandler;
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent);
        
        let userInfo = request.content.userInfo
        let data = (userInfo["custom"] as! [AnyHashable : Any])["a"] as! [AnyHashable : Any]
        let notificationId = (userInfo["custom"] as! [AnyHashable : Any])["i"] as! String

        let silent = data["silent"] as? Bool

        if (silent != nil) {
            let db: DataNotificationStorage = DataNotificationStorage()
            
            let id = data["id"] as? String
            let title = data["title"] as? String
            let text = data["text"] as? String
            let products = data["products"] as? String
            let link = data["link"] as? String
            let icon = data["icon"] as? String
            let button_text = data["button_text"] as? String
            let button_ga_action = data["button_ga_action"] as? String
            
            db.insert(id: id ?? notificationId, title: title ?? "", text: text ?? "", products: products ?? "", link: link ?? "", icon: icon ?? "", buttonText: button_text ?? "", buttonAction: button_ga_action ?? "");
        }
        
        os_log("%{public}@", log: OSLog(subsystem: "br.com.oi.tecnicovirtual", category: "OneSignalNotificationServiceExtension"), type: OSLogType.debug, userInfo.debugDescription)
        
        if let bestAttemptContent = bestAttemptContent {
            OneSignal.didReceiveNotificationExtensionRequest(self.receivedRequest, with: self.bestAttemptContent)
            
            //TODO:
            if (silent ?? false) {
                // bestAttemptContent.title = "Titulo modificado";
                // bestAttemptContent.body = "o texto foi modificado pelo interceptador";
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            OneSignal.serviceExtensionTimeWillExpireRequest(self.receivedRequest, with: self.bestAttemptContent)
            contentHandler(bestAttemptContent)
        }
    }
    
}
