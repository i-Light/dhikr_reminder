/* comments.js: the comment tool (workbench chrome, English).
   Press C or the Comment button, point at anything and click: a note is pinned to that exact element, on that
   frame, example day, language, route and popup. Pins come back where they were left. The list shows them all
   and "Copy for Claude" turns the open ones into text. Opened through serve.mjs, every change is also written
   to comments.json. Ported from the gratovo_toolbox workbench. */
(function () {
"use strict";
var W = window.W, html = W.html, useState = W.useState, useEffect = W.useEffect, useRef = W.useRef;
var Fragment = W.R.Fragment;

var KINDS = [["fix", "Fix"], ["idea", "Idea"], ["question", "Question"]];
var KIND = { fix: "Fix", idea: "Idea", question: "Question" };
var OBJ = "[data-id], button, a, input, [role=tab], h1, h2, h3, p, li, svg[data-icon]";
var BIG = '[data-screen], [data-id="phone"], [data-id="desktop"], section';

/* ---------- store ---------- */
var CM = W.CM = { list: [] };
var V = { open: null, pins: true, showDone: false, toast: null };   /* view state of the tool itself, not saved */

function valid(c) { return c && typeof c === "object" && typeof c.id === "string" && typeof c.text === "string" && c.place && c.anchor; }
function stamp(c) { return Math.max(c.at || 0, c.doneAt || 0, c.editedAt || 0); }
function byAt(a, b) { return (a.at || 0) - (b.at || 0) || (a.id < b.id ? -1 : 1); }

var putTimer = 0;
function save() {
  W.LS.set(W.KEYS.comments, CM.list);
  if (!W.served || !window.fetch) return;
  clearTimeout(putTimer);
  putTimer = setTimeout(function () {
    window.fetch("/api/comments", { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(CM.list) })
      .catch(function () { say("Could not write comments.json. They are still kept in this browser."); });
  }, 300);
}
function load() {
  var raw = W.LS.get(W.KEYS.comments, []);
  CM.list = (Array.isArray(raw) ? raw : []).filter(valid).sort(byAt);
}
/* joins the file's comments with the browser's: for the same id, the one changed last wins */
W.commentsMerge = function (a, b) {
  var by = {};
  a.concat(b).filter(valid).forEach(function (c) { if (!by[c.id] || stamp(c) > stamp(by[c.id])) by[c.id] = c; });
  return Object.keys(by).map(function (k) { return by[k]; }).sort(byAt);
};
/* called once the page knows it is served: read comments.json, join, write both back */
W.commentsSync = function () {
  if (!W.served || !window.fetch) return Promise.resolve(false);
  return window.fetch("/api/comments").then(function (r) { return r.json(); }).then(function (rows) {
    CM.list = W.commentsMerge(Array.isArray(rows) ? rows : [], CM.list);
    save();
    W.emit();
    return true;
  }).catch(function () { return false; });
};

W.commentAdd = function (c) {
  var now = Date.now();
  var n = { id: "c" + now.toString(36) + Math.random().toString(36).slice(2, 6), at: now, status: "open", doneAt: null,
    kind: KIND[c.kind] ? c.kind : "fix", text: String(c.text), place: c.place, anchor: c.anchor };
  CM.list = CM.list.concat([n]);
  save(); W.emit();
  return n;
};
W.commentPatch = function (id, patch) {
  var out = null;
  CM.list = CM.list.map(function (x) {
    if (x.id !== id) return x;
    out = Object.assign({}, x, patch, { editedAt: Date.now() });
    return out;
  });
  if (out) { save(); W.emit(); }
  return out;
};
W.commentDelete = function (id) {
  var c = CM.list.filter(function (x) { return x.id === id; })[0];
  if (!c) return null;
  CM.list = CM.list.filter(function (x) { return x.id !== id; });
  if (V.open === id) V.open = null;
  save(); W.emit();
  return c;
};
W.commentRestore = function (c) {
  if (!valid(c) || CM.list.some(function (x) { return x.id === c.id; })) return;
  CM.list = CM.list.concat([c]).sort(byAt);
  save(); W.emit();
};

/* ---------- where and what ---------- */
function nice(el) { return ((el && (el.innerText != null ? el.innerText : el.textContent)) || "").replace(/\s+/g, " ").trim(); }
function snip(el) { return ((el && el.textContent) || "").replace(/\s+/g, " ").trim().slice(0, 60); }
function inUi(el) { return !!(el && el.closest && el.closest("[data-cmt-ui]")); }
function esc(s) { return window.CSS && window.CSS.escape ? window.CSS.escape(s) : String(s).replace(/"/g, '\\"'); }

function pick(el, big) {
  if (!el || !el.closest || inUi(el)) return null;
  var t = big ? el.closest(BIG) : el.closest(OBJ);
  if (!t) t = el.closest(BIG);
  return t && !inUi(t) ? t : null;
}
function describe(el) {
  var tag = el.tagName.toLowerCase(), t = nice(el), short = t.length > 34 ? t.slice(0, 34) + "..." : t;
  var q = short ? ' "' + short + '"' : "";
  if (tag === "svg") return "Icon " + (el.getAttribute("data-icon") || "");
  if (tag === "button" || tag === "a" || el.getAttribute("role") === "tab") return "Button" + q;
  if (tag === "input" || tag === "textarea" || tag === "select") return "Field";
  if (/^h[1-3]$/.test(tag)) return "Heading" + q;
  if (tag === "p" || tag === "li") return "Text" + q;
  if (el.hasAttribute("data-screen")) return "Screen " + el.getAttribute("data-screen");
  return short ? '"' + short + '"' : "This area";
}
function label(el) {
  var id = el.getAttribute("data-id") || ((el.closest("[data-id]") || { getAttribute: function () { return null; } }).getAttribute("data-id"));
  return describe(el) + (id ? " [" + id + "]" : "");
}
function cssPath(el) {
  var parts = [], root = document.getElementById("root");
  while (el && el !== root && el.nodeType === 1) {
    var i = 1, s = el;
    while ((s = s.previousElementSibling)) if (s.tagName === el.tagName) i++;
    parts.unshift(el.tagName.toLowerCase() + ":nth-of-type(" + i + ")");
    el = el.parentElement;
  }
  return "#root > " + parts.join(" > ");
}
function anchorOf(el, x, y) {
  var r = el.getBoundingClientRect(), own = el.getAttribute("data-id"), near = own ? el : el.closest("[data-id]");
  return {
    label: label(el), dataId: near ? near.getAttribute("data-id") : null,
    own: !!own, tag: el.tagName.toLowerCase(), path: near ? null : cssPath(el), text: snip(el),
    fx: r.width ? W.clamp((x - r.left) / r.width, 0, 1) : 0.5, fy: r.height ? W.clamp((y - r.top) / r.height, 0, 1) : 0.5
  };
}
/* the element a comment was pinned to. out.approx is set when only its section could be found. */
function locate(c, out) {
  var a = c.anchor || {}, el = null, box = null;
  try {
    if (a.dataId) {
      box = document.querySelector('[data-id="' + esc(a.dataId) + '"]');
      if (box && !a.own && a.tag) {
        var cands = box.querySelectorAll(a.tag);
        for (var i = 0; i < cands.length && i < 300; i++) if (snip(cands[i]) === a.text) { el = cands[i]; break; }
      }
      if (!el) el = box;
    } else if (a.path) {
      el = document.querySelector(a.path);
      if (el && a.text && snip(el) !== a.text) el = null;
    }
  } catch (e) { el = null; }
  if (!el) { el = document.querySelector("[data-screen]"); if (el && out) out.approx = true; }
  return el && !inUi(el) ? el : null;
}

function placeNow() {
  var ui = W.U(), sc = document.querySelector("[data-screen]");
  return { frame: ui.frame, day: ui.day, lang: ui.lang, route: sc ? sc.getAttribute("data-screen") : ui.route, popup: ui.popup || null };
}
function here(c, now) {
  var p = c.place || {};
  now = now || placeNow();
  if (p.route === "gallery") return now.route === "gallery";
  return p.frame === now.frame && p.day === now.day && p.lang === now.lang && p.route === now.route && (p.popup || null) === now.popup;
}
function dayName(k) { var d = (W.DAYS || []).filter(function (x) { return x[0] === k; })[0]; return d ? d[1] : k; }
function whereText(c) {
  var p = c.place || {};
  if (p.route === "gallery") return "Icons and motion";
  return [p.frame === "windows" ? "Windows" : "Phone", dayName(p.day), p.lang === "en" ? "English" : "Arabic", p.route]
    .concat(p.popup ? ["popup " + p.popup] : []).join(" / ");
}
function number(c) { for (var i = 0; i < CM.list.length; i++) if (CM.list[i].id === c.id) return i + 1; return 0; }
function openCount() { return CM.list.filter(function (c) { return c.status !== "done"; }).length; }
function ago(ts) {
  var s = Math.max(0, (Date.now() - ts) / 1000);
  if (s < 45) return "just now";
  if (s < 3600) return Math.round(s / 60) + " min ago";
  if (s < 86400) return Math.round(s / 3600) + " h ago";
  return new Date(ts).toISOString().slice(0, 10);
}

/* goes to where a comment was left and opens it */
W.commentVisit = function (c) {
  var ui = W.U(), p = c.place || {};
  if (p.route !== "gallery") {
    if (p.frame && ui.frame !== p.frame) ui.frame = p.frame;
    if (p.lang && ui.lang !== p.lang) ui.lang = p.lang;
    if (p.day && ui.day !== p.day) W.setDay(p.day, { keepRoute: true });
    ui.popup = p.popup || null;
  }
  V.open = c.id;
  W.go(p.route || "today");
  setTimeout(function () { var el = locate(c); if (el && el.scrollIntoView) el.scrollIntoView({ block: "center", behavior: "smooth" }); }, 80);
};

function forClaude(list) {
  var open = list.filter(function (c) { return c.status !== "done"; });
  var lines = ["Dhikr workbench comments: " + open.length + " open, copied " + new Date().toISOString().slice(0, 16).replace("T", " "), ""];
  open.forEach(function (c) {
    lines.push(number(c) + ". [" + KIND[c.kind] + "] " + whereText(c) + " / " + ((c.anchor && c.anchor.label) || ""));
    lines.push("   " + c.text.replace(/\n/g, "\n   "));
  });
  return lines.join("\n");
}
W.commentsForClaude = function () { return forClaude(CM.list); };

function copy(text, what) {
  function done() { say("Copied " + what + "."); }
  function old() {
    var ta = document.createElement("textarea");
    ta.value = text; ta.setAttribute("data-cmt-ui", "1"); ta.style.position = "fixed"; ta.style.opacity = "0";
    document.body.appendChild(ta); ta.select();
    try { document.execCommand("copy"); done(); } catch (e) { say("Could not copy. Select the text in the list instead."); }
    document.body.removeChild(ta);
  }
  if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, old); else old();
}

/* one short message from the tool, with an optional Undo */
var sayTimer = 0;
function say(msg, undo) {
  V.toast = { msg: msg, undo: undo || null };
  clearTimeout(sayTimer);
  sayTimer = setTimeout(function () { V.toast = null; W.emit(); }, 5000);
  W.emit();
}

W.toggleCommentMode = function (force) {
  var ui = W.U();
  ui.commenting = force == null ? !ui.commenting : !!force;
  V.open = null;
  W.save(); W.emit();
};
function togglePanel(force) {
  var ui = W.U();
  ui.panel = (force == null ? ui.panel !== "comments" : force) ? "comments" : null;
  W.save(); W.emit();
}

/* ---------- parts ---------- */
function Seg(p) {
  return html`<span class="wb-seg" role="group" aria-label=${p.label}>${p.options.map(function (o) {
    return html`<button type="button" key=${o[0]} class=${W.cx("wb-seg-btn", o[0] === p.value && "is-on")}
      aria-pressed=${o[0] === p.value} onClick=${function () { p.onChange(o[0]); }}>${o[1]}</button>`;
  })}</span>`;
}
function popStyle(x, y, h) {
  var w = Math.min(340, window.innerWidth - 24);
  return { width: w + "px", left: W.clamp(x + 14, 12, window.innerWidth - w - 12) + "px", top: W.clamp(y + 14, 12, window.innerHeight - h) + "px" };
}

function Composer(p) {
  var t = useState(""), k = useState("fix"), ref = useRef(null);
  useEffect(function () { if (ref.current) ref.current.focus(); }, []);
  function saveIt() {
    var text = t[0].trim();
    if (!text) return;
    var c = W.commentAdd({ kind: k[0], text: text, place: p.at.place, anchor: p.at.anchor });
    p.onDone();
    say("Comment " + number(c) + " saved" + (W.served ? " to comments.json." : " in this browser."), function () { W.commentDelete(c.id); });
  }
  return html`<div class="cmt-pop" data-cmt-ui="1" role="dialog" aria-label="New comment" style=${popStyle(p.at.x, p.at.y, 250)}>
    <b class="cmt-ell">${p.at.anchor.label}</b>
    <span class="cmt-dim cmt-ell">${whereText({ place: p.at.place })}</span>
    <textarea ref=${ref} class="cmt-ta" rows="3" placeholder="What should change here, and why?" value=${t[0]} aria-label="Comment"
      onInput=${function (e) { t[1](e.target.value); }}
      onKeyDown=${function (e) {
        if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) { e.preventDefault(); e.stopPropagation(); saveIt(); }
        else if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); p.onDone(); }
      }}></textarea>
    <div class="cmt-row">
      <${Seg} label="Kind of comment" value=${k[0]} onChange=${k[1]} options=${KINDS} />
      <span class="cmt-sp"></span>
      <button type="button" class="wb-btn" onClick=${p.onDone}>Cancel</button>
      <button type="button" class="wb-btn is-on" disabled=${!t[0].trim()} onClick=${saveIt}>Save (Ctrl Enter)</button>
    </div>
  </div>`;
}

function Card(p) {
  var c = p.c, ed = useState(null);
  function close() { V.open = null; W.emit(); }
  function saveEdit() { if (ed[0] && ed[0].trim()) { W.commentPatch(c.id, { text: ed[0].trim() }); ed[1](null); } }
  var style = p.pos ? popStyle(p.pos.x + 6, p.pos.y - 20, 300)
    : { width: "340px", left: "50%", top: "30%", transform: "translateX(-50%)" };
  return html`<div class="cmt-pop" data-cmt-ui="1" data-id="cmt-card" role="dialog" aria-label=${"Comment " + p.n} style=${style}>
    <div class="cmt-row"><span class=${W.cx("cmt-pin", "static", c.status === "done" && "done")}>${p.n}</span>
      <span class="cmt-tag">${KIND[c.kind]}</span>${c.status === "done" ? html`<span class="cmt-tag good">Done</span>` : null}
      <span class="cmt-sp"></span><button type="button" class="wb-btn" onClick=${close}>Close</button></div>
    <b class="cmt-ell">${c.anchor ? c.anchor.label : ""}</b>
    ${ed[0] != null
      ? html`<textarea class="cmt-ta" rows="3" autoFocus=${true} value=${ed[0]} aria-label="Edit comment"
          onInput=${function (e) { ed[1](e.target.value); }}
          onKeyDown=${function (e) {
            if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) { e.preventDefault(); e.stopPropagation(); saveEdit(); }
            else if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); ed[1](null); }
          }}></textarea>`
      : html`<p class="cmt-text">${c.text}</p>`}
    <span class="cmt-dim">${ago(c.at)} / ${whereText(c)}</span>
    ${p.approx ? html`<span class="cmt-dim">The exact spot changed since this was written, so the pin sits on its screen.</span>` : null}
    ${p.missing ? html`<span class="cmt-dim">This spot is not on screen right now.</span>` : null}
    <div class="cmt-row">
      ${ed[0] != null
        ? html`<button type="button" class="wb-btn is-on" onClick=${saveEdit}>Save</button>
            <button type="button" class="wb-btn" onClick=${function () { ed[1](null); }}>Cancel</button>`
        : html`${c.status === "done"
            ? html`<button type="button" class="wb-btn" onClick=${function () { W.commentPatch(c.id, { status: "open", doneAt: null }); }}>Reopen</button>`
            : html`<button type="button" class="wb-btn is-on" onClick=${function () {
                W.commentPatch(c.id, { status: "done", doneAt: Date.now() }); close();
                say("Comment " + p.n + " marked done.", function () { W.commentPatch(c.id, { status: "open", doneAt: null }); });
              }}>Mark done</button>`}
            <button type="button" class="wb-btn" onClick=${function () { ed[1](c.text); }}>Edit</button>
            <span class="cmt-sp"></span>
            <button type="button" class="wb-btn" onClick=${function () {
              var gone = W.commentDelete(c.id);
              say("Comment " + p.n + " deleted.", function () { W.commentRestore(gone); });
            }}>Delete</button>`}
    </div>
  </div>`;
}

