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
/* a day named in the URL always loads fresh; otherwise the saved state carries on */
if ("day" in fromUrl || !(W.S.state.eng.prefs && ui.now)) {
  W.setDay(ui.day, { keepRoute: "route" in fromUrl || !("day" in fromUrl), keepPopup: true });
}

/* the look, theme and text size live on <html> so tokens.css can answer them */
function applyLook(u) {
  root.dataset.look = u.look;
  root.dataset.theme = u.theme;
  root.dataset.size = String(u.size);
}
applyLook(ui);

function Shell() {
  var u = W.useApp().ui;
  applyLook(u);
  return html`<div class="wb-shell">
    <div class="wb-top" data-id="topbar" dir="ltr" data-cmt-ui="1"><span class="wb-title" data-id="wb-title">Dhikr workbench</span><${W.WbMenu} /></div>
    <div class="wb-stage" data-id="stage">${u.route === "gallery" ? html`<${W.Gallery} />`
      : u.frame === "windows" ? html`<${W.WindowsFrame}><${W.Screen} /><//>`
      : html`<${W.PhoneFrame}><${W.Screen} /><//>`}</div>
  </div>`;
}

window.ReactDOM.createRoot(document.getElementById("root")).render(html`<${Shell} />`);
setTimeout(function () { root.dataset.ready = "1"; }, 0);
W.ping();
})();
