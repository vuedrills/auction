// Scripts for firebase messaging service worker

self.addEventListener('install', function (event) {
    console.log('Firebase messaging service worker installed');
});

self.addEventListener('activate', function (event) {
    console.log('Firebase messaging service worker activated');
});
