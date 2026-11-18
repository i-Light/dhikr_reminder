/* today.js: the Today companion hub (Comments #11-#13, #29, #30).
   Single unified action & moments card, Adaptive Level tracker (prog-stat-moments),
   Living Seed-to-Field continuously swaying artwork (prog-stat-streak),
   Friday Sunnahs, Emotional Doorways, Hadith & Motivation, Tutorial, and Quick Access. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

var MOMENTS = ["waking", "morning", "evening", "sleep"];
var M_ICONS = { waking: "sunrise", morning: "sun", evening: "moon", sleep: "bed" };

function openCount(id) {
  if (!id) return;
  W.U().backRoute = "today";
  W.go("count/" + id);
}

function curDayMin(ts, prefs) {
  var d = new Date(ts), m = d.getHours() * 60 + d.getMinutes();
  return m < E.dayStartMin(prefs) ? m + 1440 : m;
}

function upcomingLabel(name, diffMin) {
  var d = Math.max(1, Math.round(diffMin));
  if (d < 60) return W.t("today.moment.in.min", { name: name, n: d });
  var h = Math.floor(d / 60), rem = d % 60;
  if (rem === 0) return W.t("today.moment.in.hr", { name: name, h: h });
  return W.t("today.moment.in.hrmin", { name: name, h: h, m: rem });
}

function dueSinceLabel(name, diffMin) {
  var d = Math.max(1, Math.round(diffMin));
  if (d < 60) return W.t("today.moment.due.min", { name: name, n: d });
  return W.t("today.moment.due.hr", { name: name, h: Math.max(1, Math.round(d / 60)) });
}

function agoShort(diffMin) {
  var d = Math.max(1, Math.round(diffMin));
  if (d < 60) return W.t("today.ago.min", { n: d });
  return W.t("today.ago.hr", { h: Math.max(1, Math.round(d / 60)) });
}

function keyShift(key, delta) {
  var p = String(key || "").split("-");
  if (p.length < 3) return key;
  var d = new Date(+p[0], +p[1] - 1, +p[2] + delta);
  var two = function (n) { return (n < 10 ? "0" : "") + n; };
  return d.getFullYear() + "-" + two(d.getMonth() + 1) + "-" + two(d.getDate());
}

function hadActivityOn(eng, key, todaySaid) {
  if (eng.day && eng.day.key === key) return todaySaid > 0;
  if (eng.history && eng.history[key] && (eng.history[key].said || 0) > 0) return true;
  var filed = ((eng.week && eng.week.days) || []).filter(function (x) { return x.key === key; })[0];
  if (!filed || !filed.finished) return false;
  return Object.keys(filed.finished).some(function (id) { return !!filed.finished[id]; });
}

function computeStreak(eng, todayKey, todaySaid) {
  var streak = todaySaid > 0 ? 1 : 0;
  for (var i = 1; i <= 60; i++) {
    var k = keyShift(todayKey, -i);
    if (hadActivityOn(eng, k, 0)) streak++;
    else break;
  }
  return streak;
}

W.dayTotals = function (eng) {
  var e = eng || {}, day = e.day || {}, act = E.active(e);
  var actMap = {}, got = 0, goal = 0, listExtra = 0, otherSaid = 0;
  act.forEach(function (a) {
    actMap[a.id] = true;
    var d = (day.done && day.done[a.id]) || 0;
    var ex = (day.extra && day.extra[a.id]) || 0;
    got += Math.min(a.target, d);
    goal += a.target;
    listExtra += ex;
  });
  var otherIds = {};
  Object.keys(day.done || {}).forEach(function (id) { if (!actMap[id]) otherIds[id] = true; });
  Object.keys(day.extra || {}).forEach(function (id) { if (!actMap[id]) otherIds[id] = true; });
  Object.keys(otherIds).forEach(function (id) {
    otherSaid += ((day.done && day.done[id]) || 0) + ((day.extra && day.extra[id]) || 0);
  });
  if (day.friday && day.friday.salawat) otherSaid += day.friday.salawat;
  return {
    got: got,
    goal: goal,
    listExtra: listExtra,
    otherSaid: otherSaid,
    totalSaid: got + listExtra + otherSaid
  };
};

W.streakStats = function (eng, nowTs) {
  var e = eng || {};
  var prefs = e.prefs || W.ANSWER_DEFAULTS || { wake: "06:00", sleep: "23:00" };
  var todaySaid = W.dayTotals(e).totalSaid;
  var todayKeyStr = (e.day && e.day.key) || E.dayKey(nowTs, prefs);
  var streak = computeStreak(e, todayKeyStr, todaySaid);
  var idleDays = 0;
  if (streak === 0) {
    var recorded = {};
    Object.keys(e.history || {}).forEach(function (k) { recorded[k] = true; });
    ((e.week && e.week.days) || []).forEach(function (d) { if (d && d.key) recorded[d.key] = true; });
    for (var i = 1; i <= 60; i++) {
      var k = keyShift(todayKeyStr, -i);
      if (!recorded[k]) break;
      if (!hadActivityOn(e, k, 0)) idleDays++;
      else break;
    }
    idleDays = Math.max(idleDays, E.awayDays(e));
  }
  return { streak: streak, idleDays: idleDays, todaySaid: todaySaid, todayKey: todayKeyStr };
};

/* ---------- Comment #29: Adaptive, consistent Level system from cumulative total dhikr ---------- */
W.computeLevel = function (eng, totalSaidToday) {
  var e = eng || {};
  var prefs = e.prefs || W.ANSWER_DEFAULTS || { level: "some" };
  var keys = {};
  if (e.day && e.day.key) keys[e.day.key] = true;
  Object.keys(e.history || {}).forEach(function (k) { keys[k] = true; });
  var sumHist = 0, pastSaid = 0, pastActiveDays = 0;
  Object.keys(keys).forEach(function (k) {
    if (e.day && k === e.day.key) {
      sumHist += totalSaidToday || 0;
    } else if (e.history && e.history[k]) {
      var s = e.history[k].said || 0;
      sumHist += s;
      if (s > 0) { pastSaid += s; pastActiveDays++; }
    }
  });
  var total = Math.max(e.lifetime || 0, sumHist, totalSaidToday || 0);

  /* Adaptive pace unit: gentler thresholds for light users, naturally higher for heavy daily users,
     and invariant to intra-day taps so progress never jumps erratically mid-session. */
  var baseByLevel = prefs.level === "new" ? 35 : prefs.level === "daily" ? 175 : 85;
  var actGoal = 0;
  E.active(e).forEach(function (a) { actGoal += a.target || 0; });
  if (actGoal <= 0) actGoal = baseByLevel;
  var histAvg = pastActiveDays > 0 ? (pastSaid / pastActiveDays) : actGoal;
  var rawPace = baseByLevel * 0.45 + actGoal * 0.35 + histAvg * 0.20;
  var paceUnit = W.clamp(Math.round(rawPace / 5) * 5, 25, 300);

  function stepNeed(lv) {
    return Math.max(15, Math.round((paceUnit * (0.75 + 0.35 * Math.pow(lv, 1.25))) / 5) * 5);
  }

  var level = 1;
  var rem = total;
  var need = stepNeed(1);
  while (rem >= need && level < 999) {
    rem -= need;
    level++;
    need = stepNeed(level);
  }
  var pct = Math.min(100, Math.round((rem / Math.max(1, need)) * 100));
  return {
    level: level,
    total: total,
    into: rem,
    need: need,
    left: Math.max(0, need - rem),
    pct: pct,
    paceUnit: paceUnit
  };
};

/* ---------- Comment #30: Progressive continuously swaying Seed -> Tree -> Field of Trees artwork ---------- */
W.groveState = function (streak, idleDays, lifetime) {
  var st = streak || 0, idle = idleDays || 0, life = lifetime || 0;
  if (st <= 0 && idle >= 5) return { stage: "dormant", tone: "dormant", hadGrove: life >= 240 };
  if (st <= 0 && idle >= 2) return { stage: "wilt", tone: "wilt", hadGrove: life >= 240 };
  if (st <= 0) return { stage: "seed", tone: "lush", hadGrove: false };
  if (st === 1) return { stage: "sprout", tone: "lush", hadGrove: false };
  if (st <= 3) return { stage: "sapling", tone: "lush", hadGrove: false };
  if (st <= 5) return { stage: "tree", tone: "lush", hadGrove: false };
  if (st <= 7) return { stage: "grove", tone: "lush", hadGrove: true };
  return { stage: "field", tone: "lush", hadGrove: true };
};

