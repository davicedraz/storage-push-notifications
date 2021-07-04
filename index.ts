import { Injectable } from '@angular/core';
import { Platform } from '@ionic/angular';
import { SQLite, SQLiteObject } from '@ionic-native/sqlite/ngx';
import { BehaviorSubject, Observable } from 'rxjs';

import { NotificationModel } from '../models/notification.model';
import { NotificationDTO } from '../models/notification.dto';
import { NotificationDAO } from '../models/notification.dao';

@Injectable({
  providedIn: 'root'
})
export class NotificationSQLiteService {
  private database: SQLiteObject;
  private dbReady: BehaviorSubject<boolean> = new BehaviorSubject(false);

  private internalNotifications = new BehaviorSubject([]);

  constructor(private platform: Platform, private sqlite: SQLite) {
    this.platform.ready().then(() => {
      const databaseContext = { name: 'notifications.db' }
      this.platform.is('ios') ? databaseContext['iosDatabaseLocation'] = 'Documents' : databaseContext['location'] = 'default';

      this.sqlite.create(databaseContext)
        .then((db: SQLiteObject) => {
          db.transaction((tx) => {
            tx.executeSql("CREATE TABLE IF NOT EXISTS " + NotificationDAO.TABLE_NAME + " (" +
              NotificationDAO.ID + " TEXT PRIMARY KEY, " +
              NotificationDAO.TITLE + " TEXT, " +
              NotificationDAO.PARAGRAPH + " TEXT, " +
              NotificationDAO.CREATED_AT + " REAL, " +
              NotificationDAO.UNREAD + " INTEGER, " +
              NotificationDAO.PRODUCTS + " TEXT, " +
              NotificationDAO.LINK + " TEXT, " +
              NotificationDAO.ICON + " TEXT, " +
              NotificationDAO.BUTTON_TEXT + " TEXT, " +
              NotificationDAO.BUTTON_ACTION + " TEXT)");
          }).then(_ => {
            this.database = db;
            this.loadStoredNotifications();
            this.dbReady.next(true);
          })
        });
    });
  }

  getDatabaseState() {
    return this.dbReady.asObservable();
  }

  getInternalNotifications(): Observable<NotificationModel[]> {
    return this.internalNotifications.asObservable();
  }

  async saveNotification({ id, title, paragraph, creationDate, unread, products, link, icon, button_text, button_ga_action }) {
    let data = [id, title, paragraph, creationDate, unread, products, link, icon, button_text, button_ga_action];
    const insert = "INSERT INTO " + NotificationDAO.TABLE_NAME + " (" +
      NotificationDAO.ID + ", " +
      NotificationDAO.TITLE + ", " +
      NotificationDAO.PARAGRAPH + ", " +
      NotificationDAO.CREATED_AT + ", " +
      NotificationDAO.UNREAD + ", " +
      NotificationDAO.PRODUCTS + ", " +
      NotificationDAO.LINK + ", " +
      NotificationDAO.ICON + ", " +
      NotificationDAO.BUTTON_TEXT + ", " +
      NotificationDAO.BUTTON_ACTION + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    return this.database.executeSql(insert, data).then(_ => {
      this.loadStoredNotifications();
    });
  }

  async deleteInternalNotification(id) {
    return this.database.executeSql('DELETE FROM ' + NotificationDAO.TABLE_NAME + ' WHERE id = ?', [id]).then(_ => {
      this.loadStoredNotifications();
    });
  }

  async markInternalNotificationAsRead(notification: NotificationModel) {
    let data = [Number(notification.unread)];
    return this.database.executeSql(`UPDATE ` + NotificationDAO.TABLE_NAME + ` SET unread = ? WHERE id = ${notification.id}`, data).then(_ => {
      this.loadStoredNotifications();
    })
  }

  async loadStoredNotifications() {
    return this.database.executeSql('SELECT * FROM ' + NotificationDAO.TABLE_NAME + '', []).then(result => {
      const notifications: NotificationModel[] = [];

      if (result.rows.length > 0) {
        for (var i = 0; i < result.rows.length; i++) {
          const newNotification = new NotificationDTO(result.rows.item(i));
          notifications.push(newNotification.toNotificationModel());
        }
      }
      this.internalNotifications.next(notifications);
    });
  }
}