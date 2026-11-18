/* onboarding.js: seven steps on phone (six on Windows), one question each. Tapping an answer moves on;
   "Choose for me" takes the sensible default, so the whole thing finishes in six taps.
   Every answer is later one row in More, in the same words. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

var DEFAULTS = { level: "some", goal: "mix", freq: "hour", recite: true, wake: "06:00", sleep: "23:00", cardSize: "small" };
var TRY_TAPS = 3;
W.ANSWER_DEFAULTS = DEFAULTS;

/* "06:00" as people say it: 6:00 with morning or evening */
W.timeLabel = function (hhmm) {
  var p = String(hhmm).split(":"), h = +p[0], m = p[1] || "00";
  return ((h % 12) || 12) + ":" + m + " " + W.t(h < 12 ? "time.am" : "time.pm");
};
W.shiftTime = function (hhmm, by) {
  var p = String(hhmm).split(":"), t = ((+p[0] * 60 + +p[1] + by) % 1440 + 1440) % 1440;
  var h = Math.floor(t / 60), m = t % 60;
  return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
};

/* one time with Earlier and Later, half an hour a step */
W.TimeStep = function TimeStep(p) {
  return html`<div class="timestep" data-id=${p.id}>
    <span class="timestep-label">${p.label}</span>
    <div class="timestep-row">
      <button type="button" class="stepper-btn" data-id=${p.id + "-earlier"} onClick=${function () { p.onChange(W.shiftTime(p.value, -30)); }}>
        ${W.Icon({ name: "minus", size: 28 })}<span>${W.t("time.earlier")}</span></button>
      <span class="timestep-value num m-count" key=${p.value} data-id=${p.id + "-value"}>${W.timeLabel(p.value)}</span>
      <button type="button" class="stepper-btn" data-id=${p.id + "-later"} onClick=${function () { p.onChange(W.shiftTime(p.value, 30)); }}>
        ${W.Icon({ name: "add", size: 28 })}<span>${W.t("time.later")}</span></button>
    </div>
  </div>`;
};

function answers() {
  var ui = W.U();
  if (!ui.answers) ui.answers = {};
  return ui.answers;
}
function set(key, value) { answers()[key] = value; W.save(); W.emit(); }
function lastStep() { return W.U().frame === "windows" ? 6 : 7; }

/* builds the person's state from the answers and opens Today */
function finish() {
  var ui = W.U(), a = Object.assign({}, DEFAULTS, ui.answers || {});
  var d = new Date(W.now());
  /* the first look at Today is in the afternoon, when no timed moment is waiting, so the first dhikr is what shows */
  ui.now = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 14, 0).getTime();
  var eng = E.newState({
    level: a.level, goal: a.goal || "mix", freq: a.freq, recite: a.recite !== false,
    wake: a.wake, sleep: a.sleep, cardSize: a.cardSize
  }, W.LIB);
  if (a.goal === "moments") {
    eng = E.setMoment(E.setMoment(eng, "morning", { on: true }), "evening", { on: true });
  } else if (a.goal === "sleep") {
    eng = E.setMoment(E.setMoment(eng, "sleep", { on: true }), "waking", { on: true });
  }
  W.S.state.eng = E.rollDay(eng, ui.now);
  W.S.undo = [];
  ui.answers = null;
  W.go("today");
}
function goStep(n) { if (n > lastStep()) finish(); else W.go("onboarding/" + n); }

/* an answer was tapped: show it chosen for a moment, then move on */
function choose(step, key, value) {
  set(key, value);
  setTimeout(function () { if (W.U().route === "onboarding/" + step) goStep(step + 1); }, 260);
}