function TreeUnit(p) {
  var x = p.x, y = p.y, sc = p.scale || 1, cls = p.sway || "", droopy = !!p.droopy;
  if (droopy) {
    return html`<g transform=${"translate(" + x + " " + y + ") scale(" + sc + ")"}>
      <g class=${W.cx("grove-sway", "is-gentle", cls)}>
        <path class="gv-trunk" d="M-1.5 0 Q0.5 -8 2.8 -16 L4.2 -15.5 Q2 -7 1.4 0 Z" />
        <g transform="translate(3.2 -17.5)">
          <g class="grove-canopy-sway is-gentle">
            <ellipse class="gv-leaf-deep" cx="-4.5" cy="2.5" rx="6.2" ry="4.6" transform="rotate(18 -4.5 2.5)" />
            <ellipse class="gv-leaf-mid" cx="4.5" cy="3" rx="6" ry="4.4" transform="rotate(-16 4.5 3)" />
            <ellipse class="gv-leaf-hi" cx="0.5" cy="-1.5" rx="6.8" ry="5" transform="rotate(8 0.5 -1.5)" />
          </g>
        </g>
      </g>
    </g>`;
  }
  return html`<g transform=${"translate(" + x + " " + y + ") scale(" + sc + ")"}>
    <g class=${W.cx("grove-sway", cls)}>
      <path class="gv-trunk" d="M-1.9 0 Q-1.2 -9 -0.9 -19 L0.9 -19 Q1.2 -9 1.9 0 Z" />
      <path class="gv-branch" d="M-0.4 -12 L-4.8 -16.5 M0.4 -14 L4.8 -18.5" fill="none" stroke-width="1.3" stroke-linecap="round" />
      <g transform="translate(0 -23.5)">
        <g class="grove-canopy-sway">
          <circle class="gv-leaf-deep" cx="-6.4" cy="1.8" r="7.2" />
          <circle class="gv-leaf-deep" cx="6.4" cy="1.8" r="7.2" />
          <circle class="gv-leaf-mid" cx="0" cy="-3.4" r="9" />
          <ellipse class="gv-leaf-hi" cx="-2.4" cy="-6" rx="5" ry="3.8" />
          ${p.buds ? html`<g class="gv-buds">
            <circle cx="-5.5" cy="-2" r="1.2" />
            <circle cx="5.2" cy="-3.5" r="1.2" />
            <circle cx="1.2" cy="-8.5" r="1.1" />
          </g>` : null}
        </g>
      </g>
    </g>
  </g>`;
}

