/* comments.js: the comment tool AND live in-app text editor (workbench chrome, English).
   Press C (Comment) to pin Fix / Idea / Question notes, or press E (Edit text) to click any word, button,
   heading or dhikr and change its text directly on screen without touching code.
   Opened through serve.mjs, comments sync to comments.json and text edits sync to text-edits.json. */
(function () {
"use strict";
var W = window.W, html = W.html, useState = W.useState, useEffect = W.useEffect, useRef = W.useRef;
var Fragment = W.R.Fragment;

var KINDS = [["fix", "Fix"], ["idea", "Idea"], ["question", "Question"]];
var KIND = { fix: "Fix", idea: "Idea", question: "Question" };
var OBJ = "[data-id], button, a, input, [role=tab], h1, h2, h3, p, li, svg[data-icon]";
var BIG = '[data-screen], [data-id="phone"], [data-id="desktop"], section';
var TEXT_LEAF = ".btn-label, .choice-label, .choice-sub, .row-title, .row-sub, .tab-word, .adhkar-view-lbl, .appbar-crumb, .appbar-name, .dhikr, .dhikr-note, .card-hint, .card-cele-title, .weekly-motivate span, h1, h2, h3, p, span";

/* ---------- store ---------- */
var CM = W.CM = { list: [] };
var V = { open: null, pins: true, showDone: false, toast: null, lightbox: null };

/* ---------- pasted image compression & optional disk sync ---------- */
function compressImageBlob(blob) {
  return new Promise(function (resolve) {
    var reader = new FileReader();
    reader.onerror = function () { resolve(null); };
    reader.onload = function () {
      var rawUrl = String(reader.result || "");
      if (!rawUrl) { resolve(null); return; }
      var img = new Image();
      img.onerror = function () {
        resolve({ id: W.uid("img"), dataUrl: rawUrl, w: 0, h: 0, path: null });
      };
      img.onload = function () {
        var w = img.naturalWidth || img.width || 0;
        var h = img.naturalHeight || img.height || 0;
        var maxDim = 1100;
        var tw = w, th = h;
        if (tw > maxDim || th > maxDim) {
          var ratio = Math.min(maxDim / tw, maxDim / th);
          tw = Math.max(1, Math.round(tw * ratio));
          th = Math.max(1, Math.round(th * ratio));
        }
        var outUrl = rawUrl;
        try {
          var cv = document.createElement("canvas");
          cv.width = tw || 1; cv.height = th || 1;
          var ctx = cv.getContext("2d");
          if (ctx && tw > 0 && th > 0) {
            ctx.drawImage(img, 0, 0, tw, th);
            var webp = cv.toDataURL("image/webp", 0.82);
            outUrl = /^data:image\/webp/.test(webp) ? webp : cv.toDataURL("image/png");
          }
        } catch (e) { outUrl = rawUrl; }
        var item = { id: W.uid("img"), dataUrl: outUrl, w: tw, h: th, path: null };
        if (W.served && window.fetch) {
          window.fetch("/api/comment-image", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ id: item.id, dataUrl: outUrl })
          }).then(function (r) { return r.json(); }).then(function (j) {
            if (j && j.ok) { item.path = j.path || null; item.url = j.url || null; }
            resolve(item);
          }).catch(function () { resolve(item); });
        } else {
          resolve(item);
        }
      };
      img.src = rawUrl;
    };
    reader.readAsDataURL(blob);
  });
}

function extractClipboardImages(clipboardData) {
  var blobs = [];
  if (!clipboardData) return blobs;
  var items = clipboardData.items;
  if (items && items.length) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].type && items[i].type.indexOf("image/") === 0) {
        var f = items[i].getAsFile && items[i].getAsFile();
        if (f) blobs.push(f);
      }
    }
  }
  if (!blobs.length && clipboardData.files && clipboardData.files.length) {
    for (var j = 0; j < clipboardData.files.length; j++) {
      var cf = clipboardData.files[j];
      if (cf.type && cf.type.indexOf("image/") === 0) blobs.push(cf);
    }
  }
  return blobs;
}

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
W.commentsMerge = function (a, b) {
  var by = {};
  a.concat(b).filter(valid).forEach(function (c) { if (!by[c.id] || stamp(c) > stamp(by[c.id])) by[c.id] = c; });
  return Object.keys(by).map(function (k) { return by[k]; }).sort(byAt);
};
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
  var imgs = Array.isArray(c.images) ? c.images.filter(function (im) { return im && (im.dataUrl || im.url); }) : [];
  var n = { id: "c" + now.toString(36) + Math.random().toString(36).slice(2, 6), at: now, status: "open", doneAt: null,
    kind: KIND[c.kind] ? c.kind : "fix", text: String(c.text || ""), place: c.place, anchor: c.anchor };
  if (imgs.length) n.images = imgs;
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

