/* moments.js: the four daily moments (list, per-moment page with compact settings summary + popup), moment card, and session/<key>. */
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
  var editSt = W.useState(null), editKey = editSt[0], setEditKey = editSt[1];
  var mt = E.momentTimes(eng.prefs);
  var mp = (eng.prefs && eng.prefs.moments) || {};

  var activeKey = editKey && KEYS.indexOf(editKey) >= 0 ? editKey : null;
  var activeMp = activeKey ? (mp[activeKey] || { on: true, at: null }) : null;
  var activeOn = activeMp ? activeMp.on !== false : true;
  var activeHhmm = activeKey ? minToHhmm(mt[activeKey].start) : "06:00";

  function setActiveTime(v) {
    if (!activeKey) return;
    var m = E.min(v);
    if (m < E.dayStartMin(eng.prefs)) m += 1440;
    W.act("moment-time", function (s) { s.eng = E.setMoment(s.eng, activeKey, { at: m }); });
  }

  return html`<div class="moments-page" data-id="moments-page">
    <div class="adhkar-rows">
      ${KEYS.map(function (k) {
        var on = !(mp[k] && mp[k].on === false);
        var items = W.SETS[k] || [];
        var timeStr = W.timeLabel(minToHhmm(mt[k].start));
        var mins = estMinutes(k);
        var minLine = mins === 1 ? W.t("moments.min.one") : W.t("moments.min.many", { n: mins });
        return html`<button type="button" key=${k} class=${W.cx("moment-compact-btn", !on && "is-off")}
          data-id=${"moments-row-" + k} onClick=${function () { setEditKey(k); }}>
          <span class="moment-compact-ic">${W.Icon({ name: M_ICONS[k], size: 20 })}</span>
          <span class="moment-compact-meta">
            <span class="moment-compact-top">
              <span class="moment-compact-name">${W.t("moment." + k)}</span>
              <span class="moment-compact-chips num">
                <span class=${W.cx("mc-chip", on && "is-on")}>
                  ${W.Icon({ name: on ? "bell" : "pause", size: 13 })}
                  <span>${W.t(on ? "moments.on" : "moments.off")}</span>
                </span>
                <span class="mc-chip">
                  ${W.Icon({ name: "later", size: 13 })}
                  <span>${timeStr}</span>
                </span>
                <span class="mc-chip">
                  ${W.Icon({ name: "adhkar", size: 13 })}
                  <span>${items.length}</span>
                </span>
              </span>
            </span>
            <span class="moment-compact-sub quiet num">${minLine}</span>
          </span>
          <span class="moment-compact-edit" aria-hidden="true">${W.Icon({ name: "wrench", size: 15 })}</span>
        </button>`;
      })}
    </div>
    <${W.Sheet} id="moment-list-sheet" popup=${true} open=${!!activeKey}
      title=${activeKey ? W.t("adhkar.moment.sheet", { name: W.t("moment." + activeKey) }) : ""}
      onClose=${function () { setEditKey(null); }}
      footer=${activeKey ? html`<div class="dhikr-actions">
        <${W.Btn} kind="soft" icon="adhkar" label=${W.t("moments.contents")} id="moment-open-detail"
          onClick=${function () { var k = activeKey; setEditKey(null); W.go("moments/" + k); }} />
        <${W.Btn} kind="main" icon="check" label=${W.t("btn.done")} id="moment-sheet-done"
          onClick=${function () { setEditKey(null); }} />
      </div>` : null}>
      ${activeKey ? html`<div class="moment-sheet-body">
        <div class="adhkar-moment-head">
          <span class="title">${W.t("moment." + activeKey)}</span>
          <${SwitchBtn} id=${"moment-switch-" + activeKey} on=${activeOn}
            onClick=${function () { W.act("moment", function (s) { s.eng = E.setMoment(s.eng, activeKey, { on: !activeOn }); }); }} />
        </div>
        <${W.TimeStep} id="moment-inline-time" label=${W.t("moments.time")} value=${activeHhmm} onChange=${setActiveTime} />
        ${activeMp && activeMp.at != null ? html`<div class="moment-reset-wrap">
          <${W.Btn} kind="text" icon="undo" label=${W.t("moments.reset")} id="moment-inline-reset"
            onClick=${function () { W.act("moment-reset", function (s) { s.eng = E.setMoment(s.eng, activeKey, { at: null }); }); }} />
        </div>` : null}
      </div>` : null}
    <//>
  </div>`;
}

