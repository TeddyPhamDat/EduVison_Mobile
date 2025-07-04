// FCM Debug Script - Run this in browser console (F12)

console.log('🔧 Starting FCM Debug...');

// 1. Check notification permission
console.log('🔔 Notification Permission:', Notification.permission);
if (Notification.permission !== 'granted') {
    console.log('❌ Notification permission not granted. Requesting...');
    Notification.requestPermission().then(permission => {
        console.log('🔔 Permission result:', permission);
    });
}

// 2. Check service worker registration
navigator.serviceWorker.getRegistrations().then(registrations => {
    console.log('🛠️ Service Worker Registrations:', registrations);
    registrations.forEach((registration, index) => {
        console.log(`SW ${index}:`, registration.scope, registration.active?.state);
    });
});

// 3. Check Firebase initialization
console.log('🔥 Checking Firebase...');
try {
    // This will be available if Firebase is loaded
    if (typeof firebase !== 'undefined') {
        console.log('✅ Firebase loaded');
        if (firebase.apps.length > 0) {
            console.log('✅ Firebase app initialized:', firebase.apps[0].name);
        } else {
            console.log('❌ No Firebase apps initialized');
        }
    } else {
        console.log('❌ Firebase not loaded');
    }
} catch (e) {
    console.log('❌ Firebase check error:', e);
}

// 4. Check FCM token in localStorage
const fcmToken = localStorage.getItem('fcm_token');
console.log('🎫 FCM Token in localStorage:', fcmToken ? `${fcmToken.substring(0, 20)}...` : 'null');

// 5. Check auth token
const authToken = localStorage.getItem('auth_token');
console.log('🔐 Auth Token:', authToken ? 'Present' : 'null');

// 6. Manual FCM token test
console.log('🧪 Attempting manual FCM token generation...');

// Simple test to get FCM token manually
async function testFCMToken() {
    try {
        // Import Firebase dynamically
        const { initializeApp } = await import('https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js');
        const { getMessaging, getToken } = await import('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging.js');

        const firebaseConfig = {
            apiKey: "AIzaSyBqJM9XwpufcO-fH0w9VpUjsEZ8Bh2Hytk",
            authDomain: "eduvision-f2eca.firebaseapp.com",
            projectId: "eduvision-f2eca",
            storageBucket: "eduvision-f2eca.firebasestorage.app",
            messagingSenderId: "987583522827",
            appId: "1:987583522827:web:a9c31b5b0b3e8c8a83c5f8"
        };

        const app = initializeApp(firebaseConfig, 'test-app');
        const messaging = getMessaging(app);

        const token = await getToken(messaging, {
            vapidKey: "BFGAKHarGR4K36qci9LD5nEUe4RUKrEKiyl6EUF5fWf2g6n6jwTYUh0WTiM0tL6Og8OmfoErnk5lBz1jpGjhooo"
        });

        console.log('✅ Manual FCM Token generated:', token.substring(0, 50) + '...');
        return token;
    } catch (error) {
        console.log('❌ Manual FCM Token generation failed:', error);
        return null;
    }
}

// Run the test
testFCMToken();

console.log('🔧 FCM Debug complete. Check results above.');