/* ---------- live text binding lookup & updates ---------- */
function normSpace(s) { return String(s || "").replace(/\s+/g, " ").trim(); }

function matchStrKey(txt, lang) {
  if (!txt || !W.STR) return null;
  var hit = W._renderedKeys && W._renderedKeys[txt];
  if (hit && W.STR[lang] && W.STR[lang][hit.key] != null) return { kind: "str", key: hit.key, lang: lang };
  var langs = [lang, lang === "ar" ? "en" : "ar"];
  for (var li = 0; li < langs.length; li++) {
    var lg = langs[li], tbl = W.STR[lg] || {};
    var keys = Object.keys(tbl);
    for (var i = 0; i < keys.length; i++) {
      if (normSpace(tbl[keys[i]]) === txt) return { kind: "str", key: keys[i], lang: lg };
    }
  }
  /* match parameterized templates like "{left} left of {target}" */
  for (var li2 = 0; li2 < langs.length; li2++) {
    var lg2 = langs[li2], tbl2 = W.STR[lg2] || {};
    var tKeys = Object.keys(tbl2);
    for (var j = 0; j < tKeys.length; j++) {
      var raw = tbl2[tKeys[j]];
      if (raw.indexOf("{") < 0) continue;
      var escRe = normSpace(raw).replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/\\\{\w+\\\}/g, ".+?");
      if (escRe.replace(/\.\+\?/g, "").trim().length < 2) continue;
      try {
        if (new RegExp("^" + escRe + "$").test(txt)) return { kind: "str", key: tKeys[j], lang: lg2 };
      } catch (e) { /* skip regex */ }
    }
  }
  return null;
}

function matchLibEntry(txt) {
  if (!txt || !W.LIB) return null;
  var fields = ["ar", "translit", "arNote", "en", "source", "sourceEn"];
  for (var i = 0; i < W.LIB.length; i++) {
    var item = W.LIB[i];
    for (var f = 0; f < fields.length; f++) {
      var fname = fields[f];
      if (item[fname] && normSpace(item[fname]) === txt) {
        return { kind: "lib", id: item.id, field: fname };
      }
    }
  }
  return null;
}

W.findTextBinding = function (rawTarget, pickedEl) {
  W.ensureOrig();
  var lang = (W.U() && W.U().lang) || "ar";
  var cands = [];
  if (rawTarget && rawTarget.nodeType === 1) cands.push(rawTarget);
  if (pickedEl && pickedEl !== rawTarget) cands.push(pickedEl);
  if (pickedEl && pickedEl.querySelectorAll) {
    var inner = pickedEl.querySelectorAll(TEXT_LEAF);
    for (var i = 0; i < inner.length && i < 16; i++) cands.push(inner[i]);
  }
  for (var c = 0; c < cands.length; c++) {
    var txt = normSpace(cands[c].textContent);
    if (!txt) continue;
    var sk = matchStrKey(txt, lang);
    if (sk) return sk;
    var lk = matchLibEntry(txt);
    if (lk) return lk;
  }
  return null;
};

W.saveTextBinding = function (binding, values) {
  W.ensureOrig();
  if (!binding) return false;
  if (binding.kind === "str") {
    ["ar", "en"].forEach(function (lg) {
      if (typeof values[lg] !== "string") return;
      var v = values[lg].trim();
      var orig = W.ORIG.str && W.ORIG.str[lg] && W.ORIG.str[lg][binding.key];
      if (!v || v === orig) delete W.EDITS[lg][binding.key];
      else W.EDITS[lg][binding.key] = v;
    });
  } else if (binding.kind === "lib") {
    var cur = W.EDITS.lib[binding.id] || {};
    var val = String(values.val || "").trim();
    var origItem = (W.ORIG.lib || []).filter(function (x) { return x.id === binding.id; })[0];
    var origVal = origItem ? origItem[binding.field] : null;
    if (!val || val === origVal) delete cur[binding.field];
    else cur[binding.field] = val;
    if (Object.keys(cur).length) W.EDITS.lib[binding.id] = cur;
    else delete W.EDITS.lib[binding.id];
  }
  W.applyEditsToTables();
  W.saveEdits();
  W.emit();
  return true;
};

W.resetTextBinding = function (binding) {
  if (!binding) return;
  if (binding.kind === "str") {
    delete W.EDITS.ar[binding.key];
    delete W.EDITS.en[binding.key];
  } else if (binding.kind === "lib" && W.EDITS.lib[binding.id]) {
    delete W.EDITS.lib[binding.id][binding.field];
    if (!Object.keys(W.EDITS.lib[binding.id]).length) delete W.EDITS.lib[binding.id];
  }
  W.applyEditsToTables();
  W.saveEdits();
  W.emit();
};

