importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyCh_5G_mN9-ObQ6P0N5UQjIX_aZKb9YhQA",
  appId: "1:103223415683:web:ab313581351da759c29cb6",
  messagingSenderId: "103223415683",
  projectId: "aferconpay1",
  authDomain: "aferconpay1.firebaseapp.com",
  storageBucket: "aferconpay1.firebasestorage.app",
  measurementId: "G-NL8QGTR895",
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();
