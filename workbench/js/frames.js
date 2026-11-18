/* frames.js: the phone and the Windows desktop the app is shown in, the persistent AppBar, and W.Screen.
   Frames are plain elements (no iframe), so the comment and live text-edit tools can reach everything inside them. */
(function () {
"use strict";
var W = window.W, html = W.html;

var PHONE = { w: 410, h: 864 }, DESK = { w: 1200, h: 720 };

/* scales a fixed-size frame down to the room the stage gives it */
function useFit(w, h) {
  var st = W.useState(1), scale = st[0], setScale = st[1];
  W.useEffect(function () {
    function fit() {
      var stage = document.querySelector('[data-id="stage"]');
      var roomW = (stage ? stage.clientWidth : window.innerWidth) - 32;
      var roomH = window.innerHeight - (stage ? stage.getBoundingClientRect().top : 60) - 32;
      setScale(Math.max(0.35, Math.min(1, roomW / w, roomH / h)));
    }
    fit();
    window.addEventListener("resize", fit);
    return function () { window.removeEventListener("resize", fit); };
  }, [w, h]);
  return scale;
}

function two(n) { return (n < 10 ? "0" : "") + n; }
W.clock = function (ts) { var d = new Date(ts); return two(d.getHours()) + ":" + two(d.getMinutes()); };

function Fit(p) {
  var s = useFit(p.w, p.h);
  return html`<div class="fit" dir="ltr" style=${{ width: p.w * s + "px", height: p.h * s + "px" }}>
    <div class="fit-in" style=${{ width: p.w + "px", height: p.h + "px", transform: "scale(" + s + ")" }}>${p.children}</div>
  </div>`;
}

/* Space and Enter count on an open card; Escape closes popups or steps one level back. */
function useCardKeys(trayOpen, setTrayOpen) {
  W.useEffect(function () {
    function onKey(e) {
      if (e.defaultPrevented || e.ctrlKey || e.metaKey || e.altKey) return;
      var ui = W.U();
      if (ui.commenting || ui.editingText || ui.panel === "comments" || ui.panel === "sim") return;
      var t = e.target;
      if (t && (/^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName) || t.isContentEditable)) return;
      if (e.key === "Escape") {
        if (trayOpen && setTrayOpen) { e.preventDefault(); setTrayOpen(false); return; }
        if (ui.popup === "moment") { e.preventDefault(); ui.popup = null; W.save(); W.emit(); return; }
        if (ui.popup && W.cardLeave) { e.preventDefault(); W.cardLeave("close"); return; }
        var back = document.querySelector('[data-id="app-back"], .card-page [data-id="card-back"]');
        if (back) { e.preventDefault(); back.click(); }
        return;
      }
      if (e.key === " " || e.key === "Enter") {
        var onBtn = t && (/^(BUTTON|A)$/.test(t.tagName)
          || (t.getAttribute && t.getAttribute("role") === "button" && t.getAttribute("data-id") !== "card"));
        if (onBtn || (t && t.getAttribute && t.getAttribute("data-id") === "card")) return;
        var s = W.S.state, showing = ui.popup && ui.popup !== "moment" && s.eng && s.eng.day && s.eng.day.showing;
        if (showing && W.cardTap) { e.preventDefault(); W.cardTap(); return; }
        var pageCard = document.querySelector('.card-page[data-id="card"]');
        if (pageCard) { e.preventDefault(); pageCard.click(); }
      }
    }
    window.addEventListener("keydown", onKey);
    return function () { window.removeEventListener("keydown", onKey); };
  }, [trayOpen]);
}

function moreRowTitle(row) {
  var map = {
    level: "more.short.level", freq: "more.short.freq", sleep: "more.short.sleep",
    look: "more.short.look", recite: "more.short.sound",
    sound: "more.short.sound", lang: "more.short.lang", size: "more.short.size",
    backup: "more.backup.t", request: "more.request.t", problem: "more.problem.t",
    updates: "more.updates.t", about: "more.about.t"
  };
  return map[row] ? W.t(map[row]) : row;
}

function adhkarViewLabel(v) {
  if (!v || v === "mine") return W.t("tab.adhkar");
  if (v === "morning" || v === "evening") return W.t("moment." + v);
  if (v === "waking") return W.t("adhkar.filter.waking");
  if (v === "sleep") return W.t("adhkar.filter.sleep");
  if (v === "jumuah") return W.t("group.jumuah");
  if (v === "all") return W.t("adhkar.filter.all");
  var g = (W.GROUPS || []).filter(function (x) { return x.id === v; })[0];
  return g ? W.t(g.label) : v;
}

function routeLabel(r) {
  if (!r || r === "today") return W.t("tab.today");
  if (r === "adhkar") return W.t("tab.adhkar");
  if (r === "more") return W.t("tab.more");
  if (r === "add") return W.t("add.title");
  if (r.indexOf("add/") === 0) {
    var gid = r.slice(4), g = (W.GROUPS || []).filter(function (x) { return x.id === gid; })[0];
    return g ? W.t(g.label) : gid;
  }
  if (r === "moments") return W.t("adhkar.moments.title");
  if (r.indexOf("moments/") === 0) return W.t("moment." + r.slice(8));
  return W.t("tab.today");
}

function popBack(fallback) {
  var ui = W.U(), target = ui.backRoute || fallback || "today";
  ui.backRoute = null;
  W.go(target);
}

/* computes breadcrumb trail and one-step back handler for the persistent top bar */
function navState(route, st) {
  var ui = st.ui, eng = st.eng || {}, parts = route.split("/"), head = parts[0], arg = parts.slice(1).join("/");
  if (head === "today") return { back: null, trail: [{ label: W.t("tab.today") }] };
  if (head === "adhkar" && !arg) {
    var v = ui.adhkarView || "mine";
    if (v !== "mine") {
      var resetView = function () { ui.adhkarView = "mine"; W.save(); W.emit(); };
      return { back: resetView, trail: [{ label: W.t("tab.adhkar"), onClick: resetView }, { label: adhkarViewLabel(v) }] };
    }
    return { back: null, trail: [{ label: W.t("tab.adhkar") }] };
  }
  if (head === "adhkar" && arg) {
    var retRoute = ui.backRoute || "adhkar";
    var goParent = function () { popBack("adhkar"); };
    return { back: goParent, trail: [{ label: routeLabel(retRoute), onClick: goParent }, { label: W.t("nav.dhikr") }] };
  }
  if (head === "add" && !arg) {
    var addParent = (eng.adhkar && eng.adhkar.length) ? "adhkar" : "today";
    return {
      back: function () { W.go(addParent); },
      trail: [{ label: W.t(addParent === "adhkar" ? "tab.adhkar" : "tab.today"), onClick: function () { W.go(addParent); } }, { label: W.t("add.title") }]
    };
  }
  if (head === "add" && arg) {
    var gObj = (W.GROUPS || []).filter(function (g) { return g.id === arg; })[0];
    return {
      back: function () { W.go("add"); },
      trail: [
        { label: W.t("tab.adhkar"), onClick: function () { W.go("adhkar"); } },
        { label: W.t("add.title"), onClick: function () { W.go("add"); } },
        { label: gObj ? W.t(gObj.label) : arg }
      ]
    };
  }
  if (head === "moments" && !arg) {
    return {
      back: function () { W.go("adhkar"); },
      trail: [{ label: W.t("tab.adhkar"), onClick: function () { W.go("adhkar"); } }, { label: W.t("adhkar.moments.title") }]
    };
  }
  if (head === "moments" && arg) {
    return {
      back: function () { W.go("moments"); },
      trail: [
        { label: W.t("tab.adhkar"), onClick: function () { W.go("adhkar"); } },
        { label: W.t("today.moments"), onClick: function () { W.go("moments"); } },
        { label: W.t("moment." + arg) }
      ]
    };
  }
  if (head === "session") {
    var mKey = arg || "morning";
    var items = W.activeSetItems ? W.activeSetItems(eng, mKey) : (mKey === "jumuah" ? (W.JUMUAH_SET || []) : ((W.SETS && W.SETS[mKey]) || []));
    var pos = (eng.day && eng.day.moments && eng.day.moments[mKey]) || { i: 0 };
    var idx = items.length ? W.clamp(pos.i || 0, 0, items.length - 1) + 1 : 1;
    var sParent = ui.backRoute || "today";
    var goSParent = function () { popBack("today"); };
    var sTitle = mKey === "jumuah" ? W.t("group.jumuah") : W.t("moment." + mKey);
    return {
      back: goSParent,
      trail: [
        { label: routeLabel(sParent), onClick: goSParent },
        { label: sTitle }
      ],
      badge: items.length ? html`<span class="appbar-badge num" data-id="session-progress">${W.t("session.progress", { n: idx, total: items.length })}</span>` : null
    };
  }
  if (head === "count") {
    var cParent = ui.backRoute || "today";
    var goCParent = function () { popBack("today"); };
    return {
      back: goCParent,
      trail: [{ label: routeLabel(cParent), onClick: goCParent }, { label: W.t("nav.counting") }]
    };
  }
  if (head === "weekly") {
    return {
      back: function () { W.go("today"); },
      trail: [{ label: W.t("tab.today"), onClick: function () { W.go("today"); } }, { label: W.t("nav.weekly") }]
    };
  }
  if (head === "more" && !arg) return { back: null, trail: [{ label: W.t("tab.more") }] };
  if (head === "days") {
    var dParent = ui.backRoute || "more";
    var goDParent = function () { popBack("more"); };
    return {
      back: goDParent,
      trail: [{ label: routeLabel(dParent), onClick: goDParent }, { label: W.t("more.days.title") }]
    };
  }
  if (head === "more" && arg) {
    return {
      back: function () { W.go("more"); },
      trail: [{ label: W.t("tab.more"), onClick: function () { W.go("more"); } }, { label: moreRowTitle(arg) }]
    };
  }
  return { back: null, trail: [{ label: route }] };
}

W.AppBar = function AppBar(p) {
  var info = navState(p.route, p.st);
  var trail = info.trail.length > 2 && p.st && p.st.ui && p.st.ui.frame !== "windows"
    ? info.trail.slice(-2)
    : info.trail;
  return html`<header class=${W.cx("appbar", info.back && "has-back")} data-id="app-bar">
    <div class="appbar-row">
      ${info.back ? html`<button type="button" class="appbar-back" data-id="app-back" onClick=${info.back}>
        ${W.Icon({ name: "back", size: 22 })}<span>${W.t("btn.back")}</span>
      </button>` : null}
      <button type="button" class="appbar-brand" data-id="app-brand"
        onClick=${function () { W.U().adhkarView = "mine"; W.U().backRoute = null; W.go("today"); }}>
        <span class="appbar-logo">${W.Icon({ name: "adhkar", size: 20 })}</span>
        <span class="appbar-name">${W.t("app.name")}</span>
      </button>
      <nav class="appbar-crumbs" data-id="app-crumbs" aria-label="Breadcrumb">
        ${trail.map(function (item, idx) {
          var last = idx === trail.length - 1;
          return html`<${W.R.Fragment} key=${idx}>
            <span class="appbar-sep" aria-hidden="true">/</span>
            ${!last && item.onClick
              ? html`<button type="button" class="appbar-crumb is-link" onClick=${item.onClick}>${item.label}</button>`
              : html`<span class="appbar-crumb is-here" data-id="app-here">${item.label}</span>`}
          <//>`;
        })}
      </nav>
      ${info.badge ? info.badge : null}
    </div>
  </header>`;
};

/* screens register themselves by the first part of their route: W.screen("today", Today) */
W.SCREENS = {};
W.screen = function (name, Component) { W.SCREENS[name] = Component; };
var TABBED = { today: 1, adhkar: 1, more: 1 };

W.Screen = function Screen() {
  var st = W.useApp(), route = st.ui.route || "today", win = st.ui.frame === "windows";
  if (!(st.eng && st.eng.prefs) && route.indexOf("onboarding/") !== 0) route = "onboarding/1";
  var parts = route.split("/"), C = W.SCREENS[parts[0]];
  var inOnboarding = route.indexOf("onboarding/") === 0;
  var deskNav = win && !inOnboarding && parts[0] !== "session" && parts[0] !== "count";
  return html`<div class=${W.cx("screen-wrap", win && "is-desktop")}>
    ${deskNav ? html`<${W.TabBar} route=${route} />` : null}
    <div class="screen-main">
      ${!inOnboarding ? html`<${W.AppBar} route=${route} st=${st} />` : null}
      <div class="screen m-screen" key=${route} data-screen=${route}>
        ${C ? html`<${C} route=${route} arg=${parts.slice(1).join("/")} />`
          : html`<div class="screen-todo" data-id="screen-todo"><p class="title">${route}</p></div>`}
      </div>
      ${!win && TABBED[route] ? html`<${W.TabBar} route=${route} />` : null}
    </div>
  </div>`;
};

/* popups (the reminder card, the moment card, the lock screen) are drawn by W.Popup once it exists */
function Over() { return W.Popup ? html`<${W.Popup} />` : null; }

W.PhoneFrame = function PhoneFrame(p) {
  var ui = W.useApp().ui, rtl = ui.lang !== "en";
  useCardKeys(false, null);
  return html`<${Fit} w=${PHONE.w} h=${PHONE.h}>
    <div class="phone app" data-id="phone" dir=${rtl ? "rtl" : "ltr"} lang=${rtl ? "ar" : "en"}>
      <div class="phone-status" data-id="phone-status" dir="ltr">
        <span class="num">${W.clock(W.now())}</span><span class="phone-cam"></span><span class="phone-batt"></span>
      </div>
      <div class="phone-app" data-id="phone-app">${p.children}</div>
      <div class="phone-over" data-id="phone-over"><${Over} /></div>
      <div class="phone-bar"></div>
    </div>
  <//>`;
};