function editEntries() {
  var out = [];
  ["ar", "en"].forEach(function (lg) {
    Object.keys((W.EDITS && W.EDITS[lg]) || {}).sort().forEach(function (k) {
      var orig = W.ORIG.str && W.ORIG.str[lg] ? W.ORIG.str[lg][k] : "";
      if (normSpace(orig) === normSpace(W.EDITS[lg][k])) return;
      out.push({ id: "str:" + lg + ":" + k, kind: "str", lang: lg, key: k, from: orig, to: W.EDITS[lg][k] });
    });
  });
  Object.keys((W.EDITS && W.EDITS.lib) || {}).sort().forEach(function (id) {
    var fields = W.EDITS.lib[id] || {};
    var origItem = (W.ORIG.lib || []).filter(function (x) { return x.id === id; })[0] || {};
    Object.keys(fields).forEach(function (f) {
      out.push({ id: "lib:" + id + ":" + f, kind: "lib", itemId: id, field: f, from: origItem[f] || "", to: fields[f] });
    });
  });
  return out;
}

function editsForClaude() {
  var rows = editEntries();
  if (!rows.length) return "";
  var lines = ["Direct text edits (" + rows.length + "):", ""];
  rows.forEach(function (r, idx) {
    if (r.kind === "str") {
      lines.push((idx + 1) + ". strings.js [" + r.lang + "] \"" + r.key + "\":");
      lines.push("   from: " + r.from);
      lines.push("   to:   " + r.to);
    } else {
      lines.push((idx + 1) + ". data.js [" + r.itemId + "." + r.field + "]:");
      lines.push("   from: " + r.from);
      lines.push("   to:   " + r.to);
    }
  });
  return lines.join("\n");
}
W.textEditsForClaude = editsForClaude;

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
    if (c.text) lines.push("   " + c.text.replace(/\n/g, "\n   "));
    if (Array.isArray(c.images) && c.images.length) {
      c.images.forEach(function (im, idx) {
        var dims = im.w && im.h ? " (" + im.w + "x" + im.h + ")" : "";
        lines.push("   [Image " + (idx + 1) + dims + (im.path ? ": " + im.path : " attached in comment") + "]");
      });
    }
  });
  var te = editsForClaude();
  if (te) {
    lines.push("");
    lines.push(te);
  }
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
  if (ui.commenting) ui.editingText = false;
  V.open = null;
  W.save(); W.emit();
};

W.toggleEditTextMode = function (force) {
  var ui = W.U();
  ui.editingText = force == null ? !ui.editingText : !!force;
  if (ui.editingText) ui.commenting = false;
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
  var w = Math.min(368, window.innerWidth - 24);
  return { width: w + "px", left: W.clamp(x + 14, 12, window.innerWidth - w - 12) + "px", top: W.clamp(y + 14, 12, window.innerHeight - h) + "px" };
}

