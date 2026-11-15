/* app.js: reads the URL, restores state, renders the workbench shell. */
(function () {
"use strict";
var W = window.W, html = W.html;
var root = document.documentElement;

function fail(msg) { root.dataset.error = String(msg); }
window.onerror = function (msg) { fail(msg); };
window.addEventListener("unhandledrejection", function (e) {
  fail((e && e.reason && e.reason.message) || (e && e.reason) || "unhandled rejection");
});

var query;
try { query = new URLSearchParams(window.location.search); } catch (e) { query = new URLSearchParams(""); }

/* test hook: prove the app survives junk in storage */
if (query.get("junk") === "1") {
  try {
    [W.KEYS.eng, W.KEYS.ui, W.KEYS.comments].forEach(function (k) { window.localStorage.setItem(k, "{"); });
  } catch (e) { /* no storage */ }
}

var ui = W.cleanUi(W.LS.get(W.KEYS.ui, null));
var fromUrl = W.readUrl();
Object.keys(fromUrl).forEach(function (k) { ui[k] = fromUrl[k]; });
W.init(W.LS.get(W.KEYS.eng, {}), ui);

function Shell() {
  W.useApp();
  return html`<div class="wb-shell">
    <div class="wb-top" data-id="topbar" dir="ltr"><span class="wb-title" data-id="wb-title">Dhikr workbench</span></div>
    <div class="wb-stage" data-id="stage"></div>
  </div>`;
}

window.ReactDOM.createRoot(document.getElementById("root")).render(html`<${Shell} />`);
setTimeout(function () { root.dataset.ready = "1"; }, 0);
W.ping();
})();