function Side() {
  var f = useState("open"), sc = useState("all"), now = placeNow(), list = CM.list;
  var shown = list.filter(function (c) {
    return (f[0] === "all" || (f[0] === "done") === (c.status === "done")) && (sc[0] === "all" || here(c, now));
  }).slice().reverse();
  var n = openCount();
  return html`<aside class="cmt-side" data-cmt-ui="1" data-id="cmt-side" aria-label="Comments">
    <div class="cmt-row cmt-side-head"><b>Comments</b><span class="cmt-dim">${n} open</span><span class="cmt-sp"></span>
      <button type="button" class="wb-btn" onClick=${function () { togglePanel(false); }}>Hide</button></div>
    <div class="cmt-row cmt-side-filters">
      <${Seg} label="Which comments" value=${f[0]} onChange=${f[1]} options=${[["open", "Open"], ["done", "Done"], ["all", "All"]]} />
      <${Seg} label="Where" value=${sc[0]} onChange=${sc[1]} options=${[["all", "Everywhere"], ["here", "This screen"]]} />
    </div>
    <div class="cmt-row cmt-side-filters">
      <label class="cmt-check"><input type="checkbox" checked=${V.pins} onChange=${function (e) { V.pins = e.target.checked; W.emit(); }} /> Show pins</label>
      <label class="cmt-check"><input type="checkbox" checked=${V.showDone} onChange=${function (e) { V.showDone = e.target.checked; W.emit(); }} /> Show done pins</label>
    </div>
    <div class="cmt-list">
      ${shown.length ? shown.map(function (c) {
        return html`<button key=${c.id} type="button" class=${W.cx("cmt-item", V.open === c.id && "is-open")} onClick=${function () { W.commentVisit(c); }}>
          <span class=${W.cx("cmt-pin", "static", c.status === "done" && "done")}>${number(c)}</span>
          <span class="cmt-item-main"><span class="cmt-row"><b class="cmt-ell">${c.anchor ? c.anchor.label : "Comment"}</b><span class="cmt-tag">${KIND[c.kind]}</span></span>
            <span class="cmt-clamp">${c.text}</span><small class="cmt-dim">${whereText(c)} / ${ago(c.at)}</small></span>
        </button>`;
      }) : html`<div class="cmt-empty"><b>${list.length ? "Nothing here with these filters." : "No comments yet."}</b>
          <span class="cmt-dim">Press C, then click anything: a button, a row, an icon, a word. Your note is pinned to that exact spot. Hold Alt to pick the whole screen.</span></div>`}
    </div>
    <div class="cmt-side-foot">
      <div class="cmt-row">
        <button type="button" class=${W.cx("wb-btn", W.U().commenting && "is-on")} onClick=${function () { W.toggleCommentMode(); }}>${W.U().commenting ? "Stop commenting" : "Add a comment (C)"}</button>
        <button type="button" class="wb-btn" data-id="cmt-copy" disabled=${!n} onClick=${function () { copy(forClaude(list), n + " open comment" + (n === 1 ? "" : "s") + " for Claude"); }}>Copy open for Claude</button>
      </div>
      <span class="cmt-dim">${W.served ? "Saved to workbench/comments.json, so Claude can read them directly." : "Saved in this browser only. Open the page through node workbench/serve.mjs to write them to comments.json, or copy them for Claude."}</span>
    </div>
  </aside>`;
}

