var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// .wrangler/tmp/bundle-BtiXM2/checked-fetch.js
var require_checked_fetch = __commonJS({
  ".wrangler/tmp/bundle-BtiXM2/checked-fetch.js"() {
    var urls = /* @__PURE__ */ new Set();
    function checkURL(request, init) {
      const url = request instanceof URL ? request : new URL(
        (typeof request === "string" ? new Request(request, init) : request).url
      );
      if (url.port && url.port !== "443" && url.protocol === "https:") {
        if (!urls.has(url.toString())) {
          urls.add(url.toString());
          console.warn(
            `WARNING: known issue with \`fetch()\` requests to custom HTTPS ports in published Workers:
 - ${url.toString()} - the custom port will be ignored when the Worker is published using the \`wrangler deploy\` command.
`
          );
        }
      }
    }
    __name(checkURL, "checkURL");
    globalThis.fetch = new Proxy(globalThis.fetch, {
      apply(target, thisArg, argArray) {
        const [request, init] = argArray;
        checkURL(request, init);
        return Reflect.apply(target, thisArg, argArray);
      }
    });
  }
});

// .wrangler/tmp/bundle-BtiXM2/middleware-loader.entry.ts
var import_checked_fetch6 = __toESM(require_checked_fetch());

// .wrangler/tmp/bundle-BtiXM2/middleware-insertion-facade.js
var import_checked_fetch4 = __toESM(require_checked_fetch());

// src/index.js
var import_checked_fetch = __toESM(require_checked_fetch());
var CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};
function cosineSimilarity(a, b) {
  if (a.length !== b.length) return 0;
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}
__name(cosineSimilarity, "cosineSimilarity");
function randomId() {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
}
__name(randomId, "randomId");
var src_default = {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS });
    }
    if (url.pathname === "/api/store" && request.method === "POST") {
      try {
        const body = await request.json();
        const { vector, score: score2, label: label2, grade } = body;
        if (!vector || !Array.isArray(vector)) {
          return new Response(JSON.stringify({ error: "invalid vector" }), { status: 400, headers: CORS });
        }
        const userId = randomId();
        const entry = { userId, vector, score: score2, label: label2, grade, ts: Date.now() };
        await env.DESPAIR_KV.put(`user:${userId}`, JSON.stringify(entry), { expirationTtl: 2592e3 });
        let indexRaw = await env.DESPAIR_KV.get("_index");
        let index = indexRaw ? JSON.parse(indexRaw) : [];
        index.push(userId);
        if (index.length > 1e3) index = index.slice(-1e3);
        await env.DESPAIR_KV.put("_index", JSON.stringify(index));
        return new Response(JSON.stringify({ userId }), {
          headers: { "Content-Type": "application/json", ...CORS }
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: CORS });
      }
    }
    if (url.pathname === "/api/match" && request.method === "GET") {
      try {
        const targetId = url.searchParams.get("userId");
        if (!targetId) {
          return new Response(JSON.stringify({ error: "userId required" }), { status: 400, headers: CORS });
        }
        const targetRaw = await env.DESPAIR_KV.get(`user:${targetId}`);
        if (!targetRaw) {
          return new Response(JSON.stringify({ error: "user not found" }), { status: 404, headers: CORS });
        }
        const target = JSON.parse(targetRaw);
        const indexRaw = await env.DESPAIR_KV.get("_index");
        if (!indexRaw) {
          return new Response(JSON.stringify({ matches: [] }), {
            headers: { "Content-Type": "application/json", ...CORS }
          });
        }
        const index = JSON.parse(indexRaw);
        const allEntries = await Promise.all(
          index.filter((id) => id !== targetId).slice(-200).map(async (id) => {
            const raw = await env.DESPAIR_KV.get(`user:${id}`);
            return raw ? JSON.parse(raw) : null;
          })
        );
        const scored = allEntries.filter(Boolean).map((entry) => ({
          userId: entry.userId,
          score: entry.score,
          label: entry.label,
          grade: entry.grade,
          syncRate: Math.round(cosineSimilarity(target.vector, entry.vector) * 100)
        })).filter((e) => e.syncRate >= 60).sort((a, b) => b.syncRate - a.syncRate).slice(0, 5);
        return new Response(JSON.stringify({ matches: scored }), {
          headers: { "Content-Type": "application/json", ...CORS }
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: CORS });
      }
    }
    const score = url.searchParams.get("score") || "50";
    const label = url.searchParams.get("label") || "ANALYZING...";
    const color = parseInt(score) > 70 ? "'#00FF00'" : parseInt(score) < 30 ? "'#FF0000'" : "'#FFD700'";
    const chartConfig = {
      type: "radialGauge",
      data: { datasets: [{ data: [score], backgroundColor: color }] },
      options: {
        trackColor: "#1A1A1A",
        centerPercentage: 80,
        roundedCorners: false,
        centerArea: { text: `${score}%`, fontColor: "#FFFFFF", fontSize: 60 }
      }
    };
    const encodedChart = encodeURIComponent(JSON.stringify(chartConfig));
    const imageUrl = `https://quickchart.io/chart?w=1200&h=630&bkg=0A0A0A&c=${encodedChart}`;
    const html = `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>\u3010\u604B\u611B\u8A3A\u65ADAI\u541B\u3011SYSTEM_DIAGNOSTIC: ${score}%</title>
  <meta property="og:title" content="\u8A3A\u65AD\u7D50\u679C: ${decodeURIComponent(label)} (${score}%)">
  <meta property="og:description" content="Columbia\u5927\u5B66Speed Dating\u5B9F\u9A13\u30C7\u30FC\u30BF\xD7ML\u30E2\u30C7\u30EB\u306B\u3088\u308B\u604B\u611B\u8A3A\u65AD\u3002\u3042\u306A\u305F\u3082\u8A3A\u65AD\u3057\u3066\u307F\u3066\uFF01">
  <meta property="og:image" content="${imageUrl}">
  <meta property="og:url" content="${url.href}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="\u8A3A\u65AD\u7D50\u679C: ${decodeURIComponent(label)} (${score}%)">
  <meta name="twitter:image" content="${imageUrl}">
  <style>
    body { background:#050505; color:#00FFFF; font-family:monospace; display:flex; flex-direction:column; align-items:center; justify-content:center; min-height:100vh; margin:0; padding:20px; box-sizing:border-box; }
    h1 { font-size:2.5rem; text-shadow:0 0 10px #00FFFF; }
    img { max-width:600px; width:100%; border:1px solid #333; margin:20px 0; }
    a { color:#FF00FF; text-decoration:none; border:1px solid #FF00FF; padding:12px 24px; margin-top:10px; }
  </style>
</head>
<body>
  <h1>SYSTEM_DIAGNOSTIC: ${score}%</h1>
  <p style="color:#fff">LABEL: ${decodeURIComponent(label)}</p>
  <img src="${imageUrl}" alt="\u8A3A\u65AD\u7D50\u679C\u30B0\u30E9\u30D5">
  <a href="https://your-app-url.pages.dev">\u25B6 \u81EA\u5206\u3082\u8A3A\u65AD\u3059\u308B</a>
</body>
</html>`;
    return new Response(html, { headers: { "content-type": "text/html;charset=UTF-8" } });
  }
};

