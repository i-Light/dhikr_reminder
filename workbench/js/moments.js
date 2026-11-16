/* moments.js: the four daily moments (list, per-moment page with time), the moment popup card, and session/<key>. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

var KEYS = ["waking", "morning", "evening", "sleep"];
var M_ICONS = { waking: "sunrise", morning: "sun", evening: "moon", sleep: "bed" };

function minToHhmm(m) {
  var t = ((Math.round(m) % 1440) + 1440) % 1440;
  var h = Math.floor(t / 60), mn = t % 60;
  return (h < 10 ? "0" : "") + h + ":" + (mn < 10 ? "0" : "") + mn;
}

function estMinutes(key) {
  var items = W.SETS[key] || [], words = 0;
  items.forEach(function (x) {
    var it = W.lib(x.id);
    words += ((it && it.words) || 5) * (x.count || 1);
  });
  return Math.max(1, Math.round(words / 90));
}

function SwitchBtn(p) {
  return html`<button type="button" role="switch" aria-checked=${p.on ? "true" : "false"}
    class=${W.cx("switch-btn", p.on && "is-on")} data-id=${p.id} onClick=${p.onClick}>
    <span class="switch-track"><span class="switch-knob"></span></span>
    <span class="switch-word">${W.t(p.on ? "moments.on" : "moments.off")}</span>
  </button>`;
}

function MomentsList() {
  var eng = E.rollDay(W.useApp().eng, W.now());
  var mt = E.momentTimes(eng.prefs);
  var mp = (eng.prefs && eng.prefs.moments) || {};

  return html`<div class="moments-page" data-id="moments-page">
    <div class="sub-bar">
      <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="moments-back"
        onClick=${function () { W.go("adhkar"); }} />
      <h1 class="title">${W.t("adhkar.moments.title")}</h1>
      <span class="sub-bar-gap"></span>
    </div>

    <div class="adhkar-rows">
      ${KEYS.map(function (k) {
        var on = !(mp[k] && mp[k].on === false);
        var items = W.SETS[k] || [];
        var timeStr = W.timeLabel(minToHhmm(mt[k].start));
        return html`<div key=${k} class=${W.cx("row", "moment-row", !on && "is-done")} data-id=${"moments-row-" + k}>
          <button type="button" class="moment-row-open" data-id=${"moments-open-" + k}
            onClick=${function () { W.go("moments/" + k); }}>
            <span class="row-icon">${W.Icon({ name: M_ICONS[k], size: 28 })}</span>
            <span class="row-main">
              <span class="row-title">${W.t("moment." + k)}</span>
              <span class="row-sub num">${W.t("moments.sub", { time: timeStr, n: items.length })}</span>
            </span>
          </button>
          <span class="row-end">
            <${SwitchBtn} id=${"moment-switch-" + k} on=${on}
              onClick=${function () { W.act("moment", function (s) { s.eng = E.setMoment(s.eng, k, { on: !on }); }); }} />
          </span>
        </div>`;
      })}
    </div>
  </div>`;
}

function MomentDetail(p) {
  var key = KEYS.indexOf(p.mkey) >= 0 ? p.mkey : "morning";
  var st = W.useApp(), eng = E.rollDay(st.eng, W.now()), en = st.ui.lang === "en";
  var mt = E.momentTimes(eng.prefs);
  var mp = (eng.prefs && eng.prefs.moments && eng.prefs.moments[key]) || { on: true, at: null };
  var on = mp.on !== false;
  var hhmm = minToHhmm(mt[key].start);
  var items = W.SETS[key] || [];

  function setTime(v) {
    var m = E.min(v);
    if (m < E.dayStartMin(eng.prefs)) m += 1440;
    W.act("moment-time", function (s) { s.eng = E.setMoment(s.eng, key, { at: m }); });
  }

  return html`<div class="moments-page" data-id="moment-detail">
    <div class="sub-bar">
      <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="moments-back"
        onClick=${function () { W.go("moments"); }} />
      <h1 class="title">${W.t("moment." + key)}</h1>
      <${SwitchBtn} id=${"moment-switch-" + key} on=${on}
        onClick=${function () { W.act("moment", function (s) { s.eng = E.setMoment(s.eng, key, { on: !on }); }); }} />
    </div>

    <${W.TimeStep} id="moment-time" label=${W.t("moments.time")} value=${hhmm} onChange=${setTime} />
    ${mp.at != null ? html`<div class="moment-reset-wrap">
      <${W.Btn} kind="text" icon="undo" label=${W.t("moments.reset")} id="moment-reset"
        onClick=${function () { W.act("moment-reset", function (s) { s.eng = E.setMoment(s.eng, key, { at: null }); }); }} />
    </div>` : null}

    <${W.Btn} kind="main" wide=${true} icon="play" label=${W.t("btn.start")} id="moment-page-start"
      onClick=${function () { W.U().backRoute = "moments/" + key; W.go("session/" + key); }} />

    <section class="today-sec" data-id="moment-items">
      <h2 class="today-sec-title quiet">${W.t("moments.contents")}</h2>
      <div class="adhkar-rows">
        ${items.map(function (entry) {
          var it = W.lib(entry.id);
          var sub = entry.count === 1 ? W.t("add.once") : W.t("moments.item.count", { n: entry.count });
          return html`<div key=${entry.id} class="row" data-id=${"set-item-" + entry.id}>
            <span class="row-main">
              <span class="row-title is-dhikr" dir="rtl" lang="ar">${it ? it.ar : entry.id}</span>
              ${en && it && it.translit ? html`<span class="row-sub" dir="ltr" lang="en">${it.translit}</span>` : null}
              <span class="row-sub num">${sub}</span>
            </span>
          </div>`;
        })}
      </div>
    </section>
  </div>`;
}

W.MomentCard = function MomentCard() {
  var st = W.useApp(), ui = st.ui;
  if (!(st.eng && st.eng.prefs)) return null;
  var eng = E.rollDay(st.eng, W.now());
  var ms = E.momentState(eng, W.now());
  var key = (ui.momentKey && W.SETS[ui.momentKey]) ? ui.momentKey
    : KEYS.filter(function (k) { return ms[k] === "waiting" || ms[k] === "running"; })[0]
    || KEYS.filter(function (k) { return ms[k] === "later"; })[0]
    || "morning";
  var running = ms[key] === "running";
  var mins = estMinutes(key);
  var minLine = mins === 1 ? W.t("moments.min.one") : W.t("moments.min.many", { n: mins });

  function start() {
    ui.popup = null;
    ui.backRoute = ui.route || "today";
    W.go("session/" + key);
  }
  function later() {
    ui.popup = null;
    W.toast(W.t("toast.later"));
  }
  function close() {
    ui.popup = null;
    W.save();
    W.emit();
  }

  var card = html`<div class="card card-small moment-popup m-enter" data-id="moment-card" data-moment=${key}>
    <div class="moment-popup-head">
      <span class="moment-popup-ic">${W.Icon({ name: M_ICONS[key], size: 36 })}</span>
      <h2 class="title moment-popup-title">${W.t("moment." + key)}</h2>
      <p class="quiet num moment-popup-mins">${minLine}</p>
    </div>
    <${W.Btn} kind="main" wide=${true} icon="play"
      label=${W.t(running ? "btn.continue" : "btn.start")} id="moment-start" onClick=${start} />
    <div class="card-actions">
      <${W.Btn} kind="soft" icon="later" label=${W.t("btn.later")} id="moment-later" onClick=${later} />
      <${W.Btn} kind="text" icon="close" label=${W.t("btn.close")} id="moment-close" onClick=${close} />
    </div>
  </div>`;

  if (ui.frame === "windows") return card;
  var cells = [];
  for (var i = 0; i < 16; i++) cells.push(html`<i key=${i}></i>`);
  return html`<div class="over over-home" data-id="moment-over">
    <div class="over-status" dir="ltr"><span class="num">${W.clock(W.now())}</span><span class="phone-batt"></span></div>
    <div class="home-grid" aria-hidden="true">${cells}</div>
    <div class="home-shade"></div>
    <div class="over-dock">${card}</div>
  </div>`;
};

function SessionScreen(p) {
  var key = KEYS.indexOf(p.arg) >= 0 ? p.arg : "morning";
  var st = W.useApp(), eng = E.rollDay(st.eng, W.now());
  var items = W.SETS[key] || [];
  if (!items.length) return null;
  var pos = (eng.day && eng.day.moments && eng.day.moments[key]) || { i: 0, n: 0, done: false };
  var idx = W.clamp(pos.i || 0, 0, items.length - 1);
  var cur = items[idx];
  var doneCount = pos.done ? cur.count : W.clamp(pos.n || 0, 0, cur.count);
  var a = (eng.adhkar || []).filter(function (x) { return x.id === cur.id; })[0];

  function onTap() {
    W.act("session-tap", function (s) { s.eng = E.sessionTap(s.eng, W.now(), key, items); });
  }
  function onClose() {
    var back = W.U().backRoute || "today";
    W.U().backRoute = null;
    W.go(back);
  }
  var onBack = items.length > 1 && idx > 0
    ? function () { W.act("session-prev", function (s) { s.eng = E.sessionMove(E.rollDay(s.eng, W.now()), key, -1, items); }); }
    : null;
  var onForward = items.length > 1 && idx + 1 < items.length
    ? function () { W.act("session-next", function (s) { s.eng = E.sessionMove(E.rollDay(s.eng, W.now()), key, 1, items); }); }
    : null;

  var titleNode = html`<span class="session-head">
    <span class="session-name">${W.t("moment." + key)}</span>
    <span class="session-sep"> . </span>
    <span data-id="session-progress">${W.t("session.progress", { n: idx + 1, total: items.length })}</span>
  </span>`;

  return html`<div class="session-wrap" data-id="session">
    <${W.Card} size="page" id=${cur.id} piece=${cur.count} done=${doneCount}
      dayDone=${a ? ((eng.day.done && eng.day.done[cur.id]) || 0) : 0}
      dayTarget=${a ? a.target : 0}
      title=${titleNode}
      onTap=${onTap} onClose=${onClose}
      onBack=${onBack}
      onForward=${items.length > 1 && !onForward && !onBack ? null : onForward} />
    ${pos.done ? html`<div class="session-again">
      <${W.Btn} kind="text" icon="undo" label=${W.t("session.again")} id="session-again"
        onClick=${function () {
          W.act("session-reset", function (s) {
            s.eng = E.rollDay(s.eng, W.now());
            s.eng.day.moments[key] = { i: 0, n: 0, done: false };
          });
        }} />
    </div>` : null}
  </div>`;
}

W.wbTools.push(function () {
  return html`<button type="button" class="wb-btn" data-id="wb-moment" onClick=${function () {
    if (W.U().popup && W.U().popup !== "moment") W.cardLeave("ignore");
    W.U().popup = W.U().popup === "moment" ? null : "moment";
    W.save();
    W.emit();
  }}>Moment card</button>`;
});

W.screen("moments", function MomentsScreen(p) {
  return p.arg ? html`<${MomentDetail} key=${p.arg} mkey=${p.arg} />` : html`<${MomentsList} />`;
});
W.screen("session", SessionScreen);
})();