function Picker() {
  var hov = useState(null), comp = useState(null);
  var compRef = useRef(null);
  compRef.current = comp[0];
  useEffect(function () {
    var raf = 0;
    function box(t, lab, fixed) { var r = t.getBoundingClientRect(); return { x: r.left, y: r.top, w: r.width, h: r.height, label: lab, fixed: fixed }; }
    function move(e) {
      if (compRef.current) return;
      var t = pick(e.target, e.altKey);
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(function () { hov[1](t ? box(t, label(t)) : null); });
    }
    function block(e) { if (inUi(e.target)) return; e.preventDefault(); e.stopPropagation(); }
    function click(e) {
      if (inUi(e.target)) return;
      e.preventDefault(); e.stopPropagation();
      if (compRef.current) { comp[1](null); return; }
      var t = pick(e.target, e.altKey);
      if (!t) return;
      var anchor = anchorOf(t, e.clientX, e.clientY);
      comp[1]({ x: e.clientX, y: e.clientY, place: placeNow(), anchor: anchor });
      hov[1](box(t, anchor.label, true));
    }
    document.addEventListener("pointermove", move, true);
    document.addEventListener("mousedown", block, true);
    document.addEventListener("click", click, true);
    document.documentElement.classList.add("cmt-mode");
    return function () {
      document.removeEventListener("pointermove", move, true);
      document.removeEventListener("mousedown", block, true);
      document.removeEventListener("click", click, true);
      document.documentElement.classList.remove("cmt-mode");
      cancelAnimationFrame(raf);
    };
  }, []);
  var h = hov[0], n = openCount();
  return html`<${Fragment}>
    ${h ? html`<div class="cmt-hl" style=${{ left: h.x - 3 + "px", top: h.y - 3 + "px", width: h.w + 6 + "px", height: h.h + 6 + "px" }}><span class="cmt-hl-l">${h.label}</span></div>` : null}
    ${comp[0] ? html`<${Composer} at=${comp[0]} onDone=${function () { comp[1](null); hov[1](null); }} />` : null}
    <div class="cmt-bar" data-cmt-ui="1" data-id="cmt-bar" role="status">
      <span><b>Click anything to comment on it.</b> Hold Alt to pick the whole screen.</span>
      <button type="button" class="wb-btn" onClick=${function () { togglePanel(); }}>${n} open comment${n === 1 ? "" : "s"}</button>
      <button type="button" class="wb-btn" onClick=${function () { W.toggleCommentMode(false); }}>Done (Esc)</button>
    </div>
  <//>`;
}

