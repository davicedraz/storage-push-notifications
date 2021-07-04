package br.com.davicedraz;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import java.sql.Timestamp;

import com.onesignal.NotificationExtenderService;
import com.onesignal.OSNotificationReceivedResult;

import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import org.json.JSONException;
import org.json.JSONObject;
import me.leolin.shortcutbadger.ShortcutBadger;




class DataNotificationRepository extends SQLiteOpenHelper {
    private final String CREATE_TABLE;
    private final String ID = "id";
    private final String TITLE = "title";
    private final String PARAGRAPH = "paragraph";
    private final String CREATED_AT = "createdAt";
    private final String UNREAD = "unread";
    private final String PRODUCTS = "products";
    private final String LINK = "link";
    private final String ICON = "icon";
    private final String BUTTON_TEXT = "button_text";
    private final String BUTTON_ACTION = "button_ga_action";
    private final String TABLE_NAME = "notification";

    public DataNotificationRepository(Context context) {
        super(context, "notifications.db", null, 1);
        this.CREATE_TABLE = "CREATE TABLE IF NOT EXISTS " + TABLE_NAME + " (" +
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
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL(this.CREATE_TABLE);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        this.onCreate(db);
    }

    public long saveNotification(NotificationDAO notification, SQLiteDatabase db) {
        ContentValues values = new ContentValues();
        Timestamp ts = new Timestamp(System.currentTimeMillis());
        long notificationCreationTS = ts.getTime();

        values.put(ID, notification.id);
        values.put(TITLE, notification.title);
        values.put(PARAGRAPH, notification.paragraph);
        values.put(CREATED_AT, notificationCreationTS);
        values.put(UNREAD, 1); //1 (true) indicates the notification its stored as unread

        values.put(PRODUCTS, notification.products);
        values.put(ICON, notification.iconPath);
        values.put(LINK, notification.link);
        values.put(BUTTON_TEXT, notification.buttonText);
        values.put(BUTTON_ACTION, notification.buttonAction);

        return db.insert(TABLE_NAME, null, values);
    }

    public boolean isDataAlreadyExists(String key, String value, SQLiteDatabase db) {
        String[] data = new String[]{value};
        Cursor cursor = db.query(TABLE_NAME, null, key + " = ?", data, null, null, null, null);
        return cursor.getCount() > 0;
    }

}


public class NotificationInterceptor extends NotificationExtenderService {
    /**
     * Intercepts a notification received to process it.
     * Returns 'true' to process and not display the notification, and 'false' to not process and display the notification received.
     */
    @Override
    protected boolean onNotificationProcessing(OSNotificationReceivedResult receivedResult) {
        try {
            JSONObject notificationData = receivedResult.payload.additionalData;

            Context context = getBaseContext();
            NotificationDAO notification = new NotificationDAO(receivedResult);

            if(!isValidDataNotification(notificationData)) {
                return false;
            }

            boolean shouldSilentNotification = notificationData.getBoolean("silent");

            DataNotificationRepository notificationRepository = new DataNotificationRepository(context);
            SQLiteDatabase db = notificationRepository.getWritableDatabase();

            if (notificationRepository.isDataAlreadyExists("id", notification.id, db)) {
                return true;
            }

            notificationRepository.saveNotification(notification, db);

            if (ShortcutBadger.isBadgeCounterSupported(context)) {
                ShortcutBadger.applyCountOrThrow(context, 1);
            }

            return shouldSilentNotification;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean isValidDataNotification(JSONObject notificationData) {
        return notificationData.has("silent") && notificationData.has("title") && notificationData.has("text");
    }

}
