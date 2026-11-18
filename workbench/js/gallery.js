/* gallery.js: route "gallery". Shows the look's tokens, every icon, every part in its states and every motion
   with a replay button, each with a data-id the owner can pin a comment on.
   Labels here are workbench chrome (English); the samples are app words and real adhkar from W.LIB. */
(function () {
"use strict";
var W = window.W, html = W.html;

var OLIVE = { name: "Olive", line: "Olive wood and lime plaster. Soft round corners and pill buttons, IBM Plex Sans Arabic for words, Amiri Regular for the dhikr set centred like a line on a page, and one small eight-point star between fine rules." };
var COLOURS = ["--bg", "--surface", "--surface-2", "--ink", "--ink-2", "--line", "--accent", "--accent-ink", "--accent-soft", "--good", "--warn"];
var MOTIONS = [
  ["m-count", "The count landing: each tap's new number rises into place."],
  ["m-piece-done", "A piece completing: the card swells a little and settles."],
  ["m-ring", "A ring filling: the arc turns to its new place."],
  ["m-day-done", "The day completing: the mark turns into place, then the words."],
  ["m-enter", "A card arriving: it rises a short way and fades in."],
  ["m-leave", "A card leaving: it sinks back the way it came."],
  ["m-screen", "One screen handing over to the next, from the reading direction."]
];

function lib(id) {
  var hit = (W.LIB || []).filter(function (x) { return x.id === id; })[0];
  return hit ? hit.ar : "";
}
function tokenValue(name) {
  try { return window.getComputedStyle(document.documentElement).getPropertyValue(name).trim(); } catch (e) { return ""; }
}
function sampleDir() { return W.U().lang === "en" ? "ltr" : "rtl"; }

function Item(p) {
  return html`<div class=${W.cx("gal-item", p.className)} data-id=${p.id}>
    ${p.label ? html`<div class="gal-label">${p.label}</div>` : null}
    ${p.children}
  </div>`;
}
function Sample(p) {
  return html`<div class=${W.cx("gal-sample", p.className)} dir=${sampleDir()} lang=${W.U().lang}>${p.children}</div>`;
}

/* ---------- colours and type ---------- */
function Tokens() {
  var ui = W.U();
  return html`<section class="gal-sec" data-id="g-sec-colours">
    <h2 class="gal-h2">Colours and type</h2>
    <div class="gal-swatches">${COLOURS.map(function (n) {
      return html`<div class="gal-swatch" key=${n} data-id=${"g-token-" + n.slice(2)}>
        <span class="gal-chip" style=${{ background: "var(" + n + ")" }}></span>
        <code>${n}</code><span class="gal-val">${tokenValue(n)}</span>
      </div>`;
    })}</div>
    <div class="gal-grid-2">
      <${Item} id="g-token-font-ui" label=${"--font-ui at --text (" + tokenValue("--text") + ") and --text-lg (" + tokenValue("--text-lg") + ")"}>
        <${Sample}><p class="title">${W.t("group.morning")}</p><p class="gal-p">${W.t("level.daily")}. ${W.t("freq.few")}</p>
          <p class="gal-p quiet num">${W.t("count.left", { n: 37 })}</p><//>
      <//>
      <${Item} id="g-token-text-xl" label=${"--text-xl (" + tokenValue("--text-xl") + "), numbers tabular"}>
        <${Sample}><p class="gal-xl num">0123456789</p><p class="gal-xl num">100</p><//>
      <//>
    </div>
    <${Item} id="g-token-font-dhikr" label=${"--font-dhikr at --text-dhikr (" + tokenValue("--text-dhikr") + "), line height " + tokenValue("--dhikr-lh")}>
      <${Sample}><div class="panel gal-panel">
        <p class="dhikr">${lib("d11ccb91029")}</p>
        <${W.Ornament} id="g-token-ornament" />
        <p class="dhikr">سُبْحَانَ اللَّهِ وَبِحَمْدِهِ</p>
      </div><//>
    <//>
    <div class="gal-shapes">
      <${Item} id="g-token-radius" label="--radius"><div class="gal-shape" style=${{ borderRadius: "var(--radius)" }}></div><//>
      <${Item} id="g-token-radius-lg" label="--radius-lg"><div class="gal-shape" style=${{ borderRadius: "var(--radius-lg)" }}></div><//>
      <${Item} id="g-token-shadow" label="--shadow"><div class="gal-shape gal-shadow"></div><//>
      <${Item} id="g-token-tap" label=${"--tap (" + tokenValue("--tap") + ")"}><div class="gal-tap"></div><//>
    </div>
    <p class="gal-note">Olive (${ui.theme}), text size ${ui.size} of 7. Switch with the URL keys theme=light|dark, size=1..7, lang=ar|en.</p>
  </section>`;
}

/* ---------- icons ---------- */
function Icons() {
  return html`<section class="gal-sec" data-id="g-sec-icons">
    <h2 class="gal-h2">Icons</h2>
    <p class="gal-note">One family on a 24 grid, one stroke, round ends. Each shown at 48 and 24 px. In the app an icon always sits beside its word.</p>
    <div class="gal-icons">${Object.keys(W.ICONS).map(function (n) {
      return html`<div class="gal-icon" key=${n} data-id=${"g-icon-" + n}>
        <div class="gal-icon-art">${W.Icon({ name: n, size: 48 })}${W.Icon({ name: n, size: 24 })}</div>
        <code>${n}</code>
      </div>`;
    })}</div>
  </section>`;
}

/* ---------- parts ---------- */
function Parts() {
  var s = W.useState(30), step = s[0], setStep = s[1];
  var c = W.useState("few"), choice = c[0], setChoice = c[1];
  var t = W.useState("today"), tab = t[0], setTab = t[1];
  var o = W.useState(true), sheet = o[0], setSheet = o[1];
  var k = W.useState(0), toast = k[0], setToast = k[1];
  var noop = function () {};
  return html`<section class="gal-sec" data-id="g-sec-parts">
    <h2 class="gal-h2">Parts</h2>
    <${Item} id="g-part-btn" label="W.Btn kind main, soft, text. Rows: normal, pressed, focused, disabled.">
      <${Sample} className="gal-btns">${[["", "normal"], ["is-pressed", "pressed"], ["is-focus", "focused"], ["", "disabled"]].map(function (st, i) {
        var off = st[1] === "disabled";
        return html`<div class="gal-btn-row" key=${i}>
          <${W.Btn} kind="main" icon="play" label=${W.t("btn.start")} id=${"g-btn-main-" + st[1]} className=${st[0]} disabled=${off} onClick=${noop} />
          <${W.Btn} kind="soft" icon="later" label=${W.t("btn.later")} id=${"g-btn-soft-" + st[1]} className=${st[0]} disabled=${off} onClick=${noop} />
          <${W.Btn} kind="text" icon="close" label=${W.t("btn.close")} id=${"g-btn-text-" + st[1]} className=${st[0]} disabled=${off} onClick=${noop} />
        </div>`;
      })}<//>
    <//>
    <div class="gal-grid-2">
      <${Item} id="g-part-ring" label="W.Ring done/total at 0, 3, 7 and 10 of 10; 64 and 40 px">
        <${Sample} className="gal-rings">
          <${W.Ring} done=${0} total=${10} size=${64} id="g-ring-0" />
          <${W.Ring} done=${3} total=${10} size=${64} id="g-ring-3" label="3" />
          <${W.Ring} done=${7} total=${10} size=${64} id="g-ring-7" />
          <${W.Ring} done=${10} total=${10} size=${64} id="g-ring-10" />
          <${W.Ring} done=${7} total=${10} size=${40} id="g-ring-small" />
        <//>
      <//>
      <${Item} id="g-part-ornament" label="W.Ornament, the look's one ornament">
        <${Sample}><${W.Ornament} id="g-orn" /><div class="gal-orn-bare"><${W.Ornament} id="g-orn-bare" bare=${true} size=${56} /></div><//>
      <//>
    </div>
    <${Item} id="g-part-row" label="W.Row: with a ring and a dhikr title, with an icon and a chevron, done">
      <${Sample} className="gal-stack">
        <${W.Row} id="g-row-1" dhikr=${true} title=${lib("db5fd486b57")} sub=${W.t("count.left", { n: 20 })}
          lead=${html`<${W.Ring} done=${10} total=${30} size=${48} />`} onClick=${noop} />
        <${W.Row} id="g-row-2" icon="sunrise" title=${W.t("moment.waking")} sub=${W.t("group.sleep")} onClick=${noop} />
        <${W.Row} id="g-row-3" dhikr=${true} done=${true} title=${lib("d516bd15e8a")}
          lead=${html`<${W.Ring} done=${100} total=${100} size=${48} />`} />
      <//>
    <//>
    <div class="gal-grid-2">
      <${Item} id="g-part-stepper" label="W.Stepper value, step 10, mark at the sunnah 100">
        <${Sample}><${W.Stepper} id="g-stepper" value=${step} step=${10} mark=${100} unit=${W.t("step.aday")} onChange=${setStep} /><//>
      <//>
      <${Item} id="g-part-choice" label="W.Choice options, one chosen">
        <${Sample}><${W.Choice} id="g-choice" value=${choice} onChange=${setChoice} options=${[
          { value: "few", label: W.t("freq.few") }, { value: "hour", label: W.t("freq.hour") }, { value: "often", label: W.t("freq.often") }
        ]} /><//>
      <//>
    </div>
    <div class="gal-grid-2">
      <${Item} id="g-part-tabbar" label="W.TabBar, the three places">
        <${Sample}><${W.TabBar} id="g-tabbar" route=${tab} onGo=${setTab} /><//>
      <//>
      <${Item} id="g-part-toast" label="W.Toast with Undo; leaves by itself after 6 seconds">
        <${Sample}><${W.Toast} id="g-toast" text=${W.t("toast.later")} stamp=${toast} onUndo=${noop} /><//>
        <button type="button" class="gal-replay" data-id="g-toast-again" onClick=${function () { setToast(toast + 1); }}>${W.Icon({ name: "play", size: 18 })}<span>Show again</span></button>
      <//>
    </div>
    <${Item} id="g-part-sheet" label="W.Sheet, rising from the bottom of its box">
      <${Sample} className="gal-phone">
        <div class="gal-phone-under"><p class="title">${W.t("tab.adhkar")}</p>
          <${W.Row} id="g-sheet-under" icon="sun" title=${W.t("group.morning")} onClick=${function () { setSheet(true); }} /></div>
        <${W.Sheet} id="g-sheet" open=${sheet} title=${W.t("moment.morning")} onClose=${function () { setSheet(false); }}>
          <p class="dhikr">${lib("df563766dac")}</p>
          <${W.Btn} kind="main" wide=${true} icon="play" label=${W.t("btn.start")} id="g-sheet-start" onClick=${noop} />
        <//>
      <//>
    <//>
  </section>`;
}

/* ---------- motion ---------- */
function RingDemo(p) {
  var s = W.useState(0), done = s[0], setDone = s[1];
  W.useEffect(function () {
    setDone(0);
    var id = setTimeout(function () { setDone(7); }, 80);
    return function () { clearTimeout(id); };
  }, [p.n]);
  return html`<div class="m-ring"><${W.Ring} done=${done} total=${10} size=${88} id="g-motion-ring" /></div>`;
}
function LeaveDemo(p) {
  var s = W.useState(false), leaving = s[0], setLeaving = s[1];
  W.useEffect(function () {
    if (!p.n) return undefined;
    setLeaving(true);
    var id = setTimeout(function () { setLeaving(false); }, 1000);
    return function () { clearTimeout(id); };
  }, [p.n]);
  return html`<div class=${W.cx("panel gal-card", leaving && "m-leave")}><p class="dhikr">${lib("d2652166f09")}</p></div>`;
}
var DEMOS = {
  "m-count": function (n) { return html`<span class="gal-count num m-count" key=${n}>${7 + n}</span>`; },
  "m-piece-done": function (n) {
    return html`<div class="panel gal-card gal-piece m-piece-done" key=${n}>
      <${W.Ring} done=${10} total=${10} size=${48} /><span class="gal-count-sm num">10 / 10</span></div>`;
  },
  "m-ring": function (n) { return html`<${RingDemo} n=${n} />`; },
  "m-day-done": function (n) {
    return html`<div class="gal-day m-day-done" key=${n}>
      <span class="m-day-mark"><${W.Ornament} bare=${true} size=${64} /></span>
      <p class="dhikr m-day-text">${lib("d74bf8e76b3")}</p></div>`;
  },
  "m-enter": function (n) { return html`<div class="panel gal-card m-enter" key=${n}><p class="dhikr">${lib("d904e76671e")}</p></div>`; },
  "m-leave": function (n) { return html`<${LeaveDemo} n=${n} />`; },
  "m-screen": function (n) {
    return html`<div class="gal-mini m-screen" key=${n}><p class="title">${W.t("tab.today")}</p>
      <${W.Row} icon="moon" title=${W.t("moment.evening")} sub=${W.t("count.left", { n: 9 })} /></div>`;
  }
};
function MotionItem(p) {
  var s = W.useState(0), n = s[0], setN = s[1];
  return html`<div class="gal-item gal-motion" data-id=${"g-motion-" + p.cls}>
    <${Sample} className="gal-stage">${DEMOS[p.cls](n)}<//>
    <div class="gal-motion-foot">
      <div><code>.${p.cls}</code><div class="gal-line">${p.line}</div></div>
      <button type="button" class="gal-replay" data-id=${"g-motion-" + p.cls + "-replay"} onClick=${function () { setN(n + 1); }}>
        ${W.Icon({ name: "play", size: 18 })}<span>Replay</span></button>
    </div>
  </div>`;
}
function Motion() {
  return html`<section class="gal-sec" data-id="g-sec-motion">
    <h2 class="gal-h2">Motion</h2>
    <p class="gal-note">Transform and opacity only. All of it is off under reduce motion and with data-motion="off" on the root.</p>
    <div class="gal-motions">${MOTIONS.map(function (m) { return html`<${MotionItem} key=${m[0]} cls=${m[0]} line=${m[1]} />`; })}</div>
  </section>`;
}

W.Gallery = function Gallery() {
  return html`<main class="app gal" data-screen="gallery" dir="ltr" lang="en">
    <header class="gal-head" data-id="g-head">
      <h1 class="gal-h1">Palette, icons and motion</h1>
      <p class="gal-look" data-id="g-look"><strong>${OLIVE.name}.</strong> ${OLIVE.line}</p>
    </header>
    <${Tokens} />
    <${Icons} />
    <${Parts} />
    <${Motion} />
  </main>`;
};
})();
