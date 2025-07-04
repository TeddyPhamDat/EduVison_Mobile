// Import Firebase scripts for FCM
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
const firebaseConfig = {
  apiKey: "AIzaSyChBjvAEBhWl6XuBBD16UktKXlh1AMBNoU",
  authDomain: "eduvision-6ba8d.firebaseapp.com",
  projectId: "eduvision-6ba8d",
  storageBucket: "eduvision-6ba8d.firebasestorage.app",
  messagingSenderId: "297050045843",
  appId: "1:297050045843:web:66e1b13861b4246c91fc66",
  measurementId: "G-N1DZJ8S2NL"
};

firebase.initializeApp(firebaseConfig);

// Get Firebase Messaging instance
const messaging = firebase.messaging();

// Handle background message
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'EduVision Notification';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.type || 'general',
    data: payload.data,
    actions: []
  };

  // Add action buttons based on notification type
  const notificationType = payload.data?.type;
  if (notificationType === 'slide_generated') {
    notificationOptions.actions.push({
      action: 'view_slide',
      title: 'View Slide'
    });
  } else if (notificationType === 'video_generated') {
    notificationOptions.actions.push({
      action: 'view_video',
      title: 'View Video'
    });
  } else if (notificationType === 'slide_and_video_generated') {
    notificationOptions.actions.push(
      { action: 'view_slide', title: 'View Slide' },
      { action: 'view_video', title: 'View Video' }
    );
  }

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received:', event);

  event.notification.close();

  const notificationData = event.notification.data || {};
  const action = event.action;

  // Handle action button clicks
  let urlToOpen = '/';

  if (action === 'view_slide' && notificationData.slideUrl) {
    urlToOpen = notificationData.slideUrl;
  } else if (action === 'view_video' && notificationData.videoUrl) {
    urlToOpen = notificationData.videoUrl;
  } else {
    // Default click - open main app
    urlToOpen = '/';
  }

  // Open the app/URL
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Try to focus existing window
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Open new window if no existing one
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});

console.log('[firebase-messaging-sw.js] Service worker loaded and ready for FCM');