function TextEditorPop(p) {
  var b = p.binding;
  var arInit = b && b.kind === "str" ? (W.STR.ar[b.key] || "") : "";
  var enInit = b && b.kind === "str" ? (W.STR.en[b.key] || "") : "";
  var libItem = b && b.kind === "lib" ? W.lib(b.id) : null;
  var libInit = libItem && b ? (libItem[b.field] || "") : "";

  var arSt = useState(arInit), enSt = useState(enInit), libSt = useState(libInit);
  var ref = useRef(null);
  useEffect(function () { if (ref.current) ref.current.focus(); }, []);

  function applySave() {
    if (!b) return;
    if (b.kind === "str") {
      W.saveTextBinding(b, { ar: arSt[0], en: enSt[0] });
      say("Updated text for \"" + b.key + "\" live on screen.", function () { W.resetTextBinding(b); });
    } else {
      W.saveTextBinding(b, { val: libSt[0] });
      say("Updated dhikr text (" + b.field + ") live on screen.", function () { W.resetTextBinding(b); });
    }
    p.onDone();
  }

  function resetOrig() {
    W.resetTextBinding(b);
    say("Restored original text.");
    p.onDone();
  }

  function onKd(e) {
    if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) { e.preventDefault(); e.stopPropagation(); applySave(); }
    else if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); p.onDone(); }
  }

  return html`<div class="cmt-pop cmt-edit-pop" data-cmt-ui="1" data-id="text-edit-pop" role="dialog" aria-label="Edit text directly" style=${popStyle(p.at.x, p.at.y, 320)}>
    <div class="cmt-row">
      <b class="cmt-ell">${b ? (b.kind === "str" ? "String: " + b.key : "Library: " + b.id + "." + b.field) : p.at.anchor.label}</b>
      <span class="cmt-sp"></span>
      ${p.onSwitchComment ? html`<button type="button" class="wb-btn" onClick=${p.onSwitchComment}>Leave note instead</button>` : null}
    </div>
    ${!b ? html`<p class="cmt-dim">This element has no editable text binding (icon or layout container). Leave a comment instead.</p>
      <div class="cmt-row"><span class="cmt-sp"></span><button type="button" class="wb-btn" onClick=${p.onDone}>Close</button></div>`
      : b.kind === "str" ? html`<${Fragment}>
        <label class="cmt-edit-lbl">Arabic (ar)
          <textarea ref=${W.U().lang !== "en" ? ref : null} class="cmt-ta" dir="rtl" rows="2" data-id="text-edit-ar"
            value=${arSt[0]} onKeyDown=${onKd}
            onInput=${function (e) { arSt[1](e.target.value); W.saveTextBinding(b, { ar: e.target.value, en: enSt[0] }); }}></textarea>
        </label>
        <label class="cmt-edit-lbl">English (en)
          <textarea ref=${W.U().lang === "en" ? ref : null} class="cmt-ta" dir="ltr" rows="2" data-id="text-edit-en"
            value=${enSt[0]} onKeyDown=${onKd}
            onInput=${function (e) { enSt[1](e.target.value); W.saveTextBinding(b, { ar: arSt[0], en: e.target.value }); }}></textarea>
        </label>
        <div class="cmt-row">
          <button type="button" class="wb-btn" onClick=${resetOrig}>Reset original</button>
          <span class="cmt-sp"></span>
          <button type="button" class="wb-btn is-on" data-id="text-edit-done" onClick=${applySave}>Done (Ctrl Enter)</button>
        </div>
      <//>` : html`<${Fragment}>
        <label class="cmt-edit-lbl">${b.field}
          <textarea ref=${ref} class="cmt-ta" dir=${b.field === "ar" || b.field === "arNote" || b.field === "source" ? "rtl" : "ltr"} rows="3"
            data-id="text-edit-lib" value=${libSt[0]} onKeyDown=${onKd}
            onInput=${function (e) { libSt[1](e.target.value); W.saveTextBinding(b, { val: e.target.value }); }}></textarea>
        </label>
        <div class="cmt-row">
          <button type="button" class="wb-btn" onClick=${resetOrig}>Reset original</button>
          <span class="cmt-sp"></span>
          <button type="button" class="wb-btn is-on" data-id="text-edit-done" onClick=${applySave}>Done (Ctrl Enter)</button>
        </div>
      <//>`}
  </div>`;
}

function ImageStrip(p) {
  var list = p.images || [];
  if (!list.length) return null;
  return html`<div class="cmt-imgs" data-id="cmt-imgs">
    ${list.map(function (im, idx) {
      var src = im.dataUrl || im.url;
      return html`<div key=${im.id || idx} class="cmt-img-wrap">
        <button type="button" class="cmt-img-btn" title="Click to enlarge" onClick=${function (e) {
          e.stopPropagation();
          V.lightbox = src;
          W.emit();
        }}>
          <img src=${src} alt=${"Attached image " + (idx + 1)} class="cmt-img-thumb" />
        </button>
        ${p.onRemove ? html`<button type="button" class="cmt-img-rm" aria-label="Remove image" title="Remove image"
          onClick=${function (e) { e.stopPropagation(); p.onRemove(idx); }}>x</button>` : null}
      </div>`;
    })}
  </div>`;
}

function Composer(p) {
  var t = useState(""), k = useState("fix"), imgsSt = useState([]), busySt = useState(false);
  var modeSt = useState(p.startEdit ? "edit" : "comment"), ref = useRef(null), fileRef = useRef(null);
  useEffect(function () { if (modeSt[0] === "comment" && ref.current) ref.current.focus(); }, [modeSt[0]]);

  function ingestBlobs(blobs) {
    if (!blobs || !blobs.length) return;
    busySt[1](true);
    Promise.all(blobs.map(compressImageBlob)).then(function (added) {
      var clean = added.filter(Boolean);
      if (clean.length) imgsSt[1](function (prev) { return prev.concat(clean); });
      busySt[1](false);
    });
  }

  useEffect(function () {
    if (modeSt[0] !== "comment") return undefined;
    function onWinPaste(e) {
      if (e.defaultPrevented) return;
      var blobs = extractClipboardImages(e.clipboardData);
      if (blobs.length) {
        e.preventDefault();
        ingestBlobs(blobs);
      }
    }
    window.addEventListener("paste", onWinPaste);
    return function () { window.removeEventListener("paste", onWinPaste); };
  }, [modeSt[0]]);

  if (modeSt[0] === "edit") {
    return html`<${TextEditorPop} at=${p.at} binding=${p.at.binding} onDone=${p.onDone}
      onSwitchComment=${function () { modeSt[1]("comment"); }} />`;
  }

  function onPaste(e) {
    var blobs = extractClipboardImages(e.clipboardData);
    if (blobs.length) {
      e.preventDefault();
      e.stopPropagation();
      ingestBlobs(blobs);
    }
  }

  function onPickFiles(e) {
    var files = e.target && e.target.files ? Array.prototype.slice.call(e.target.files) : [];
    if (files.length) ingestBlobs(files);
    if (e.target) e.target.value = "";
  }

  function removeImg(idx) {
    imgsSt[1](function (prev) { return prev.filter(function (_, i) { return i !== idx; }); });
  }

  function saveIt() {
    var text = t[0].trim();
    if (!text && !imgsSt[0].length) return;
    var c = W.commentAdd({ kind: k[0], text: text, images: imgsSt[0], place: p.at.place, anchor: p.at.anchor });
    p.onDone();
    say("Comment " + number(c) + " saved" + (W.served ? " to comments.json." : " in this browser."), function () { W.commentDelete(c.id); });
  }
  var canSave = (t[0].trim().length > 0 || imgsSt[0].length > 0) && !busySt[0];
  return html`<div class="cmt-pop" data-cmt-ui="1" role="dialog" aria-label="New comment" onPaste=${onPaste} style=${popStyle(p.at.x, p.at.y, imgsSt[0].length ? 350 : 290)}>
    <div class="cmt-row">
      <b class="cmt-ell">${p.at.anchor.label}</b>
      <span class="cmt-sp"></span>
      ${p.at.binding ? html`<button type="button" class="wb-btn" data-id="cmt-switch-edit"
        onClick=${function () { modeSt[1]("edit"); }}>Edit text directly</button>` : null}
    </div>
    <span class="cmt-dim cmt-ell">${whereText({ place: p.at.place })}</span>
    <textarea ref=${ref} class="cmt-ta" rows="3" placeholder="What should change here, and why? (Ctrl+V to paste images)" value=${t[0]} aria-label="Comment"
      onInput=${function (e) { t[1](e.target.value); }}
      onPaste=${onPaste}
      onKeyDown=${function (e) {
        if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) { e.preventDefault(); e.stopPropagation(); saveIt(); }
        else if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); p.onDone(); }
      }}></textarea>
    <${ImageStrip} images=${imgsSt[0]} onRemove=${removeImg} />
    <div class="cmt-row">
      <input ref=${fileRef} type="file" accept="image/*" multiple style=${{ display: "none" }} onChange=${onPickFiles} />
      <button type="button" class="wb-btn" data-id="cmt-add-img" onClick=${function () { if (fileRef.current) fileRef.current.click(); }}>${busySt[0] ? "Adding..." : "+ Image (or Ctrl+V)"}</button>
      <span class="cmt-dim">Paste screenshots directly</span>
    </div>
    <div class="cmt-row">
      <${Seg} label="Kind of comment" value=${k[0]} onChange=${k[1]} options=${KINDS} />
      <span class="cmt-sp"></span>
      <button type="button" class="wb-btn" onClick=${p.onDone}>Cancel</button>
      <button type="button" class="wb-btn is-on" disabled=${!canSave} onClick=${saveIt}>Save (Ctrl Enter)</button>
    </div>
  </div>`;
}

function Card(p) {
  var c = p.c, ed = useState(null), edImgs = useState(null), fileRef = useRef(null);
  function close() { V.open = null; W.emit(); }
  function startEdit() { ed[1](c.text || ""); edImgs[1]((c.images || []).slice()); }
  function cancelEdit() { ed[1](null); edImgs[1](null); }
  function saveEdit() {
    var nextTxt = ed[0] != null ? ed[0].trim() : (c.text || "");
    var nextImgs = edImgs[0] != null ? edImgs[0] : (c.images || []);
    if (!nextTxt && !nextImgs.length) return;
    W.commentPatch(c.id, { text: nextTxt, images: nextImgs });
    cancelEdit();
  }
  function addCardBlobs(blobs) {
    if (!blobs || !blobs.length) return;
    Promise.all(blobs.map(compressImageBlob)).then(function (added) {
      var clean = added.filter(Boolean);
      if (!clean.length) return;
      if (ed[0] != null) {
        edImgs[1](function (prev) { return (prev || []).concat(clean); });
      } else {
        W.commentPatch(c.id, { images: (c.images || []).concat(clean) });
      }
    });
  }
  function onCardPaste(e) {
    var blobs = extractClipboardImages(e.clipboardData);
    if (blobs.length) { e.preventDefault(); e.stopPropagation(); addCardBlobs(blobs); }
  }
  var curImgs = ed[0] != null ? (edImgs[0] || []) : (c.images || []);
  var style = p.pos ? popStyle(p.pos.x + 6, p.pos.y - 20, curImgs.length ? 360 : 300)
    : { width: "356px", left: "50%", top: "26%", transform: "translateX(-50%)" };
  return html`<div class="cmt-pop" data-cmt-ui="1" data-id="cmt-card" role="dialog" aria-label=${"Comment " + p.n} onPaste=${onCardPaste} style=${style}>
    <div class="cmt-row"><span class=${W.cx("cmt-pin", "static", c.status === "done" && "done")}>${p.n}</span>
      <span class="cmt-tag">${KIND[c.kind]}</span>${c.status === "done" ? html`<span class="cmt-tag good">Done</span>` : null}
      <b class="cmt-ell">${c.anchor ? c.anchor.label : "Comment"}</b><span class="cmt-sp"></span>
      <button type="button" class="wb-btn" onClick=${close}>Close</button></div>
    ${ed[0] != null
      ? html`<textarea class="cmt-ta" rows="3" placeholder="Comment text (or Ctrl+V to paste image)" value=${ed[0]} onInput=${function (e) { ed[1](e.target.value); }}
          onPaste=${onCardPaste}
          onKeyDown=${function (e) {
            if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) { e.preventDefault(); saveEdit(); }
            else if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); cancelEdit(); }
          }}></textarea>`
      : (c.text ? html`<p class="cmt-text">${c.text}</p>` : null)}
    <${ImageStrip} images=${curImgs} onRemove=${ed[0] != null ? function (idx) {
      edImgs[1](function (prev) { return (prev || []).filter(function (_, i) { return i !== idx; }); });
    } : null} />
    ${ed[0] != null ? html`<div class="cmt-row">
      <input ref=${fileRef} type="file" accept="image/*" multiple style=${{ display: "none" }} onChange=${function (e) {
        var files = e.target && e.target.files ? Array.prototype.slice.call(e.target.files) : [];
        if (files.length) addCardBlobs(files);
        if (e.target) e.target.value = "";
      }} />
      <button type="button" class="wb-btn" onClick=${function () { if (fileRef.current) fileRef.current.click(); }}>+ Image (or Ctrl+V)</button>
    </div>` : null}
    <span class="cmt-dim">${ago(c.at)} / ${whereText(c)}</span>
    ${p.approx ? html`<span class="cmt-dim">The exact spot changed since this was written, so the pin sits on its screen.</span>` : null}
    ${p.missing ? html`<span class="cmt-dim">This spot is not on screen right now.</span>` : null}
    <div class="cmt-row">
      ${ed[0] != null
        ? html`<button type="button" class="wb-btn is-on" onClick=${saveEdit}>Save</button>
            <button type="button" class="wb-btn" onClick=${cancelEdit}>Cancel</button>`
        : html`${c.status === "done"
            ? html`<button type="button" class="wb-btn" onClick=${function () { W.commentPatch(c.id, { status: "open", doneAt: null }); }}>Reopen</button>`
            : html`<button type="button" class="wb-btn is-on" onClick=${function () {
                W.commentPatch(c.id, { status: "done", doneAt: Date.now() }); close();
                say("Comment " + p.n + " marked done.", function () { W.commentPatch(c.id, { status: "open", doneAt: null }); });
              }}>Mark done</button>`}
            <button type="button" class="wb-btn" onClick=${startEdit}>Edit</button>
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
  var edits = editEntries();
  var copyable = n > 0 || edits.length > 0;

  return html`<aside class="cmt-side" data-cmt-ui="1" data-id="cmt-side" aria-label="Comments">
    <div class="cmt-row cmt-side-head"><b>Comments & text</b><span class="cmt-dim">${n} open, ${edits.length} text</span><span class="cmt-sp"></span>
      <button type="button" class="wb-btn" onClick=${function () { togglePanel(false); }}>Hide</button></div>
    <div class="cmt-row cmt-side-filters">
      <${Seg} label="Which comments" value=${f[0]} onChange=${f[1]} options=${[["open", "Open"], ["done", "Done"], ["all", "All"], ["edits", "Text (" + edits.length + ")"]]} />
      ${f[0] !== "edits" ? html`<${Seg} label="Where" value=${sc[0]} onChange=${sc[1]} options=${[["all", "Everywhere"], ["here", "This screen"]]} />` : null}
    </div>
    ${f[0] !== "edits" ? html`<div class="cmt-row cmt-side-filters">
      <label class="cmt-check"><input type="checkbox" checked=${V.pins} onChange=${function (e) { V.pins = e.target.checked; W.emit(); }} /> Show pins</label>
      <label class="cmt-check"><input type="checkbox" checked=${V.showDone} onChange=${function (e) { V.showDone = e.target.checked; W.emit(); }} /> Show done pins</label>
    </div>` : null}
    <div class="cmt-list">
      ${f[0] === "edits"
        ? (edits.length ? edits.map(function (r) {
            return html`<div key=${r.id} class="cmt-item">
              <span class="cmt-item-main">
                <span class="cmt-row"><b class="cmt-ell">${r.kind === "str" ? r.key + " (" + r.lang + ")" : r.itemId + "." + r.field}</b></span>
                <span class="cmt-clamp">${r.to}</span>
                <small class="cmt-dim">was: ${r.from}</small>
              </span>
              <button type="button" class="wb-btn" onClick=${function () {
                if (r.kind === "str") W.resetTextBinding({ kind: "str", key: r.key });
                else W.resetTextBinding({ kind: "lib", id: r.itemId, field: r.field });
              }}>Reset</button>
            </div>`;
          }) : html`<div class="cmt-empty"><b>No live text changes yet.</b>
            <span class="cmt-dim">Press E (or click Edit text in the top bar), then click any word or button on screen to rewrite it directly.</span></div>`)
        : (shown.length ? shown.map(function (c) {
            var imgCount = Array.isArray(c.images) ? c.images.length : 0;
            return html`<button key=${c.id} type="button" class=${W.cx("cmt-item", V.open === c.id && "is-open")} onClick=${function () { W.commentVisit(c); }}>
              <span class=${W.cx("cmt-pin", "static", c.status === "done" && "done")}>${number(c)}</span>
              <span class="cmt-item-main"><span class="cmt-row"><b class="cmt-ell">${c.anchor ? c.anchor.label : "Comment"}</b><span class="cmt-tag">${KIND[c.kind]}</span>${imgCount ? html`<span class="cmt-tag">${imgCount + (imgCount === 1 ? " img" : " imgs")}</span>` : null}</span>
                ${c.text ? html`<span class="cmt-clamp">${c.text}</span>` : null}
                ${imgCount ? html`<span class="cmt-side-thumbs">${c.images.slice(0, 3).map(function (im, ii) { return html`<img key=${ii} src=${im.dataUrl || im.url} alt="" class="cmt-side-thumb" />`; })}</span>` : null}
                <small class="cmt-dim">${whereText(c)} / ${ago(c.at)}</small></span>
            </button>`;
          }) : html`<div class="cmt-empty"><b>${list.length ? "Nothing here with these filters." : "No comments yet."}</b>
              <span class="cmt-dim">Press C to pin a note, or press E to edit any visible text directly on screen.</span></div>`)}
    </div>
    <div class="cmt-side-foot">
      <div class="cmt-row">
        <button type="button" class=${W.cx("wb-btn", W.U().commenting && "is-on")} onClick=${function () { W.toggleCommentMode(); }}>${W.U().commenting ? "Stop (C)" : "Comment (C)"}</button>
        <button type="button" class=${W.cx("wb-btn", W.U().editingText && "is-on")} onClick=${function () { W.toggleEditTextMode(); }}>${W.U().editingText ? "Stop edit (E)" : "Edit text (E)"}</button>
        <button type="button" class="wb-btn" data-id="cmt-copy" disabled=${!copyable}
          onClick=${function () { copy(forClaude(list), "open comments and text edits"); }}>Copy open for Claude</button>
      </div>
      <span class="cmt-dim">${W.served ? "Synced to workbench/comments.json and text-edits.json." : "Saved in this browser. Open through node workbench/serve.mjs to write JSON files, or click Copy open for Claude."}</span>
    </div>
  </aside>`;
}

function Picker(p) {
  var isEdit = !!p.editMode;
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
      raf = requestAnimationFrame(function () {
        if (!t) { hov[1](null); return; }
        if (isEdit) {
          var b = W.findTextBinding(e.target, t);
          hov[1](box(t, b ? (b.kind === "str" ? "Edit: " + b.key : "Edit: " + b.field) : label(t)));
        } else {
          hov[1](box(t, label(t)));
        }
      });
    }
    function block(e) { if (inUi(e.target)) return; e.preventDefault(); e.stopPropagation(); }
    function click(e) {
      if (inUi(e.target)) return;
      e.preventDefault(); e.stopPropagation();
      if (compRef.current) { comp[1](null); return; }
      var t = pick(e.target, e.altKey);
      if (!t) return;
      var anchor = anchorOf(t, e.clientX, e.clientY);
      var binding = W.findTextBinding(e.target, t);
      comp[1]({ x: e.clientX, y: e.clientY, place: placeNow(), anchor: anchor, binding: binding });
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
  }, [isEdit]);
  var h = hov[0], n = openCount();
  return html`<${Fragment}>
    ${h ? html`<div class=${W.cx("cmt-hl", isEdit && "is-edit")} style=${{ left: h.x - 3 + "px", top: h.y - 3 + "px", width: h.w + 6 + "px", height: h.h + 6 + "px" }}><span class="cmt-hl-l">${h.label}</span></div>` : null}
    ${comp[0] ? html`<${Composer} at=${comp[0]} startEdit=${isEdit} onDone=${function () { comp[1](null); hov[1](null); }} />` : null}
    <div class="cmt-bar" data-cmt-ui="1" data-id="cmt-bar" role="status">
      ${isEdit
        ? html`<span><b>Click any word or button to change its text live.</b> Changes save instantly.</span>`
        : html`<span><b>Click anything to comment on it.</b> Or switch to Edit text inside the popup.</span>`}
      <button type="button" class="wb-btn" onClick=${function () { togglePanel(); }}>${n} open comment${n === 1 ? "" : "s"}</button>
      <button type="button" class="wb-btn" onClick=${function () { W.toggleCommentMode(false); W.toggleEditTextMode(false); }}>Done (Esc)</button>
    </div>
  <//>`;
}

