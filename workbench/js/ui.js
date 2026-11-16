/* ui.js: the shared parts every screen is built from. Use them as components: html`<${W.Btn} ... />`.
   Every part takes an id that becomes its data-id. Words come from W.t. Layout uses logical properties,
   so each part works right to left and left to right. Styles live in css/app.css, motion in css/motion.css. */
(function () {
"use strict";
var W = window.W, html = W.html;

/* kind: "main" (the one main action), "soft" (a second choice), "text" (a quiet action). label or children is the word. */
function Btn(p) {
  var kind = p.kind || "main";
  return html`<button type="button" class=${W.cx("btn", "btn-" + kind, p.wide && "btn-wide", p.className)}
    data-id=${p.id} onClick=${p.onClick} disabled=${p.disabled}>
    ${p.icon ? W.Icon({ name: p.icon, size: kind === "text" ? 22 : 24 }) : null}
    <span class="btn-label">${p.label != null ? p.label : p.children}</span>
  </button>`;
}

/* progress ring: two half rings turned with transform, so filling animates without repainting the arc.
   label (optional) sits in the middle; a full ring shows a check. */
function Ring(p) {
  var size = p.size || 48, total = Math.max(1, p.total || 1);
  var done = W.clamp(p.done || 0, 0, total), f = done / total, full = done >= total;
  var prev = W.useRef(f);
  var up = prev.current < 0.5 && f > 0.5, down = prev.current > 0.5 && f < 0.5;
  W.useEffect(function () { prev.current = f; });
  var s1 = { transform: "rotate(" + Math.min(f, 0.5) * 360 + "deg)" };
  var s2 = { transform: "rotate(" + Math.max(f - 0.5, 0) * 360 + "deg)" };
  /* crossing the half: the first half finishes before the second starts */
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

/* a panel that rises from the bottom of the nearest positioned box. Closes with its own labelled button. */
function Sheet(p) {
  if (!p.open) return null;
  return html`<div class="sheet-layer" data-id=${p.id}>
    <div class="sheet-scrim" onClick=${p.onClose}></div>
    <div class="sheet m-enter" role="dialog" aria-modal="true" aria-label=${p.title}>
      <div class="sheet-head">
        <h2 class="sheet-title">${p.title}</h2>
        ${p.onClose ? html`<${Btn} kind="text" icon="close" label=${W.t("btn.close")} id=${p.id + "-close"} onClick=${p.onClose} />` : null}
      </div>
      <div class="sheet-body">${p.children}</div>
    </div>
  </div>`;
}

/* the three places. route defaults to the current one; onGo defaults to W.go. */
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

/* a large list row. lead: a node at the start (a Ring); icon: or an icon there. dhikr: set the title in the dhikr face.
   end: a node at the end; with onClick and no end, a quiet chevron. done: the finished look. */
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

/* one number with Less and More. mark: the sunnah number, shown under it; tapping it sets the value to it. */
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

/* large choice buttons, one chosen. options: [{value, label, sub, icon}] */
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

/* one message with an optional Undo. Leaves by itself after 6 seconds, then calls onDone.
   A new text or stamp shows it again. */
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

/* the look's one quiet ornament: a small eight-point star (look a) or a pointed arch (look b) between fine rules */
var STAR = '<rect x="6.5" y="6.5" width="11" height="11"/><rect x="6.5" y="6.5" width="11" height="11" transform="rotate(45 12 12)"/>';
var ARCH = '<path d="M6.5 21V12c0-3.6 2.4-6.2 5.5-8.5 3.1 2.3 5.5 4.9 5.5 8.5v9M9.5 21v-8c0-1.9 1-3.3 2.5-4.6 1.5 1.3 2.5 2.7 2.5 4.6v8"/>';
/* size: the mark's size (26); bare: the mark alone, without the rules */
function Ornament(p) {
  var size = p.size || 26;
  function mark(cls, body) {
    return html`<svg class=${cls} viewBox="0 0 24 24" width=${size} height=${size} fill="none" stroke="currentColor"
      strokeWidth=${size > 40 ? 0.9 : 1.25} strokeLinejoin="round" strokeLinecap="round" dangerouslySetInnerHTML=${{ __html: body }}></svg>`;
  }
  return html`<span class=${W.cx("orn", p.bare && "is-bare", p.className)} data-id=${p.id} aria-hidden="true">
    ${p.bare ? null : html`<span class="orn-line"></span>`}${mark("orn-a", STAR)}${mark("orn-b", ARCH)}${p.bare ? null : html`<span class="orn-line"></span>`}
  </span>`;
}

W.Btn = Btn; W.Ring = Ring; W.Sheet = Sheet; W.TabBar = TabBar; W.Row = Row;
W.Stepper = Stepper; W.Choice = Choice; W.Toast = Toast; W.Ornament = Ornament;
})();