function Pins() {
  var pins = useState([]), now = placeNow(), list = CM.list;
  var want = list.filter(function (c) { return here(c, now) && (V.showDone || c.status !== "done" || V.open === c.id); });
  var key = want.map(function (c) { return c.id + c.status; }).join(",") + "|" + [now.frame, now.day, now.lang, now.route, now.popup].join("|");
  useEffect(function () {
    /* measured directly, not inside an animation frame: a page that is not being painted would never run it */
    var soonTimer = 0;
    function measure() {
      pins[1](want.map(function (c) {
        var o = {}, el = locate(c, o);
        if (!el) return { c: c, miss: true };
        var r = el.getBoundingClientRect(), a = c.anchor || {};
        if (!r.width && !r.height) return { c: c, miss: true };
        return { c: c, approx: !!o.approx, off: r.bottom < 4 || r.top > window.innerHeight - 4,
          x: r.left + r.width * (o.approx || a.fx == null ? 0.5 : a.fx), y: r.top + r.height * (o.approx || a.fy == null ? 0.12 : a.fy) };
      }));
    }
    function soon() { clearTimeout(soonTimer); soonTimer = setTimeout(measure, 16); }
    measure();
    var iv = setInterval(measure, 450);
    window.addEventListener("scroll", soon, true);
    window.addEventListener("resize", soon);
    return function () {
      clearInterval(iv);
      clearTimeout(soonTimer);
      window.removeEventListener("scroll", soon, true);
      window.removeEventListener("resize", soon);
    };
  }, [key]);
  var openC = V.open ? list.filter(function (c) { return c.id === V.open; })[0] : null;
  var openP = openC ? pins[0].filter(function (p) { return p.c.id === openC.id; })[0] : null;
  return html`<${Fragment}>
    ${V.pins || W.U().commenting ? pins[0].map(function (p0) {
      if (p0.miss || p0.off) return null;
      var c = list.filter(function (x) { return x.id === p0.c.id; })[0];
      if (!c) return null;
      var n = number(c);
      return html`<button key=${c.id} type="button" data-cmt-ui="1" data-id=${"cmt-pin-" + n}
        class=${W.cx("cmt-pin", c.status === "done" && "done", p0.approx && "approx")}
        style=${{ left: W.clamp(p0.x - 4, 4, window.innerWidth - 30) + "px", top: W.clamp(p0.y - 24, 4, window.innerHeight - 30) + "px" }}
        aria-label=${"Comment " + n + ": " + c.text} aria-expanded=${String(V.open === c.id)} title=${c.text.slice(0, 120)}
        onClick=${function () { V.open = V.open === c.id ? null : c.id; W.emit(); }}>${n}</button>`;
    }) : null}
    ${openC ? html`<${Card} key=${openC.id} c=${openC} n=${number(openC)}
      pos=${openP && !openP.miss ? { x: openP.x, y: openP.y } : null} missing=${!openP || openP.miss} approx=${!!(openP && openP.approx)} />` : null}
  <//>`;
}

