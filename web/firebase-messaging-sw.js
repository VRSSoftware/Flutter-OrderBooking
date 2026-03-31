importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD-i-lNZdCPdJPkNEGHiN7oz362I997-04",
  authDomain: "testnotificationapp-aebb2.firebaseapp.com",
  projectId: "testnotificationapp-aebb2",
  storageBucket: "testnotificationapp-aebb2.firebasestorage.app",
  messagingSenderId: "904453695362",
  appId: "1:904453695362:web:941918098023c107f1519b"
});

const messaging = firebase.messaging();