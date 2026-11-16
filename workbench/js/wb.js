/* wb.js: the Workbench menu and the day simulator. English only, outside the frames, and marked data-cmt-ui
   so the comment tool ignores it. */
(function () {
"use strict";
var W = window.W, html = W.html;

W.DAYS = [
  ["first", "First open"], ["noon", "A normal day at noon"], ["complete", "Everything complete"],
  ["missed", "Back after a missed week"], ["weekup", "Weekly card: going up"],
  ["weekdown", "Weekly card: going down"], ["weekheavy", "Weekly card: one heavy dhikr"]
];

var PEOPLE = [
  ["responsive", "Responsive"],
  ["busyNoon", "Busy at noon"],
  ["ignoresOne", "Ignores one dhikr"],
  ["away", "Away all day"]
];
var HOW = { finish: "Finished", partial: "Partial", close: "Closed", ignore: "Ignored" };

var SIM = {
  person: "responsive",
  seed: 1,
  dayKey: null,
  wakeTs: 0,
  wakeSnap: null,
  beforeShow: null,
  log: [],
  playing: false,
  timer: 0
};

function clone(o) { return JSON.parse(JSON.stringify(o)); }

function stopPlay() {
  if (SIM.timer) { clearInterval(SIM.timer); SIM.timer = 0; }
  SIM.playing = false;
}

function clearSim() {
  stopPlay();
  SIM.dayKey = null;
  SIM.wakeTs = 0;
  SIM.wakeSnap = null;
  SIM.beforeShow = null;
  SIM.log = [];
}

function setUi(key, value) {
  if (key === "panel" && value !== "sim") stopPlay();
  W.U()[key] = value;
  W.save();
  W.emit();
}

/* loads an example day: a state the simulator really produced, and the pretend time that goes with it */
W.setDay = function (key, opts) {
  opts = opts || {};
  clearSim();
  var d = W.Sim.day(key), ui = W.U();
  W.S.state.eng = d.state || {};
  W.S.undo = [];
  ui.day = key;
  ui.now = d.now;
  if (!opts.keepPopup) ui.popup = null;
  if (!opts.keepRoute) ui.route = d.state ? "today" : "onboarding/1";
  W.save();
  W.emit();
};
W.setLang = function (v) { setUi("lang", v); };
W.setTheme = function (v) { setUi("theme", v); };
W.setSize = function (v) { setUi("size", v); };
W.setLook = function (v) { setUi("look", v); };
W.setFrame = function (v) { setUi("frame", v); };
/* example data back to how the chosen day starts; comments are kept */
W.resetAll = function () { W.setDay(W.U().day); };

/* ---------- day simulator ---------- */
function sleepMin(prefs) {
  var w = W.E.min(prefs.wake), s = W.E.min(prefs.sleep);
  return s <= w ? s + 1440 : s;
}

function atMin(key, m) {
  var p = key.split("-");
  return new Date(+p[0], +p[1] - 1, +p[2], 0, m).getTime();
}

function curMin(ts, prefs) {
  var d = new Date(ts), m = d.getHours() * 60 + d.getMinutes();
  return m < W.E.dayStartMin(prefs) ? m + 1440 : m;
}

function emptyDay(key) {
  return { key: key, done: {}, extra: {}, carry: {}, showing: null, lastShown: null, moments: {}, complete: false,
    shows: {}, skips: {}, laterAt: 0, fresh: 0 };
}

function makeWakeSnap(eng, key) {
  var snap = clone(eng);
  snap.day = emptyDay(key);
  snap.pausedUntil = 0;
  return snap;
}

function ensureSimDay() {
  if (!(W.S.state.eng && W.S.state.eng.prefs)) W.setDay("noon");
  var eng = W.E.rollDay(W.S.state.eng, W.now());
  W.S.state.eng = eng;
  var key = eng.day.key;
  if (SIM.dayKey !== key || !SIM.wakeSnap) {
    SIM.dayKey = key;
    SIM.wakeTs = atMin(key, W.E.min(eng.prefs.wake));
    SIM.wakeSnap = makeWakeSnap(eng, key);
    SIM.beforeShow = null;
    SIM.log = [];
  }
}

function clearLivePopup() {
  var s = W.S.state;
  if (SIM.beforeShow && s.eng && s.eng.day && s.eng.day.showing && !s.eng.day.fresh) {
    s.eng = clone(SIM.beforeShow);
  } else if (s.eng && s.eng.day && s.eng.day.showing) {
    s.eng = W.E.leave(s.eng, W.now(), "ignore");
  }
  SIM.beforeShow = null;
  s.ui.popup = null;
}

function isSlot(eng, ts) {
  var d = new Date(ts);
  if (d.getSeconds() !== 0) return false;
  var prefs = eng.prefs, w = W.E.min(prefs.wake), s = sleepMin(prefs), m = curMin(ts, prefs);
  return m > w && m < s && (m - w) % W.E.intervalMin(eng) === 0;
}

function applySlotPopup() {
  var s = W.S.state;
  if (!(s.eng && s.eng.prefs) || !W.showReminder) return;
  if (String(s.ui.route || "").indexOf("session/") === 0) return;
  if (isSlot(s.eng, s.ui.now)) {
    var snap = clone(s.eng);
    if (W.showReminder()) SIM.beforeShow = snap;
  }
}

W.simSeek = function (toTs) {
  ensureSimDay();
  var s = W.S.state, fromTs = W.now();
  if (toTs === fromTs) return;
  clearLivePopup();
  if (toTs > fromTs) {
    var r = W.Sim.run(s.eng, fromTs, toTs, SIM.person, SIM.seed);
    s.eng = r.state;
    s.ui.now = toTs;
    if (s.eng.day.key !== SIM.dayKey) {
      SIM.dayKey = s.eng.day.key;
      SIM.wakeTs = atMin(SIM.dayKey, W.E.min(s.eng.prefs.wake));
      SIM.wakeSnap = makeWakeSnap(s.eng, SIM.dayKey);
    }
    SIM.log = SIM.log.concat(r.log);
  } else {
    var target = Math.max(SIM.wakeTs, toTs);
    var r2 = W.Sim.run(clone(SIM.wakeSnap), SIM.wakeTs, target, SIM.person, SIM.seed);
    s.eng = r2.state;
    s.ui.now = target;
    SIM.log = r2.log;
  }
  W.save();
  W.emit();
  applySlotPopup();
};

W.simSeekMin = function (m) {
  ensureSimDay();
  W.simSeek(atMin(SIM.dayKey, m));
};

W.simSeekClock = function (hhmm) {
  if (!hhmm || !/^\d{1,2}:\d{2}$/.test(hhmm)) return;
  ensureSimDay();
  var prefs = W.S.state.eng.prefs, m = W.E.min(hhmm);
  if (m < W.E.dayStartMin(prefs)) m += 1440;
  W.simSeek(atMin(SIM.dayKey, m));
};

W.simSetPerson = function (person) {
  if (W.Sim.PEOPLE.indexOf(person) < 0) return;
  stopPlay();
  SIM.person = person;
  W.emit();
};

W.simAdvanceDays = function (days) {
  stopPlay();
  ensureSimDay();
  var s = W.S.state, fromTs = W.now(), prefs = s.eng.prefs;
  var p = SIM.dayKey.split("-"), d = new Date(+p[0], +p[1] - 1, +p[2] + days);
  var z = function (n) { return (n < 10 ? "0" : "") + n; };
  var targetKey = d.getFullYear() + "-" + z(d.getMonth() + 1) + "-" + z(d.getDate());
  var m = curMin(fromTs, prefs);
  var targetWakeTs = atMin(targetKey, W.E.min(prefs.wake));
  var targetTs = Math.max(targetWakeTs, atMin(targetKey, m));
  clearLivePopup();
  var r1 = W.Sim.run(s.eng, fromTs, targetWakeTs, SIM.person, SIM.seed);
  SIM.dayKey = targetKey;
  SIM.wakeTs = targetWakeTs;
  SIM.wakeSnap = clone(r1.state);
  var r2 = targetTs > targetWakeTs ? W.Sim.run(r1.state, targetWakeTs, targetTs, SIM.person, SIM.seed) : { state: r1.state, log: [] };
  s.eng = r2.state;
  s.ui.now = targetTs;
  SIM.log = r1.log.concat(r2.log);
  W.save();
  W.emit();
  applySlotPopup();
};

W.simOpen = function (person) {
  if (person && W.Sim.PEOPLE.indexOf(person) >= 0) SIM.person = person;
  W.U().panel = "sim";
  ensureSimDay();
  W.save();
  W.emit();
};

W.simToggle = function (force) {
  var want = force == null ? W.U().panel !== "sim" : !!force;
  if (!want) {
    stopPlay();
    if (W.U().panel === "sim") setUi("panel", null);
    return;
  }
  W.simOpen();
};

W.simTogglePlay = function () {
  if (SIM.playing) { stopPlay(); W.emit(); return; }
  ensureSimDay();
  var prefs = W.S.state.eng.prefs, w = W.E.min(prefs.wake), s = sleepMin(prefs);
  if (curMin(W.now(), prefs) >= s) W.simSeekMin(w);
  SIM.playing = true;
  W.emit();
  SIM.timer = setInterval(function () {
    if (W.U().panel !== "sim" || !(W.S.state.eng && W.S.state.eng.prefs)) { stopPlay(); W.emit(); return; }
    var pr = W.S.state.eng.prefs, end = sleepMin(pr), next = curMin(W.now(), pr) + 10;
    if (next >= end) {
      W.simSeekMin(end);
      stopPlay();
      W.emit();
      return;
    }
    W.simSeekMin(next);
  }, 360);
};

function shortDhikr(id) {
  var it = W.lib ? W.lib(id) : null;
  if (!it) return id;
  var s = it.translit || it.ar || id;
  return s.length > 44 ? s.slice(0, 41) + "..." : s;
}

function fmtMin(m) {
  var h = Math.floor((m % 1440) / 60), mm = m % 60;
  return (h < 10 ? "0" : "") + h + ":" + (mm < 10 ? "0" : "") + mm;
}

function fmtSimDate(ts) {
  try { return new Date(ts).toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short" }); }
  catch (e) { return ""; }
}

W.SimPanel = function SimPanel() {
  var st = W.useApp(), ui = st.ui, eng = st.eng;
  W.useEffect(function () {
    function onKey(e) {
      var t = e.target, typing = t && (/^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName) || t.isContentEditable);
      if (typing) return;
      if (e.key === "Escape" && W.U().panel === "sim") W.simToggle(false);
    }
    document.addEventListener("keydown", onKey);
    return function () { document.removeEventListener("keydown", onKey); };
  }, []);

  if (ui.panel !== "sim") return null;
  if (!(eng && eng.prefs)) {
    return html`<aside class="cmt-side sim-panel" data-id="sim" data-cmt-ui="1" dir="ltr" aria-label="Simulate a day">
      <div class="cmt-row cmt-side-head"><b>Simulate a day</b><span class="cmt-sp"></span>
        <button type="button" class="wb-btn" onClick=${function () { W.simToggle(false); }}>Hide</button></div>
      <div class="cmt-empty">
        <b>Choose an example day first.</b>
        <span class="cmt-dim">Onboarding has no daily schedule yet.</span>
        <button type="button" class="wb-btn" onClick=${function () { W.setDay("noon"); W.simOpen(); }}>Start from a normal day</button>
      </div>
    </aside>`;
  }

  var prefs = eng.prefs, w = W.E.min(prefs.wake), s = sleepMin(prefs), now = W.now();
  var m = W.clamp(curMin(now, prefs), w, s);
  var lines = SIM.log;

  return html`<aside class="cmt-side sim-panel" data-id="sim" data-cmt-ui="1" dir="ltr" aria-label="Simulate a day">
    <div class="cmt-row cmt-side-head">
      <b>Simulate a day</b>
      <span class="cmt-dim" data-id="sim-date">${fmtSimDate(now)}</span>
      <span class="cmt-sp"></span>
      <button type="button" class="wb-btn" data-id="sim-hide" onClick=${function () { W.simToggle(false); }}>Hide</button>
    </div>
    <div class="sim-controls">
      <label class="sim-field">
        <span class="cmt-dim">Pretend person</span>
        <select class="sim-select" data-id="sim-person" value=${SIM.person} onChange=${function (e) { W.simSetPerson(e.target.value); }}>
          ${PEOPLE.map(function (p) { return html`<option key=${p[0]} value=${p[0]}>${p[1]}</option>`; })}
        </select>
      </label>
      <div class="sim-clock-box">
        <div class="cmt-row">
          <span class="cmt-dim">Wake ${fmtMin(w)}</span>
          <span class="cmt-sp"></span>
          <b class="sim-clock" data-id="sim-clock">${W.clock(now)}</b>
          <span class="cmt-sp"></span>
          <span class="cmt-dim">Sleep ${fmtMin(s)}</span>
        </div>
        <input type="range" class="sim-range" data-id="sim-slider" aria-label="Time of day"
          min=${w} max=${s} step="5" value=${m}
          onInput=${function (e) { stopPlay(); W.simSeekMin(Number(e.target.value)); }}
          onChange=${function (e) { stopPlay(); W.simSeekMin(Number(e.target.value)); }} />
      </div>
      <div class="cmt-row">
        <button type="button" class=${W.cx("wb-btn", SIM.playing && "is-on")} data-id="sim-play" onClick=${W.simTogglePlay}>${SIM.playing ? "Pause" : "Play"}</button>
        <button type="button" class="wb-btn" data-id="sim-next-day" onClick=${function () { W.simAdvanceDays(1); }}>Next day</button>
        <button type="button" class="wb-btn" data-id="sim-next-week" onClick=${function () { W.simAdvanceDays(7); }}>Next week</button>
      </div>
    </div>
    <div class="cmt-list sim-log" data-id="sim-log">
      ${lines.length ? lines.map(function (e, i) {
        var changed = e.comfortBefore !== e.comfortAfter
          ? "comfort " + e.comfortBefore + " to " + e.comfortAfter
          : "comfort steady at " + e.comfortAfter;
        return html`<div key=${i} class="sim-line" data-sim-line="1">
          <div class="cmt-row">
            <b>${W.clock(e.ts)}</b>
            <span class=${W.cx("cmt-tag", e.how === "finish" && "good")}>${HOW[e.how] || e.how}</span>
            <span class="cmt-dim">${e.did}/${e.piece}</span>
            <span class="cmt-sp"></span>
            <span class="cmt-dim">${changed}</span>
          </div>
          <div class="cmt-ell sim-dhikr">${shortDhikr(e.id)}</div>
        </div>`;
      }) : html`<div class="cmt-empty"><b>No appearances yet in this run.</b>
        <span class="cmt-dim">Drag the clock forward, press Play, or jump to the next day to watch how the engine adapts.</span></div>`}
    </div>
  </aside>`;
};

function Seg(p) {
  return html`<span class="wb-seg" role="group" aria-label=${p.label} data-id=${p.id} data-cmt-ui="1">
    <span class="wb-seg-label">${p.label}</span>
    ${p.options.map(function (o) {
      return html`<button type="button" key=${String(o[0])} class=${W.cx("wb-seg-btn", o[0] === p.value && "is-on")}
        data-id=${p.id + "-" + o[0]} aria-pressed=${o[0] === p.value} onClick=${function () { p.onChange(o[0]); }}>${o[1]}</button>`;
    })}
  </span>`;
}

/* one short line from the workbench itself, shown in the menu for a few seconds */
var noteTimer = 0;
W.wbNote = function (msg) {
  W.U().wbNote = msg;
  clearTimeout(noteTimer);
  noteTimer = setTimeout(function () { W.U().wbNote = null; W.emit(); }, 5000);
  W.emit();
};

/* extra buttons other tasks add to the menu: W.wbTools.push(function () { return html`...`; }) */
W.wbTools = [];

W.WbMenu = function WbMenu() {
  var ui = W.useApp().ui, inGallery = ui.route === "gallery";
  return html`<div class="wb-menu" data-id="wb-menu" data-cmt-ui="1" dir="ltr">
    <label class="wb-pick"><span class="wb-seg-label">Example day</span>
      <select data-id="wb-day" value=${ui.day} onChange=${function (e) { W.setDay(e.target.value); }}>
        ${W.DAYS.map(function (d) { return html`<option key=${d[0]} value=${d[0]}>${d[1]}</option>`; })}
      </select>
    </label>
    <button type="button" class=${W.cx("wb-btn", ui.panel === "sim" && "is-on")} data-id="wb-sim" onClick=${function () { W.simToggle(); }}>Simulate a day</button>
    <${Seg} id="wb-frame" label="Frame" value=${ui.frame} options=${[["phone", "Phone"], ["windows", "Windows"]]} onChange=${W.setFrame} />
    <${Seg} id="wb-lang" label="Language" value=${ui.lang} options=${[["ar", "Arabic"], ["en", "English"]]} onChange=${W.setLang} />
    <${Seg} id="wb-theme" label="Theme" value=${ui.theme} options=${[["light", "Light"], ["dark", "Dark"]]} onChange=${W.setTheme} />
    <${Seg} id="wb-size" label="Text" value=${ui.size} options=${[[1, "A"], [2, "A+"], [3, "A++"]]} onChange=${W.setSize} />
    <${Seg} id="wb-look" label="Look" value=${ui.look} options=${[["a", "A Olive"], ["b", "B Iznik"]]} onChange=${W.setLook} />
    ${W.wbTools.map(function (tool, i) { return html`<span key=${i} class="wb-tool">${tool()}</span>`; })}
    <button type="button" class="wb-btn" data-id="wb-gallery" onClick=${function () {
      if (inGallery) W.go(ui.backRoute || "today"); else { ui.backRoute = ui.route; W.go("gallery"); }
    }}>${inGallery ? "Back to the app" : "Icons and motion"}</button>
    <button type="button" class="wb-btn" data-id="wb-reset" onClick=${W.resetAll}>Reset example data</button>
    ${ui.wbNote ? html`<span class="wb-note" data-id="wb-note" role="status">${ui.wbNote}</span>` : null}
  </div>`;
};
})();
