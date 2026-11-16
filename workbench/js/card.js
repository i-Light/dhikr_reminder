/* card.js: the dhikr card in three sizes, and the reminder that arrives on the phone.
   small: a card over whatever the person is doing; a tap on the card counts one.
   full: the whole screen; a tap anywhere counts one.
   page: the same card inside the app (count now, a session), with Back and, in a session, Previous and Next. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

var LONG_WORDS = 14;   /* a dhikr longer than this cannot fit the small card, so it opens full */

W.lib = function (id) { return W.LIB.filter(function (x) { return x.id === id; })[0] || null; };
W.cardSizeFor = function (id, want) {
  var it = W.lib(id);
  return want === "small" && it && it.words > LONG_WORDS ? "full" : want;
};

/* the dhikr itself: always in Arabic, with how it sounds under it when the app is in English */
W.DhikrText = function DhikrText(p) {
  var it = W.lib(p.id), en = W.U().lang === "en";
  return html`<div class="card-text" data-id=${p.dataId || "card-text"}>
    <p class="dhikr" dir="rtl" lang="ar">${it ? it.ar : ""}</p>
    ${en && it && it.translit ? html`<p class="card-translit" dir="ltr" lang="en">${it.translit}</p>` : null}
  </div>`;
};

function stop(fn) { return function (e) { if (e && e.stopPropagation) e.stopPropagation(); if (fn) fn(); }; }