W.LivingGrove = function LivingGrove(p) {
  var info = p.stageOverride
    ? { stage: p.stageOverride, tone: (p.stageOverride === "wilt" || p.stageOverride === "dormant") ? p.stageOverride : "lush", hadGrove: false }
    : W.groveState(p.streak, p.idleDays, p.lifetime);
  var stage = info.stage;
  var wide = !p.compact;
  var vb = wide ? "0 0 280 98" : "0 0 116 54";

  function renderPlantsCompact() {
    if (stage === "seed") {
      return html`<g transform="translate(58 46)">
        <ellipse class="gv-soil-patch" cx="0" cy="1.5" rx="13" ry="3.2" />
        <g class="grove-seed-sway">
          <ellipse class="gv-seed" cx="0" cy="-3.2" rx="6.2" ry="4.4" transform="rotate(-14 0 -3.2)" />
          <path class="gv-stem" d="M1.5 -5.8 Q2.8 -11 5.5 -13.5" fill="none" stroke-width="1.8" stroke-linecap="round" />
          <ellipse class="gv-leaf-hi" cx="6.6" cy="-14.2" rx="3.2" ry="1.9" transform="rotate(-28 6.6 -14.2)" />
        </g>
      </g>`;
    }
    if (stage === "sprout") {
      return html`<g transform="translate(58 47)">
        <ellipse class="gv-soil-patch" cx="0" cy="1" rx="12" ry="2.8" />
        <g class="grove-sway">
          <ellipse class="gv-seed" cx="-1.5" cy="-1.5" rx="4.2" ry="2.8" transform="rotate(-18 -1.5 -1.5)" />
          <path class="gv-stem" d="M0 0 Q-1.2 -10 0.8 -20" fill="none" stroke-width="2.2" stroke-linecap="round" />
          <g transform="translate(0.6 -18)">
            <g class="grove-canopy-sway">
              <path class="gv-leaf-mid" d="M-0.4 3 Q-10.5 0 -9.5 -7.5 Q-1.5 -6 -0.4 3 Z" />
              <path class="gv-leaf-hi" d="M0.4 0 Q10.5 -3.5 9.5 -11 Q1.5 -9 0.4 0 Z" />
            </g>
          </g>
        </g>
      </g>`;
    }
    if (stage === "sapling") {
      return html`<g transform="translate(58 48)">
        <g class="grove-sway">
          <path class="gv-trunk" d="M-1.3 0 L-0.7 -22 L0.7 -22 L1.3 0 Z" />
          <path class="gv-branch" d="M-0.3 -12 L-5 -16 M0.3 -15 L5 -19" fill="none" stroke-width="1.3" stroke-linecap="round" />
          <g transform="translate(0 -22)">
            <g class="grove-canopy-sway">
              <ellipse class="gv-leaf-deep" cx="-6" cy="3.5" rx="5.5" ry="4.2" transform="rotate(-18 -6 3.5)" />
              <ellipse class="gv-leaf-deep" cx="6" cy="2" rx="5.5" ry="4.2" transform="rotate(18 6 2)" />
              <circle class="gv-leaf-mid" cx="0" cy="-3" r="6.8" />
              <ellipse class="gv-leaf-hi" cx="-1.8" cy="-5" rx="3.8" ry="2.8" />
            </g>
          </g>
        </g>
      </g>`;
    }
    if (stage === "tree") {
      return html`<${TreeUnit} x=${58} y=${49} scale=${1.08} buds=${true} />`;
    }
    if (stage === "grove") {
      return html`<${W.R.Fragment}>
        <${TreeUnit} x=${30} y=${47} scale=${0.74} sway="is-alt" />
        <${TreeUnit} x=${86} y=${47.5} scale=${0.78} sway="is-slow" />
        <${TreeUnit} x=${58} y=${49.5} scale=${1.02} buds=${true} />
      <//>`;
    }
    if (stage === "field") {
      return html`<${W.R.Fragment}>
        <${TreeUnit} x=${16} y=${44.5} scale=${0.52} sway="is-slow" />
        <${TreeUnit} x=${44} y=${43} scale=${0.58} sway="is-alt" />
        <${TreeUnit} x=${73} y=${43.5} scale=${0.56} />
        <${TreeUnit} x=${101} y=${45} scale=${0.5} sway="is-alt" />
        <${TreeUnit} x=${29} y=${49} scale=${0.8} sway="is-alt" />
        <${TreeUnit} x=${59} y=${50} scale=${0.94} sway="is-slow" buds=${true} />
        <${TreeUnit} x=${88} y=${49} scale=${0.78} />
      <//>`;
    }
    if (stage === "wilt") {
      return info.hadGrove
        ? html`<${W.R.Fragment}>
            <${TreeUnit} x=${32} y=${47.5} scale=${0.58} sway="is-alt" droopy=${true} />
            <${TreeUnit} x=${84} y=${48} scale=${0.56} sway="is-slow" droopy=${true} />
            <${TreeUnit} x=${57} y=${49.5} scale=${0.76} droopy=${true} />
          <//>`
        : html`<${TreeUnit} x=${57} y=${49} scale=${0.8} droopy=${true} />`;
    }
    /* dormant: noticeably smaller, calm grayish-greenish & yellowish-olive resting state */
    return html`<${W.R.Fragment}>
      ${info.hadGrove ? html`<${TreeUnit} x=${35} y=${48} scale=${0.44} sway="is-alt" droopy=${true} />` : null}
      ${info.hadGrove ? html`<${TreeUnit} x=${81} y=${48.5} scale=${0.42} sway="is-slow" droopy=${true} />` : null}
      <${TreeUnit} x=${57} y=${49.5} scale=${0.6} droopy=${true} />
      <ellipse class="gv-fallen-leaf" cx="46" cy="50" rx="2.6" ry="1.2" transform="rotate(-12 46 50)" />
      <ellipse class="gv-fallen-leaf" cx="70" cy="50.5" rx="2.4" ry="1.1" transform="rotate(15 70 50.5)" />
    <//>`;
  }

  function renderPlantsWide() {
    if (stage === "seed") {
      return html`<g transform="translate(140 82)">
        <ellipse class="gv-soil-patch" cx="0" cy="2" rx="22" ry="5" />
        <g class="grove-seed-sway">
          <ellipse class="gv-seed" cx="0" cy="-5" rx="10" ry="7" transform="rotate(-14 0 -5)" />
          <path class="gv-stem" d="M2 -9 Q5 -18 9.5 -22" fill="none" stroke-width="2.6" stroke-linecap="round" />
          <ellipse class="gv-leaf-hi" cx="11.5" cy="-23.5" rx="5.2" ry="3" transform="rotate(-28 11.5 -23.5)" />
        </g>
      </g>`;
    }
    if (stage === "sprout") {
      return html`<g transform="translate(140 83) scale(1.55)">
        <ellipse class="gv-soil-patch" cx="0" cy="1" rx="13" ry="2.8" />
        <g class="grove-sway">
          <ellipse class="gv-seed" cx="-1.5" cy="-1.5" rx="4.2" ry="2.8" transform="rotate(-18 -1.5 -1.5)" />
          <path class="gv-stem" d="M0 0 Q-1.2 -10 0.8 -20" fill="none" stroke-width="2.2" stroke-linecap="round" />
          <g transform="translate(0.6 -18)">
            <g class="grove-canopy-sway">
              <path class="gv-leaf-mid" d="M-0.4 3 Q-10.5 0 -9.5 -7.5 Q-1.5 -6 -0.4 3 Z" />
              <path class="gv-leaf-hi" d="M0.4 0 Q10.5 -3.5 9.5 -11 Q1.5 -9 0.4 0 Z" />
            </g>
          </g>
        </g>
      </g>`;
    }
    if (stage === "sapling") {
      return html`<g transform="translate(140 85) scale(1.65)">
        <g class="grove-sway">
          <path class="gv-trunk" d="M-1.3 0 L-0.7 -22 L0.7 -22 L1.3 0 Z" />
          <path class="gv-branch" d="M-0.3 -12 L-5 -16 M0.3 -15 L5 -19" fill="none" stroke-width="1.3" stroke-linecap="round" />
          <g transform="translate(0 -22)">
            <g class="grove-canopy-sway">
              <ellipse class="gv-leaf-deep" cx="-6" cy="3.5" rx="5.5" ry="4.2" transform="rotate(-18 -6 3.5)" />
              <ellipse class="gv-leaf-deep" cx="6" cy="2" rx="5.5" ry="4.2" transform="rotate(18 6 2)" />
              <circle class="gv-leaf-mid" cx="0" cy="-3" r="6.8" />
              <ellipse class="gv-leaf-hi" cx="-1.8" cy="-5" rx="3.8" ry="2.8" />
            </g>
          </g>
        </g>
      </g>`;
    }
    if (stage === "tree") {
      return html`<${TreeUnit} x=${140} y=${86} scale=${1.85} buds=${true} />`;
    }
    if (stage === "grove") {
      return html`<${W.R.Fragment}>
        <${TreeUnit} x=${82} y=${82} scale=${1.28} sway="is-alt" />
        <${TreeUnit} x=${198} y=${83} scale=${1.34} sway="is-slow" />
        <${TreeUnit} x=${140} y=${87} scale=${1.76} buds=${true} />
      <//>`;
    }
    if (stage === "field") {
      return html`<${W.R.Fragment}>
        <${TreeUnit} x=${34} y=${76} scale=${0.92} sway="is-slow" />
        <${TreeUnit} x=${86} y=${73} scale=${1.04} sway="is-alt" />
        <${TreeUnit} x=${142} y=${72} scale=${1.08} />
        <${TreeUnit} x=${196} y=${74} scale=${1.0} sway="is-slow" />
        <${TreeUnit} x=${246} y=${77} scale=${0.9} sway="is-alt" />
        <${TreeUnit} x=${58} y=${85} scale=${1.38} sway="is-alt" />
        <${TreeUnit} x=${116} y=${87} scale=${1.62} sway="is-slow" buds=${true} />
        <${TreeUnit} x=${174} y=${86} scale=${1.5} buds=${true} />
        <${TreeUnit} x=${226} y=${85} scale=${1.32} sway="is-alt" />
      <//>`;
    }
    if (stage === "wilt") {
      return html`<${W.R.Fragment}>
        ${info.hadGrove ? html`<${TreeUnit} x=${88} y=${83} scale=${1.02} sway="is-alt" droopy=${true} />` : null}
        ${info.hadGrove ? html`<${TreeUnit} x=${192} y=${84} scale=${0.98} sway="is-slow" droopy=${true} />` : null}
        <${TreeUnit} x=${140} y=${86} scale=${1.38} droopy=${true} />
      <//>`;
    }
    return html`<${W.R.Fragment}>
      ${info.hadGrove ? html`<${TreeUnit} x=${94} y=${84} scale=${0.78} sway="is-alt" droopy=${true} />` : null}
      ${info.hadGrove ? html`<${TreeUnit} x=${186} y=${84.5} scale=${0.74} sway="is-slow" droopy=${true} />` : null}
      <${TreeUnit} x=${140} y=${86} scale=${1.04} droopy=${true} />
      <ellipse class="gv-fallen-leaf" cx="118" cy="88" rx="4.5" ry="1.9" transform="rotate(-12 118 88)" />
      <ellipse class="gv-fallen-leaf" cx="164" cy="89" rx="4.2" ry="1.8" transform="rotate(15 164 89)" />
    <//>`;
  }

  return html`<span class=${W.cx("living-grove", wide ? "is-wide" : "is-compact", p.mini && "is-mini", "is-tone-" + info.tone)}
    data-id=${p.mini ? null : "living-grove"} data-stage=${stage} aria-hidden="true">
    <svg class="living-grove-svg" viewBox=${vb}>
      ${wide ? html`<${W.R.Fragment}>
        <rect class="gv-sky" x="0" y="0" width="280" height="98" rx="14" />
        <path class="gv-hill-back" d="M0 78 Q72 58 148 70 T280 66 L280 98 L0 98 Z" />
        <path class="gv-hill-front" d="M0 84 Q88 68 176 80 T280 78 L280 98 L0 98 Z" />
        ${renderPlantsWide()}
      <//>` : html`<${W.R.Fragment}>
        <path class="gv-hill-back" d="M2 46 Q34 36 68 42 T114 40 L114 54 L2 54 Z" />
        <path class="gv-hill-front" d="M2 49 Q42 41 82 47 T114 46 L114 54 L2 54 Z" />
        ${renderPlantsCompact()}
      <//>`}
    </svg>
  </span>`;
};

function isFridayDay(dayKeyStr, ts) {
  if (dayKeyStr && /^\d{4}-\d{2}-\d{2}$/.test(dayKeyStr)) {
    var p = dayKeyStr.split("-");
    return new Date(+p[0], +p[1] - 1, +p[2]).getDay() === 5;
  }
  return new Date(ts).getDay() === 5;
}

function Today() {
  var st = W.useApp(), ui = st.ui, nowTs = W.now(), en = ui.lang === "en";
  var eng = E.rollDay(st.eng, nowTs);
  var now = E.nowCard(eng, nowTs, { permissionMissing: !!ui.permissionMissing });
  var away = E.awayDays(eng) >= 3;
  var paused = (eng.pausedUntil || 0) > nowTs;

  var doorSt = W.useState(null), activeDoorId = doorSt[0], setActiveDoorId = doorSt[1];
  var parentSt = W.useState(false), parentOpen = parentSt[0], setParentOpen = parentSt[1];
  var guideSt = W.useState(false), guideOpen = guideSt[0], setGuideOpen = guideSt[1];
  var levelSt = W.useState(false), levelOpen = levelSt[0], setLevelOpen = levelSt[1];
  var gemSt = W.useState(0), gemIdx = gemSt[0], setGemIdx = gemSt[1];
  var kahfPopSt = W.useState(false), kahfPopOpen = kahfPopSt[0], setKahfPopOpen = kahfPopSt[1];
  var kahfSparkSt = W.useState(0), kahfSpark = kahfSparkSt[0], setKahfSpark = kahfSparkSt[1];
  var salPulseSt = W.useState(0), salPulse = salPulseSt[0], setSalPulse = salPulseSt[1];

  /* play the day-complete celebration once per day */
  var celRef = W.useRef(false);
  var uncelebrated = now.kind === "complete" && !(st.eng.day && st.eng.day.key === eng.day.key && st.eng.day.celebrated);
  if (uncelebrated) celRef.current = true;
  W.useEffect(function () {
    if (now.kind === "complete") {
      if (!st.eng.day || st.eng.day.key !== eng.day.key) W.S.state.eng = eng;
      if (!W.S.state.eng.day.celebrated) {
        W.S.state.eng.day.celebrated = true;
        W.save();
      }
    }
  }, [now.kind, eng.day.key]);

  var act = E.active(eng);
  var prefs = eng.prefs || W.ANSWER_DEFAULTS;
  var ms = E.momentState(eng, nowTs);
  var mt = E.momentTimes(prefs);
  var mNow = curDayMin(nowTs, prefs);

  var dueMoments = MOMENTS.filter(function (k) { return ms[k] === "waiting" || ms[k] === "running"; })
    .sort(function (a, b) { return mt[a].start - mt[b].start; });
  var missedMoments = MOMENTS.filter(function (k) { return ms[k] === "missed"; })
    .sort(function (a, b) { return mt[a].start - mt[b].start; });
  var upcomingMoments = MOMENTS.filter(function (k) { return ms[k] === "later"; })
    .sort(function (a, b) { return mt[a].start - mt[b].start; });

  /* daily totals, living seed-to-field streak, adaptive level & Friday sunnah trackers */
  var dayTots = W.dayTotals(eng);
  var todayDone = dayTots.got, todayGoal = dayTots.goal;
  var todayExtra = dayTots.listExtra + dayTots.otherSaid;
  var totalSaidToday = dayTots.totalSaid;
  var isFinishedGoal = todayGoal > 0 && todayDone >= todayGoal;
  var isOverSaid = isFinishedGoal && todayExtra > 0;
  var hasBonusSaid = todayExtra > 0;
  var todayKeyStr = (eng.day && eng.day.key) || E.dayKey(nowTs, prefs);

  var streakInfo = W.streakStats(eng, nowTs);
  var streak = streakInfo.streak;
  var levelInfo = W.computeLevel(eng, totalSaidToday);
  var groveInfo = W.groveState(streak, streakInfo.idleDays, levelInfo.total);

  var insightKey = isOverSaid ? "today.prog.insight.over"
    : isFinishedGoal ? "today.prog.insight.done"
    : away ? "today.prog.insight.back"
    : streak >= 3 ? "today.prog.insight.week"
    : "today.prog.insight.start";

  var isFriday = isFridayDay(todayKeyStr, nowTs);
  var friState = (eng.day && eng.day.friday) || {};
  var kahfRead = !!friState.kahf;
  var salawatBase = ((eng.day && eng.day.done && eng.day.done.d904e76671e) || 0) + ((eng.day && eng.day.extra && eng.day.extra.d904e76671e) || 0);
  var salawatCount = (friState.salawat != null ? friState.salawat : 0) + salawatBase;
  var jumuahItems = W.JUMUAH_SET || [];
  var jumuahPos = (eng.day && eng.day.moments && eng.day.moments.jumuah) || { i: 0, n: 0, done: false };
  var jumuahDone = jumuahPos.done ? jumuahItems.length : W.clamp(jumuahPos.i || 0, 0, jumuahItems.length);
  var jumuahTotal = jumuahItems.length || 6;

  var gems = W.GEMS || [];
  var gem = gems.length ? gems[gemIdx % gems.length] : null;
  var activeDoor = (W.DOORS || []).filter(function (d) { return d.id === activeDoorId; })[0] || null;
  var firstDays = now.kind !== "empty" && (!eng.week || !eng.week.days || eng.week.days.length < 3);

  function startSession(k) {
    W.U().backRoute = "today";
    W.go("session/" + k);
  }

  /* Next automatic reminder timestamp across all Today states */
  function calcNextReminderAt() {
    if (now.nextAt) return now.nextAt;
    if (!eng || !eng.prefs || !eng.day || !eng.day.key || !act.length) return null;
    if (eng.day.laterAt && eng.day.laterAt > nowTs && eng.day.laterAt >= (eng.pausedUntil || 0)) {
      return eng.day.laterAt;
    }
    var step = E.intervalMin(eng);
    var w = E.min(prefs.wake), s = E.min(prefs.sleep);
    if (s <= w) s += 1440;
    var mp = prefs.moments || {};
    function quietAt(tMin) {
      return MOMENTS.some(function (k) {
        var on = !mp[k] || mp[k].on !== false;
        return on && tMin >= mt[k].start && tMin < mt[k].start + E.CFG.momentQuietMin;
      });
    }
    var p = String(eng.day.key).split("-");
    for (var t = w + step; t < s; t += step) {
      var at = new Date(+p[0], +p[1] - 1, +p[2], 0, t).getTime();
      if (t > mNow && at >= (eng.pausedUntil || 0) && !quietAt(t)) return at;
    }
    return null;
  }

  function boardLaterLabel(diffMin) {
    var d = Math.max(1, Math.round(diffMin));
    if (d < 60) return W.t("today.board.in.min", { n: d });
    var h = Math.max(1, Math.round(d / 60));
    if (h === 1) return W.t("today.board.in.hr1");
    if (h === 2) return W.t("today.board.in.hr2");
    if (h <= 10) return W.t("today.board.in.hrs", { h: h });
    return W.t("today.board.in.hr", { h: h });
  }

  function nextDhikrCountdownLabel(diffMin) {
    var d = Math.max(1, Math.round(diffMin));
    if (d < 60) {
      if (d === 1) return W.t("today.next.in.min1");
      if (d >= 2 && d <= 10) return W.t("today.next.in.mins", { n: d });
      return W.t("today.next.in.min", { n: d });
    }
    var h = Math.max(1, Math.round(d / 60));
    if (h === 1) return W.t("today.next.in.hr1");
    if (h === 2) return W.t("today.next.in.hr2");
    if (h <= 10) return W.t("today.next.in.hrs", { h: h });
    return W.t("today.next.in.hr", { h: h });
  }

  function renderAlarmIcon() {
    return html`<svg class="now-alarm-ic" width="26" height="26" viewBox="0 0 24 24" fill="none"
      stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="13" r="7.5" />
      <path d="M4.2 6.8A3.3 3.3 0 0 1 8.6 3.5" />
      <path d="M19.8 6.8A3.3 3.3 0 0 0 15.4 3.5" />
      <path d="M12 3.2v2.1" />
      <path d="M12 9.2v4.1l2.6 1.7" />
      <path d="M7.2 19.3 5.5 21.2M16.8 19.3l1.7 1.9" />
    </svg>`;
  }

  function renderNowMisbahaIcon() {
    return html`<svg class="now-misbaha-ic" width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <g fill="currentColor">
        <circle cx="15.2" cy="4.2" r="1.45" />
        <circle cx="18.3" cy="5.4" r="1.45" />
        <circle cx="19.8" cy="8.2" r="1.45" />
        <circle cx="19.3" cy="11.4" r="1.45" />
        <circle cx="17.2" cy="14.0" r="1.45" />
        <circle cx="14.2" cy="15.7" r="1.45" />
        <circle cx="10.9" cy="16.1" r="1.5" />
        <circle cx="8.4" cy="14.1" r="1.45" />
        <circle cx="7.9" cy="10.9" r="1.45" />
        <circle cx="9.4" cy="7.9" r="1.45" />
        <circle cx="12.1" cy="5.5" r="1.45" />
      </g>
      <path d="M9.7 16.7 7.1 19.6M7.1 19.6l-2.3 1.2M7.1 19.6l-.6 2.5" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx="8.4" cy="18.1" r="1.3" fill="currentColor" />
    </svg>`;
  }

  function renderPauseBarsIcon(isResume) {
    if (isResume) {
      return html`<svg class="now-pause-ic" width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M7.5 5.2c0-.9 1-1.4 1.8-.9l10.2 6.8c.7.5.7 1.4 0 1.8L9.3 19.7c-.8.5-1.8 0-1.8-.9z" />
      </svg>`;
    }
    return html`<svg class="now-pause-ic" width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <rect x="6.2" y="4.5" width="4.2" height="15" rx="1.4" />
      <rect x="13.6" y="4.5" width="4.2" height="15" rx="1.4" />
    </svg>`;
  }

  function renderMomentArt(key) {
    var gid = "now-gold-" + key;
    var defs = html`<defs>
      <linearGradient id=${gid} x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#F7E3A6" />
        <stop offset="55%" stopColor="#E1B963" />
        <stop offset="100%" stopColor="#C59840" />
      </linearGradient>
    </defs>`;

    if (key === "waking") {
      return html`<svg class="now-mart-svg" viewBox="0 0 68 54" aria-hidden="true">
        ${defs}
        <circle cx="34" cy="32" r="18" fill="#F7E3A6" opacity="0.13" />
        <path d="M34 6.5l1.1 2.5 2.5 1.1-2.5 1.1-1.1 2.5-1.1-2.5-2.5-1.1 2.5-1.1z" fill="#FAFBF5" opacity="0.92" />
        <g stroke="#F5DE9B" strokeWidth="1.85" strokeLinecap="round">
          <line x1="34" y1="15" x2="34" y2="18.2" />
          <line x1="21.5" y1="18.2" x2="23.8" y2="20.8" />
          <line x1="46.5" y1="18.2" x2="44.2" y2="20.8" />
          <line x1="14.2" y1="26" x2="17.5" y2="27.2" />
          <line x1="53.8" y1="26" x2="50.5" y2="27.2" />
        </g>
        <path d="M21.5 34a12.5 12.5 0 0 1 25 0z" fill=${"url(#" + gid + ")"} stroke="#FAFBF5" strokeWidth="1.25" strokeLinejoin="round" />
        <path d="M25.2 34a8.8 8.8 0 0 1 17.6 0" fill="none" stroke="#FAFBF5" strokeWidth="0.9" opacity="0.55" />
        <line x1="11.5" y1="34.5" x2="56.5" y2="34.5" stroke="#FAFBF5" strokeWidth="2.1" strokeLinecap="round" />
        <path d="M18.5 39.2q15.5 -2.2 31 0" fill="none" stroke="#DCE8CA" strokeWidth="1.65" strokeLinecap="round" />
        <line x1="25" y1="43" x2="43" y2="43" stroke="#A7C086" strokeWidth="1.45" strokeLinecap="round" />
      </svg>`;
    }
    if (key === "morning") {
      return html`<svg class="now-mart-svg" viewBox="0 0 68 54" aria-hidden="true">
        ${defs}
        <g transform="translate(34 27)">
          <circle cx="0" cy="0" r="19.5" fill="#F7E3A6" opacity="0.14" />
          <g fill="#F5DE9B">
            <polygon points="0,-22.5 2.4,-14.5 -2.4,-14.5" />
            <polygon points="0,22.5 2.4,14.5 -2.4,14.5" />
            <polygon points="-22.5,0 -14.5,2.4 -14.5,-2.4" />
            <polygon points="22.5,0 14.5,2.4 14.5,-2.4" />
            <polygon points="0,-20.5 2.1,-14.2 -2.1,-14.2" transform="rotate(45)" />
            <polygon points="0,-20.5 2.1,-14.2 -2.1,-14.2" transform="rotate(135)" />
            <polygon points="0,-20.5 2.1,-14.2 -2.1,-14.2" transform="rotate(225)" />
            <polygon points="0,-20.5 2.1,-14.2 -2.1,-14.2" transform="rotate(315)" />
          </g>
          <g stroke="#FAFBF5" strokeWidth="1.35" strokeLinecap="round" opacity="0.85">
            <line x1="0" y1="-17.2" x2="0" y2="-15.2" transform="rotate(22.5)" />
            <line x1="0" y1="-17.2" x2="0" y2="-15.2" transform="rotate(67.5)" />
            <line x1="0" y1="-17.2" x2="0" y2="-15.2" transform="rotate(112.5)" />
            <line x1="0" y1="-17.2" x2="0" y2="-15.2" transform="rotate(157.5)" />
            <line x1="0" y1="-17.2" x2="0" y2="-15.2" transform="rotate(202.5)" />
            <line x1="0" y1="-17.2" x2="0" y2="-15.2" transform="rotate(247.5)" />
            <line x1="0" y1="-17.2" x2="0" y2="-15.2" transform="rotate(292.5)" />
            <line x1="0" y1="-17.2" x2="0" y2="-15.2" transform="rotate(337.5)" />
          </g>
          <circle cx="0" cy="0" r="11.2" fill=${"url(#" + gid + ")"} stroke="#FAFBF5" strokeWidth="1.3" />
          <circle cx="0" cy="0" r="7.4" fill="none" stroke="#FAFBF5" strokeWidth="0.95" opacity="0.6" />
        </g>
      </svg>`;
    }
    if (key === "evening") {
      return html`<svg class="now-mart-svg" viewBox="0 0 68 54" aria-hidden="true">
        ${defs}
        <circle cx="35" cy="25" r="18.5" fill="#F7E3A6" opacity="0.12" />
        <path d="M48 31.2A15.8 15.8 0 1 1 31.8 8a12.3 12.3 0 0 0 16.2 23.2z"
          fill=${"url(#" + gid + ")"} stroke="#FAFBF5" strokeWidth="1.2" strokeLinejoin="round" />
        <g fill="#FAFBF5">
          <path d="M39.5 10.2l1.15 2.8 2.8 1.15-2.8 1.15-1.15 2.8-1.15-2.8-2.8-1.15 2.8-1.15z" />
          <path d="M47.4 16.8l.85 2.05 2.05.85-2.05.85-.85 2.05-.85-2.05-2.05-.85 2.05-.85z" />
        </g>
        <circle cx="34.8" cy="18.5" r="1.15" fill="#F7E3A6" />
        <path d="M16.5 44.5h19.2a4.8 4.8 0 0 0 .6-9.55 6.5 6.5 0 0 0-12.3-1.65A5.1 5.1 0 0 0 16.5 44.5z"
          fill="#FAFBF5" opacity="0.95" />
        <path d="M18.5 44.5h16.2" stroke="#C8DAB0" strokeWidth="1.6" strokeLinecap="round" />
      </svg>`;
    }
    return html`<svg class="now-mart-svg" viewBox="0 0 68 54" aria-hidden="true">
      ${defs}
      <circle cx="35" cy="27" r="18" fill="#F7E3A6" opacity="0.11" />
      <path d="M46.5 16.4a5.6 5.6 0 1 1-5.8-8.3 4.4 4.4 0 0 0 5.8 8.3z" fill="#F5DE9B" />
      <path d="M31.5 10.2l.95 2.2 2.2.95-2.2.95-.95 2.2-.95-2.2-2.2-.95 2.2-.95z" fill="#FAFBF5" opacity="0.92" />
      <circle cx="24.5" cy="16.5" r="1.05" fill="#F5DE9B" opacity="0.85" />
      <path d="M12.5 22.5a2 2 0 0 1 4 0v19.5h-4z" fill=${"url(#" + gid + ")"} />
      <rect x="16.5" y="26.2" width="11.5" height="6.2" rx="3.1" fill="#FAFBF5" />
      <path d="M26.5 27.2h23a5.5 5.5 0 0 1 5.5 5.5v3.3H26.5z" fill="#DCE8CA" stroke="#FAFBF5" strokeWidth="1.15" strokeLinejoin="round" />
      <path d="M26.5 27.2h7.5v8.8h-7.5z" fill="#FAFBF5" />
      <rect x="12.5" y="35.5" width="43.5" height="4.2" rx="1.6" fill=${"url(#" + gid + ")"} />
      <path d="M52.5 31.5a1.75 1.75 0 0 1 3.5 0v10.5h-3.5z" fill=${"url(#" + gid + ")"} />
    </svg>`;
  }

  var nextAtTs = calcNextReminderAt();
  var hasAltNext = !paused && !!nextAtTs && nextAtTs > nowTs;

  function boardProgressFrac() {
    var starts = [mt.waking.start, mt.morning.start, mt.evening.start, mt.sleep.start].sort(function (a, b) { return a - b; });
    if (mNow <= starts[0]) return 0;
    if (mNow >= starts[3]) return 1;
    for (var i = 0; i < 3; i++) {
      if (mNow >= starts[i] && mNow <= starts[i + 1]) {
        var seg = (mNow - starts[i]) / Math.max(1, starts[i + 1] - starts[i]);
        return W.clamp((i + seg) / 3, 0, 1);
      }
    }
    return 0.5;
  }

  function renderMomentsBoard() {
    var frac = boardProgressFrac();
    var pctStr = (frac * 100).toFixed(1) + "%";
    var clipW = Math.round(frac * 300);

    return html`<div class="now-board" data-id="moments-sec">
      <div class="now-track" aria-hidden="true">
        <svg class="now-track-wavy" viewBox="0 0 300 16" preserveAspectRatio="none">
          <defs>
            <clipPath id="now-wave-clip">
              <rect x="0" y="0" width=${clipW} height="16" />
            </clipPath>
          </defs>
          <path clipPath="url(#now-wave-clip)"
            d="M0 8 Q 15 5.4, 30 8 T 60 8 T 90 8 T 120 8 T 150 8 T 180 8 T 210 8 T 240 8 T 270 8 T 300 8"
            fill="none" stroke="currentColor" strokeWidth="2.3" strokeLinecap="round" />
        </svg>
        ${frac < 0.99 ? html`<span class="now-track-dots" style=${{ insetInlineStart: pctStr }}></span>` : null}
        <span class="now-track-diamond" data-id="now-track-diamond" style=${{ insetInlineStart: pctStr }}></span>
      </div>

      <div class="now-board-cols">
        ${MOMENTS.map(function (k) {
          var stKey = ms[k] || "later";
          var isDue = stKey === "waiting" || stKey === "running";
          var dataState = isDue ? "due" : stKey;
          var pillLbl = stKey === "running" ? W.t("today.board.contnow")
            : stKey === "waiting" ? W.t("today.board.readnow")
            : stKey === "done" ? W.t("today.board.done")
            : stKey === "missed" ? W.t("today.board.missed")
            : stKey === "off" ? W.t("today.board.off")
            : boardLaterLabel(mt[k].start - mNow);

          function onMomentTap() {
            if (stKey === "off") {
              W.U().adhkarView = k;
              W.go("adhkar");
              return;
            }
            startSession(k);
          }

          return html`<button type="button" key=${k}
            class=${W.cx("now-mcol", "is-" + dataState)}
            data-id=${"moment-" + k}
            data-state=${dataState}
            onClick=${onMomentTap}>
            <span class="now-mcol-name">${W.t("today.board." + k)}</span>
            <span class="now-mcol-art">${renderMomentArt(k)}</span>
            <span class="now-mpill-wrap">
              ${isDue ? html`<span class="now-mpill-halo" aria-hidden="true"></span>` : null}
              <span class=${W.cx("now-mpill", "num", isDue && "is-due", stKey === "done" && "is-done", stKey === "missed" && "is-missed", stKey === "later" && "is-later", stKey === "off" && "is-off")}>
                ${pillLbl}
              </span>
            </span>
          </button>`;
        })}
      </div>
    </div>`;
  }

  function renderNowHead() {
    if (now.kind === "weekly") {
      return html`<button type="button" class="now-head now-head-btn" data-id="now-weekly-open"
        onClick=${function () { W.go("weekly"); }}>
        <span class="now-head-text">${W.t("today.weekly.text")}</span>
      </button>`;
    }
    if (now.kind === "fix") {
      return html`<div class="now-head" data-id="now-head">
        ${W.Icon({ name: "bell", size: 24 })}
        <span class="now-head-text">${W.t("today.fix.text")}</span>
      </div>`;
    }
    if (now.kind === "continue") {
      return html`<button type="button" class="now-head now-head-btn" data-id="now-continue-open"
        onClick=${function () { openCount(now.id); }}>
        <span class="now-head-text">${W.t("today.continue.text")}</span>
      </button>`;
    }
    if (now.kind === "empty") {
      return html`<div class="now-head" data-id="now-head">
        ${renderAlarmIcon()}
        <span class="now-head-text">${W.t("today.empty.text")}</span>
      </div>`;
    }
    if (now.kind === "complete") {
      return html`<div class="now-head is-complete" data-id="now-head">
        <span class="now-done-mark m-day-mark"><${W.Ornament} bare=${true} size=${28} /></span>
        <span class="now-head-text m-day-text">${W.t("today.complete.title")}</span>
      </div>`;
    }
    return html`<div class="now-head" data-id="now-head">
      ${renderAlarmIcon()}
      <span class="now-head-text">${W.t("today.now.title")}</span>
    </div>`;
  }

  function renderNowActions() {
    if (now.kind === "fix") {
      return html`<div class="now-actions is-single" data-id="now-remind">
        <button type="button" class="now-cta-btn" data-id="now-button"
          onClick=${function () { W.U().permissionMissing = false; W.toast(W.t("today.fix.done")); }}>
          ${W.Icon({ name: "bell", size: 22 })}
          <span>${W.t("today.fix.btn")}</span>
        </button>
      </div>`;
    }
    if (now.kind === "empty" || !act.length) {
      return html`<div class="now-actions is-single" data-id="now-remind">
        <button type="button" class="now-cta-btn" data-id="now-button"
          onClick=${function () { W.go("add"); }}>
          ${W.Icon({ name: "add", size: 22 })}
          <span>${W.t("today.add")}</span>
        </button>
      </div>`;
    }

    var manualPickId = now.id
      || ((act.filter(function (a) { return eng.day && eng.day.carry && eng.day.carry[a.id]; })[0] || {}).id)
      || ((act.filter(function (a) { return E.left(eng, a.id) > 0 && a.id !== (eng.day && eng.day.lastShown); })[0] || {}).id)
      || ((act.filter(function (a) { return E.left(eng, a.id) > 0; })[0] || {}).id)
      || ((act.filter(function (a) { return a.id !== (eng.day && eng.day.lastShown); })[0] || act[0] || {}).id);

    var ctaLabel = now.kind === "continue" ? W.t("today.now.cont.btn")
      : now.kind === "complete" ? W.t("today.saymore")
      : W.t("today.say.btn");

    var statusText = paused
      ? W.t("today.paused.until", { time: W.timeLabel(W.clock(eng.pausedUntil)) })
      : nextAtTs
        ? nextDhikrCountdownLabel((nextAtTs - nowTs) / 60000)
        : W.t("today.remind.active");

    var actionLabel = W.t(paused ? "today.resume" : "today.pause");

    return html`<div class="now-actions" data-id="now-remind">
      <button type="button" class="now-cta-btn" data-id="now-button"
        onClick=${function () { if (manualPickId) openCount(manualPickId); }}>
        <span class="now-cta-sheen" aria-hidden="true"></span>
        ${renderNowMisbahaIcon()}
        <span class="now-cta-label">${ctaLabel}</span>
      </button>

      <button type="button"
        class=${W.cx("now-pause-pill", paused && "is-paused", hasAltNext && "has-alt")}
        data-id="pause"
        aria-label=${actionLabel}
        onClick=${function () {
          W.act("pause", function (s) { s.eng = E.pause(s.eng, W.now(), paused ? 0 : 60); });
        }}>
        <span class="now-pause-face is-action">
          ${renderPauseBarsIcon(paused)}
          <span>${actionLabel}</span>
        </span>
        <span class="now-pause-face is-next num" data-id="now-next" aria-hidden="true">
          ${statusText}
        </span>
      </button>
    </div>`;
  }

  function renderNow() {
    return html`${renderNowHead()}
      ${renderMomentsBoard()}
      ${renderNowActions()}`;
  }

  return html`<div class="today" data-id="today">
    ${away ? html`<div class="today-welcome" data-id="welcome-back">
      ${W.Icon({ name: "sparkle", size: 22 })}<span>${W.t("today.welcome")}</span>
    </div>` : null}

    <section class=${W.cx("panel", "now-card", "now-hub", now.kind === "complete" && celRef.current && "m-day-done")}
      data-id="now-card" data-kind=${now.kind}>
      ${renderNow()}
    </section>

    ${act.length ? html`<section class=${W.cx("panel", "today-prog-card", isFinishedGoal && "is-goal-done", isOverSaid && "is-over-said")} data-id="today-progress">
      <div class="today-prog-head">
        <span class="today-prog-brand">
          <span class="today-prog-leaf">${W.Icon({ name: "leaf", size: 20 })}</span>
          <span class="today-prog-title">${W.t("today.prog.title")}</span>
        </span>
        <button type="button" class="today-prog-details" data-id="today-prog-details"
          onClick=${function () { W.U().backRoute = "today"; W.go("days"); }}>
          <span>${W.t("today.prog.details")}</span>
          ${W.Icon({ name: "forward", size: 15 })}
        </button>
      </div>

      <div class="today-prog-trackers">
        <button type="button" class=${W.cx("prog-tracker", isFinishedGoal && "is-finished", isOverSaid && "is-oversaid")}
          data-id="prog-stat-finished"
          onClick=${function () {
            var nxt = act.filter(function (a) { return E.left(eng, a.id) > 0; })[0] || act[0];
            if (nxt) openCount(nxt.id);
          }}>
          ${(isFinishedGoal || isOverSaid) ? html`<span class="tracker-sparks" aria-hidden="true"><i></i><i></i><i></i><i></i></span>` : null}
          <span class="prog-tracker-ic is-heart">${W.Icon({ name: isFinishedGoal ? "done" : "heart", size: 21 })}</span>
          <span class="prog-tracker-val num m-count" key=${totalSaidToday}>${todayDone}/${todayGoal}</span>
          ${hasBonusSaid ? html`<span class="prog-over-pill num">${W.t("today.prog.oversaid", { n: todayExtra })}</span>` : null}
          <span class="prog-tracker-lbl">${W.t("today.prog.finished")}</span>
        </button>

        <button type="button" class=${W.cx("prog-tracker", "prog-tracker-grove", "is-tone-" + groveInfo.tone)}
          data-id="prog-stat-streak"
          data-stage=${groveInfo.stage}
          onClick=${function () { W.U().backRoute = "today"; W.go("days"); }}>
          <${W.LivingGrove} streak=${streak} idleDays=${streakInfo.idleDays} lifetime=${levelInfo.total} compact=${true} />
          <span class="prog-tracker-val num">${streak}</span>
          <span class="prog-tracker-lbl">${W.t("today.prog.streak")}</span>
        </button>

        <button type="button" class="prog-tracker prog-tracker-level"
          data-id="prog-stat-moments"
          data-level=${levelInfo.level}
          onClick=${function () { setLevelOpen(true); }}>
          <span class="prog-level-badge num">
            ${W.Icon({ name: "sparkle", size: 14 })}
            <span>${W.t("today.prog.level", { n: levelInfo.level })}</span>
          </span>
          <span class="prog-tracker-val num m-count" key=${levelInfo.total}>${levelInfo.total}</span>
          <span class="prog-tracker-lbl">${W.t("today.prog.totaldhikr")}</span>
          <span class="prog-level-bar" aria-hidden="true">
            <i style=${{ width: levelInfo.pct + "%" }}></i>
          </span>
          <span class="prog-level-sub quiet num">${W.t("today.prog.level.next", { into: levelInfo.into, need: levelInfo.need, next: levelInfo.level + 1 })}</span>
        </button>
      </div>

      <div class="today-prog-insight" data-id="today-prog-insight">
        <span class="today-prog-trend">${W.Icon({ name: "trend", size: 18 })}</span>
        <span>${W.t(insightKey)}</span>
      </div>
    </section>` : null}

    ${isFriday ? html`<section class="panel today-prog-card today-friday-card" data-id="today-friday">
      <div class="today-prog-head">
        <span class="today-prog-brand">
          <span class="today-prog-leaf is-friday">${W.Icon({ name: "mosque", size: 20 })}</span>
          <span class="today-prog-title">${W.t("friday.title")}</span>
        </span>
        <span class="friday-badge">${W.t("friday.badge")}</span>
      </div>

      <div class="today-prog-trackers">
        <button type="button" class=${W.cx("prog-tracker", kahfRead && "is-finished", kahfRead && "is-oversaid")}
          data-id="friday-kahf" onClick=${function () { setKahfPopOpen(true); }}>
          ${kahfRead ? html`<span class="tracker-sparks" key=${"ks-" + kahfSpark} aria-hidden="true"><i></i><i></i><i></i><i></i></span>` : null}
          <span class="prog-tracker-ic is-kahf">${W.Icon({ name: kahfRead ? "done" : "book", size: 21 })}</span>
          <span class="prog-tracker-val is-word">${W.t(kahfRead ? "friday.kahf.read" : "friday.kahf.unread")}</span>
          <span class="prog-tracker-lbl">${W.t("friday.kahf.title")}</span>
        </button>

        <button type="button" class=${W.cx("prog-tracker", salawatCount >= 10 && "is-streak-hot")}
          data-id="friday-salawat"
          onClick=${function () {
            if (W.feelBead) W.feelBead(salawatCount + 1, 100);
            setSalPulse(salPulse + 1);
            W.act("friday-salawat", function (s) {
              s.eng = E.rollDay(s.eng, W.now());
              var hasSalawat = (s.eng.adhkar || []).some(function (x) { return x.id === "d904e76671e"; });
              if (hasSalawat) {
                s.eng = E.tap(s.eng, W.now(), "d904e76671e", 1);
              } else {
                s.eng = E.tap(s.eng, W.now(), "d904e76671e", 1);
              }
            });
          }}>
          ${salPulse > 0 ? html`<span class="tap-pulse" key=${salPulse} aria-hidden="true"></span>` : null}
          <span class="prog-tracker-ic is-heart">${W.Icon({ name: "heart", size: 21 })}</span>
          <span class="prog-tracker-val num m-count" key=${salawatCount}>${salawatCount}</span>
          <span class="prog-tracker-lbl">${W.t("friday.salawat.title")}</span>
        </button>

        <button type="button" class=${W.cx("prog-tracker", jumuahDone >= jumuahTotal && "is-finished")}
          data-id="friday-jumuah"
          onClick=${function () { W.U().adhkarView = "jumuah"; W.U().backRoute = "today"; W.go("adhkar"); }}>
          <span class="prog-tracker-ic is-moments">${W.Icon({ name: jumuahDone >= jumuahTotal ? "done" : "mosque", size: 21 })}</span>
          <span class="prog-tracker-val num">${jumuahDone}/${jumuahTotal}</span>
          <span class="prog-tracker-lbl">${W.t("friday.jumuah.title")}</span>
        </button>
      </div>

      <div class="today-prog-insight" data-id="friday-insight">
        <span class="today-prog-trend">${W.Icon({ name: "sparkle", size: 18 })}</span>
        <span>${W.t(kahfRead ? "friday.insight.kahf" : "friday.insight.default")}</span>
      </div>
    </section>` : null}

    <section class="panel today-doors-card" data-id="today-doors">
      <div class="today-card-head">
        ${W.Icon({ name: "heart", size: 22 })}
        <div>
          <h2 class="title today-card-title">${W.t("today.doors.title")}</h2>
          <p class="quiet today-card-sub">${W.t("today.doors.sub")}</p>
        </div>
      </div>
      <div class="doors-pills">
        ${(W.DOORS || []).map(function (d) {
          return html`<button type="button" key=${d.id} class="door-pill"
            data-id=${"door-" + d.id} onClick=${function () { setActiveDoorId(d.id); }}>
            ${W.Icon({ name: d.icon, size: 19 })}
            <span>${W.t(d.label)}</span>
          </button>`;
        })}
      </div>
    </section>

    ${gem ? html`<section class="panel today-hadith-card" data-id="today-hadith">
      <div class="today-hadith-top">
        <span class="today-hadith-badge">${W.Icon({ name: "book", size: 18 })}<span>${W.t("today.hadith.title")}</span></span>
        <button type="button" class="cele-gem-next" data-id="hadith-next"
          onClick=${function () { setGemIdx(gemIdx + 1); }}>
          ${W.Icon({ name: "sparkle", size: 16 })}<span>${W.t("today.hadith.next")}</span>
        </button>
      </div>
      <p class="today-hadith-text" key=${gemIdx}>${en ? gem.en : gem.ar}</p>
      <div class="today-hadith-foot">
        <span class="quiet">${en ? gem.srcEn : gem.srcAr}</span>
        ${gem.dhikrId ? html`<button type="button" class="hadith-try-btn" data-id="hadith-try"
          onClick=${function () { openCount(gem.dhikrId); }}>
          ${W.Icon({ name: "adhkar", size: 18 })}<span>${W.t("today.hadith.try")}</span>
        </button>` : null}
      </div>
    </section>` : null}

    <section class="today-sec" data-id="today-quick">
      <h2 class="today-sec-title quiet">${W.t("today.quick.title")}</h2>
      <div class="adhkar-rows">
        <${W.Row} id="quick-adhkar" icon="adhkar"
          title=${W.t("today.quick.adhkar")} sub=${W.t("today.quick.adhkar.sub")}
          onClick=${function () { W.U().adhkarView = "mine"; W.go("adhkar"); }} />
        <${W.Row} id="open-parent-preset" icon="heart"
          title=${W.t("parent.btn")} sub=${W.t("parent.sub")}
          onClick=${function () { setParentOpen(true); }} />
        <${W.Row} id="quick-days" icon="history"
          title=${W.t("today.quick.days")} sub=${W.t("today.quick.days.sub")}
          onClick=${function () { W.go("days"); }} />
      </div>
    </section>

    <section class="panel today-guide-card" data-id="today-guide">
      <button type="button" class="today-guide-toggle" data-id="guide-toggle"
        aria-expanded=${(firstDays || guideOpen) ? "true" : "false"}
        onClick=${function () { setGuideOpen(!guideOpen); }}>
        ${W.Icon({ name: "help", size: 22 })}
        <span class="today-guide-title">${W.t("today.guide.title")}</span>
        ${W.Icon({ name: "forward", size: 18, className: W.cx("row-go", (firstDays || guideOpen) && "is-open") })}
      </button>
      ${(firstDays || guideOpen) ? html`<div class="today-guide-body">
        <p class="quiet">${W.t("today.guide.1")}</p>
        <p class="quiet">${W.t("today.guide.2")}</p>
        <p class="quiet">${W.t("today.guide.3")}</p>
      </div>` : null}
    </section>

    <${W.Sheet} id="level-sheet" popup=${true} open=${levelOpen}
      title=${W.t("level.sheet.title")}
      onClose=${function () { setLevelOpen(false); }}
      footer=${html`<${W.Btn} kind="main" wide=${true} icon="history" label=${W.t("level.sheet.days")} id="level-open-days"
        onClick=${function () { setLevelOpen(false); W.U().backRoute = "today"; W.go("days"); }} />`}>
      <div class="level-sheet-body">
        <div class="level-sheet-hero">
          <span class="level-sheet-badge num">
            ${W.Icon({ name: "sparkle", size: 18 })}
            <span>${W.t("today.prog.level", { n: levelInfo.level })}</span>
          </span>
          <span class="level-sheet-total num">${levelInfo.total}</span>
          <span class="quiet">${W.t("today.prog.totaldhikr")}</span>
        </div>
        <div class="level-sheet-meter">
          <div class="level-sheet-bar" aria-hidden="true">
            <i style=${{ width: levelInfo.pct + "%" }}></i>
          </div>
          <span class="level-sheet-left num">${W.t("level.sheet.left", { n: levelInfo.left, next: levelInfo.level + 1 })}</span>
        </div>
        <p class="quiet level-sheet-sub">${W.t("level.sheet.sub")}</p>
      </div>
    <//>

    <${W.Sheet} id="door-sheet" open=${!!activeDoor}
      title=${activeDoor ? W.t(activeDoor.label) : ""}
      onClose=${function () { setActiveDoorId(null); }}>
      ${activeDoor ? html`<div class="door-sheet-body">
        <p class="door-sheet-note">${en ? activeDoor.noteEn : activeDoor.noteAr}</p>
        <div class="adhkar-rows">
          ${activeDoor.ids.map(function (did) {
            var it = W.lib(did);
            if (!it) return null;
            var fadl = en ? (it.en || it.arNote) : (it.arNote || it.en);
            return html`<div key=${did} class="panel door-item" data-id=${"door-item-" + did}>
              <p class="dhikr" dir="rtl" lang="ar">${it.ar}</p>
              ${en && it.translit ? html`<p class="card-translit" dir="ltr" lang="en">${it.translit}</p>` : null}
              ${fadl ? html`<p class="quiet door-item-fadl">${fadl}</p>` : null}
              <${W.Btn} kind="main" wide=${true} icon="adhkar" label=${W.t("door.say")}
                id=${"door-say-" + did}
                onClick=${function () { setActiveDoorId(null); openCount(did); }} />
            </div>`;
          })}
        </div>
      </div>` : null}
    <//>

    <${W.Sheet} id="friday-kahf-sheet" popup=${true} open=${kahfPopOpen}
      title=${W.t("friday.kahf.q")}
      onClose=${function () { setKahfPopOpen(false); }}>
      <div class="moment-sheet-body">
        <p class="quiet" style=${{ margin: 0, lineHeight: 1.55 }}>${W.t("friday.kahf.sub")}</p>
        <${W.Btn} kind="main" wide=${true} icon="done" label=${W.t("friday.kahf.yes")} id="friday-kahf-yes"
          onClick=${function () {
            if (W.feelBead) W.feelBead(1, 1);
            setKahfSpark(kahfSpark + 1);
            W.act("friday-kahf", function (s) {
              s.eng = E.rollDay(s.eng, W.now());
              s.eng.day.friday = Object.assign({}, s.eng.day.friday || {}, { kahf: true });
            });
            setKahfPopOpen(false);
          }} />
        ${kahfRead ? html`<${W.Btn} kind="text" wide=${true} icon="undo" label=${W.t("friday.kahf.undo")} id="friday-kahf-undo"
          onClick=${function () {
            W.act("friday-kahf-undo", function (s) {
              s.eng = E.rollDay(s.eng, W.now());
              s.eng.day.friday = Object.assign({}, s.eng.day.friday || {}, { kahf: false });
            });
            setKahfPopOpen(false);
          }} />` : null}
      </div>
    <//>

    <${W.ParentSheet} open=${parentOpen} onClose=${function () { setParentOpen(false); }} />
  </div>`;
}

function CountBody(p) {
  var id = p.id, st = W.useApp(), nowTs = W.now();
  var eng = E.rollDay(st.eng, nowTs);
  var a = (eng.adhkar || []).filter(function (x) { return x.id === id; })[0];
  var it = W.lib(id);

  function microPieceSize(forExtra) {
    var h = new Date(nowTs).getHours();
    var comfort = Math.max(1, (eng.comfort && eng.comfort[h]) || 10);
    if (!forExtra && a && E.left(eng, id) > 0) {
      var picked = E.pick ? E.pick(eng, nowTs, true) : null;
      if (picked && picked.id === id && picked.piece > 0) return picked.piece;
      return Math.min(E.left(eng, id), comfort);
    }
    if (!a && it && it.sunnah != null && it.sunnah <= 15) return it.sunnah;
    return a ? comfort : Math.min((it && it.sunnah) || 10, 10);
  }

  var initCarry = eng.day && eng.day.carry && eng.day.carry[id];
  var modeSt = W.useState(function () {
    if (initCarry) return { kind: "piece", piece: initCarry.piece, initDone: initCarry.done || 0 };
    if (a && E.left(eng, id) > 0) return { kind: "piece", piece: microPieceSize(false), initDone: 0 };
    return { kind: "extra", piece: microPieceSize(true), initDone: 0 };
  });
  var mode = modeSt[0], setMode = modeSt[1];
  var locSt = W.useState(mode.initDone || 0), localDone = locSt[0], setLocalDone = locSt[1];

  var dayDone = (eng.day && eng.day.done && eng.day.done[id]) || 0;
  var dayExtra = (eng.day && eng.day.extra && eng.day.extra[id]) || 0;
  var done = W.clamp(localDone, 0, mode.piece);

  var nextOpen = E.active(eng).filter(function (x) { return x.id !== id && E.left(eng, x.id) > 0; })[0];

  function onTap() {
    if (done >= mode.piece) return;
    var nextDone = done + 1;
    setLocalDone(nextDone);
    W.act("tap", function (s) {
      s.eng = E.tap(s.eng, W.now(), id, 1);
      if (mode.kind === "piece" && a) {
        if (nextDone >= mode.piece || E.left(s.eng, id) <= 0) {
          delete s.eng.day.carry[id];
        } else {
          s.eng.day.carry[id] = { piece: mode.piece, done: nextDone };
        }
      }
    });
  }

  function onMore() {
    var rem = a ? E.left(eng, id) : 0;
    setMode({ kind: rem > 0 ? "piece" : "extra", piece: microPieceSize(rem <= 0), initDone: 0 });
    setLocalDone(0);
  }

  function onNextDhikr() {
    if (nextOpen) W.go("count/" + nextOpen.id);
  }

  function onClose() {
    var back = W.U().backRoute || "today";
    W.U().backRoute = null;
    W.go(back);
  }

  return html`<${W.Card} size="page" id=${id} piece=${mode.piece} done=${done}
    extra=${mode.kind === "extra" && !!a}
    dayDone=${mode.kind === "extra" && a ? dayDone + dayExtra : dayDone}
    dayTarget=${a ? a.target : 0}
    onTap=${onTap} onClose=${onClose}
    onMore=${onMore}
    onNextDhikr=${nextOpen ? onNextDhikr : null} />`;
}

W.screen("today", Today);
W.screen("count", function CountScreen(p) {
  var id = p.arg || (W.LIB[0] && W.LIB[0].id);
  return html`<${CountBody} key=${id} id=${id} />`;
});
})();
