/* more.js: More settings (with search, merged Sound & Recitation, interactive Sleep sky, containered Other)
   and My days (illustrated hero, motivational phrases, GitHub-style monthly heatmap with linked streak borders, and history). */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

function norm(s) {
  return String(s || "").toLowerCase()
    .replace(/[\u064b-\u065f\u0670\u06d6-\u06ed]/g, "")
    .replace(/[\u0622\u0623\u0625\u0671]/g, "\u0627")
    .replace(/\u0649/g, "\u064a")
    .replace(/\u0629/g, "\u0647");
}

function bothLangs(key) {
  var ar = (W.STR && W.STR.ar && W.STR.ar[key]) || "";
  var en = (W.STR && W.STR.en && W.STR.en[key]) || "";
  return ar + " " + en;
}

function setPref(label, patch) {
  W.act(label, function (s) {
    var prefs = Object.assign({}, s.eng.prefs, patch);
    s.eng = E.rollDay(Object.assign({}, s.eng, { prefs: prefs }), W.now());
  });
}

function MoreHome() {
  var st = W.useApp(), ui = st.ui, eng = E.rollDay(st.eng, W.now());
  var prefs = eng.prefs || W.ANSWER_DEFAULTS;
  var openSt = W.useState(false), open = openSt[0], setOpen = openSt[1];
  var pSt = W.useState(false), pOpen = pSt[0], setPOpen = pSt[1];
  var qSt = W.useState(""), q = qSt[0], setQ = qSt[1];

  var cardSize = prefs.cardSize || "small";
  var recite = prefs.recite !== false;
  var sound = prefs.sound || "soft";
  var soundSub = W.t("more.sound." + sound) + " . " + W.t(recite ? "more.recite.short.on" : "more.recite.short.off");

  var mainRows = [
    {
      id: "more-row-parent", icon: "heart",
      title: W.t("parent.btn"), sub: W.t("parent.sub"),
      kw: bothLangs("parent.btn") + " " + bothLangs("parent.sub") + " " + bothLangs("parent.sheet.title"),
      onClick: function () { setPOpen(true); }
    },
    {
      id: "more-row-level", icon: "sparkle",
      title: W.t("more.level.t"),
      sub: W.t("level." + (prefs.level || "some")) + " . " + W.t("goal." + (prefs.goal || "mix")),
      kw: bothLangs("more.level.t") + " " + bothLangs("ob.level.q") + " " + bothLangs("ob.goal.q") + " " + bothLangs("level.new") + " " + bothLangs("level.some") + " " + bothLangs("level.daily") + " " + bothLangs("goal.mix") + " " + bothLangs("goal.day") + " " + bothLangs("goal.moments") + " " + bothLangs("goal.sleep"),
      onClick: function () { W.go("more/level"); }
    },
    {
      id: "more-row-freq", icon: "bell",
      title: W.t("ob.freq.q"), sub: W.t("freq." + (prefs.freq || "hour")),
      kw: bothLangs("ob.freq.q") + " " + bothLangs("freq.few") + " " + bothLangs("freq.hour") + " " + bothLangs("freq.often"),
      onClick: function () { W.go("more/freq"); }
    },
    {
      id: "more-row-sleep", icon: "bed",
      title: W.t("ob.sleep.q"),
      sub: W.timeLabel(prefs.wake || "06:00") + " . " + W.timeLabel(prefs.sleep || "23:00"),
      kw: bothLangs("ob.sleep.q") + " " + bothLangs("ob.wake") + " " + bothLangs("ob.sleep"),
      onClick: function () { W.go("more/sleep"); }
    },
    {
      id: "more-row-look", icon: cardSize === "full" ? "card-full" : "card-small",
      title: W.t("ob.try.pick"),
      sub: W.t("ob.size." + cardSize) + " . " + W.t("more.theme." + ui.theme),
      kw: bothLangs("ob.try.pick") + " " + bothLangs("more.theme.q") + " " + bothLangs("more.theme.light") + " " + bothLangs("more.theme.dark") + " " + bothLangs("ob.size.small") + " " + bothLangs("ob.size.full"),
      onClick: function () { W.go("more/look"); }
    },
    {
      id: "more-row-sound", icon: "sound",
      title: W.t("more.sound.q"), sub: soundSub,
      kw: bothLangs("more.sound.q") + " " + bothLangs("more.sound.soft") + " " + bothLangs("more.sound.vibrate") + " " + bothLangs("more.sound.silent") + " " + bothLangs("ob.recite.q") + " " + bothLangs("card.reciting"),
      onClick: function () { W.go("more/sound"); }
    },
    {
      id: "more-row-lang", icon: "language",
      title: W.t("ob.lang.q"), sub: W.t("ob.lang." + ui.lang),
      kw: bothLangs("ob.lang.q") + " " + bothLangs("ob.lang.ar") + " " + bothLangs("ob.lang.en"),
      onClick: function () { W.go("more/lang"); }
    },
    {
      id: "more-row-size", icon: "text-size",
      title: W.t("more.size.q"), sub: W.t("more.size." + ui.size),
      kw: bothLangs("more.size.q") + " " + bothLangs("more.size.sub"),
      onClick: function () { W.go("more/size"); }
    },
    {
      id: "more-row-days", icon: "history",
      title: W.t("more.days.title"), sub: W.t("more.days.sub"),
      kw: bothLangs("more.days.title") + " " + bothLangs("more.days.sub") + " " + bothLangs("days.cal.title"),
      onClick: function () { W.go("days"); }
    }
  ];

  var otherRows = [
    {
      id: "more-row-backup", icon: "backup", title: W.t("more.backup.t"),
      kw: bothLangs("more.backup.t") + " " + bothLangs("more.backup.p"),
      onClick: function () { W.go("more/backup"); }
    },
    {
      id: "more-row-request", icon: "add", title: W.t("more.request.t"),
      kw: bothLangs("more.request.t") + " " + bothLangs("more.request.p"),
      onClick: function () { W.go("more/request"); }
    },
    {
      id: "more-row-problem", icon: "wrench", title: W.t("more.problem.t"),
      kw: bothLangs("more.problem.t") + " " + bothLangs("more.problem.p"),
      onClick: function () { W.go("more/problem"); }
    },
    {
      id: "more-row-updates", icon: "sparkle", title: W.t("more.updates.t"),
      kw: bothLangs("more.updates.t") + " " + bothLangs("more.updates.p"),
      onClick: function () { W.go("more/updates"); }
    },
    {
      id: "more-row-about", icon: "help", title: W.t("more.about.t"),
      kw: bothLangs("more.about.t") + " " + bothLangs("more.about.p"),
      onClick: function () { W.go("more/about"); }
    }
  ];

  var nq = norm(q).trim();
  function matchesRow(r) {
    if (!nq) return true;
    return norm((r.title || "") + " " + (r.sub || "") + " " + (r.kw || "")).indexOf(nq) >= 0;
  }

  var shownMain = mainRows.filter(matchesRow);
  var shownOther = otherRows.filter(matchesRow);
  var showOtherBox = !nq || shownOther.length > 0;
  var otherExpanded = nq ? shownOther.length > 0 : open;
  var nothingFound = !!nq && shownMain.length === 0 && shownOther.length === 0;

  return html`<div class="more-page" data-id="more-page">
    <label class="search-box" data-id="more-search-box">
      <span class="search-ic">${W.Icon({ name: "search", size: 22 })}</span>
      <input type="search" class="search-in" data-id="more-search" value=${q}
        placeholder=${W.t("more.search")}
        onInput=${function (e) { setQ(e.target.value); }} />
      ${q ? html`<button type="button" class="search-clear" data-id="more-search-clear"
        aria-label=${W.t("btn.close")} onClick=${function () { setQ(""); }}>
        ${W.Icon({ name: "close", size: 20 })}
      </button>` : null}
    </label>

    ${nothingFound ? html`<p class="add-empty quiet" data-id="more-search-empty">${W.t("more.search.empty")}</p>` : null}

    ${shownMain.length ? html`<div class="adhkar-rows">
      ${shownMain.map(function (r) {
        return html`<${W.Row} key=${r.id} id=${r.id} icon=${r.icon}
          title=${r.title} sub=${r.sub} onClick=${r.onClick} />`;
      })}
    </div>` : null}

    ${showOtherBox ? html`<div class=${W.cx("more-other-wrap", otherExpanded && "is-open")} data-id="more-other-box">
      <button type="button" class=${W.cx("row", "more-other-btn", otherExpanded && "is-open")}
        data-id="more-other" aria-expanded=${otherExpanded ? "true" : "false"}
        onClick=${function () { setOpen(!open); }}>
        <span class="row-icon">${W.Icon({ name: "more", size: 28 })}</span>
        <span class="row-main"><span class="row-title">${W.t("more.other")}</span></span>
        <span class="row-end more-other-chev">${W.Icon({ name: "forward", size: 22, className: "row-go" })}</span>
      </button>

      ${otherExpanded ? html`<div class="adhkar-rows more-other-list" data-id="more-other-list">
        ${shownOther.map(function (r) {
          return html`<${W.Row} key=${r.id} id=${r.id} icon=${r.icon} title=${r.title} onClick=${r.onClick} />`;
        })}
      </div>` : null}
    </div>` : null}

    <${W.ParentSheet} open=${pOpen} onClose=${function () { setPOpen(false); }} />
  </div>`;
}

