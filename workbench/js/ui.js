/* ui.js: the shared parts every screen is built from, plus the 30-second Parent Preset helper & sheet. */
(function () {
"use strict";
var W = window.W, html = W.html;

function Btn(p) {
  var kind = p.kind || "main";
  return html`<button type="button" class=${W.cx("btn", "btn-" + kind, p.wide && "btn-wide", p.className)}
    data-id=${p.id} onClick=${p.onClick} disabled=${p.disabled}>
    ${p.icon ? W.Icon({ name: p.icon, size: kind === "text" ? 22 : 24 }) : null}
    <span class="btn-label">${p.label != null ? p.label : p.children}</span>
  </button>`;
}

function Ring(p) {
  var size = p.size || 48, total = Math.max(1, p.total || 1);
  var done = W.clamp(p.done || 0, 0, total), f = done / total, full = done >= total;
  var prev = W.useRef(f);
  var up = prev.current < 0.5 && f > 0.5, down = prev.current > 0.5 && f < 0.5;
  W.useEffect(function () { prev.current = f; });
  var s1 = { transform: "rotate(" + Math.min(f, 0.5) * 360 + "deg)" };
  var s2 = { transform: "rotate(" + Math.max(f - 0.5, 0) * 360 + "deg)" };
  if (up) { s1.transitionDuration = "200ms"; s1.transitionTimingFunction = "linear"; s2.transitionDelay = "200ms"; }
  if (down) { s2.transitionDuration = "200ms"; s2.transitionTimingFunction = "linear"; s1.transitionDelay = "200ms"; }
  return html`<span class=${W.cx("ring", full && "is-full", p.className)} data-id=${p.id}
    style=${{ "--ring": size + "px" }} role="img" aria-label=${done + " / " + total}>
    <span class="ring-arcs">
      <span class="ring-half ring-half-1"><span class="ring-fill" style=${s1}></span></span>
      <span class="ring-half ring-half-2"><span class="ring-fill" style=${s2}></span></span>
    </span>
    ${full ? html`<span class="ring-mid">${W.Icon({ name: "check", size: Math.round(size * 0.5) })}</span>`
      : p.label != null ? html`<span class="ring-mid ring-num">${p.label}</span>` : null}
  </span>`;
}

function Sheet(p) {
  if (!p.open) return null;
  var node = html`<div class=${W.cx("sheet-layer", p.popup && "is-popup")} data-id=${p.id}>
    <div class="sheet-scrim" onClick=${p.onClose}></div>
    <div class=${W.cx("sheet", p.popup && "is-popup", "m-enter")} role="dialog" aria-modal="true" aria-label=${p.title}>
      <div class="sheet-head">
        <h2 class="sheet-title">${p.title}</h2>
        ${p.onClose ? html`<${Btn} kind="text" icon="close" label=${W.t("btn.close")} id=${p.id + "-close"} onClick=${p.onClose} />` : null}
      </div>
      <div class="sheet-body">${p.children}</div>
      ${p.footer ? html`<div class="sheet-foot">${p.footer}</div>` : null}
    </div>
  </div>`;
  var host = !p.inline && typeof document !== "undefined" && document.querySelector ? document.querySelector(".screen-main") : null;
  return host && window.ReactDOM && window.ReactDOM.createPortal ? window.ReactDOM.createPortal(node, host) : node;
}

var TABS = [["today", "tab.today"], ["adhkar", "tab.adhkar"], ["more", "tab.more"]];
function TabBar(p) {
  var here = String(p.route != null ? p.route : W.U().route).split("/")[0];
  var go = p.onGo || W.go;
  return html`<nav class="tabbar" data-id=${p.id || "tabbar"}>${TABS.map(function (t) {
    var on = here === t[0];
    return html`<button type="button" key=${t[0]} class=${W.cx("tab", on && "is-on")} data-id=${"tab-" + t[0]}
      aria-current=${on ? "page" : null} onClick=${function () { go(t[0]); }}>
      <span class="tab-icon">${W.Icon({ name: t[0], size: 28 })}</span><span class="tab-word">${W.t(t[1])}</span>
    </button>`;
  })}</nav>`;
}

function Row(p) {
  var Tag = p.onClick ? "button" : "div";
  var lead = p.lead || (p.icon ? html`<span class="row-icon">${W.Icon({ name: p.icon, size: 28 })}</span>` : null);
  var end = p.end != null ? p.end : p.onClick ? W.Icon({ name: "forward", size: 22, className: "row-go" }) : null;
  return html`<${Tag} type=${p.onClick ? "button" : null} class=${W.cx("row", p.done && "is-done", p.className)}
    data-id=${p.id} onClick=${p.onClick}>
    ${lead}
    <span class="row-main">
      <span class=${W.cx("row-title", p.dhikr && "is-dhikr")}>${p.title}</span>
      ${p.sub != null ? html`<span class="row-sub">${p.sub}</span>` : null}
    </span>
    ${end != null ? html`<span class="row-end">${end}</span>` : null}
  <//>`;
}

function Stepper(p) {
  var step = p.step || 1, min = p.min == null ? 1 : p.min, max = p.max == null ? 9999 : p.max, v = p.value;
  function set(n) { n = W.clamp(n, min, max); if (n !== v) p.onChange(n); }
  var atMark = p.mark != null && v === p.mark;
  return html`<div class="stepper" data-id=${p.id}>
    <div class="stepper-row">
      <button type="button" class="stepper-btn" data-id=${p.id + "-less"} disabled=${v <= min}
        onClick=${function () { set(v - step); }}>${W.Icon({ name: "minus", size: 28 })}<span>${W.t("step.less")}</span></button>
      <span class="stepper-value">
        <span class="stepper-num m-count" key=${v}>${v}</span>
        ${p.unit ? html`<span class="stepper-unit">${p.unit}</span>` : null}
      </span>
      <button type="button" class="stepper-btn" data-id=${p.id + "-more"} disabled=${v >= max}
        onClick=${function () { set(v + step); }}>${W.Icon({ name: "add", size: 28 })}<span>${W.t("step.more")}</span></button>
    </div>
    ${p.mark != null ? html`<button type="button" class=${W.cx("stepper-mark", atMark && "is-on")} data-id=${p.id + "-mark"}
      aria-pressed=${atMark} onClick=${function () { set(p.mark); }}>
      ${W.Icon({ name: atMark ? "done" : "sparkle", size: 22 })}<span>${W.t("step.mark", { n: p.mark })}</span>
    </button>` : null}
  </div>`;
}

function Choice(p) {
  var id = p.id || "choice";
  return html`<div class="choices" role="radiogroup" data-id=${id}>${p.options.map(function (o) {
    var on = o.value === p.value;
    return html`<button type="button" key=${String(o.value)} role="radio" aria-checked=${on ? "true" : "false"}
      class=${W.cx("choice", on && "is-on")} data-id=${id + "-" + o.value} onClick=${function () { p.onChange(o.value); }}>
      ${o.icon ? html`<span class="choice-icon">${W.Icon({ name: o.icon, size: 28 })}</span>` : null}
      <span class="choice-main"><span class="choice-label">${o.label}</span>
        ${o.sub ? html`<span class="choice-sub">${o.sub}</span>` : null}</span>
      <span class="choice-mark">${on ? W.Icon({ name: "done", size: 28 }) : null}</span>
    </button>`;
  })}</div>`;
}

var TOAST_MS = 6000, LEAVE_MS = 220;
function Toast(p) {
  var st = W.useState("in"), phase = st[0], setPhase = st[1];
  var doneRef = W.useRef(p.onDone);
  doneRef.current = p.onDone;
  W.useEffect(function () {
    setPhase("in");
    var a = setTimeout(function () { setPhase("leaving"); }, TOAST_MS);
    var b = setTimeout(function () { setPhase("gone"); if (doneRef.current) doneRef.current(); }, TOAST_MS + LEAVE_MS);
    return function () { clearTimeout(a); clearTimeout(b); };
  }, [p.text, p.stamp]);
  if (!p.text || phase === "gone") return null;
  return html`<div class=${W.cx("toast", phase === "leaving" ? "m-leave" : "m-enter")} data-id=${p.id} role="status" aria-live="polite">
    <span class="toast-text">${p.text}</span>
    ${p.onUndo ? html`<button type="button" class="toast-undo" data-id=${p.id + "-undo"}
      onClick=${function () { p.onUndo(); setPhase("gone"); if (doneRef.current) doneRef.current(); }}>
      ${W.Icon({ name: "undo", size: 22 })}<span>${W.t("btn.undo")}</span></button>` : null}
  </div>`;
}

var STAR = '<rect x="6.5" y="6.5" width="11" height="11"/><rect x="6.5" y="6.5" width="11" height="11" transform="rotate(45 12 12)"/>';
function Ornament(p) {
  var size = p.size || 26;
  return html`<span class=${W.cx("orn", p.bare && "is-bare", p.className)} data-id=${p.id} aria-hidden="true">
    ${p.bare ? null : html`<span class="orn-line"></span>`}<svg class="orn-a" viewBox="0 0 24 24" width=${size} height=${size} fill="none" stroke="currentColor"
      strokeWidth=${size > 40 ? 0.9 : 1.25} strokeLinejoin="round" strokeLinecap="round" dangerouslySetInnerHTML=${{ __html: STAR }}></svg>${p.bare ? null : html`<span class="orn-line"></span>`}
  </span>`;
}

/* 30-second Parent & Elder Preset: configures text size, calm voice recitation, misbaha card style, soft bead sound, and daily moments */
W.applyParentPreset = function (opts) {
  var cfg = Object.assign({ size: 7, recite: true, cardSize: "full", momentsOn: true }, opts || {});
  var E = W.E, ui = W.U();
  ui.size = W.clamp(Number(cfg.size) || 7, 1, 7);
  ui.answers = null;
  ui.permissionMissing = false;
  var wantRecite = cfg.recite !== false;
  var wantCard = cfg.cardSize === "small" ? "small" : "full";
  var wantMoments = cfg.momentsOn !== false;
  if (!(W.S.state.eng && W.S.state.eng.prefs)) {
    var d = new Date(W.now());
    ui.now = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 14, 0).getTime();
    var fresh = E.newState({
      level: "some", freq: "hour", recite: wantRecite,
      wake: "06:00", sleep: "22:30", cardSize: wantCard
    }, W.LIB);
    fresh.prefs.sound = "soft";
    ["waking", "morning", "evening", "sleep"].forEach(function (k) {
      fresh.prefs.moments[k] = { on: wantMoments, at: null };
    });
    W.S.state.eng = E.rollDay(fresh, ui.now);
    W.S.undo = [];
  } else {
    W.act("parent-preset", function (s) {
      if (s.eng.prefs && s.eng.prefs.level === "daily" && E.setLevel) {
        s.eng = E.setLevel(s.eng, "some");
      }
      var prefs = Object.assign({}, s.eng.prefs, {
        cardSize: wantCard, recite: wantRecite, sound: "soft", freq: "hour"
      });
      var moments = {};
      ["waking", "morning", "evening", "sleep"].forEach(function (k) {
        var cur = (prefs.moments && prefs.moments[k]) || {};
        moments[k] = { on: wantMoments, at: cur.at == null ? null : cur.at };
      });
      prefs.moments = moments;
      s.eng = E.rollDay(Object.assign({}, s.eng, { prefs: prefs }), W.now());
    });
  }
  W.go("today");
  if (W.toast) W.toast(W.t("parent.done"));
};

function ParentSheet(p) {
  var szSt = W.useState(7), sz = szSt[0], setSz = szSt[1];
  var recSt = W.useState(true), recite = recSt[0], setRecite = recSt[1];
  var csSt = W.useState("full"), cardSize = csSt[0], setCardSize = csSt[1];
  var mmSt = W.useState(true), momentsOn = mmSt[0], setMomentsOn = mmSt[1];

  W.useEffect(function () {
    if (p.open) {
      setSz(7);
      setRecite(true);
      setCardSize("full");
      setMomentsOn(true);
    }
  }, [p.open]);

  function cycleSize() {
    setSz(sz <= 3 ? 7 : sz - 1);
  }

  return html`<${Sheet} id="parent-sheet" open=${p.open} title=${W.t("parent.sheet.title")} onClose=${p.onClose}
    footer=${html`<${Btn} kind="main" wide=${true} icon="heart" label=${W.t("parent.apply")} id="apply-parent-preset"
      onClick=${function () {
        if (p.onClose) p.onClose();
        W.applyParentPreset({ size: sz, recite: recite, cardSize: cardSize, momentsOn: momentsOn });
      }} />`}>
    <div class="parent-sheet-body">
      <p class="quiet parent-sheet-lead">${W.t("parent.sheet.lead")}</p>
      <p class="quiet parent-sheet-hint">${W.t("parent.sheet.hint")}</p>
      <div class="parent-feats" data-id="parent-feats">
        <button type="button" class="parent-feat is-btn is-on" data-id="parent-feat-size"
          onClick=${cycleSize}>
          <span class="parent-feat-ic">${W.Icon({ name: "text-size", size: 24 })}</span>
          <span class="parent-feat-main">
            <span class="parent-feat-title">${W.t("parent.feat.size.t")}</span>
            <span class="parent-feat-sub quiet">${W.t("more.size." + sz)}</span>
          </span>
          <span class="parent-feat-pill num">${sz}/7</span>
        </button>

        <button type="button" class=${W.cx("parent-feat", "is-btn", recite && "is-on")} data-id="parent-feat-recite"
          aria-pressed=${recite ? "true" : "false"}
          onClick=${function () { setRecite(!recite); }}>
          <span class="parent-feat-ic">${W.Icon({ name: recite ? "sound" : "sound-off", size: 24 })}</span>
          <span class="parent-feat-main">
            <span class="parent-feat-title">${W.t("parent.feat.recite.t")}</span>
            <span class="parent-feat-sub quiet">${W.t(recite ? "parent.feat.recite.on" : "parent.feat.recite.off")}</span>
          </span>
          <span class=${W.cx("parent-feat-switch", recite && "is-on")} aria-hidden="true">
            <span class="switch-knob"></span>
          </span>
        </button>

        <button type="button" class=${W.cx("parent-feat", "is-btn", cardSize === "full" && "is-on")} data-id="parent-feat-card"
          aria-pressed=${cardSize === "full" ? "true" : "false"}
          onClick=${function () { setCardSize(cardSize === "full" ? "small" : "full"); }}>
          <span class="parent-feat-ic">${W.Icon({ name: cardSize === "full" ? "card-full" : "card-small", size: 24 })}</span>
          <span class="parent-feat-main">
            <span class="parent-feat-title">${W.t("parent.feat.card.t")}</span>
            <span class="parent-feat-sub quiet">${W.t(cardSize === "full" ? "parent.feat.card.full" : "parent.feat.card.small")}</span>
          </span>
          <span class="parent-feat-pill">${W.t("ob.size." + cardSize)}</span>
        </button>

        <button type="button" class=${W.cx("parent-feat", "is-btn", momentsOn && "is-on")} data-id="parent-feat-moments"
          aria-pressed=${momentsOn ? "true" : "false"}
          onClick=${function () { setMomentsOn(!momentsOn); }}>
          <span class="parent-feat-ic">${W.Icon({ name: "sun", size: 24 })}</span>
          <span class="parent-feat-main">
            <span class="parent-feat-title">${W.t("parent.feat.moments.t")}</span>
            <span class="parent-feat-sub quiet">${W.t(momentsOn ? "parent.feat.moments.on" : "parent.feat.moments.off")}</span>
          </span>
          <span class=${W.cx("parent-feat-switch", momentsOn && "is-on")} aria-hidden="true">
            <span class="switch-knob"></span>
          </span>
        </button>
      </div>
    </div>
  <//>`;
}

W.Btn = Btn; W.Ring = Ring; W.Sheet = Sheet; W.TabBar = TabBar; W.Row = Row;
W.Stepper = Stepper; W.Choice = Choice; W.Toast = Toast; W.Ornament = Ornament;
W.ParentSheet = ParentSheet;
})();