function MomentDetail(p) {
  var key = KEYS.indexOf(p.mkey) >= 0 ? p.mkey : "morning";
  var st = W.useApp(), eng = E.rollDay(st.eng, W.now()), en = st.ui.lang === "en";
  var popSt = W.useState(false), popOpen = popSt[0], setPopOpen = popSt[1];
  var mt = E.momentTimes(eng.prefs);
  var mp = (eng.prefs && eng.prefs.moments && eng.prefs.moments[key]) || { on: true, at: null };
  var on = mp.on !== false;
  var hhmm = minToHhmm(mt[key].start);
  var timeStr = W.timeLabel(hhmm);
  var items = W.SETS[key] || [];
  var mins = estMinutes(key);
  var minLine = mins === 1 ? W.t("moments.min.one") : W.t("moments.min.many", { n: mins });
  var mName = W.t("moment." + key);

  function setTime(v) {
    var m = E.min(v);
    if (m < E.dayStartMin(eng.prefs)) m += 1440;
    W.act("moment-time", function (s) { s.eng = E.setMoment(s.eng, key, { at: m }); });
  }

  return html`<div class="moments-page" data-id="moment-detail">
    <button type="button" class=${W.cx("moment-compact-btn", !on && "is-off")}
      data-id="moment-compact-open" onClick=${function () { setPopOpen(true); }}>
      <span class="moment-compact-ic">${W.Icon({ name: M_ICONS[key] || "sun", size: 20 })}</span>
      <span class="moment-compact-meta">
        <span class="moment-compact-top">
          <span class="moment-compact-name">${mName}</span>
          <span class="moment-compact-chips num">
            <span class=${W.cx("mc-chip", on && "is-on")}>
              ${W.Icon({ name: on ? "bell" : "pause", size: 13 })}
              <span>${W.t(on ? "moments.on" : "moments.off")}</span>
            </span>
            <span class="mc-chip">
              ${W.Icon({ name: "later", size: 13 })}
              <span>${timeStr}</span>
            </span>
            <span class="mc-chip">
              ${W.Icon({ name: "adhkar", size: 13 })}
              <span>${items.length}</span>
            </span>
          </span>
        </span>
        <span class="moment-compact-sub quiet num">${minLine}</span>
      </span>
      <span class="moment-compact-edit" aria-hidden="true">
        ${W.Icon({ name: "wrench", size: 15 })}
      </span>
    </button>

    <${W.Btn} kind="main" wide=${true} icon="play" label=${W.t("btn.start")} id="moment-page-start"
      onClick=${function () { W.U().backRoute = "moments/" + key; W.go("session/" + key); }} />

    <section class="today-sec" data-id="moment-items">
      <h2 class="today-sec-title quiet">${W.t("moments.contents")}</h2>
      <div class="adhkar-rows">
        ${items.map(function (entry) {
          var it = W.lib(entry.id);
          var sub = entry.count === 1 ? W.t("add.once") : W.t("moments.item.count", { n: entry.count });
          return html`<${W.Row} key=${entry.id} id=${"set-item-" + entry.id} dhikr=${true}
            title=${it ? it.ar : entry.id}
            sub=${en && it && it.translit ? it.translit + " . " + sub : sub}
            onClick=${function () { W.U().backRoute = "moments/" + key; W.go("adhkar/" + entry.id); }} />`;
        })}
      </div>
    </section>

    <${W.Sheet} id="moment-settings-sheet" popup=${true} open=${popOpen}
      title=${W.t("adhkar.moment.sheet", { name: mName })}
      onClose=${function () { setPopOpen(false); }}
      footer=${html`<${W.Btn} kind="main" wide=${true} icon="check" label=${W.t("btn.done")} id="moment-sheet-done"
        onClick=${function () { setPopOpen(false); }} />`}>
      <div class="moment-sheet-body">
        <div class="adhkar-moment-head">
          <span class="title">${mName}</span>
          <${SwitchBtn} id=${"moment-switch-" + key} on=${on}
            onClick=${function () { W.act("moment", function (s) { s.eng = E.setMoment(s.eng, key, { on: !on }); }); }} />
        </div>
        <${W.TimeStep} id="moment-time" label=${W.t("moments.time")} value=${hhmm} onChange=${setTime} />
        ${mp.at != null ? html`<div class="moment-reset-wrap">
          <${W.Btn} kind="text" icon="undo" label=${W.t("moments.reset")} id="moment-reset"
            onClick=${function () { W.act("moment-reset", function (s) { s.eng = E.setMoment(s.eng, key, { at: null }); }); }} />
        </div>` : null}
      </div>
    <//>
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

W.activeSetItems = function (eng, key) {
  var raw = key === "jumuah" ? (W.JUMUAH_SET || []) : ((W.SETS && W.SETS[key]) || []);
  var sk = eng && eng.prefs && eng.prefs.momentSkip && eng.prefs.momentSkip[key];
  if (!sk) return raw;
  var filtered = raw.filter(function (x) { return !sk[x.id]; });
  return filtered.length ? filtered : raw;
};

function SessionScreen(p) {
  var key = p.arg === "jumuah" ? "jumuah" : (KEYS.indexOf(p.arg) >= 0 ? p.arg : "morning");
  var st = W.useApp(), eng = E.rollDay(st.eng, W.now());
  var items = W.activeSetItems(eng, key);
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

  var onAgain = pos.done ? function () {
    W.act("session-reset", function (s) {
      s.eng = E.rollDay(s.eng, W.now());
      s.eng.day.moments[key] = { i: 0, n: 0, done: false };
    });
  } : null;

  return html`<div class="session-wrap" data-id="session">
    <${W.Card} size="page" id=${cur.id} piece=${cur.count} done=${doneCount}
      dayDone=${a ? ((eng.day.done && eng.day.done[cur.id]) || 0) : 0}
      dayTarget=${a ? a.target : 0}
      inSession=${true}
      onTap=${onTap} onClose=${onClose}
      onAgain=${onAgain}
      onBack=${onBack}
      onForward=${items.length > 1 && !onForward && !onBack ? null : onForward} />
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