function SubShell(p) {
  return html`<div class=${W.cx("more-sub", p.className)} data-id=${"more-" + p.name} style=${p.style || null}>
    <h1 class="title more-sub-title">${p.title}</h1>
    ${p.sub ? html`<p class="quiet more-sub-p">${p.sub}</p>` : null}
    ${p.children}
  </div>`;
}

function minToHhmm(m) {
  var t = ((Math.round(m) % 1440) + 1440) % 1440;
  var h = Math.floor(t / 60), mn = t % 60;
  return (h < 10 ? "0" : "") + h + ":" + (mn < 10 ? "0" : "") + mn;
}

function minToDeg(m) {
  return (((m / 1440) * 360) + 90) % 360;
}

function ptOnRing(cx, cy, r, m) {
  var rad = minToDeg(m) * Math.PI / 180;
  return { x: +(cx + r * Math.cos(rad)).toFixed(2), y: +(cy + r * Math.sin(rad)).toFixed(2) };
}

function ringArcPath(cx, cy, r, fromMin, toMin) {
  var span = ((toMin - fromMin) % 1440 + 1440) % 1440;
  if (span <= 0) span = 30;
  if (span >= 1439) span = 1410;
  var a = ptOnRing(cx, cy, r, fromMin);
  var b = ptOnRing(cx, cy, r, (fromMin + span) % 1440);
  var largeArc = span > 720 ? 1 : 0;
  return "M " + a.x + " " + a.y + " A " + r + " " + r + " 0 " + largeArc + " 1 " + b.x + " " + b.y;
}

function angDistMin(a, b) {
  var d = Math.abs(a - b) % 1440;
  return d > 720 ? 1440 - d : d;
}