function Frame(p) {
  var total = lastStep();
  return html`<div class="ob" data-id="ob">
    <div class="ob-top">
      ${p.step > 1 ? html`<${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="ob-back" onClick=${function () { W.go("onboarding/" + (p.step - 1)); }} />` : html`<span></span>`}
      <span class="ob-step num" data-id="ob-step">${W.t("ob.step", { n: Math.min(p.step, total), total: total })}</span>
    </div>
    <div class="ob-dots" aria-hidden="true">${Array.apply(null, { length: total }).map(function (x, i) {
      return html`<i key=${i} class=${i < p.step ? "is-on" : null}></i>`;
    })}</div>
    <h1 class="ob-q title" data-id="ob-question">${p.q}</h1>
    ${p.sub ? html`<p class="ob-sub" data-id="ob-sub">${p.sub}</p>` : null}
    <div class="ob-main">${p.children}</div>
    <div class="ob-foot">
      ${p.main || null}
      ${p.onDefault ? html`<${W.Btn} kind="text" label=${W.t("btn.chooseforme")} id="choose-for-me" onClick=${p.onDefault} />` : null}
    </div>
  </div>`;
}

function StepLang() {
  var ui = W.U(), curSize = W.clamp(Number(ui.size) || 3, 1, 7);
  var pSt = W.useState(false), pOpen = pSt[0], setPOpen = pSt[1];
  function pick(v) { W.setLang(v); setTimeout(function () { if (W.U().route === "onboarding/1") goStep(2); }, 260); }
  return html`<${Frame} step=${1} q=${W.t("ob.lang.q")} onDefault=${function () { goStep(2); }}>
    <div class="panel ob-fontsize-box" data-id="ob-fontsize">
      <div class="ob-fontsize-head">
        <span class="ob-fontsize-lbl">${W.Icon({ name: "text-size", size: 20 })}<span>${W.t("ob.fontsize.label")}</span></span>
        <span class="ob-fontsize-val num">${curSize}/7</span>
      </div>
      <div class="size-slider-row">
        <button type="button" class="size-step-btn" data-id="ob-size-less" disabled=${curSize <= 1}
          aria-label=${W.t("step.less")} onClick=${function () { W.setSize(Math.max(1, curSize - 1)); }}>
          <span class="size-a-sm">A</span>
        </button>
        <input type="range" class="size-range" data-id="ob-size-slider" aria-label=${W.t("ob.fontsize.label")}
          min="1" max="7" step="1" value=${curSize}
          onInput=${function (e) { W.setSize(Number(e.target.value)); }}
          onChange=${function (e) { W.setSize(Number(e.target.value)); }} />
        <button type="button" class="size-step-btn" data-id="ob-size-more" disabled=${curSize >= 7}
          aria-label=${W.t("step.more")} onClick=${function () { W.setSize(Math.min(7, curSize + 1)); }}>
          <span class="size-a-lg">A</span>
        </button>
      </div>
    </div>
    <${W.Choice} id="ob-lang" value=${ui.lang} onChange=${pick}
      options=${[{ value: "ar", label: W.t("ob.lang.ar"), icon: "language" }, { value: "en", label: W.t("ob.lang.en"), icon: "language" }]} />
    <${W.Btn} kind="soft" wide=${true} icon="heart" label=${W.t("parent.btn")} id="ob-parent-preset"
      onClick=${function () { setPOpen(true); }} />
    <${W.ParentSheet} open=${pOpen} onClose=${function () { setPOpen(false); }} />
  <//>`;
}
function StepLevel() {
  var a = answers(), curGoal = a.goal || DEFAULTS.goal;
  return html`<${Frame} step=${2} q=${W.t("ob.level.q")} sub=${W.t("ob.level.sub")}
    onDefault=${function () { set("goal", curGoal); set("level", DEFAULTS.level); goStep(3); }}>
    <${W.Choice} id="ob-level" value=${a.level}
      onChange=${function (v) { if (!a.goal) set("goal", DEFAULTS.goal); choose(2, "level", v); }}
      options=${["new", "some", "daily"].map(function (k) {
        return { value: k, label: W.t("level." + k), sub: W.t("level." + k + ".sub") };
      })} />
    <div class="ob-goal-box" data-id="ob-goal">
      <p class="ob-goal-title quiet">${W.t("ob.goal.q")}</p>
      <div class="ob-goal-pills" role="radiogroup" aria-label=${W.t("ob.goal.q")}>
        ${[["mix", "sparkle"], ["day", "adhkar"], ["moments", "sun"], ["sleep", "moon"]].map(function (g) {
          var on = curGoal === g[0];
          return html`<button type="button" key=${g[0]} role="radio" aria-checked=${on ? "true" : "false"}
            class=${W.cx("ob-goal-pill", on && "is-on")} data-id=${"ob-goal-" + g[0]}
            onClick=${function () { set("goal", g[0]); }}>
            ${W.Icon({ name: g[1], size: 18 })}
            <span>${W.t("goal." + g[0])}</span>
          </button>`;
        })}
      </div>
    </div>
  <//>`;
}
function StepFreq() {
  var a = answers();
  return html`<${Frame} step=${3} q=${W.t("ob.freq.q")} sub=${W.t("ob.freq.sub")} onDefault=${function () { set("freq", DEFAULTS.freq); goStep(4); }}>
    <${W.Choice} id="ob-freq" value=${a.freq} onChange=${function (v) { choose(3, "freq", v); }}
      options=${["few", "hour", "often"].map(function (k) { return { value: k, label: W.t("freq." + k) }; })} />
  <//>`;
}
function StepRecite() {
  var a = answers(), val = a.recite === undefined ? null : (a.recite ? "yes" : "no");
  return html`<${Frame} step=${4} q=${W.t("ob.recite.q")} sub=${W.t("ob.recite.sub")}
    onDefault=${function () { set("recite", DEFAULTS.recite); goStep(5); }}>
    <${W.Choice} id="ob-recite" value=${val} onChange=${function (v) { choose(4, "recite", v === "yes"); }}
      options=${[
        { value: "yes", label: W.t("ob.recite.yes"), sub: W.t("ob.recite.yes.sub"), icon: "sound" },
        { value: "no", label: W.t("ob.recite.no"), sub: W.t("ob.recite.no.sub"), icon: "close" }
      ]} />
  <//>`;
}
function StepSleep() {
  var a = answers(), wake = a.wake || DEFAULTS.wake, sleep = a.sleep || DEFAULTS.sleep;
  function next() { set("wake", wake); set("sleep", sleep); goStep(6); }
  return html`<${Frame} step=${5} q=${W.t("ob.sleep.q")} sub=${W.t("ob.sleep.sub")}
    main=${html`<${W.Btn} kind="main" wide=${true} label=${W.t("btn.continue")} id="ob-next" onClick=${next} />`}
    onDefault=${function () { set("wake", DEFAULTS.wake); set("sleep", DEFAULTS.sleep); goStep(6); }}>
    ${W.SleepPicker
      ? html`<${W.SleepPicker} idPrefix="ob" compact=${true} wake=${wake} sleep=${sleep}
          onWake=${function (v) { set("wake", v); }} onSleep=${function (v) { set("sleep", v); }}
          onBoth=${function (w, s) { set("wake", w); set("sleep", s); }} />`
      : html`<${W.R.Fragment}>
          <${W.TimeStep} id="ob-wake" label=${W.t("ob.wake")} value=${wake} onChange=${function (v) { set("wake", v); }} />
          <${W.TimeStep} id="ob-sleeptime" label=${W.t("ob.sleep")} value=${sleep} onChange=${function (v) { set("sleep", v); }} />
        <//>`}
  <//>`;
}

/* try one: a real card, tapped three times, then the two sizes to choose between by seeing them */
function StepTry() {
  var a = answers(), n = Math.min(a.tried || 0, TRY_TAPS), ready = n >= TRY_TAPS, size = a.cardSize || DEFAULTS.cardSize;
  var first = W.LIB.filter(function (x) { return x.starter === 0; })[0];
  var card = { id: first.id, piece: TRY_TAPS, done: ready ? 1 : n, dayDone: n, dayTarget: 30 };
  function tap() { set("tried", (answers().tried || 0) + 1); }
  var sample = ready && size === "full"
    ? html`<div class="ob-full" data-id="ob-sample-full"><div class="ob-full-in"><${W.Card} ...${card} size="full" /></div></div>`
    : html`<${W.Card} ...${card} size="small" onTap=${ready ? null : tap} />`;
  return html`<${Frame} step=${6} q=${ready ? W.t("ob.try.pick") : W.t("ob.try.q")} sub=${ready ? null : W.t("ob.try.sub")}
    main=${ready ? html`<${W.Btn} kind="main" wide=${true} label=${W.t("btn.continue")} id="ob-next" onClick=${function () { set("cardSize", size); goStep(7); }} />` : null}
    onDefault=${ready ? null : function () { set("cardSize", DEFAULTS.cardSize); goStep(7); }}>
    <div class="ob-sample" data-id="ob-sample">${sample}</div>
    ${ready ? html`<${W.Choice} id="ob-size" value=${size} onChange=${function (v) { set("cardSize", v); }} options=${[
      { value: "small", label: W.t("ob.size.small"), sub: W.t("ob.size.small.sub"), icon: "card-small" },
      { value: "full", label: W.t("ob.size.full"), sub: W.t("ob.size.full.sub"), icon: "card-full" },
      { value: "banner", label: W.t("ob.size.banner"), sub: W.t("ob.size.banner.sub"), icon: "bell" }]} />` : null}
  <//>`;
}

/* phone only: the permissions, one at a time, one sentence each (pretend in the prototype) */
var PERMS = [["card-small", "ob.perm.1"], ["bell", "ob.perm.2"], ["history", "ob.perm.3"]];
function StepPerms() {
  var a = answers(), i = Math.min(a.perm || 0, PERMS.length - 1), perm = PERMS[i];
  function next(allowed) {
    if (!allowed) W.U().permissionMissing = true;
    if (i + 1 >= PERMS.length) { if (allowed && !a.refused) W.U().permissionMissing = false; finish(); return; }
    if (!allowed) answers().refused = true;
    set("perm", i + 1);
  }
  return html`<${Frame} step=${7} q=${W.t("ob.perm.q")}
    main=${html`<${W.Btn} kind="main" wide=${true} icon="check" label=${W.t("btn.allow")} id="perm-allow" onClick=${function () { next(true); }} />`}>
    <div class="ob-perm panel m-enter" key=${i} data-id="ob-perm">
      <span class="ob-perm-icon">${W.Icon({ name: perm[0], size: 44 })}</span>
      <h2 class="ob-perm-title">${W.t(perm[1] + ".t")}</h2>
      <p class="ob-perm-sub">${W.t(perm[1] + ".s")}</p>
      <span class="ob-perm-n num">${W.t("ob.step", { n: i + 1, total: PERMS.length })}</span>
    </div>
    <${W.Btn} kind="text" label=${W.t("btn.notnow")} id="perm-notnow" onClick=${function () { next(false); }} />
  <//>`;
}

var STEPS = [null, StepLang, StepLevel, StepFreq, StepRecite, StepSleep, StepTry, StepPerms];
W.screen("onboarding", function Onboarding(p) {
  var n = W.clamp(parseInt(p.arg, 10) || 1, 1, 7), Step = STEPS[n];
  return html`<${Step} />`;
});
})();
