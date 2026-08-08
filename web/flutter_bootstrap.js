{{flutter_build_config}}
{{flutter_js}}

(async () => {
  if ("serviceWorker" in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }
  if ("caches" in window) {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
  }

  for (const build of _flutter.buildConfig.builds) {
    if (build.mainJsPath) {
      build.mainJsPath = build.mainJsPath + "?v=0.2.0";
    }
  }

  await _flutter.loader.load({
    config: {
      canvasKitBaseUrl: "canvaskit/",
      fontFallbackBaseUrl: "assets/assets/fonts/fallback/",
    },
  });
})();