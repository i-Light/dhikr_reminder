/* card.js: the dhikr card in three sizes, interactive SVG Misbaha bead strand, pocket-misbaha haptics & bead sound,
   and variable Fadl & reflection unlocks on completion. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

var LONG_WORDS = 14;

W.lib = function (id) {
  var found = W.LIB.filter(function (x) { return x.id === id; })[0];
  if (found) return found;
  var custom = W.S && W.S.state && W.S.state.eng && W.S.state.eng.custom;
  return (custom || []).filter(function (x) { return x.id === id; })[0] || null;
};
W.cardSizeFor = function (id, want) {
  var it = W.lib(id);
  if (want === "banner") return it && it.words > LONG_WORDS ? "small" : "banner";
  return want === "small" && it && it.words > LONG_WORDS ? "full" : want;
};

/* ---------- Pocket Misbaha tactile haptic + wooden bead WebAudio synthesis ---------- */
var audioCtx = null;
function getAudio() {
  if (audioCtx) return audioCtx;
  var AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return null;
  try { audioCtx = new AC(); } catch (e) { audioCtx = null; }
  return audioCtx;
}

function tone(ctx, freq, endFreq, durSec, gainPeak, delaySec, wave) {
  try {
    var t0 = ctx.currentTime + (delaySec || 0);
    var osc = ctx.createOscillator(), g = ctx.createGain();
    osc.type = wave || "sine";
    osc.frequency.setValueAtTime(freq, t0);
    if (endFreq && endFreq !== freq) osc.frequency.exponentialRampToValueAtTime(endFreq, t0 + durSec);
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.linearRampToValueAtTime(gainPeak, t0 + 0.005);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + durSec);
    osc.connect(g);
    g.connect(ctx.destination);
    osc.start(t0);
    osc.stop(t0 + durSec + 0.01);
  } catch (e) { /* audio blocked or headless */ }
}

W.isLandmarkBead = function (done, piece) {
  if (done <= 0 || done >= piece) return false;
  return done % 10 === 0 || done === 33 || done === 66 || done === 99;
};

W.feelBead = function (nextDone, piece) {
  var s = W.S && W.S.state;
  var soundPref = (s && s.eng && s.eng.prefs && s.eng.prefs.sound) || "soft";
  if (soundPref === "silent") return;
  var fin = nextDone >= piece;
  var landmark = W.isLandmarkBead(nextDone, piece);
  try {
    if (navigator && typeof navigator.vibrate === "function") {
      if (fin) navigator.vibrate([24, 36, 52]);
      else if (landmark) navigator.vibrate([18, 28, 22]);
      else navigator.vibrate(11);
    }
  } catch (e) { /* vibration unsupported */ }

  if (soundPref !== "soft") return;
  var ctx = getAudio();
  if (!ctx) return;
  try { if (ctx.state === "suspended") ctx.resume(); } catch (e) { /* ignore */ }
  if (fin) {
    tone(ctx, 261.6, 261.6, 0.16, 0.07, 0, "sine");
    tone(ctx, 329.6, 329.6, 0.18, 0.07, 0.055, "sine");
    tone(ctx, 392.0, 392.0, 0.28, 0.08, 0.115, "sine");
  } else if (landmark) {
    tone(ctx, 196, 145, 0.055, 0.08, 0, "triangle");
    tone(ctx, 293.7, 260, 0.09, 0.065, 0.05, "sine");
  } else {
    tone(ctx, 165, 92, 0.026, 0.055, 0, "triangle");
  }
};

