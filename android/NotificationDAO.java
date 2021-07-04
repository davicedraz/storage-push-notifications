package br.com.davicedraz;

import com.onesignal.OSNotificationReceivedResult;
import org.json.JSONObject;

class NotificationDAO {
    String id;
    String title;
    String paragraph;
    String products;
    String iconPath;
    String link;
    String buttonText;
    String buttonAction;

    public NotificationDAO(OSNotificationReceivedResult receivedResult) {
        try {
            JSONObject notificationData = receivedResult.payload.additionalData;

            id = notificationData.has("id") ? notificationData.getString("id") : receivedResult.payload.notificationID;
            title = notificationData.getString("title");
            paragraph = notificationData.getString("text");
            products = notificationData.has("products") ? notificationData.getString("products") : "";
            iconPath = notificationData.has("icon") ? notificationData.getString("icon") : "";
            link = notificationData.has("link") ? notificationData.getString("link") : "";
            buttonText = notificationData.has("button_text") ? notificationData.getString("button_text") : "";
            buttonAction = notificationData.has("button_ga_action") ? notificationData.getString("button_ga_action") : "";
        }
        catch (JSONException e) {
            throw new Error("Invalid notification", e);
        }
    }

}