W.SleepPicker = function SleepPicker(p) {
  var pfx = p.idPrefix || "more";
  var wake = p.wake || "06:00";
  var sleep = p.sleep || "23:00";
  var focusSt = W.useState("both"), focus = focusSt[0], setFocus = focusSt[1];
  var dragSt = W.useState(null), dragKind = dragSt[0], setDragKind = dragSt[1];
  var pickSt = W.useState(null), pickKind = pickSt[0], setPickKind = pickSt[1];
  var ringRef = W.useRef(null);

  var wakeMin = E.min(wake);
  var sleepMin = E.min(sleep);
  var sleepDurMin = ((wakeMin - sleepMin) % 1440 + 1440) % 1440 || 480;
  var quietHrs = Math.round((sleepDurMin / 60) * 10) / 10;

  var cx = 120, cy = 120, R = 82;
  var wakePt = ptOnRing(cx, cy, R, wakeMin);
  var sleepPt = ptOnRing(cx, cy, R, sleepMin);
  var restPath = ringArcPath(cx, cy, R, sleepMin, wakeMin);
  var awakePath = ringArcPath(cx, cy, R, wakeMin, sleepMin);
  var wakeAtNight = wakeMin < 270 || wakeMin >= 1080;

  function applyWake(hhmm) {
    if (hhmm === sleep) hhmm = W.shiftTime(hhmm, 30);
    setFocus("wake");
    if (p.onWake) p.onWake(hhmm);
  }

  function applySleep(hhmm) {
    if (hhmm === wake) hhmm = W.shiftTime(hhmm, -30);
    setFocus("sleep");
    if (p.onSleep) p.onSleep(hhmm);
  }

  function applyPreset(w, s) {
    setFocus("both");
    if (p.onBoth) p.onBoth(w, s);
    else {
      if (p.onWake) p.onWake(w);
      if (p.onSleep) p.onSleep(s);
    }
  }

  function pointerToSnappedMin(ev) {
    var el = ringRef.current;
    if (!el) return null;
    var rect = el.getBoundingClientRect();
    var dx = ev.clientX - (rect.left + rect.width / 2);
    var dy = ev.clientY - (rect.top + rect.height / 2);
    if (Math.hypot(dx, dy) < 12) return null;
    var deg = (Math.atan2(dy, dx) * 180 / Math.PI + 360) % 360;
    var rawMin = (((deg - 90 + 360) % 360) / 360) * 1440;
    return (Math.round(rawMin / 30) * 30) % 1440;
  }

  function captureRing(ev) {
    var el = ringRef.current;
    if (el && el.setPointerCapture && ev && ev.pointerId != null) {
      try { el.setPointerCapture(ev.pointerId); } catch (err) { /* ignore */ }
    }
  }

  function startHandleDrag(which, ev) {
    if (ev && ev.stopPropagation) ev.stopPropagation();
    if (ev && ev.preventDefault) ev.preventDefault();
    captureRing(ev);
    setDragKind(which);
    setFocus(which);
  }

  function onDialDown(ev) {
    var m = pointerToSnappedMin(ev);
    if (m == null) return;
    var which = angDistMin(m, wakeMin) <= angDistMin(m, sleepMin) ? "wake" : "sleep";
    if (angDistMin(m, wakeMin) > 120 && angDistMin(m, sleepMin) > 120 && (focus === "wake" || focus === "sleep")) {
      which = focus;
    }
    captureRing(ev);
    setDragKind(which);
    setFocus(which);
    var hhmm = minToHhmm(m);
    if (which === "wake") applyWake(hhmm);
    else applySleep(hhmm);
  }

  function onDialMove(ev) {
    if (!dragKind) return;
    var m = pointerToSnappedMin(ev);
    if (m == null) return;
    var hhmm = minToHhmm(m);
    if (dragKind === "wake") {
      if (hhmm !== wake) applyWake(hhmm);
    } else {
      if (hhmm !== sleep) applySleep(hhmm);
    }
  }

  function onDialUp() {
    if (dragKind) setDragKind(null);
  }

  var presets = [
    { id: "normal", label: W.t("sleep.preset.normal"), wake: "06:00", sleep: "23:00" },
    { id: "late", label: W.t("sleep.preset.late"), wake: "08:30", sleep: "01:00" },
    { id: "shift", label: W.t("sleep.preset.shift"), wake: "18:00", sleep: "09:00" }
  ];

  var pickVal = pickKind === "sleep" ? sleep : wake;
  var pickParts = String(pickVal).split(":");
  var pickHour = +pickParts[0] || 0;
  var pickHalf = (+pickParts[1] || 0) >= 30 ? 30 : 0;

  function setQuickTime(h, half) {
    var v = (h < 10 ? "0" : "") + h + ":" + (half ? "30" : "00");
    if (pickKind === "sleep") applySleep(v);
    else applyWake(v);
  }

  return html`<div class=${W.cx("sleep-picker", p.compact && "is-compact")} data-id=${pfx + "-sleep-picker"}>
    <div class="sleep-presets" data-id="sleep-presets">
      ${presets.map(function (pr) {
        var active = wake === pr.wake && sleep === pr.sleep;
        return html`<button type="button" key=${pr.id}
          class=${W.cx("sleep-preset-chip", active && "is-on")}
          data-id=${"sleep-preset-" + pr.id}
          onClick=${function () { applyPreset(pr.wake, pr.sleep); }}>
          <span>${pr.label}</span>
        </button>`;
      })}
    </div>

    <div class=${W.cx("sleep-sky-card", "is-dial", "is-focus-" + focus)} data-id="sleep-sky" data-focus=${focus}>
      <div class="sleep-dial-stage" dir="ltr">
        <svg ref=${ringRef} class="sleep-dial-svg" viewBox="0 0 240 240"
          onPointerDown=${onDialDown} onPointerMove=${onDialMove} onPointerUp=${onDialUp} onPointerCancel=${onDialUp}>
          <defs>
            <linearGradient id="dial-day-night" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stop-color="#f6df9d" stop-opacity="0.34" />
              <stop offset="48%" stop-color="#9cb5c9" stop-opacity="0.14" />
              <stop offset="100%" stop-color="#2c3e6b" stop-opacity="0.32" />
            </linearGradient>
          </defs>

          <circle cx=${cx} cy=${cy} r="62" fill="url(#dial-day-night)" />
          <line x1="58" y1=${cy} x2="182" y2=${cy} stroke="var(--line)" stroke-width="1" stroke-dasharray="3 3" opacity="0.65" />

          <g class="sleep-dial-marks" font-size="11" font-weight="600" fill="var(--ink-2)" text-anchor="middle">
            <text x=${cx} y="20">12 ${W.t("time.pm")}</text>
            <text x="223" y=${cy + 4}>6 ${W.t("time.pm")}</text>
            <text x=${cx} y="231">12 ${W.t("time.am")}</text>
            <text x="17" y=${cy + 4}>6 ${W.t("time.am")}</text>
          </g>

          <circle cx=${cx} cy=${cy} r=${R} fill="none" stroke="var(--surface-2)" stroke-width="20" />
          <path d=${awakePath} fill="none" stroke="var(--accent)" stroke-opacity="0.26" stroke-width="14" stroke-linecap="round" />
          <path d=${restPath} fill="none" stroke="#4f679d" stroke-width="18" stroke-linecap="round" class="sleep-rest-arc" />

          <g class=${W.cx("sleep-handle", "is-sleep", (focus === "sleep" || dragKind === "sleep") && "is-active")}
            data-id="sleep-moon"
            transform=${"translate(" + sleepPt.x + " " + sleepPt.y + ")"}
            onPointerDown=${function (ev) { startHandleDrag("sleep", ev); }}>
            <circle cx="0" cy="0" r="16" class="sleep-handle-bg is-moon" />
            <path d="M 3.2 -6.5 A 7 7 0 1 0 7.2 4.6 A 5.5 5.5 0 0 1 3.2 -6.5 Z" fill="#ffffff" />
          </g>

          <g class=${W.cx("sleep-handle", "is-wake", (focus === "wake" || dragKind === "wake") && "is-active")}
            data-id="sleep-sun"
            transform=${"translate(" + wakePt.x + " " + wakePt.y + ")"}
            onPointerDown=${function (ev) { startHandleDrag("wake", ev); }}>
            <circle cx="0" cy="0" r="16" class=${W.cx("sleep-handle-bg", wakeAtNight ? "is-night-wake" : "is-sun")} />
            ${wakeAtNight
              ? html`<path d="M0 -7.5 L1.8 -1.8 L7.5 0 L1.8 1.8 L0 7.5 L-1.8 1.8 L-7.5 0 L-1.8 -1.8 Z" fill="#1f2838" />`
              : html`<g stroke="#3d2800" stroke-width="1.6" stroke-linecap="round">
                  <circle cx="0" cy="0" r="4.6" fill="#3d2800" stroke="none" />
                  <line x1="0" y1="-7.2" x2="0" y2="-9.2" />
                  <line x1="0" y1="7.2" x2="0" y2="9.2" />
                  <line x1="-7.2" y1="0" x2="-9.2" y2="0" />
                  <line x1="7.2" y1="0" x2="9.2" y2="0" />
                </g>`}
          </g>
        </svg>

        <div class="sleep-dial-center">
          <span class="sleep-dial-hrs num">${W.t("sleep.center.hrs", { n: quietHrs })}</span>
        </div>
      </div>
      <p class="quiet sleep-dial-hint">${W.t("sleep.dial.hint")}</p>
    </div>

    <div class="panel sleep-rows-card">
      <div class=${W.cx("sleep-time-row", focus === "wake" && "is-active")} data-id=${pfx + "-wake"}>
        <button type="button" class="sleep-row-label" onClick=${function () { setFocus("wake"); setPickKind("wake"); }}>
          <span class="sleep-control-ic is-wake">${W.Icon({ name: "sunrise", size: 20 })}</span>
          <span class="sleep-control-title">${W.t("ob.wake")}</span>
        </button>
        <div class="sleep-row-stepper">
          <button type="button" class="sleep-nudge-btn" data-id=${pfx + "-wake-earlier"}
            aria-label=${W.t("time.earlier")}
            onClick=${function () { applyWake(W.shiftTime(wake, -30)); }}>
            ${W.Icon({ name: "minus", size: 22 })}
          </button>
          <button type="button" class="sleep-time-pill num" data-id=${pfx + "-wake-value"}
            onClick=${function () { setFocus("wake"); setPickKind("wake"); }}>
            <span>${W.timeLabel(wake)}</span>
          </button>
          <button type="button" class="sleep-nudge-btn" data-id=${pfx + "-wake-later"}
            aria-label=${W.t("time.later")}
            onClick=${function () { applyWake(W.shiftTime(wake, 30)); }}>
            ${W.Icon({ name: "add", size: 22 })}
          </button>
        </div>
      </div>

      <div class=${W.cx("sleep-time-row", focus === "sleep" && "is-active")} data-id=${pfx + "-sleeptime"}>
        <button type="button" class="sleep-row-label" onClick=${function () { setFocus("sleep"); setPickKind("sleep"); }}>
          <span class="sleep-control-ic is-sleep">${W.Icon({ name: "moon", size: 20 })}</span>
          <span class="sleep-control-title">${W.t("ob.sleep")}</span>
        </button>
        <div class="sleep-row-stepper">
          <button type="button" class="sleep-nudge-btn" data-id=${pfx + "-sleeptime-earlier"}
            aria-label=${W.t("time.earlier")}
            onClick=${function () { applySleep(W.shiftTime(sleep, -30)); }}>
            ${W.Icon({ name: "minus", size: 22 })}
          </button>
          <button type="button" class="sleep-time-pill num" data-id=${pfx + "-sleeptime-value"}
            onClick=${function () { setFocus("sleep"); setPickKind("sleep"); }}>
            <span>${W.timeLabel(sleep)}</span>
          </button>
          <button type="button" class="sleep-nudge-btn" data-id=${pfx + "-sleeptime-later"}
            aria-label=${W.t("time.later")}
            onClick=${function () { applySleep(W.shiftTime(sleep, 30)); }}>
            ${W.Icon({ name: "add", size: 22 })}
          </button>
        </div>
      </div>
    </div>

    <${W.Sheet} id="sleep-quick-sheet" popup=${true} open=${!!pickKind}
      title=${W.t(pickKind === "sleep" ? "sleep.pick.sleep" : "sleep.pick.wake")}
      onClose=${function () { setPickKind(null); }}
      footer=${html`<${W.Btn} kind="main" wide=${true} icon="check" label=${W.t("btn.done")} id="sleep-quick-done"
        onClick=${function () { setPickKind(null); }} />`}>
      <div class="sleep-quick-body">
        <div class="sleep-half-toggle">
          <button type="button" class=${W.cx("sleep-half-btn", pickHalf === 0 && "is-on")}
            data-id="sleep-half-00" onClick=${function () { setQuickTime(pickHour, 0); }}>
            ${W.t("sleep.half.00")}
          </button>
          <button type="button" class=${W.cx("sleep-half-btn", pickHalf === 30 && "is-on")}
            data-id="sleep-half-30" onClick=${function () { setQuickTime(pickHour, 30); }}>
            ${W.t("sleep.half.30")}
          </button>
        </div>
        <div class="sleep-hours-grid">
          ${Array.apply(null, { length: 24 }).map(function (_, h) {
            var lbl = ((h % 12) || 12) + " " + W.t(h < 12 ? "time.am" : "time.pm");
            var on = h === pickHour;
            return html`<button type="button" key=${h}
              class=${W.cx("sleep-hour-btn", "num", on && "is-on")}
              data-id=${"sleep-hour-" + h}
              onClick=${function () { setQuickTime(h, pickHalf); }}>
              ${lbl}
            </button>`;
          })}
        </div>
      </div>
    <//>
  </div>`;
};

