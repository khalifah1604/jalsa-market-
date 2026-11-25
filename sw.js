const CACHE_NAME = 'jalsa-market-v5';
const APP_SHELL = [
  './',
  './index.html',
  './jalsa%20logo.png',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './manifest.webmanifest'
];

self.addEventListener('install', event => {
  // Add entries individually so one missing file can't fail the whole install.
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => Promise.allSettled(APP_SHELL.map(url => cache.add(url))))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;
  // Only handle same-origin assets. Never cache Supabase API/auth/storage calls.
  if (new URL(req.url).origin !== self.location.origin) return;
  event.respondWith(
    fetch(req).then(response => {
      if (response && response.ok) {
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(req, copy)).catch(() => {});
      }
      return response;
    }).catch(() =>
      caches.match(req).then(cached =>
        cached || (req.mode === 'navigate' ? caches.match('./index.html') : undefined)
      )
    )
  );
});