function Pins() {
  var pins = useState([]), now = placeNow(), list = CM.list;
  var want = list.filter(function (c) { return here(c, now) && (V.showDone || c.status !== "done" || V.open === c.id); });
  var key = want.map(function (c) { return c.id + c.status; }).join(",") + "|" + [now.frame, now.day, now.lang, now.route, now.popup].join("|");
  useEffect(function () {
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

W.CommentLayer = function CommentLayer() {
  var ui = W.useApp().ui;
  useEffect(function () {
    function key(e) {
      var t = e.target, typing = t && (/^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName) || t.isContentEditable);
      if (typing || e.ctrlKey || e.metaKey || e.altKey) return;
      if (e.key === "c" || e.key === "C") { e.preventDefault(); W.toggleCommentMode(); }
      else if (e.key === "e" || e.key === "E") { e.preventDefault(); W.toggleEditTextMode(); }
      else if (e.key === "Escape") {
        if (V.lightbox) { V.lightbox = null; W.emit(); }
        else if (W.U().commenting) W.toggleCommentMode(false);
        else if (W.U().editingText) W.toggleEditTextMode(false);
        else if (V.open) { V.open = null; W.emit(); }
        else if (W.U().panel === "comments") togglePanel(false);
      }
    }
    document.addEventListener("keydown", key);
    return function () { document.removeEventListener("keydown", key); };
  }, []);
  return html`<${Fragment}>
    <${Pins} />
    ${ui.commenting || ui.editingText ? html`<${Picker} editMode=${!!ui.editingText} />` : null}
    ${ui.panel === "comments" ? html`<${Side} />` : null}
    ${V.lightbox ? html`<div class="cmt-lightbox" data-cmt-ui="1" data-id="cmt-lightbox" role="dialog" aria-label="Image preview" onClick=${function () { V.lightbox = null; W.emit(); }}>
      <img src=${V.lightbox} alt="Comment attachment" class="cmt-lightbox-img" onClick=${function (e) { e.stopPropagation(); }} />
      <button type="button" class="wb-btn cmt-lightbox-close" onClick=${function () { V.lightbox = null; W.emit(); }}>Close (Esc)</button>
    </div>` : null}
    ${V.toast ? html`<div class="cmt-toast" data-cmt-ui="1" role="status"><span>${V.toast.msg}</span>
      ${V.toast.undo ? html`<button type="button" class="wb-btn" onClick=${function () { var u = V.toast.undo; V.toast = null; u(); W.emit(); }}>Undo</button>` : null}</div>` : null}
  <//>`;
};

/* buttons in the Workbench menu */
W.wbTools.push(function () {
  var ui = W.U(), n = openCount(), edN = editEntries().length;
  return html`<${Fragment}>
    <button type="button" class=${W.cx("wb-btn", ui.editingText && "is-on")} data-id="wb-edit-text"
      onClick=${function () { W.toggleEditTextMode(); }}>${ui.editingText ? "Stop editing" : "Edit text (E)" + (edN ? " (" + edN + ")" : "")}</button>
    <button type="button" class=${W.cx("wb-btn", ui.commenting && "is-on")} data-id="wb-comment"
      onClick=${function () { W.toggleCommentMode(); }}>${ui.commenting ? "Stop commenting" : "Comment (C)"}</button>
    <button type="button" class=${W.cx("wb-btn", ui.panel === "comments" && "is-on")} data-id="wb-comments"
      onClick=${function () { togglePanel(); }}>Comments (${n})</button>
  <//>`;
});

load();
})();