function SleepSub(p) {
  var prefs = p.prefs;
  var wake = prefs.wake || "06:00";
  var sleep = prefs.sleep || "23:00";
  var mt = E.momentTimes(prefs);
  var momentPrev = [
    ["sunrise", "waking", mt.waking.start],
    ["sun", "morning", mt.morning.start],
    ["moon", "evening", mt.evening.start],
    ["bed", "sleep", mt.sleep.start]
  ];

  return html`<${SubShell} name="sleep" className="sleep-page"
    title=${W.t("ob.sleep.q")} sub=${W.t("ob.sleep.sub")}>
    <${W.SleepPicker} idPrefix="more" wake=${wake} sleep=${sleep}
      onWake=${function (v) { setPref("wake", { wake: v }); }}
      onSleep=${function (v) { setPref("sleep", { sleep: v }); }}
      onBoth=${function (w, s) { setPref("sleep-both", { wake: w, sleep: s }); }} />

    <div class="panel sleep-moments-preview" data-id="sleep-moments-preview">
      <p class="quiet sleep-moments-note">${W.t("sleep.auto.moments")}</p>
      <div class="sleep-moments-grid">
        ${momentPrev.map(function (m) {
          return html`<div key=${m[1]} class="sleep-moment-mini">
            <span class="sleep-moment-ic">${W.Icon({ name: m[0], size: 18 })}</span>
            <span class="sleep-moment-lbl">${W.t("moment." + m[1])}</span>
            <span class="sleep-moment-tm quiet num">${W.timeLabel(minToHhmm(m[2]))}</span>
          </div>`;
        })}
      </div>
    </div>
  <//>`;
}

