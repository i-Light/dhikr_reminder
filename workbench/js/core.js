/* core.js: the shared runtime. W.html, a tiny store with undo, storage helpers, live text edits, navigation. */
(function () {
"use strict";
var R = window.React;
var W = window.W = {};
W.R = R;
["useState", "useEffect", "useRef", "useMemo"].forEach(function (k) { W[k] = R[k]; });
W.html = window.htm.bind(R.createElement);

W.cx = function () { return Array.prototype.filter.call(arguments, Boolean).join(" "); };
W.clamp = function (v, a, b) { return Math.max(a, Math.min(b, v)); };
W.uid = function (p) { return (p || "x") + Math.random().toString(36).slice(2, 8); };

W.LS = {
  get: function (key, fallback) {
    try {
      var raw = window.localStorage.getItem(key);
      if (raw == null) return fallback;
      var v = JSON.parse(raw);
      return v == null ? fallback : v;
    } catch (e) { return fallback; }
  },
  set: function (key, value) {
    try { window.localStorage.setItem(key, JSON.stringify(value)); } catch (e) { /* storage unavailable */ }
  }
};

W.KEYS = { eng: "dhikr-wb-state", ui: "dhikr-wb-ui", comments: "dhikr-wb-comments", edits: "dhikr-wb-edits" };

W.DEFAULT_UI = { day: "first", lang: "ar", frame: "phone", theme: "light", size: 3, route: "today", popup: null, commenting: false, editingText: false, panel: null };
var ENUM = {
  day: ["first", "noon", "friday", "complete", "missed", "weekup", "weekdown", "weekheavy"],
  lang: ["ar", "en"], frame: ["phone", "windows"], theme: ["light", "dark"],
  size: [1, 2, 3, 4, 5, 6, 7], popup: ["banner", "small", "full", "moment", "lock"]
};

function clone(o) { return JSON.parse(JSON.stringify(o)); }
function plain(v) { return v && typeof v === "object" && !Array.isArray(v); }

/* ui from saved state, keeping only valid values */
W.cleanUi = function (saved) {
  var ui = clone(W.DEFAULT_UI);
  if (!plain(saved)) return ui;
  Object.keys(ENUM).forEach(function (k) {
    var v = k === "size" ? Number(saved[k]) : saved[k];
    if (ENUM[k].indexOf(v) >= 0) ui[k] = v;
  });
  if (typeof saved.route === "string" && saved.route) ui.route = saved.route;
  if (typeof saved.commenting === "boolean") ui.commenting = saved.commenting;
  if (typeof saved.editingText === "boolean") ui.editingText = saved.editingText;
  if (typeof saved.panel === "string") ui.panel = saved.panel;
  if (typeof saved.now === "number" && isFinite(saved.now)) ui.now = saved.now;
  if (typeof saved.backRoute === "string") ui.backRoute = saved.backRoute;
  if (typeof saved.permissionMissing === "boolean") ui.permissionMissing = saved.permissionMissing;
  if (plain(saved.answers)) ui.answers = saved.answers;
  return ui;
};

/* URL contract: returns only the keys that are present and valid */
W.readUrl = function (search) {
  var out = {};
  var q;
  try { q = new URLSearchParams(search == null ? window.location.search : search); } catch (e) { return out; }
  Object.keys(ENUM).forEach(function (k) {
    var raw = q.get(k);
    if (raw == null) return;
    var v = k === "size" ? Number(raw) : raw;
    if (ENUM[k].indexOf(v) >= 0) out[k] = v;
  });
  var route = q.get("route");
  if (route) out.route = route;
  var panel = q.get("panel");
  if (panel === "comments" || panel === "sim") out.panel = panel;
  return out;
};

/* ---------- store ---------- */
var S = W.S = { state: { eng: {}, ui: clone(W.DEFAULT_UI) }, ver: 0, subs: [], undo: [] };
W.init = function (eng, ui) { S.state = { eng: plain(eng) ? eng : {}, ui: ui }; S.undo = []; };
W.U = function () { return S.state.ui; };
W.emit = function () {
  S.ver++;
  for (var i = 0; i < S.subs.length; i++) S.subs[i]();
};
W.subscribe = function (f) {
  S.subs.push(f);
  return function () { S.subs = S.subs.filter(function (x) { return x !== f; }); };
};
W.useApp = function () {
  R.useSyncExternalStore(W.subscribe, function () { return S.ver; });
  return S.state;
};
W.save = function () {
  W.LS.set(W.KEYS.eng, S.state.eng);
  W.LS.set(W.KEYS.ui, S.state.ui);
};
/* change the engine state: snapshot for undo, run fn(state), save, emit */
W.act = function (label, fn) {
  var before = clone(S.state.eng);
  var r = fn(S.state);
  if (r === false) return false;
  S.undo.push({ label: label, eng: before });
  if (S.undo.length > 80) S.undo.shift();
  W.save();
  W.emit();
  return r;
};
W.undo = function () {
  var u = S.undo.pop();
  if (!u) return false;
  S.state.eng = u.eng;
  W.save();
  W.emit();
  return true;
};

/* ---------- live text overrides ---------- */
W.ORIG = { str: null, lib: null };
W.EDITS = { ar: {}, en: {}, lib: {}, dom: {} };
W._renderedKeys = {};

W.ensureOrig = function () {
  if (!W.ORIG.str && W.STR) W.ORIG.str = clone(W.STR);
  if (!W.ORIG.lib && W.LIB) W.ORIG.lib = clone(W.LIB);
};

W.applyEditsToTables = function () {
  W.ensureOrig();
  if (W.ORIG.str && W.STR) {
    ["ar", "en"].forEach(function (lg) {
      if (!W.ORIG.str[lg] || !W.STR[lg]) return;
      Object.keys(W.ORIG.str[lg]).forEach(function (k) { W.STR[lg][k] = W.ORIG.str[lg][k]; });
      var ov = (W.EDITS && W.EDITS[lg]) || {};
      Object.keys(ov).forEach(function (k) {
        if (typeof ov[k] === "string" && ov[k].trim()) W.STR[lg][k] = ov[k];
      });
    });
  }
  if (W.ORIG.lib && W.LIB) {
    var origMap = {};
    W.ORIG.lib.forEach(function (x) { origMap[x.id] = x; });
    W.LIB.forEach(function (item) {
      var ox = origMap[item.id];
      if (!ox) return;
      ["ar", "translit", "arNote", "en", "source", "sourceEn"].forEach(function (f) {
        item[f] = ox[f];
      });
      var lov = W.EDITS && W.EDITS.lib && W.EDITS.lib[item.id];
      if (plain(lov)) {
        ["ar", "translit", "arNote", "en", "source", "sourceEn"].forEach(function (f) {
          if (typeof lov[f] === "string" && lov[f].trim()) item[f] = lov[f];
        });
      }
    });
  }
};

W.loadEdits = function () {
  W.ensureOrig();
  var saved = W.LS.get(W.KEYS.edits, null);
  if (plain(saved)) {
    W.EDITS = {
      ar: plain(saved.ar) ? saved.ar : {},
      en: plain(saved.en) ? saved.en : {},
      lib: plain(saved.lib) ? saved.lib : {},
      dom: plain(saved.dom) ? saved.dom : {}
    };
    ["ar", "en"].forEach(function (lg) {
      var origTbl = (W.ORIG.str && W.ORIG.str[lg]) || {};
      Object.keys(W.EDITS[lg]).forEach(function (k) {
        if (origTbl[k] != null && String(W.EDITS[lg][k]).trim() === String(origTbl[k]).trim()) delete W.EDITS[lg][k];
      });
    });
  }
  W.applyEditsToTables();
};

var editPutTimer = 0;
W.saveEdits = function () {
  W.LS.set(W.KEYS.edits, W.EDITS);
  if (!W.served || !window.fetch) return;
  clearTimeout(editPutTimer);
  editPutTimer = setTimeout(function () {
    window.fetch("/api/edits", { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(W.EDITS) })
      .catch(function () { /* kept in browser */ });
  }, 250);
};

W.editsSync = function () {
  if (!W.served || !window.fetch) return Promise.resolve(false);
  return window.fetch("/api/edits").then(function (r) { return r.json(); }).then(function (remote) {
    if (plain(remote)) {
      ["ar", "en"].forEach(function (lg) {
        if (plain(remote[lg])) W.EDITS[lg] = Object.assign({}, remote[lg], W.EDITS[lg]);
      });
      if (plain(remote.lib)) W.EDITS.lib = Object.assign({}, remote.lib, W.EDITS.lib);
      if (plain(remote.dom)) W.EDITS.dom = Object.assign({}, remote.dom, W.EDITS.dom);
      W.applyEditsToTables();
      W.saveEdits();
      W.emit();
    }
    return true;
  }).catch(function () { return false; });
};

/* words: W.STR comes from strings.js; {name} is filled from vars; a missing key shows as [key] */
W.t = function (key, vars) {
  var ui = W.U(), lang = (ui && ui.lang) || "ar";
  var table = W.STR && (W.STR[lang] || W.STR.ar);
  var s = table && table[key];
  if (s == null) return "[" + key + "]";
  var out = vars ? s.replace(/\{(\w+)\}/g, function (m, k) { return vars[k] == null ? m : String(vars[k]); }) : s;
  var normOut = out.replace(/\s+/g, " ").trim();
  if (normOut) W._renderedKeys[normOut] = { key: key, lang: lang };
  return out;
};

/* the pretend time the prototype is showing; an example day sets it */
W.now = function () { return S.state.ui.now || Date.now(); };
W.go = function (route) {
  S.state.ui.route = route;
  W.save();
  W.emit();
};

/* true once GET /api/ping answers; only tried when the page is served over http */
W.served = false;
W.ping = function () {
  if (!/^https?:$/.test(window.location.protocol) || !window.fetch) return Promise.resolve(false);
  return window.fetch("/api/ping").then(function (r) { return r.json(); }).then(function (j) {
    W.served = !!(j && j.ok);
    W.emit();
    return W.served;
  }).catch(function () { return false; });
};
})();