/* ---------- Interactive 3D SVG Misbaha (Sibhah) for full-screen & page counters ---------- */
W.Misbaha = function Misbaha(p) {
  var piece = Math.max(1, p.piece || 1), done = W.clamp(p.done || 0, 0, piece), fin = done >= piece;
  /* Always draw a full 33-bead sibhah strand so even 1 or 3 counts look unmistakably like a real sibhah */
  var STRAND_BEADS = 33;
  var activeSlots = Math.min(STRAND_BEADS, piece);
  var litCount = fin ? activeSlots
    : piece <= STRAND_BEADS ? done
    : (done === 0 ? 0 : ((done - 1) % STRAND_BEADS) + 1);
  var landmark = W.isLandmarkBead(done, piece);

  /* Natural draped teardrop sibhah loop meeting at the Imam head-piece at top (130, 56) */
  var cx = 130, cy = 152, rx = 84, ry = 84;
  var startDeg = 14, spanDeg = 332;
  function strandPt(deg) {
    var rad = deg * Math.PI / 180;
    /* Gently pinch top toward the Imam neck so the cord forms a real sibhah teardrop silhouette */
    var topFactor = (1 + Math.cos(rad)) * 0.5;
    var pinch = 1 - 0.26 * Math.pow(topFactor, 2.2);
    var x = cx + rx * pinch * Math.sin(rad);
    var y = cy - ry * Math.cos(rad) - 6 * Math.pow(topFactor, 3);
    return { x: +x.toFixed(2), y: +y.toFixed(2), deg: deg };
  }

  /* Build smooth cord path from Imam base around the loop and back into Imam base */
  var cordPts = ["M 127.5 55"];
  for (var s = 0; s <= 48; s++) {
    var cp = strandPt(10 + (s / 48) * 340);
    cordPts.push("L " + cp.x + " " + cp.y);
  }
  cordPts.push("L 132.5 55");
  var cordD = cordPts.join(" ");

  var beads = [];
  for (var i = 0; i < STRAND_BEADS; i++) {
    var frac = i / (STRAND_BEADS - 1);
    var pt = strandPt(startDeg + frac * spanDeg);
    var inTarget = i < activeSlots;
    var isLit = inTarget && i < litCount;
    var isCur = !fin && inTarget && i === litCount;
    var isClassicDiv = activeSlots === STRAND_BEADS && (i === 10 || i === 21);
    var isGroupEnd = activeSlots < STRAND_BEADS && i === activeSlots;
    beads.push({
      i: i, x: pt.x, y: pt.y, deg: pt.deg,
      inTarget: inTarget, isLit: isLit, isCur: isCur,
      isDiv: isClassicDiv || isGroupEnd
    });
  }

  var rActive = activeSlots <= 5 ? 8.2 : activeSlots <= 12 ? 7.4 : 6.2;
  var rRest = 5.4;

  return html`<div class=${W.cx("misbaha-wrap", fin && "is-done", landmark && "is-landmark")} data-id="misbaha">
    <svg class="misbaha-svg" data-id="misbaha-svg" viewBox="0 0 260 258" width=${fin ? "202" : "242"} height=${fin ? "200" : "240"} aria-hidden="true">
      <defs>
        <filter id="msb-drop" x="-25%" y="-25%" width="150%" height="155%">
          <feDropShadow dx="0" dy="2.2" stdDeviation="2.1" flood-color="#0b1009" flood-opacity="0.26" />
        </filter>
        <radialGradient id="msb-bead-lit" cx="34%" cy="30%" r="68%">
          <stop offset="0%" stop-color="#ffffff" stop-opacity="0.72" />
          <stop offset="28%" stop-color="var(--accent)" stop-opacity="0.92" />
          <stop offset="78%" stop-color="var(--accent)" />
          <stop offset="100%" stop-color="#0d150b" stop-opacity="0.88" />
        </radialGradient>
        <radialGradient id="msb-bead-done" cx="34%" cy="30%" r="68%">
          <stop offset="0%" stop-color="#ffffff" stop-opacity="0.78" />
          <stop offset="30%" stop-color="var(--good)" stop-opacity="0.94" />
          <stop offset="80%" stop-color="var(--good)" />
          <stop offset="100%" stop-color="#0a2413" stop-opacity="0.9" />
        </radialGradient>
        <radialGradient id="msb-bead-target" cx="33%" cy="28%" r="70%">
          <stop offset="0%" stop-color="#ffffff" stop-opacity="0.95" />
          <stop offset="45%" stop-color="var(--surface)" />
          <stop offset="84%" stop-color="var(--surface-2)" />
          <stop offset="100%" stop-color="var(--line)" />
        </radialGradient>
        <radialGradient id="msb-bead-cur" cx="33%" cy="28%" r="70%">
          <stop offset="0%" stop-color="#ffffff" />
          <stop offset="45%" stop-color="var(--accent-soft)" />
          <stop offset="88%" stop-color="var(--accent)" stop-opacity="0.55" />
          <stop offset="100%" stop-color="var(--accent)" />
        </radialGradient>
        <radialGradient id="msb-bead-rest" cx="34%" cy="30%" r="70%">
          <stop offset="0%" stop-color="var(--surface)" stop-opacity="0.9" />
          <stop offset="55%" stop-color="var(--surface-2)" />
          <stop offset="100%" stop-color="var(--line)" />
        </radialGradient>
        <linearGradient id="msb-imam-3d" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#0e160b" stop-opacity="0.55" />
          <stop offset="32%" stop-color="#ffffff" stop-opacity="0.45" />
          <stop offset="65%" stop-color="var(--accent)" stop-opacity="0.2" />
          <stop offset="100%" stop-color="#090f07" stop-opacity="0.65" />
        </linearGradient>
      </defs>

      <g class="misbaha-tassel-group" key=${"tas-" + done}>
        <path class="misbaha-tassel" d="M130 22 C130 14, 130 8, 130 3 M130 21 C126 14, 121 9, 117 4 M130 21 C134 14, 139 9, 143 4 M130 21 C128 13, 125 8, 123 3.5 M130 21 C132 13, 135 8, 137 3.5" fill="none" />
        <circle class="misbaha-knot" cx="130" cy="22" r="3.8" filter="url(#msb-drop)" />
        <circle cx="128.8" cy="20.8" r="1.2" fill="#ffffff" fill-opacity="0.55" />
      </g>

      <g class="misbaha-imam-group" filter="url(#msb-drop)">
        <path class="misbaha-imam" d="M126 25.5 Q130 24 134 25.5 L136.2 35 Q137 42 133.8 49.5 L133 53.5 Q130 55 127 53.5 L126.2 49.5 Q123 42 123.8 35 Z" />
        <path d="M126 25.5 Q130 24 134 25.5 L136.2 35 Q137 42 133.8 49.5 L133 53.5 Q130 55 127 53.5 L126.2 49.5 Q123 42 123.8 35 Z" fill="url(#msb-imam-3d)" />
        <ellipse cx="130" cy="31.5" rx="5.6" ry="1.3" fill="#ffffff" fill-opacity="0.32" />
        <ellipse cx="130" cy="46.5" rx="4.7" ry="1.1" fill="#000000" fill-opacity="0.22" />
        <circle class="misbaha-knot" cx="130" cy="56.5" r="3.2" />
      </g>

      <path class="misbaha-cord-shadow" d=${cordD} fill="none" />
      <path class="misbaha-cord" d=${cordD} fill="none" />

      <g filter="url(#msb-drop)">
        ${beads.map(function (b) {
          if (b.isDiv && !b.inTarget) {
            return html`<g key=${b.i} transform=${"translate(" + b.x + " " + b.y + ") rotate(" + b.deg.toFixed(1) + ")"}>
              <rect class="misbaha-divider-disk" x="-5.8" y="-2.5" width="11.6" height="5" rx="2.4" />
              <ellipse cx="-1.8" cy="-0.7" rx="2.6" ry="0.9" fill="#ffffff" fill-opacity="0.55" />
            </g>`;
          }
          if (b.isDiv && b.inTarget) {
            var s = (b.isCur ? rActive * 1.65 : rActive * 1.42).toFixed(2);
            var half = (s / 2).toFixed(2);
            var divFill = fin ? "url(#msb-bead-done)" : b.isLit ? "url(#msb-bead-lit)" : b.isCur ? "url(#msb-bead-cur)" : "url(#msb-bead-target)";
            return html`<g key=${b.i} transform=${"translate(" + b.x + " " + b.y + ") rotate(" + (b.deg + 45).toFixed(1) + ")"}>
              ${b.isCur ? html`<circle class="misbaha-cur-halo" cx="0" cy="0" r=${(rActive * 1.95).toFixed(1)} fill="none" />` : null}
              <rect class=${W.cx("misbaha-bead", "is-divider", b.isLit && "is-lit", b.isCur && "is-cur")}
                x=${-half} y=${-half} width=${s} height=${s} rx="2.8" style=${{ fill: divFill }} />
            </g>`;
          }
          var r = !b.inTarget ? rRest : (b.isCur ? rActive * 1.24 : rActive);
          var fillUrl = !b.inTarget ? "url(#msb-bead-rest)"
            : fin ? "url(#msb-bead-done)"
            : b.isLit ? "url(#msb-bead-lit)"
            : b.isCur ? "url(#msb-bead-cur)"
            : "url(#msb-bead-target)";
          return html`<g key=${b.i} class=${W.cx(!b.inTarget && "is-resting-bead")}>
            ${b.isCur ? html`<circle class="misbaha-cur-halo" cx=${b.x} cy=${b.y} r=${(r + 4.8).toFixed(1)} fill="none" />` : null}
            <circle class=${W.cx("misbaha-bead", b.inTarget ? "is-target" : "is-rest", b.isLit && "is-lit", b.isCur && "is-cur")}
              cx=${b.x} cy=${b.y} r=${r.toFixed(2)} style=${{ fill: fillUrl }} />
            <ellipse class="misbaha-shine"
              cx=${(b.x - r * 0.3).toFixed(2)} cy=${(b.y - r * 0.32).toFixed(2)}
              rx=${Math.max(1.1, r * 0.3).toFixed(2)} ry=${Math.max(0.8, r * 0.2).toFixed(2)}
              transform=${"rotate(-32 " + (b.x - r * 0.3).toFixed(2) + " " + (b.y - r * 0.32).toFixed(2) + ")"} />
          </g>`;
        })}
      </g>
    </svg>

    <div class="misbaha-center">
      ${done > 0 && !fin ? html`<span class=${W.cx("tap-pulse", landmark && "is-landmark")} key=${done} aria-hidden="true"></span>` : null}
      ${fin ? html`<span class="misbaha-done-ic">${W.Icon({ name: "check", size: 34 })}</span>` : null}
      <span class="card-count num" data-id="card-count" data-done=${done} data-piece=${piece}>
        ${!fin ? html`<span class="card-count-n m-count" key=${done}>${done}</span>` : null}
        <span class="card-count-of">${fin ? done + " " + W.t("card.of", { n: piece }) : W.t("card.of", { n: piece })}</span>
      </span>
    </div>
  </div>`;
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

function isReciting() {
  var s = W.S.state;
  if (s.eng && s.eng.prefs && s.eng.prefs.recite !== undefined) return !!s.eng.prefs.recite;
  if (s.ui && s.ui.answers && s.ui.answers.recite !== undefined) return !!s.ui.answers.recite;
  return true;
}

function toggleRecite() {
  var next = !isReciting();
  var s = W.S.state;
  if (s.eng && s.eng.prefs) {
    W.act("recite", function (st) {
      var prefs = Object.assign({}, st.eng.prefs, { recite: next });
      st.eng = E.rollDay(Object.assign({}, st.eng, { prefs: prefs }), W.now());
    });
  } else {
    if (!s.ui.answers) s.ui.answers = {};
    s.ui.answers.recite = next;
    W.save();
    W.emit();
  }
}

function Sparks() {
  return html`<span class="cele-sparks" aria-hidden="true">
    <i class="sp-1"></i><i class="sp-2"></i><i class="sp-3"></i>
    <i class="sp-4"></i><i class="sp-5"></i><i class="sp-6"></i>
  </span>`;
}

function nextMilestone(total) {
  var list = W.MILESTONES || [33, 100, 300, 500, 1000, 5000, 10000];
  for (var i = 0; i < list.length; i++) if (list[i] > total) return list[i];
  return Math.ceil((total + 1) / 5000) * 5000;
}

function unlockedGemsFor(it, en) {
  var out = [];
  if (it) {
    var f = en ? (it.en || it.arNote) : (it.arNote || it.en);
    var t = en ? (it.tadabburEn || it.tadabburAr) : (it.tadabburAr || it.tadabburEn);
    if (f) out.push(f);
    if (t && t !== f) out.push(t);
  }
  var s = W.S && W.S.state && W.S.state.eng;
  var total = (s && s.lifetime) || 0;
  if (total > 0) {
    out.push(W.t("card.cele.seed", { total: total, next: nextMilestone(total) }));
  }
  return out;
}

W.Card = function Card(p) {
  var size = W.cardSizeFor(p.id, p.size || "small");
  var piece = Math.max(1, p.piece || 1), done = W.clamp(p.done || 0, 0, piece), fin = done >= piece;
  var it = W.lib(p.id), en = W.U().lang === "en";
  var recite = isReciting();
  var landmark = W.isLandmarkBead(done, piece);
  var gemSt = W.useState(0), gemIdx = gemSt[0], setGemIdx = gemSt[1];

  var tap = fin ? null : (p.onTap ? function () {
    W.feelBead(done + 1, piece);
    p.onTap();
  } : null);

  function key(e) { if (tap && (e.key === " " || e.key === "Enter")) { e.preventDefault(); tap(); } }
  var count = html`<span class="card-count num" data-id="card-count" data-done=${done} data-piece=${piece}>
    <span class="card-count-n m-count" key=${done}>${done}</span><span class="card-count-of">${W.t("card.of", { n: piece })}</span>
  </span>`;
  var day = p.extra ? W.t("card.extra", { n: p.dayDone || 0 })
    : p.dayTarget ? W.t("card.day", { done: p.dayDone || 0, target: p.dayTarget }) : null;
  var cls = W.cx("card", "card-" + size, fin && "is-done");
  var reciteBtn = !fin ? html`<button type="button"
    class=${W.cx("card-recite-pill", !recite && "is-off")}
    data-id="card-recite"
    aria-pressed=${recite ? "true" : "false"}
    onClick=${stop(toggleRecite)}
    onKeyDown=${function (e) { if (e.key === " " || e.key === "Enter") e.stopPropagation(); }}>
    ${W.Icon({ name: recite ? "sound" : "sound-off", size: 18 })}
    <span>${W.t(recite ? "card.reciting" : "card.reciting.off")}</span>
  </button>` : null;

  if (size === "banner") {
    return html`<div class=${W.cx(cls, "card-small", "card-banner", "m-enter")} data-id="card" data-size="banner" role="button" tabIndex="0" onClick=${tap} onKeyDown=${key}>
      <div class="card-banner-top">
        ${reciteBtn}
        <span class="card-banner-actions">
          <${W.Btn} kind="soft" icon="later" label=${W.t("btn.later")} id="card-later" onClick=${stop(p.onLater)} disabled=${fin} />
          <${W.Btn} kind="text" icon="close" label=${W.t("btn.close")} id="card-close" onClick=${stop(p.onClose)} />
        </span>
      </div>
      <div class="card-banner-main">
        <span class=${W.cx("ring-stage", "m-ring", fin && "m-piece-done")} key=${fin ? "done" : "go"}>
          ${done > 0 && !fin ? html`<span class=${W.cx("tap-pulse", landmark && "is-landmark")} key=${done} aria-hidden="true"></span>` : null}
          ${fin ? html`<${Sparks} />` : null}
          <${W.Ring} done=${done} total=${piece} size=${48} label=${String(done)} />
        </span>
        <div class="card-banner-copy">
          <${W.DhikrText} id=${p.id} />
          <span class="card-banner-sub quiet num">${fin ? W.t("card.cele.added", { n: piece }) : W.t("card.of", { n: piece })}</span>
        </div>
      </div>
    </div>`;
  }

  if (size === "small") {
    return html`<div class=${W.cx(cls, "m-enter")} data-id="card" data-size="small" role="button" tabIndex="0" onClick=${tap} onKeyDown=${key}>
      <div class="card-small-top">
        <p class="card-hint" data-id="card-hint">${fin ? W.t("card.cele.title") : (landmark ? W.t("card.bead.landmark", { n: done }) : W.t("card.hint.small"))}</p>
        ${reciteBtn}
      </div>
      <${W.DhikrText} id=${p.id} />
      <div class="card-meter">
        <span class=${W.cx("ring-stage", "m-ring", fin && "m-piece-done")} key=${fin ? "done" : "go"}>
          ${done > 0 && !fin ? html`<span class=${W.cx("tap-pulse", landmark && "is-landmark")} key=${done} aria-hidden="true"></span>` : null}
          ${fin ? html`<${Sparks} />` : null}
          <${W.Ring} done=${done} total=${piece} size=${56} />
        </span>
        ${count}
        ${fin ? html`<span class="cele-pill num m-enter" data-id="card-cele">${W.t("card.cele.added", { n: piece })}</span>`
          : day ? html`<span class="card-day num" data-id="card-day">${day}</span>` : null}
      </div>
      <div class="card-actions">
        <${W.Btn} kind="soft" icon="later" label=${W.t("btn.later")} id="card-later" onClick=${stop(p.onLater)} disabled=${fin} />
        <${W.Btn} kind="text" icon="close" label=${W.t("btn.close")} id="card-close" onClick=${stop(p.onClose)} />
      </div>
    </div>`;
  }

  var page = size === "page";
  var gems = unlockedGemsFor(it, en);
  var curGem = gems.length ? gems[gemIdx % gems.length] : null;

  return html`<div class=${cls} data-id="card" data-size=${size} role="button" tabIndex="0" onClick=${tap} onKeyDown=${key}>
    ${!page ? html`<div class="card-bar">
      <${W.Btn} kind="soft" icon="later" label=${W.t("btn.later")} id="card-later" onClick=${stop(p.onLater)} disabled=${fin} />
      ${p.title ? html`<span class="card-title num" data-id="card-title">${p.title}</span>` : null}
      <${W.Btn} kind="text" icon="close" label=${W.t("btn.close")} id="card-close" onClick=${stop(p.onClose)} />
    </div>` : null}
    <div class="card-body">
      <div class="card-orn-row">
        <${W.Ornament} />
        ${reciteBtn}
      </div>
      <${W.DhikrText} id=${p.id} />
    </div>
    <div class="card-foot">
      <div class=${W.cx("misbaha-stage", fin && "m-piece-done")} key=${fin ? "done" : "go"}>
        ${fin ? html`<${Sparks} />` : null}
        <${W.Misbaha} done=${done} piece=${piece} />
      </div>
      ${fin ? html`<div class="card-cele m-day-done" data-id="card-cele">
        <div class="card-cele-head">
          <span class="cele-pill num">${W.t("card.cele.added", { n: piece })}</span>
          <p class="card-cele-title title" data-id="card-hint">${W.t("card.cele.title")}</p>
        </div>
        ${curGem ? html`<div class="cele-gem-box" data-id="cele-gem">
          <div class="cele-gem-head">
            ${W.Icon({ name: "sparkle", size: 18 })}
            <span>${W.t("card.cele.gem")}</span>
            ${gems.length > 1 ? html`<button type="button" class="cele-gem-next" data-id="cele-another"
              onClick=${stop(function () { setGemIdx(gemIdx + 1); })}>
              ${W.Icon({ name: "undo", size: 16 })}<span>${W.t("card.cele.another")}</span>
            </button>` : null}
          </div>
          <p class="card-cele-fadl">${curGem}</p>
        </div>` : null}
        ${day ? html`<p class="card-day num" data-id="card-day">${day}</p>` : null}
        ${page && (!p.inSession || p.onAgain) ? html`<div class="card-cele-actions" data-id="card-cele-actions">
          ${p.onNextDhikr
            ? html`<${W.Btn} kind="main" wide=${true} icon="forward" label=${W.t("card.cele.next")} id="cele-next" onClick=${stop(p.onNextDhikr)} />`
            : html`<${W.Btn} kind="main" wide=${true} icon="check" label=${W.t("card.cele.back")} id="cele-done" onClick=${stop(p.onClose)} />`}
          ${p.onAgain ? html`<${W.Btn} kind="soft" wide=${true} icon="undo" label=${W.t("session.again")} id="session-again" onClick=${stop(p.onAgain)} />` : null}
          ${p.onMore ? html`<${W.Btn} kind="soft" wide=${true} icon="add" label=${W.t("card.cele.more")} id="cele-more" onClick=${stop(p.onMore)} />` : null}
        </div>` : null}
      </div>` : html`<${W.R.Fragment}>
        ${landmark
          ? html`<p class="bead-landmark-pill m-count" data-id="bead-landmark">${W.Icon({ name: "sparkle", size: 18 })}<span>${W.t("card.bead.landmark", { n: done })}</span></p>`
          : html`<p class="card-hint" data-id="card-hint">${W.t("card.hint.full")}</p>`}
        ${day ? html`<p class="card-day num" data-id="card-day">${day}</p>` : null}
      <//>`}
      ${page && (p.onBack || p.onForward) ? html`<div class="card-nav">
        <${W.Btn} kind="soft" icon="back" label=${W.t("card.prev")} id="card-prev" onClick=${stop(p.onBack)} disabled=${!p.onBack} />
        <${W.Btn} kind="soft" icon="forward" label=${W.t("card.next")} id="card-next" onClick=${stop(p.onForward)} disabled=${!p.onForward} />
      </div>` : null}
    </div>
  </div>`;
};

W.cardProps = function (eng, card) {
  var a = (eng.adhkar || []).filter(function (x) { return x.id === card.id; })[0];
  var done = (eng.day.done && eng.day.done[card.id]) || 0, extra = (eng.day.extra && eng.day.extra[card.id]) || 0;
  return { id: card.id, piece: card.piece, done: card.done, extra: !!card.extra,
    dayDone: card.extra ? done + extra : done, dayTarget: a ? a.target : 0 };
};

var HOLD_MS = 1050, leaveTimer = 0;

function commit() { W.save(); W.emit(); }
W.toast = function (text, undo) { W.U().toast = { text: text, undo: !!undo, stamp: Date.now() }; commit(); };

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
W.cardLeave = function (how) {
  clearTimeout(leaveTimer);
  var s = W.S.state;
  if (s.eng.day && s.eng.day.showing) s.eng = E.leave(s.eng, W.now(), how);
  s.ui.popup = null;
  if (how === "later") s.ui.toast = { text: W.t("toast.later"), stamp: Date.now() };
  commit();
};

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
  var wantSize = pop === "full" ? "full" : (pop === "banner" || (pop !== "small" && eng.prefs && eng.prefs.cardSize === "banner")) ? "banner" : "small";
  var size = wantSize === "full" ? "full" : W.cardSizeFor(card.id, wantSize);
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

W.wbTools.push(function () {
  function show(size) {
    return function () {
      if (W.U().popup) W.cardLeave("ignore");
      if (!W.showReminder(size)) W.wbNote("Nothing to remind about right now (paused, no adhkar, or a moment has just started).");
    };
  }
  return html`<span class="wb-seg" role="group" aria-label="Show a reminder now" data-id="wb-remind">
    <span class="wb-seg-label">Reminder now</span>
    <button type="button" class="wb-seg-btn" data-id="wb-remind-banner" onClick=${show("banner")}>Banner</button>
    <button type="button" class="wb-seg-btn" data-id="wb-remind-small" onClick=${show("small")}>Small</button>
    <button type="button" class="wb-seg-btn" data-id="wb-remind-full" onClick=${show("full")}>Full</button>
    <button type="button" class="wb-seg-btn" data-id="wb-remind-lock" onClick=${show("lock")}>Lock screen</button>
  </span>`;
});
})();