// ../../../../Users/hatake/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/middleware-ensure-req-body-drained.ts
var import_checked_fetch2 = __toESM(require_checked_fetch());
var drainBody = /* @__PURE__ */ __name(async (request, env, _ctx, middlewareCtx) => {
  try {
    return await middlewareCtx.next(request, env);
  } finally {
    try {
      if (request.body !== null && !request.bodyUsed) {
        const reader = request.body.getReader();
        while (!(await reader.read()).done) {
        }
      }
    } catch (e) {
      console.error("Failed to drain the unused request body.", e);
    }
  }
}, "drainBody");
var middleware_ensure_req_body_drained_default = drainBody;

// ../../../../Users/hatake/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/middleware-miniflare3-json-error.ts
var import_checked_fetch3 = __toESM(require_checked_fetch());
function reduceError(e) {
  return {
    name: e?.name,
    message: e?.message ?? String(e),
    stack: e?.stack,
    cause: e?.cause === void 0 ? void 0 : reduceError(e.cause)
  };
}
__name(reduceError, "reduceError");
var jsonError = /* @__PURE__ */ __name(async (request, env, _ctx, middlewareCtx) => {
  try {
    return await middlewareCtx.next(request, env);
  } catch (e) {
    const error = reduceError(e);
    return Response.json(error, {
      status: 500,
      headers: { "MF-Experimental-Error-Stack": "true" }
    });
  }
}, "jsonError");
var middleware_miniflare3_json_error_default = jsonError;

// .wrangler/tmp/bundle-BtiXM2/middleware-insertion-facade.js
var __INTERNAL_WRANGLER_MIDDLEWARE__ = [
  middleware_ensure_req_body_drained_default,
  middleware_miniflare3_json_error_default
];
var middleware_insertion_facade_default = src_default;