function MoreSub(p) {
  var row = p.row, st = W.useApp(), ui = st.ui, eng = E.rollDay(st.eng, W.now());
  var prefs = eng.prefs || W.ANSWER_DEFAULTS;
  var txtSt = W.useState(""), txt = txtSt[0], setTxt = txtSt[1];

  if (row === "level") {
    var curLv = prefs.level || "some", curGoal = prefs.goal || "mix";
    return html`<${SubShell} name="level" title=${W.t("more.level.t")} sub=${W.t("ob.level.sub")}>
      <section class="today-sec">
        <h2 class="today-sec-title quiet">${W.t("ob.level.q")}</h2>
        <${W.Choice} id="more-level" value=${curLv}
          onChange=${function (v) {
            W.act("level", function (s) {
              s.eng = E.setLevel ? E.setLevel(E.rollDay(s.eng, W.now()), v) : s.eng;
            });
          }}
          options=${["new", "some", "daily"].map(function (k) {
            return { value: k, label: W.t("level." + k), sub: W.t("level." + k + ".sub") };
          })} />
      </section>
      <section class="today-sec">
        <h2 class="today-sec-title quiet">${W.t("ob.goal.q")}</h2>
        <${W.Choice} id="more-goal" value=${curGoal}
          onChange=${function (v) { setPref("goal", { goal: v }); }}
          options=${[
            { value: "mix", label: W.t("goal.mix"), icon: "sparkle" },
            { value: "day", label: W.t("goal.day"), icon: "adhkar" },
            { value: "moments", label: W.t("goal.moments"), icon: "sun" },
            { value: "sleep", label: W.t("goal.sleep"), icon: "moon" }
          ]} />
      </section>
    <//>`;
  }

  if (row === "freq") {
    return html`<${SubShell} name="freq" title=${W.t("ob.freq.q")} sub=${W.t("ob.freq.sub")}>
      <${W.Choice} id="more-freq" value=${prefs.freq || "hour"}
        onChange=${function (v) { setPref("freq", { freq: v }); }}
        options=${["few", "hour", "often"].map(function (k) { return { value: k, label: W.t("freq." + k) }; })} />
    <//>`;
  }

  if (row === "sleep") {
    return html`<${SleepSub} prefs=${prefs} />`;
  }

  if (row === "look") {
    var cs = prefs.cardSize || "small";
    return html`<${SubShell} name="look" title=${W.t("ob.try.pick")}>
      <${W.Choice} id="more-cardsize" value=${cs}
        onChange=${function (v) { setPref("cardSize", { cardSize: v }); }}
        options=${[
          { value: "small", label: W.t("ob.size.small"), sub: W.t("ob.size.small.sub"), icon: "card-small" },
          { value: "full", label: W.t("ob.size.full"), sub: W.t("ob.size.full.sub"), icon: "card-full" },
          { value: "banner", label: W.t("ob.size.banner"), sub: W.t("ob.size.banner.sub"), icon: "bell" }
        ]} />
      <section class="today-sec">
        <h2 class="today-sec-title quiet">${W.t("more.theme.q")}</h2>
        <${W.Choice} id="more-theme" value=${ui.theme}
          onChange=${function (v) { W.setTheme(v); }}
          options=${[
            { value: "light", label: W.t("more.theme.light"), icon: "sun" },
            { value: "dark", label: W.t("more.theme.dark"), icon: "moon" }
          ]} />
      </section>
    <//>`;
  }

  if (row === "sound" || row === "recite") {
    var rec = prefs.recite !== false ? "yes" : "no";
    var soundIcons = { soft: "sound", vibrate: "bell", silent: "sound-off" };
    return html`<${SubShell} name="sound" title=${W.t("more.sound.q")}>
      <section class="today-sec">
        <h2 class="today-sec-title quiet">${W.t("more.sound.bead.q")}</h2>
        <${W.Choice} id="more-sound" value=${prefs.sound || "soft"}
          onChange=${function (v) { setPref("sound", { sound: v }); }}
          options=${["soft", "vibrate", "silent"].map(function (k) {
            return { value: k, label: W.t("more.sound." + k), icon: soundIcons[k] || "sound" };
          })} />
      </section>

      <section class="today-sec">
        <h2 class="today-sec-title quiet">${W.t("ob.recite.q")}</h2>
        <p class="quiet more-sub-p">${W.t("ob.recite.sub")}</p>
        <${W.Choice} id="more-recite" value=${rec}
          onChange=${function (v) { setPref("recite", { recite: v === "yes" }); }}
          options=${[
            { value: "yes", label: W.t("ob.recite.yes"), sub: W.t("ob.recite.yes.sub"), icon: "sound" },
            { value: "no", label: W.t("ob.recite.no"), sub: W.t("ob.recite.no.sub"), icon: "sound-off" }
          ]} />
      </section>
    <//>`;
  }

  if (row === "lang") {
    return html`<${SubShell} name="lang" title=${W.t("ob.lang.q")}>
      <${W.Choice} id="more-lang" value=${ui.lang}
        onChange=${function (v) { W.setLang(v); }}
        options=${[
          { value: "ar", label: W.t("ob.lang.ar"), icon: "language" },
          { value: "en", label: W.t("ob.lang.en"), icon: "language" }
        ]} />
    <//>`;
  }

  if (row === "size") {
    var sample = W.LIB[0];
    var curSize = W.clamp(Number(ui.size) || 3, 1, 7);
    return html`<${SubShell} name="size" title=${W.t("more.size.q")} sub=${W.t("more.size.sub")}>
      <div class="panel size-slider-panel" data-id="more-size">
        <div class="size-slider-head">
          <span class="size-slider-lbl">${W.t("more.size." + curSize)}</span>
        </div>
        <div class="size-slider-row">
          <button type="button" class="size-step-btn" data-id="more-size-less" disabled=${curSize <= 1}
            aria-label=${W.t("step.less")} onClick=${function () { W.setSize(Math.max(1, curSize - 1)); }}>
            <span class="size-a-sm">A</span>
          </button>
          <input type="range" class="size-range" data-id="more-size-slider" aria-label=${W.t("more.size.q")}
            min="1" max="7" step="1" value=${curSize}
            onInput=${function (e) { W.setSize(Number(e.target.value)); }}
            onChange=${function (e) { W.setSize(Number(e.target.value)); }} />
          <button type="button" class="size-step-btn" data-id="more-size-more" disabled=${curSize >= 7}
            aria-label=${W.t("step.more")} onClick=${function () { W.setSize(Math.min(7, curSize + 1)); }}>
            <span class="size-a-lg">A</span>
          </button>
        </div>
        <div class="size-stages" role="radiogroup" aria-label=${W.t("more.size.q")}>
          ${[1, 2, 3, 4, 5, 6, 7].map(function (n) {
            var on = n === curSize;
            return html`<button type="button" key=${n} role="radio" aria-checked=${on ? "true" : "false"}
              class=${W.cx("size-stage-dot", on && "is-on")} data-id=${"more-size-" + n}
              onClick=${function () { W.setSize(n); }}>
              <span class="num">${n}</span>
            </button>`;
          })}
        </div>
      </div>
      <div class="panel size-preview-panel">
        <p class="title">${W.t("today.prog.title")}</p>
        <p class="quiet">${W.t("today.hint")}</p>
        <p class="dhikr" dir="rtl" lang="ar">${sample ? sample.ar : ""}</p>
      </div>
    <//>`;
  }

  if (row === "backup") {
    return html`<${SubShell} name="backup" title=${W.t("more.backup.t")} sub=${W.t("more.backup.p")}>
      <${W.Btn} kind="main" wide=${true} icon="backup" label=${W.t("more.backup.save")} id="backup-save"
        onClick=${function () { W.toast(W.t("more.backup.done")); }} />
      <${W.Btn} kind="soft" wide=${true} icon="return" label=${W.t("more.backup.restore")} id="backup-restore"
        onClick=${function () { W.toast(W.t("more.backup.done")); }} />
    <//>`;
  }

  if (row === "request" || row === "problem") {
    var pfx = "more." + row;
    return html`<${SubShell} name=${row} title=${W.t(pfx + ".t")} sub=${W.t(pfx + ".p")}>
      <textarea class="more-ta" rows="4" data-id=${row + "-input"} value=${txt}
        onInput=${function (e) { setTxt(e.target.value); }}></textarea>
      <${W.Btn} kind="main" wide=${true} icon="check" label=${W.t("more.send")} id=${row + "-send"}
        onClick=${function () { setTxt(""); W.toast(W.t("more.sent")); W.go("more"); }} />
    <//>`;
  }

  if (row === "updates") {
    return html`<${SubShell} name="updates" title=${W.t("more.updates.t")} sub=${W.t("more.updates.p")}>
      <${W.Btn} kind="main" wide=${true} icon="sparkle" label=${W.t("more.updates.btn")} id="updates-check"
        onClick=${function () { W.toast(W.t("more.updates.ok")); }} />
    <//>`;
  }

  return html`<${SubShell} name="about" title=${W.t("more.about.t")} sub=${W.t("more.about.p")}>
    <${W.Ornament} />
  <//>`;
}

function keyShift(key, delta) {
  var p = key.split("-");
  var d = new Date(+p[0], +p[1] - 1, +p[2] + delta);
  var two = function (n) { return (n < 10 ? "0" : "") + n; };
  return d.getFullYear() + "-" + two(d.getMonth() + 1) + "-" + two(d.getDate());
}