W.Card = function Card(p) {
  var size = W.cardSizeFor(p.id, p.size || "small");
  var piece = Math.max(1, p.piece || 1), done = W.clamp(p.done || 0, 0, piece), fin = done >= piece;
  var tap = fin ? null : p.onTap;
  function key(e) { if (tap && (e.key === " " || e.key === "Enter")) { e.preventDefault(); tap(); } }
  var count = html`<span class="card-count num" data-id="card-count" data-done=${done} data-piece=${piece}>
    <span class="card-count-n m-count" key=${done}>${done}</span><span class="card-count-of">${W.t("card.of", { n: piece })}</span>
  </span>`;
  var day = p.extra ? W.t("card.extra", { n: p.dayDone || 0 })
    : p.dayTarget ? W.t("card.day", { done: p.dayDone || 0, target: p.dayTarget }) : null;
  var cls = W.cx("card", "card-" + size, fin && "is-done");

  if (size === "small") {
    return html`<div class=${W.cx(cls, "m-enter")} data-id="card" data-size="small" role="button" tabIndex="0" onClick=${tap} onKeyDown=${key}>
      <${W.DhikrText} id=${p.id} />
      <div class="card-meter">
        <span class=${W.cx("m-ring", fin && "m-piece-done")} key=${fin ? "done" : "go"}><${W.Ring} done=${done} total=${piece} size=${56} /></span>
        ${count}
        ${day ? html`<span class="card-day num" data-id="card-day">${day}</span>` : null}
      </div>
      <p class="card-hint" data-id="card-hint">${fin ? W.t("card.done") : W.t("card.hint.small")}</p>
      <div class="card-actions">
        <${W.Btn} kind="soft" icon="later" label=${W.t("btn.later")} id="card-later" onClick=${stop(p.onLater)} disabled=${fin} />
        <${W.Btn} kind="text" icon="close" label=${W.t("btn.close")} id="card-close" onClick=${stop(p.onClose)} />
      </div>
    </div>`;
  }

  var page = size === "page";
  return html`<div class=${cls} data-id="card" data-size=${size} role="button" tabIndex="0" onClick=${tap} onKeyDown=${key}>
    <div class="card-bar">
      ${page ? html`<${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="card-back" onClick=${stop(p.onClose)} />`
        : html`<${W.Btn} kind="soft" icon="later" label=${W.t("btn.later")} id="card-later" onClick=${stop(p.onLater)} disabled=${fin} />`}
      ${p.title ? html`<span class="card-title num" data-id="card-title">${p.title}</span>` : null}
      ${page ? html`<span class="card-bar-gap"></span>`
        : html`<${W.Btn} kind="text" icon="close" label=${W.t("btn.close")} id="card-close" onClick=${stop(p.onClose)} />`}
    </div>
    <div class="card-body">
      <${W.Ornament} />
      <${W.DhikrText} id=${p.id} />
    </div>
    <div class="card-foot">
      <span class=${W.cx("m-ring", fin && "m-piece-done")} key=${fin ? "done" : "go"}>
        <${W.Ring} done=${done} total=${piece} size=${150} label=${html`<span class="m-count" key=${done}>${done}</span>`} />
      </span>
      ${count}
      <p class="card-hint" data-id="card-hint">${fin ? W.t("card.done") : W.t("card.hint.full")}</p>
      ${day ? html`<p class="card-day num" data-id="card-day">${day}</p>` : null}
      ${page && (p.onBack || p.onForward) ? html`<div class="card-nav">
        <${W.Btn} kind="soft" icon="back" label=${W.t("card.prev")} id="card-prev" onClick=${stop(p.onBack)} disabled=${!p.onBack} />
        <${W.Btn} kind="soft" icon="forward" label=${W.t("card.next")} id="card-next" onClick=${stop(p.onForward)} disabled=${!p.onForward} />
      </div>` : null}
    </div>
  </div>`;
};

/* what a card needs to know about the day, for any dhikr */
W.cardProps = function (eng, card) {
  var a = (eng.adhkar || []).filter(function (x) { return x.id === card.id; })[0];
  var done = (eng.day.done && eng.day.done[card.id]) || 0, extra = (eng.day.extra && eng.day.extra[card.id]) || 0;
  return { id: card.id, piece: card.piece, done: card.done, extra: !!card.extra,
    dayDone: card.extra ? done + extra : done, dayTarget: a ? a.target : 0 };
};

/* ---------- the reminder: show, tap, leave ---------- */
var HOLD_MS = 900, leaveTimer = 0;

function commit() { W.save(); W.emit(); }
W.toast = function (text, undo) { W.U().toast = { text: text, undo: !!undo, stamp: Date.now() }; commit(); };

/* asks the engine what to show now. size: "small" | "full" | "lock"; default is the person's own choice. */
W.showReminder = function (size) {
  var s = W.S.state;
  if (!(s.eng && s.eng.prefs)) return false;
  if (String(s.ui.route || "").indexOf("session/") === 0) return false;
  var r = E.show(E.rollDay(s.eng, W.now()), W.now());
  if (!r.card) return false;
  s.eng = r.state;
  s.ui.popup = size || s.eng.prefs.cardSize || "small";
  commit();
  return true;
};
W.cardTap = function () {
  var s = W.S.state, card = s.eng.day && s.eng.day.showing;
  if (!card || card.done >= card.piece) return;
  s.eng = E.tap(s.eng, W.now(), card.id, 1);
  commit();
  var now = s.eng.day.showing;
  if (now && now.done >= now.piece) {
    clearTimeout(leaveTimer);
    leaveTimer = setTimeout(function () { W.cardLeave("close"); }, HOLD_MS);
  }
};
/* how: "close" | "ignore" | "later". A finished piece is a finish whatever how says. */
W.cardLeave = function (how) {
  clearTimeout(leaveTimer);
  var s = W.S.state;
  if (s.eng.day && s.eng.day.showing) s.eng = E.leave(s.eng, W.now(), how);
  s.ui.popup = null;
  if (how === "later") s.ui.toast = { text: W.t("toast.later"), stamp: Date.now() };
  commit();
};

/* ---------- what sits under and around the card on the phone ---------- */
function OverStatus() {
  return html`<div class="over-status" dir="ltr"><span class="num">${W.clock(W.now())}</span><span class="phone-batt"></span></div>`;
}
function Home() {
  var cells = [];
  for (var i = 0; i < 16; i++) cells.push(html`<i key=${i}></i>`);
  return html`<${W.R.Fragment}><${OverStatus} /><div class="home-grid" aria-hidden="true">${cells}</div><div class="home-shade"></div><//>`;
}
function dateLine() {
  var en = W.U().lang === "en";
  try { return new Date(W.now()).toLocaleDateString(en ? "en-GB" : "ar-EG-u-nu-latn", { weekday: "long", day: "numeric", month: "long" }); }
  catch (e) { return ""; }
}

W.Popup = function Popup() {
  var st = W.useApp(), ui = st.ui, eng = st.eng, pop = ui.popup;
  var toast = ui.toast ? html`<div class="over-toast"><${W.Toast} id="app-toast" text=${ui.toast.text} stamp=${ui.toast.stamp}
    onUndo=${ui.toast.undo ? function () { W.undo(); W.U().toast = null; commit(); } : null}
    onDone=${function () { W.U().toast = null; commit(); }} /></div>` : null;
  if (pop === "moment") return W.MomentCard ? html`<${W.R.Fragment}><${W.MomentCard} />${toast}<//>` : toast;
  var card = eng && eng.day && eng.day.showing;
  if (!pop || !card) return toast;
  var size = pop === "full" ? "full" : W.cardSizeFor(card.id, "small");
  var c = html`<${W.Card} ...${W.cardProps(eng, card)} size=${size} onTap=${W.cardTap}
    onLater=${function () { W.cardLeave("later"); }} onClose=${function () { W.cardLeave("close"); }} />`;
  if (pop === "lock") {
    return html`<div class="over over-lock" data-id="lock"><${OverStatus} />
      <div class="lock-top"><div class="lock-clock num" data-id="lock-clock">${W.clock(W.now())}</div><div class="lock-date" data-id="lock-date">${dateLine()}</div></div>
      <div class=${size === "full" ? "over-fill" : "over-dock"}>${c}</div>
    </div>`;
  }
  if (size === "full") return html`<div class="over over-full" data-id="over-full">${c}</div>`;
  return html`<div class="over over-home" data-id="home"><${Home} /><div class="over-dock">${c}</div></div>`;
};

/* the Workbench menu: bring a reminder now, in the person's size, full or on the lock screen */
W.wbTools.push(function () {
  function show(size) {
    return function () {
      if (W.U().popup) W.cardLeave("ignore");
      if (!W.showReminder(size)) W.wbNote("Nothing to remind about right now (paused, no adhkar, or a moment has just started).");
    };
  }
  return html`<span class="wb-seg" role="group" aria-label="Show a reminder now" data-id="wb-remind">
    <span class="wb-seg-label">Reminder now</span>
    <button type="button" class="wb-seg-btn" data-id="wb-remind-small" onClick=${show("small")}>Small</button>
    <button type="button" class="wb-seg-btn" data-id="wb-remind-full" onClick=${show("full")}>Full</button>
    <button type="button" class="wb-seg-btn" data-id="wb-remind-lock" onClick=${show("lock")}>Lock screen</button>
  </span>`;
});
})();
