importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

const firebaseConfig = {
    apiKey: 'AIzaSyDwLR8YZ9z659soqNniOpRcUIXlnDolKOs',
    appId: '1:775134713875:web:63190d4f8cb97a66a947e6',
    messagingSenderId: '775134713875',
    projectId: 'rental-b3324',
    authDomain: 'rental-b3324.firebaseapp.com',
    storageBucket: 'rental-b3324.firebasestorage.app',
    measurementId: 'G-NC0VWBDYBH',
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here if needed
    const notificationTitle = payload.data.title || payload.notification.title || "New Notification";
    const notificationOptions = {
        body: payload.data.body || payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