function dayScore(eng, key) {
  if (eng.day && eng.day.key === key) {
    if (W.dayTotals) {
      var dt = W.dayTotals(eng);
      var ratio = dt.goal > 0 ? dt.got / dt.goal : (dt.totalSaid > 0 ? 1 : 0);
      return { ratio: ratio, count: dt.totalSaid, complete: !!eng.day.complete };
    }
    var act = E.active(eng);
    if (!act.length) return { ratio: 0, count: 0, complete: false };
    var goal = 0, got = 0, totalSaid = 0;
    act.forEach(function (a) {
      var d = (eng.day.done && eng.day.done[a.id]) || 0;
      var ex = (eng.day.extra && eng.day.extra[a.id]) || 0;
      goal += a.target;
      got += Math.min(a.target, d);
      totalSaid += d + ex;
    });
    return { ratio: goal > 0 ? got / goal : 0, count: totalSaid, complete: !!eng.day.complete };
  }
  if (eng.history && eng.history[key]) {
    var h = eng.history[key];
    return { ratio: h.goal > 0 ? Math.min(1, h.got / h.goal) : (h.said > 0 ? 1 : 0), count: h.said || 0, complete: !!h.complete };
  }
  var filed = (eng.week && eng.week.days || []).filter(function (x) { return x.key === key; })[0];
  if (!filed || !filed.finished) return { ratio: 0, count: 0, complete: false };
  var ids = Object.keys(filed.finished);
  if (!ids.length) return { ratio: 0, count: 0, complete: false };
  var fin = 0, est = 0;
  ids.forEach(function (id) {
    if (filed.finished[id]) {
      fin++;
      var a = (eng.adhkar || []).filter(function (x) { return x.id === id; })[0];
      est += a ? a.target : 10;
    }
  });
  return { ratio: fin / ids.length, count: est, complete: fin === ids.length && ids.length > 0 };
}

function DaysHeroCard() {
  var mSt = W.useState(0), mIdx = mSt[0], setMIdx = mSt[1];
  var quotes = ["days.motivate.1", "days.motivate.2", "days.motivate.3"];
  var curQuote = W.t(quotes[mIdx % quotes.length]);

  return html`<section class="panel days-hero-card" data-id="days-hero">
    <div class="days-hero-art">
      <svg class="days-hero-svg" viewBox="0 0 360 132" aria-hidden="true">
        <defs>
          <linearGradient id="days-dawn-grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stop-color="var(--accent-soft)" />
            <stop offset="58%" stop-color="#e8dfbe" stop-opacity="0.72" />
            <stop offset="100%" stop-color="var(--surface-2)" />
          </linearGradient>
          <radialGradient id="days-sun-orb" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stop-color="#fff9e2" stop-opacity="0.95" />
            <stop offset="55%" stop-color="#ebd089" stop-opacity="0.42" />
            <stop offset="100%" stop-color="#ebd089" stop-opacity="0" />
          </radialGradient>
        </defs>
        <rect x="0" y="0" width="360" height="132" rx="18" fill="url(#days-dawn-grad)" />
        <circle cx="282" cy="44" r="44" fill="url(#days-sun-orb)" />
        <circle cx="282" cy="44" r="15" fill="#fff7d6" opacity="0.9" />

        <path d="M0 98 Q78 72 164 90 T360 82 L360 132 L0 132 Z" fill="var(--accent)" opacity="0.16" />
        <path d="M0 110 Q98 86 196 104 T360 98 L360 132 L0 132 Z" fill="var(--good)" opacity="0.24" />

        <g transform="translate(58, 102)" opacity="0.86">
          <g class="grove-sway">
            <path d="M0 0 L0 -22" stroke="#6b5842" stroke-width="2.6" stroke-linecap="round" />
            <ellipse cx="0" cy="-28" rx="13" ry="16" fill="var(--good)" opacity="0.82" />
            <ellipse cx="-4" cy="-31" rx="7" ry="9" fill="#88bc6c" opacity="0.55" />
          </g>
        </g>
        <g transform="translate(96, 107)" opacity="0.92">
          <g class="grove-sway is-alt">
            <path d="M0 0 L0 -17" stroke="#6b5842" stroke-width="2.2" stroke-linecap="round" />
            <ellipse cx="0" cy="-22" rx="10" ry="12.5" fill="var(--accent)" opacity="0.78" />
          </g>
        </g>
        <g transform="translate(232, 104)" opacity="0.85">
          <g class="grove-sway is-slow">
            <path d="M0 0 L0 -19" stroke="#6b5842" stroke-width="2.3" stroke-linecap="round" />
            <ellipse cx="0" cy="-25" rx="11" ry="14" fill="var(--good)" opacity="0.78" />
          </g>
        </g>

        <g transform="translate(166, 98)" fill="var(--accent)" opacity="0.42">
          <path d="M-18 8 L-18 -8 Q0 -26 18 -8 L18 8 Z" />
          <path d="M-8 8 L-8 -5 Q0 -15 8 -5 L8 8 Z" fill="var(--surface)" opacity="0.75" />
          <circle cx="0" cy="-22" r="2.2" />
        </g>
      </svg>
    </div>

    <div class="days-hero-body" data-id="days-motivate">
      <div class="days-hero-top">
        <span class="days-hero-badge">
          ${W.Icon({ name: "sparkle", size: 17 })}
          <span>${W.t("days.hero.badge")}</span>
        </span>
        <button type="button" class="cele-gem-next" data-id="days-motivate-next"
          onClick=${function () { setMIdx(mIdx + 1); }}>
          ${W.Icon({ name: "sparkle", size: 15 })}
          <span>${W.t("days.motivate.next")}</span>
        </button>
      </div>
      <h1 class="title days-hero-title">${W.t("days.hero.title")}</h1>
      <p class="days-motivate-quote" key=${mIdx}>${curQuote}</p>
    </div>
  </section>`;
}

function OasisQuoteCard() {
  return html`<section class="panel days-oasis-card" data-id="days-oasis">
    <svg class="days-oasis-svg" viewBox="0 0 108 88" aria-hidden="true">
      <rect x="0" y="0" width="108" height="88" rx="14" fill="var(--accent-soft)" />
      <path d="M 68 18 A 11 11 0 1 0 76 34 A 8.8 8.8 0 0 1 68 18 Z" fill="var(--accent)" opacity="0.82" />
      <circle cx="30" cy="24" r="1.6" fill="var(--accent)" opacity="0.55" />
      <circle cx="48" cy="16" r="1.3" fill="var(--good)" opacity="0.65" />
      <path d="M0 62 Q28 52 56 60 T108 58 L108 88 L0 88 Z" fill="var(--good)" opacity="0.22" />
      <path d="M18 72 H90 M28 79 H80" stroke="var(--accent)" stroke-width="1.5" stroke-linecap="round" opacity="0.4" />
      <g transform="translate(36, 63)">
        <g class="grove-sway">
          <path d="M0 0 L0 -18" stroke="#6b5842" stroke-width="2.2" stroke-linecap="round" />
          <ellipse cx="0" cy="-23" rx="9" ry="12" fill="var(--good)" opacity="0.85" />
        </g>
      </g>
    </svg>
    <div class="days-oasis-body">
      <span class="days-oasis-title">
        ${W.Icon({ name: "leaf", size: 17 })}
        <span>${W.t("days.oasis.title")}</span>
      </span>
      <p class="days-oasis-quote">${W.t("days.oasis.quote")}</p>
    </div>
  </section>`;
}