W.WindowsFrame = function WindowsFrame(p) {
  var st = W.useApp(), ui = st.ui, eng = st.eng, rtl = ui.lang !== "en";
  var tr = W.useState(false), trayOpen = tr[0], setTrayOpen = tr[1];
  var wn = W.useState(true), winOpen = wn[0], setWinOpen = wn[1];
  W.useEffect(function () { setWinOpen(true); }, [ui.route, ui.day]);
  useCardKeys(trayOpen, setTrayOpen);

  var pop = ui.popup, card = eng && eng.day && eng.day.showing;
  var wantDeskSize = pop === "full" ? "full" : (pop === "banner" || (pop !== "small" && eng && eng.prefs && eng.prefs.cardSize === "banner")) ? "banner" : "small";
  var size = pop && pop !== "moment" && card && W.cardSizeFor
    ? (wantDeskSize === "full" ? "full" : W.cardSizeFor(card.id, wantDeskSize))
    : null;
  var toast = ui.toast && W.Toast ? html`<div class="desktop-toast"><${W.Toast} id="app-toast" text=${ui.toast.text} stamp=${ui.toast.stamp}
    onUndo=${ui.toast.undo ? function () { W.undo(); W.U().toast = null; W.save(); W.emit(); } : null}
    onDone=${function () { W.U().toast = null; W.save(); W.emit(); }} /></div>` : null;

  var paused = !!(eng && eng.pausedUntil && eng.pausedUntil > W.now());

  function openWin() {
    setTrayOpen(false);
    setWinOpen(true);
  }
  function countOne() {
    setTrayOpen(false);
    if (W.U().popup) W.cardLeave("ignore");
    if (!W.showReminder || !W.showReminder("small")) {
      setWinOpen(true);
      W.go("today");
    }
  }
  function togglePause() {
    setTrayOpen(false);
    if (!(eng && eng.prefs)) return;
    W.act("pause", function (s) {
      s.eng = W.E.pause(s.eng, W.now(), paused ? 0 : 60);
    });
  }
  function closeWin() {
    setTrayOpen(false);
    if (W.U().popup && W.cardLeave) W.cardLeave("close");
    else setWinOpen(false);
  }

  return html`<${Fit} w=${DESK.w} h=${DESK.h}>
    <div class="desktop" data-id="desktop" dir=${rtl ? "rtl" : "ltr"} lang=${rtl ? "ar" : "en"}>
      ${winOpen ? html`<div class="desktop-window app" data-id="desktop-window">
        <div class="desktop-titlebar" data-id="desktop-titlebar">
          <span class="desktop-title">${W.t("app.name")}</span>
          <span class="desktop-winbtns" dir="ltr">
            <button type="button" class="desktop-winbtn" aria-label="Minimize" onClick=${function () { setWinOpen(false); }}><i></i></button>
            <button type="button" class="desktop-winbtn" aria-label="Maximize" disabled><i></i></button>
            <button type="button" class="desktop-winbtn is-close" aria-label=${W.t("btn.close")} onClick=${function () { setWinOpen(false); }}><i></i></button>
          </span>
        </div>
        <div class="desktop-body">${p.children}</div>
      </div>` : null}
      ${size === "full" ? html`<div class="desktop-full app" data-id="desktop-full">
        <div class="desktop-full-box m-enter">
          <${W.Card} ...${W.cardProps(eng, card)} size="full" onTap=${W.cardTap}
            onLater=${function () { W.cardLeave("later"); }} onClose=${function () { W.cardLeave("close"); }} />
        </div>
      </div>` : null}
      <div class="desktop-corner app" data-id="desktop-corner">
        ${pop === "moment" && W.MomentCard ? html`<${W.MomentCard} />` : null}
        ${(size === "small" || size === "banner") ? html`<${W.Card} ...${W.cardProps(eng, card)} size=${size} onTap=${W.cardTap}
          onLater=${function () { W.cardLeave("later"); }} onClose=${function () { W.cardLeave("close"); }} />` : null}
        ${toast}
      </div>
      ${trayOpen ? html`<div class="tray-scrim" onClick=${function () { setTrayOpen(false); }}></div>` : null}
      ${trayOpen ? html`<div class="tray-menu app m-enter" data-id="tray-menu" role="menu">
        <button type="button" class="tray-item" role="menuitem" data-id="tray-open" onClick=${openWin}>
          ${W.Icon({ name: "today", size: 22 })}<span>${W.t("tray.open")}</span>
        </button>
        <button type="button" class="tray-item" role="menuitem" data-id="tray-count" onClick=${countOne}>
          ${W.Icon({ name: "adhkar", size: 22 })}<span>${W.t("tray.count")}</span>
        </button>
        <button type="button" class="tray-item" role="menuitem" data-id="tray-pause" onClick=${togglePause}>
          ${W.Icon({ name: paused ? "play" : "pause", size: 22 })}<span>${W.t(paused ? "today.resume" : "today.pause")}</span>
        </button>
        <button type="button" class="tray-item" role="menuitem" data-id="tray-close" onClick=${closeWin}>
          ${W.Icon({ name: "close", size: 22 })}<span>${W.t("btn.close")}</span>
        </button>
      </div>` : null}
      <div class="desktop-taskbar" data-id="desktop-taskbar">
        <span class="desktop-start">
          <i></i><i></i>
          <button type="button" class=${W.cx("desktop-taskapp", winOpen && "is-on")} data-id="taskbar-app" onClick=${function () { setWinOpen(true); }}>
            <span class="desktop-trayicon"></span><span>${W.t("app.name")}</span>
          </button>
        </span>
        <span class="desktop-tray" data-id="desktop-tray">
          <button type="button" class=${W.cx("desktop-traybtn", trayOpen && "is-on")} data-id="tray-icon"
            aria-expanded=${String(trayOpen)} onClick=${function () { setTrayOpen(!trayOpen); }}>
            <span class="desktop-trayicon"></span>
            <span>${W.t("app.name")}</span>
          </button>
          <span class="num">${W.clock(W.now())}</span>
        </span>
      </div>
    </div>
  <//>`;
};
})();
