package com.logistics.orders.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.IOException;

@Service
public class FirebaseNotificationService {
    private boolean initialized = false;

    @PostConstruct
    public void initialize() {
        if (!initialized) {
            try {
                FileInputStream serviceAccount = new FileInputStream("backend/logistics-microservices/orders-service/src/main/resources/firebase-service-account.json");
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(com.google.auth.oauth2.GoogleCredentials.fromStream(serviceAccount))
                        .build();
                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                }
                initialized = true;
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public void sendNotification(String title, String body, String token) {
        try {
            System.out.println("[FirebaseNotificationService] Enviando notificação para token: " + token + " | Título: " + title + " | Corpo: " + body);
            Message message = Message.builder()
                    .setToken(token)
                    .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                    .build();
            FirebaseMessaging.getInstance().send(message);
            System.out.println("[FirebaseNotificationService] Notificação enviada com sucesso!");
        } catch (Exception e) {
            System.out.println("[FirebaseNotificationService] Erro ao enviar notificação: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