function ActivityCalendarCard(p) {
  var eng = p.eng, todayKey = p.todayKey, en = W.U().lang === "en";
  var offSt = W.useState(0), mOff = offSt[0], setMOff = offSt[1];
  var selSt = W.useState(null), selKey = selSt[0], setSelKey = selSt[1];

  var tp = todayKey.split("-");
  var viewDate = new Date(+tp[0], +tp[1] - 1 + mOff, 1);
  var yr = viewDate.getFullYear(), mo = viewDate.getMonth();
  var daysInMonth = new Date(yr, mo + 1, 0).getDate();
  var two = function (n) { return (n < 10 ? "0" : "") + n; };

  var monthLabel = yr + "-" + two(mo + 1);
  try {
    monthLabel = viewDate.toLocaleDateString(en ? "en-GB" : "ar-EG-u-nu-latn", { month: "long", year: "numeric" });
  } catch (e) { /* keep fallback */ }

  /* Saturday-first weekday index: Sat=0, Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6 */
  var startPad = (new Date(yr, mo, 1).getDay() + 1) % 7;

  var dayItems = [];
  var monthTotal = 0, peakCount = 1;
  for (var d = 1; d <= daysInMonth; d++) {
    var k = yr + "-" + two(mo + 1) + "-" + two(d);
    var sc = dayScore(eng, k);
    monthTotal += sc.count;
    if (sc.count > peakCount) peakCount = sc.count;
    dayItems.push({ key: k, day: d, sc: sc });
  }

  function isActiveKey(k) {
    return dayScore(eng, k).count > 0;
  }

  var cells = [];
  for (var pad = 0; pad < startPad; pad++) {
    cells.push({ empty: true, id: "pad-" + pad, col: pad });
  }
  dayItems.forEach(function (item, idx) {
    var col = (startPad + idx) % 7;
    var cnt = item.sc.count;
    var intensity = cnt > 0 ? Math.max(item.sc.ratio, cnt / peakCount) : 0;
    var lv = cnt <= 0 ? 0
      : (item.sc.complete || intensity >= 0.85) ? 4
      : intensity >= 0.55 ? 3
      : intensity >= 0.28 ? 2 : 1;

    var curActive = cnt > 0;
    var prevActive = curActive && isActiveKey(keyShift(item.key, -1));
    var nextActive = curActive && isActiveKey(keyShift(item.key, 1));
    var isChain = curActive && (prevActive || nextActive);
    var joinPrev = isChain && col > 0 && prevActive;
    var joinNext = isChain && col < 6 && nextActive;
    var wrapPrev = isChain && col === 0 && prevActive;
    var wrapNext = isChain && col === 6 && nextActive;

    cells.push({
      empty: false,
      key: item.key,
      day: item.day,
      count: cnt,
      lv: lv,
      col: col,
      isToday: item.key === todayKey,
      isChain: isChain,
      joinPrev: joinPrev,
      joinNext: joinNext,
      wrapPrev: wrapPrev,
      wrapNext: wrapNext
    });
  });

  var activeSelKey = selKey || todayKey;
  var selScore = dayScore(eng, activeSelKey);
  var selDayNum = Number(String(activeSelKey).split("-")[2] || 1);

  return html`<section class="panel days-card days-cal-card" data-id="days-calendar">
    <div class="days-head">
      <div>
        <h2 class="title days-sec-title">${W.t("days.cal.title")}</h2>
        <span class="quiet num">${W.t("days.total", { n: monthTotal })}</span>
      </div>
      <div class="days-cal-nav">
        <button type="button" class="cal-nav-btn" data-id="days-cal-prev" aria-label=${W.t("card.prev")}
          onClick=${function () { setMOff(mOff - 1); setSelKey(null); }}>
          ${W.Icon({ name: "back", size: 18 })}
        </button>
        <span class="days-cal-month num">${monthLabel}</span>
        <button type="button" class="cal-nav-btn" data-id="days-cal-next" disabled=${mOff >= 0} aria-label=${W.t("card.next")}
          onClick=${function () { setMOff(Math.min(0, mOff + 1)); setSelKey(null); }}>
          ${W.Icon({ name: "forward", size: 18 })}
        </button>
      </div>
    </div>

    <div class="cal-weekdays" aria-hidden="true">
      ${[0, 1, 2, 3, 4, 5, 6].map(function (w) {
        return html`<span key=${w} class="cal-wd quiet">${W.t("days.cal.wd." + w)}</span>`;
      })}
    </div>

    <div class="cal-grid" data-id="days-cal-grid">
      ${cells.map(function (c) {
        if (c.empty) return html`<span key=${c.id} class="cal-slot is-empty" aria-hidden="true"></span>`;
        var selected = c.key === activeSelKey;
        return html`<div key=${c.key} class=${W.cx(
          "cal-slot",
          c.isChain && "is-chain",
          c.joinPrev && "join-prev",
          c.joinNext && "join-next",
          c.wrapPrev && "wrap-prev",
          c.wrapNext && "wrap-next"
        )}>
          <button type="button"
            class=${W.cx("cal-cell", "is-lv-" + c.lv, c.isToday && "is-today", selected && "is-selected")}
            data-id=${"cal-day-" + c.key}
            data-level=${c.lv}
            onClick=${function () { setSelKey(c.key); }}>
            <span class="cal-day-num num">${c.day}</span>
          </button>
          ${c.joinNext ? html`<span class="cal-chain-link" data-id="cal-chain-link" aria-hidden="true">
            ${W.Icon({ name: "link", size: 11 })}
          </span>` : null}
          ${c.wrapNext ? html`<span class="cal-chain-link is-wrap" data-id="cal-chain-link" aria-hidden="true">
            ${W.Icon({ name: "link", size: 10 })}
          </span>` : null}
        </div>`;
      })}
    </div>

    <div class="cal-foot">
      <div class="cal-legend" aria-hidden="true">
        <span class="quiet">${W.t("days.cal.less")}</span>
        ${[0, 1, 2, 3, 4].map(function (lv) {
          return html`<i key=${lv} class=${"cal-swatch is-lv-" + lv}></i>`;
        })}
        <span class="quiet">${W.t("days.cal.more")}</span>
      </div>
      <span class="cal-sel-pill num" data-id="days-cal-info">
        ${selScore.count > 0
          ? W.t("days.cal.selected", { d: selDayNum, n: selScore.count })
          : W.t("days.cal.selected.zero", { d: selDayNum })}
      </span>
    </div>

    <div class="cal-chain-note quiet">
      <span class="cal-note-link">${W.Icon({ name: "link", size: 15 })}</span>
      <span>${W.t("days.cal.chain")}</span>
    </div>
  </section>`;
}

function LivingGroveSection(p) {
  if (!W.LivingGrove || !W.streakStats) return null;
  var st = W.streakStats(p.eng, W.now());
  var allTotal = p.allTotal || 0;
  var info = W.groveState ? W.groveState(st.streak, st.idleDays, allTotal) : { stage: "seed" };
  var stages = ["seed", "sprout", "sapling", "tree", "field"];

  return html`<section class="panel days-card days-grove-card" data-id="days-grove">
    <div class="days-head">
      <h2 class="title days-sec-title">${W.t("days.grove.title")}</h2>
      <span class="days-grove-streak num">${st.streak} ${W.t("today.prog.streak")}</span>
    </div>
    <${W.LivingGrove} streak=${st.streak} idleDays=${st.idleDays} lifetime=${allTotal} compact=${false} />
    <p class="quiet days-grove-caption">${W.t("grove.stage." + info.stage)}</p>
    <div class="grove-stages-strip" data-id="days-grove-stages">
      ${stages.map(function (sg) {
        var active = info.stage === sg || (info.stage === "grove" && sg === "field");
        return html`<div key=${sg} class=${W.cx("grove-stage-chip", active && "is-on")}>
          <${W.LivingGrove} stageOverride=${sg} compact=${true} mini=${true} />
          <span class="grove-stage-lbl">${W.t("grove.short." + sg)}</span>
        </div>`;
      })}
    </div>
  </section>`;
}

