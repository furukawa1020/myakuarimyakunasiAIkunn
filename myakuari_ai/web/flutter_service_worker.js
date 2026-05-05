'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "408874def34ffb06568ac39f5841018b",
"assets/AssetManifest.bin.json": "fce266f9bf391505bfc8a80c8504224a",
"assets/assets/audio/home_1.wav": "a918902dbb5f56dbde68800885d31bf0",
"assets/assets/audio/home_2.wav": "69762159b3c8ceaf389fe25894145842",
"assets/assets/audio/home_3.wav": "f2ea23dd63ec5a8b101f56607216b8ca",
"assets/assets/audio/loading.wav": "fbef5633faf4b4d283bd93db9c414359",
"assets/assets/audio/loading_1.wav": "fbef5633faf4b4d283bd93db9c414359",
"assets/assets/audio/loading_2.wav": "8de347f93512de4255278c51cb46691c",
"assets/assets/audio/loading_3.wav": "d596c7339a35ea920c96d4743ded9cf2",
"assets/assets/audio/loading_4.wav": "3a9b5dd53dc0cc5171feb5350537f56e",
"assets/assets/audio/q_how.wav": "eec6b92ebae509e4045d312278e7a3f2",
"assets/assets/audio/q_how_1.wav": "eec6b92ebae509e4045d312278e7a3f2",
"assets/assets/audio/q_how_2.wav": "758c9db1bb51ea1d7d7c9e0703a96c51",
"assets/assets/audio/q_how_3.wav": "064ca86a35af2ae5e48a28452183d587",
"assets/assets/audio/q_what.wav": "fe4c0226e6ad5b7adf45eb065042343f",
"assets/assets/audio/q_what_1.wav": "fe4c0226e6ad5b7adf45eb065042343f",
"assets/assets/audio/q_what_2.wav": "bd48faf80d842b1058324927d935186f",
"assets/assets/audio/q_what_3.wav": "f90f006b80bc962f5757435963889c54",
"assets/assets/audio/q_when.wav": "495573aa5c48048edad5d897cf9f0c06",
"assets/assets/audio/q_when_1.wav": "495573aa5c48048edad5d897cf9f0c06",
"assets/assets/audio/q_when_2.wav": "97082d63d789b22ec8c4f8d91baf0100",
"assets/assets/audio/q_when_3.wav": "5e1ee514096738d9b03280ffcfe666f3",
"assets/assets/audio/q_where.wav": "9485dc4e095297e20acca68b81d5576c",
"assets/assets/audio/q_where_1.wav": "9485dc4e095297e20acca68b81d5576c",
"assets/assets/audio/q_where_2.wav": "6f1d57229af81e6f519c9f31db1a0d28",
"assets/assets/audio/q_where_3.wav": "a766f0718fbc5f3258313913d1f644ee",
"assets/assets/audio/q_who.wav": "f5bde5a81c35ed31949ce1bb1b3569ee",
"assets/assets/audio/q_who_1.wav": "f5bde5a81c35ed31949ce1bb1b3569ee",
"assets/assets/audio/q_who_2.wav": "620266d18570beb6208250f697c5e8e8",
"assets/assets/audio/q_who_3.wav": "39251fc01f5b1ff6b0d6ab0daf29b4de",
"assets/assets/audio/q_why.wav": "0343557f614afbd160277f2d7bd6386f",
"assets/assets/audio/q_why_1.wav": "0343557f614afbd160277f2d7bd6386f",
"assets/assets/audio/q_why_2.wav": "2907aa32c24eb3dcec0b50c822c75da1",
"assets/assets/audio/q_why_3.wav": "d154f61a879e889a0e1eab80a37968a8",
"assets/assets/audio/result_bad.wav": "1e50a5cff4687302e6784290f46deab1",
"assets/assets/audio/result_bad_1.wav": "1e50a5cff4687302e6784290f46deab1",
"assets/assets/audio/result_bad_2.wav": "729b3a305d0edeede5304ab2dea62025",
"assets/assets/audio/result_bad_3.wav": "04b0a1c81cca24ca5c38d9bd998392b1",
"assets/assets/audio/result_good.wav": "a5f80ba8c7f41c5bacf9bd1ad0418f8a",
"assets/assets/audio/result_good_1.wav": "a5f80ba8c7f41c5bacf9bd1ad0418f8a",
"assets/assets/audio/result_good_2.wav": "29b022c9f363db8c587bc1edf23f16d1",
"assets/assets/audio/result_good_3.wav": "dee77284920b7d435a9f0f199952fe7f",
"assets/assets/audio/result_good_4.wav": "dfa7a6c5eceb0a91a95325737cf5ffa4",
"assets/assets/audio/result_neutral.wav": "31d0c00c083e4dc257d34250a8bdd865",
"assets/assets/audio/result_neutral_1.wav": "31d0c00c083e4dc257d34250a8bdd865",
"assets/assets/audio/result_neutral_2.wav": "35aabe4ca7c9343ca61edbc637ce0e69",
"assets/assets/audio/result_neutral_3.wav": "1ba8fcc24adb65214e81ad6ebf355f29",
"assets/assets/audio/thanks_1.wav": "af5e4ad29cb7ed206803175551e712e3",
"assets/assets/audio/thanks_2.wav": "ec90bacc532f2c49eb3e4dd2cbf6da45",
"assets/assets/audio/thanks_3.wav": "d464f2ca995dce722afd49f3f49be6ae",
"assets/assets/images/app_icon.png": "19462d6119d24cd7d3a98ff972f58b74",
"assets/assets/images/char/char_0.png": "c262fd063134ae69d248ed6b5980196b",
"assets/assets/images/char/char_1.png": "a1d3b03f69f639b0ddb40204f21bbcd6",
"assets/assets/images/char/char_10.png": "abec84abc166dbeb87cecc0a14299dcb",
"assets/assets/images/char/char_11.png": "98147439083bf829a7b54d270dc47513",
"assets/assets/images/char/char_2.png": "2f2f6de5c1d0f60f995eb1d85f46edf1",
"assets/assets/images/char/char_3.png": "69b8c0964f56058dab6a4971fc3d2bce",
"assets/assets/images/char/char_4.png": "b8b9955ff70462c111afe877e0409e03",
"assets/assets/images/char/char_5.png": "7a18e2301fab2b471b74ee54f54f392f",
"assets/assets/images/char/char_6.png": "4d925acf22bf6e5d7e5898fcdb26263c",
"assets/assets/images/char/char_7.png": "487bfd0244f2f91b7bdf407bedb3581b",
"assets/assets/images/char/char_8.png": "e4ef001948c00d4e5222d87de2733a29",
"assets/assets/images/char/char_9.png": "dc6ce5cdbd82b91ba6277edf0dab420e",
"assets/assets/images/zundamon_base.png": "8884f5dfa3016725af5c0f72e1f38cba",
"assets/assets/ml/deep_ml_metadata.json": "773d040de6239bfdf9b018c471e33d21",
"assets/assets/ml/feature_metadata.json": "c244aa6d987040f58eae98b9d446ace7",
"assets/assets/ml/inference_logic.rb": "5532a934bad2c89873b8b5fc77c69464",
"assets/assets/ml/true_stats_weights.json": "7224b696ac91d9e1f5d1ef080093673d",
"assets/assets/voicevox/zundamon.vvm": "7c933a72ce96b21fbf0a3157b864fb63",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "371a1773f7f523fbbe4267fa0e2fa680",
"assets/NOTICES": "bc451d6c6866b9e912d81997247755b1",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "aa127f5072c8b61afc4e76edb8e34723",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "71dc29d251ef20b3e9241f3845c5c4e1",
"/": "71dc29d251ef20b3e9241f3845c5c4e1",
"main.dart.js": "8f671465baa5972b4712dd823f0969bc",
"manifest.json": "a5ec5d0364b288fc33df6ff6af2900da",
"version.json": "d82c894677603955f5961037dace9674"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