// ../../../../Users/hatake/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/common.ts
var import_checked_fetch5 = __toESM(require_checked_fetch());
var __facade_middleware__ = [];
function __facade_register__(...args) {
  __facade_middleware__.push(...args.flat());
}
__name(__facade_register__, "__facade_register__");
function __facade_invokeChain__(request, env, ctx, dispatch, middlewareChain) {
  const [head, ...tail] = middlewareChain;
  const middlewareCtx = {
    dispatch,
    next(newRequest, newEnv) {
      return __facade_invokeChain__(newRequest, newEnv, ctx, dispatch, tail);
    }
  };
  return head(request, env, ctx, middlewareCtx);
}
__name(__facade_invokeChain__, "__facade_invokeChain__");
function __facade_invoke__(request, env, ctx, dispatch, finalMiddleware) {
  return __facade_invokeChain__(request, env, ctx, dispatch, [
    ...__facade_middleware__,
    finalMiddleware
  ]);
}
__name(__facade_invoke__, "__facade_invoke__");

// .wrangler/tmp/bundle-BtiXM2/middleware-loader.entry.ts
var __Facade_ScheduledController__ = class ___Facade_ScheduledController__ {
  constructor(scheduledTime, cron, noRetry) {
    this.scheduledTime = scheduledTime;
    this.cron = cron;
    this.#noRetry = noRetry;
  }
  static {
    __name(this, "__Facade_ScheduledController__");
  }
  #noRetry;
  noRetry() {
    if (!(this instanceof ___Facade_ScheduledController__)) {
      throw new TypeError("Illegal invocation");
    }
    this.#noRetry();
  }
};
function wrapExportedHandler(worker) {
  if (__INTERNAL_WRANGLER_MIDDLEWARE__ === void 0 || __INTERNAL_WRANGLER_MIDDLEWARE__.length === 0) {
    return worker;
  }
  for (const middleware of __INTERNAL_WRANGLER_MIDDLEWARE__) {
    __facade_register__(middleware);
  }
  const fetchDispatcher = /* @__PURE__ */ __name(function(request, env, ctx) {
    if (worker.fetch === void 0) {
      throw new Error("Handler does not export a fetch() function.");
    }
    return worker.fetch(request, env, ctx);
  }, "fetchDispatcher");
  return {
    ...worker,
    fetch(request, env, ctx) {
      const dispatcher = /* @__PURE__ */ __name(function(type, init) {
        if (type === "scheduled" && worker.scheduled !== void 0) {
          const controller = new __Facade_ScheduledController__(
            Date.now(),
            init.cron ?? "",
            () => {
            }
          );
          return worker.scheduled(controller, env, ctx);
        }
      }, "dispatcher");
      return __facade_invoke__(request, env, ctx, dispatcher, fetchDispatcher);
    }
  };
}
__name(wrapExportedHandler, "wrapExportedHandler");
function wrapWorkerEntrypoint(klass) {
  if (__INTERNAL_WRANGLER_MIDDLEWARE__ === void 0 || __INTERNAL_WRANGLER_MIDDLEWARE__.length === 0) {
    return klass;
  }
  for (const middleware of __INTERNAL_WRANGLER_MIDDLEWARE__) {
    __facade_register__(middleware);
  }
  return class extends klass {
    #fetchDispatcher = /* @__PURE__ */ __name((request, env, ctx) => {
      this.env = env;
      this.ctx = ctx;
      if (super.fetch === void 0) {
        throw new Error("Entrypoint class does not define a fetch() function.");
      }
      return super.fetch(request);
    }, "#fetchDispatcher");
    #dispatcher = /* @__PURE__ */ __name((type, init) => {
      if (type === "scheduled" && super.scheduled !== void 0) {
        const controller = new __Facade_ScheduledController__(
          Date.now(),
          init.cron ?? "",
          () => {
          }
        );
        return super.scheduled(controller);
      }
    }, "#dispatcher");
    fetch(request) {
      return __facade_invoke__(
        request,
        this.env,
        this.ctx,
        this.#dispatcher,
        this.#fetchDispatcher
      );
    }
  };
}
__name(wrapWorkerEntrypoint, "wrapWorkerEntrypoint");
var WRAPPED_ENTRY;
if (typeof middleware_insertion_facade_default === "object") {
  WRAPPED_ENTRY = wrapExportedHandler(middleware_insertion_facade_default);
} else if (typeof middleware_insertion_facade_default === "function") {
  WRAPPED_ENTRY = wrapWorkerEntrypoint(middleware_insertion_facade_default);
}
var middleware_loader_entry_default = WRAPPED_ENTRY;
export {
  __INTERNAL_WRANGLER_MIDDLEWARE__,
  middleware_loader_entry_default as default
};
//# sourceMappingURL=index.js.map