function BarStrip(p) {
  var total = 0;
  var bars = [];
  for (var i = p.count - 1; i >= 0; i--) {
    var k = keyShift(p.todayKey, -i);
    var sc = dayScore(p.eng, k);
    total += sc.count;
    bars.push({ key: k, ratio: sc.ratio, dayNum: Number(k.split("-")[2]) });
  }
  return html`<section class="panel days-card" data-id=${p.id}>
    <div class="days-head">
      <h2 class="title days-sec-title">${p.title}</h2>
      <span class="quiet num">${W.t("days.total", { n: total })}</span>
    </div>
    <div class=${W.cx("days-bars", p.count > 10 && "is-dense")}>
      ${bars.map(function (b) {
        var h = b.ratio > 0 ? Math.max(16, Math.round(b.ratio * 100)) : 5;
        return html`<div key=${b.key} class="days-col" data-day=${b.key}>
          <div class="days-track">
            <span class=${W.cx("days-bar", b.ratio > 0 && "is-lit")} style=${{ height: h + "%" }}></span>
          </div>
          ${p.count <= 7 ? html`<span class="days-lbl quiet num">${b.dayNum}</span>` : null}
        </div>`;
      })}
    </div>
  </section>`;
}

function YearStrip(p) {
  var tp = p.todayKey.split("-"), y0 = +tp[0], m0 = +tp[1];
  var months = [];
  for (var i = 11; i >= 0; i--) {
    var d = new Date(y0, m0 - 1 - i, 1);
    var ym = d.getFullYear() + "-" + (d.getMonth() + 1 < 10 ? "0" : "") + (d.getMonth() + 1);
    months.push({ ym: ym, num: d.getMonth() + 1, count: 0 });
  }
  var mMap = {};
  months.forEach(function (m) { mMap[m.ym] = m; });

  var seen = {};
  if (p.eng.day && p.eng.day.key) {
    seen[p.eng.day.key] = true;
    var ymNow = p.eng.day.key.slice(0, 7);
    if (mMap[ymNow]) mMap[ymNow].count += dayScore(p.eng, p.eng.day.key).count;
  }
  Object.keys(p.eng.history || {}).forEach(function (k) {
    if (seen[k]) return;
    seen[k] = true;
    var ym = k.slice(0, 7);
    if (mMap[ym]) mMap[ym].count += dayScore(p.eng, k).count;
  });
  (p.eng.week && p.eng.week.days || []).forEach(function (fd) {
    if (!fd.key || seen[fd.key]) return;
    seen[fd.key] = true;
    var ym = fd.key.slice(0, 7);
    if (mMap[ym]) mMap[ym].count += dayScore(p.eng, fd.key).count;
  });

  var yearTotal = months.reduce(function (acc, m) { return acc + m.count; }, 0);
  var peak = Math.max(1, months.reduce(function (mx, m) { return Math.max(mx, m.count); }, 0));

  return html`<section class="panel days-card" data-id="days-year">
    <div class="days-head">
      <h2 class="title days-sec-title">${W.t("days.year")}</h2>
      <span class="quiet num">${W.t("days.total", { n: yearTotal })}</span>
    </div>
    <div class="days-bars is-year">
      ${months.map(function (m) {
        var h = m.count > 0 ? Math.max(16, Math.round((m.count / peak) * 100)) : 5;
        return html`<div key=${m.ym} class="days-col" data-month=${m.ym}>
          <div class="days-track">
            <span class=${W.cx("days-bar", m.count > 0 && "is-lit")} style=${{ height: h + "%" }}></span>
          </div>
          <span class="days-lbl quiet num">${m.num}</span>
        </div>`;
      })}
    </div>
  </section>`;
}

function computeAllTimeSummary(eng) {
  var keys = {};
  if (eng.day && eng.day.key) keys[eng.day.key] = true;
  Object.keys(eng.history || {}).forEach(function (k) { keys[k] = true; });
  (eng.week && eng.week.days || []).forEach(function (d) { if (d.key) keys[d.key] = true; });

  var sumDays = 0, activeDays = 0, completeDays = 0;
  Object.keys(keys).forEach(function (k) {
    var sc = dayScore(eng, k);
    sumDays += sc.count;
    if (sc.count > 0) activeDays++;
    if (sc.complete) completeDays++;
  });
  return {
    allTotal: Math.max(eng.lifetime || 0, sumDays),
    activeDays: activeDays,
    completeDays: completeDays
  };
}

function AllTimeCard(p) {
  var sum = p.summary || computeAllTimeSummary(p.eng);

  return html`<section class="panel days-card days-all" data-id="days-all">
    <div class="days-head">
      <h2 class="title days-sec-title">${W.t("days.all")}</h2>
      ${W.Icon({ name: "sparkle", size: 22 })}
    </div>
    <div class="stats-grid">
      <div class="stat-box">
        <span class="stat-val num m-count">${sum.allTotal}</span>
        <span class="stat-lbl quiet">${W.t("days.all.total")}</span>
      </div>
      <div class="stat-box">
        <span class="stat-val num m-count">${sum.activeDays}</span>
        <span class="stat-lbl quiet">${W.t("days.all.days")}</span>
      </div>
      <div class="stat-box">
        <span class="stat-val num m-count">${sum.completeDays}</span>
        <span class="stat-lbl quiet">${W.t("days.all.complete")}</span>
      </div>
    </div>
  </section>`;
}

function DaysScreen() {
  var eng = E.rollDay(W.useApp().eng, W.now());
  var todayKey = E.dayKey(W.now(), eng.prefs || W.ANSWER_DEFAULTS);
  var summary = computeAllTimeSummary(eng);

  return html`<div class="more-page" data-id="days-page">
    <${DaysHeroCard} />
    <${ActivityCalendarCard} eng=${eng} todayKey=${todayKey} />
    <${LivingGroveSection} eng=${eng} allTotal=${summary.allTotal} />
    <${AllTimeCard} eng=${eng} summary=${summary} />
    <${BarStrip} id="days-7" title=${W.t("days.week")} count=${7} eng=${eng} todayKey=${todayKey} />
    <${OasisQuoteCard} />
    <${BarStrip} id="days-30" title=${W.t("days.month")} count=${30} eng=${eng} todayKey=${todayKey} />
    <${YearStrip} eng=${eng} todayKey=${todayKey} />
    <p class="today-hint quiet">${W.t("days.private")}</p>
  </div>`;
}

W.screen("more", function MoreScreen(p) {
  return p.arg ? html`<${MoreSub} key=${p.arg} row=${p.arg} />` : html`<${MoreHome} />`;
});
W.screen("days", DaysScreen);
})();