/* the whole layer, mounted once by app.js next to the stage */
W.CommentLayer = function CommentLayer() {
  var ui = W.useApp().ui;
  useEffect(function () {
    function key(e) {
      var t = e.target, typing = t && (/^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName) || t.isContentEditable);
      if (typing || e.ctrlKey || e.metaKey || e.altKey) return;
      if (e.key === "c" || e.key === "C") { e.preventDefault(); W.toggleCommentMode(); }
      else if (e.key === "Escape") {
        if (W.U().commenting) W.toggleCommentMode(false);
        else if (V.open) { V.open = null; W.emit(); }
        else if (W.U().panel === "comments") togglePanel(false);
      }
    }
    document.addEventListener("keydown", key);
    return function () { document.removeEventListener("keydown", key); };
  }, []);
  return html`<${Fragment}>
    <${Pins} />
    ${ui.commenting ? html`<${Picker} />` : null}
    ${ui.panel === "comments" ? html`<${Side} />` : null}
    ${V.toast ? html`<div class="cmt-toast" data-cmt-ui="1" role="status"><span>${V.toast.msg}</span>
      ${V.toast.undo ? html`<button type="button" class="wb-btn" onClick=${function () { var u = V.toast.undo; V.toast = null; u(); W.emit(); }}>Undo</button>` : null}</div>` : null}
  <//>`;
};

/* the two buttons in the Workbench menu */
W.wbTools.push(function () {
  var ui = W.U(), n = openCount();
  return html`<${Fragment}>
    <button type="button" class=${W.cx("wb-btn", ui.commenting && "is-on")} data-id="wb-comment" onClick=${function () { W.toggleCommentMode(); }}>${ui.commenting ? "Stop commenting" : "Comment (C)"}</button>
    <button type="button" class=${W.cx("wb-btn", ui.panel === "comments" && "is-on")} data-id="wb-comments" onClick=${function () { togglePanel(); }}>Comments (${n})</button>
  <//>`;
});

load();
})();
