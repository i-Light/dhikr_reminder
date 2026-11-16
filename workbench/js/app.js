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

/* test hook: rest every dhikr so Today opens in its empty state */
if (query.get("restAll") === "1" && W.S.state.eng && W.S.state.eng.adhkar) {
  W.S.state.eng.adhkar.forEach(function (a) { W.S.state.eng = W.E.rest(W.S.state.eng, a.id, true); });
}

/* the look, theme and text size live on <html> so tokens.css can answer them */
function applyLook(u) {
  root.dataset.look = u.look;
  root.dataset.theme = u.theme;
  root.dataset.size = String(u.size);
}
applyLook(ui);

/* a popup named in the URL (or left open before a reload) needs its card: ask the engine for one */
if (ui.popup && ui.popup !== "moment") {
  var showing = W.S.state.eng.day && W.S.state.eng.day.showing;
  if (!showing && !W.showReminder(ui.popup)) ui.popup = null;
}

/* test hook: open the simulator, run forward to simTo, and optionally drag backward to simBack */
var simPerson = query.get("sim");
if (simPerson) {
  W.simOpen(simPerson);
  if (query.get("simTo")) W.simSeekClock(query.get("simTo"));
  if (query.get("simBack")) W.simSeekClock(query.get("simBack"));
} else if (ui.panel === "sim" && W.S.state.eng && W.S.state.eng.prefs) {
  W.simOpen();
}

/* test hook: one saved comment pinned to the part with this data-id, on the today screen of the current day */
var seed = query.get("seedComment");
if (seed) {
  W.CM.list = [{ id: "cseed", at: 1, status: "open", doneAt: null, kind: "fix", text: "Seeded comment",
    place: { frame: ui.frame, day: ui.day, lang: ui.lang, route: "today", popup: null },
    anchor: { label: "Seeded", dataId: seed, own: true, tag: "div", path: null, text: "", fx: 0.5, fy: 0.5 } }];
}

function Shell() {
  var u = W.useApp().ui;
  applyLook(u);
  return html`<div class="wb-shell">
    <div class="wb-top" data-id="topbar" dir="ltr" data-cmt-ui="1"><span class="wb-title" data-id="wb-title">Dhikr workbench</span><${W.WbMenu} /></div>
    <div class="wb-stage" data-id="stage">${u.route === "gallery" ? html`<${W.Gallery} />`
      : u.frame === "windows" ? html`<${W.WindowsFrame}><${W.Screen} /><//>`
      : html`<${W.PhoneFrame}><${W.Screen} /><//>`}</div>
    <${W.SimPanel} />
    <${W.CommentLayer} />
  </div>`;
}

window.ReactDOM.createRoot(document.getElementById("root")).render(html`<${Shell} />`);
setTimeout(function () { root.dataset.ready = "1"; }, 0);
W.ping().then(function (ok) { if (ok) W.commentsSync(); });
})();

/* test hook: go through the real comment flow once (comment mode, click the part, type, save) */
(function () {
  var W = window.W, q;
  try { q = new URLSearchParams(window.location.search); } catch (e) { return; }
  var auto = q.get("autoComment");
  if (!auto) return;
  function later(ms, fn) { setTimeout(fn, ms); }
  later(150, function () {
    W.toggleCommentMode(true);
    later(150, function () {
      var el = document.querySelector('[data-id="' + auto + '"]');
      if (!el) return;
      var r = el.getBoundingClientRect();
      el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, clientX: r.left + r.width / 2, clientY: r.top + r.height / 2 }));
      later(150, function () {
        var ta = document.querySelector(".cmt-ta");
        if (!ta) return;
        Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, "value").set.call(ta, "auto");
        ta.dispatchEvent(new Event("input", { bubbles: true }));
        later(100, function () {
          ta.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", ctrlKey: true, bubbles: true }));
          later(100, function () { W.toggleCommentMode(false); });
        });
      });
    });
  });
})();

/* test hook: tap the card on show, once or until its piece is finished */
(function () {
  var W = window.W, q;
  try { q = new URLSearchParams(window.location.search); } catch (e) { return; }
  var n = q.get("autoTap");
  if (!n) return;
  setTimeout(function () {
    var card = W.S.state.eng.day && W.S.state.eng.day.showing;
    var times = n === "all" ? (card ? card.piece - card.done : 0) : Number(n) || 0;
    for (var i = 0; i < times; i++) W.cardTap();
  }, 200);
})();

/* test hook: click parts one after another, by data-id: autoClick=a,b,c */
(function () {
  var q;
  try { q = new URLSearchParams(window.location.search); } catch (e) { return; }
  var list = (q.get("autoClick") || "").split(",").filter(Boolean);
  function step(i) {
    if (i >= list.length) return;
    var el = document.querySelector('[data-id="' + list[i] + '"]');
    if (el) el.click();
    setTimeout(function () { step(i + 1); }, 300);
  }
  if (list.length) setTimeout(function () { step(0); }, 250);
})();
