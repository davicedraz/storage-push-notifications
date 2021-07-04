import Foundation
import SQLite3
import os.log

class DataNotificationStorage {
    
    let ID: String = "id";
    let TITLE: String = "title";
    let PARAGRAPH: String = "paragraph";
    let CREATED_AT: String = "createdAt";
    let UNREAD: String = "unread";
    let PRODUCTS: String = "products";
    let LINK: String = "link";
    let ICON: String = "icon";
    let BUTTON_TEXT: String = "button_text";
    let BUTTON_ACTION: String = "button_ga_action";
    let TABLE_NAME: String = "notification";
    
    let dbPath: String = "notifications.db";
    var db:OpaquePointer?;
    
    init() {
        db = openDatabase()
        createTable()
    }
    
    func openDatabase() -> OpaquePointer? {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbPath)
        
//        // FIXME:
//        let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.br.com.oi.tecnicovirtual.onesignal");
//        os_log("SQLite URL: %s", fileURL.absoluteString)
        
        var db: OpaquePointer? = nil
        let result = sqlite3_open(fileURL.path, &db)
//        let result = sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil)
        
        if result == SQLITE_OK {
            print("SQLite: Successfully opened connection to database at \(dbPath)")
            return db
        }
        else {
            print("SQLite: error opening database")
            return nil
        }
    }
    
    func createTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS " + TABLE_NAME + " (" +
            ID + " TEXT PRIMARY KEY, " +
            TITLE + " TEXT, " +
            PARAGRAPH + " TEXT, " +
            CREATED_AT + " REAL, " +
            UNREAD + " INTEGER, " +
            PRODUCTS +  " TEXT, " +
            LINK + " TEXT, " +
            ICON + " TEXT, " +
            BUTTON_TEXT + " TEXT, " +
            BUTTON_ACTION + " TEXT)";
        
        var createTableStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("SQLite: notification table created.")
            } else {
                print("SQLite: notification table could not be created.")
            }
        } else {
            print("SQLite: CREATE TABLE statement could not be prepared.")
        }
        
        sqlite3_finalize(createTableStatement)
    }
    
    func insert(id: String, title: String, text: String, products: String, link: String, icon: String, buttonText: String, buttonAction: String) {
        let insertStatementString = "INSERT INTO " + TABLE_NAME + " (" +
            ID + ", " +
            TITLE + ", " +
            PARAGRAPH + ", " +
            CREATED_AT + ", " +
            UNREAD + ", " +
            PRODUCTS +  ", " +
            LINK + ", " +
            ICON + ", " +
            BUTTON_TEXT + ", " +
            BUTTON_ACTION + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        
        var insertStatement: OpaquePointer? = nil
        let actualTimestamp = Double((NSDate().timeIntervalSince1970 * 1000.0).rounded())
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (id as NSString).utf8String, -1, nil) //id
            sqlite3_bind_text(insertStatement, 2, (title as NSString).utf8String, -1, nil) //title
            sqlite3_bind_text(insertStatement, 3, (text as NSString).utf8String, -1, nil) //paragraph
            sqlite3_bind_double(insertStatement, 4, actualTimestamp) //createdAt
            sqlite3_bind_int(insertStatement, 5, 1) //1 (true) indicates the notification its stored as unread
            sqlite3_bind_text(insertStatement, 6, (products as NSString).utf8String, -1, nil) //products
            sqlite3_bind_text(insertStatement, 7, (link as NSString).utf8String, -1, nil) //link
            sqlite3_bind_text(insertStatement, 8, (icon as NSString).utf8String, -1, nil) //icon
            sqlite3_bind_text(insertStatement, 9, (buttonText as NSString).utf8String, -1, nil) //button_text
            sqlite3_bind_text(insertStatement, 10, (buttonAction as NSString).utf8String, -1, nil) //button_ga_action
            
            let result = sqlite3_step(insertStatement)
            
            if result == SQLITE_DONE {
                print("SQLite: Successfully inserted row.")
            } else {
                print("SQLite: Could not insert row.")
            }
        } else {
            print("SQLite: INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
}
