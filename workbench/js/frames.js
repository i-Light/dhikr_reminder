/* frames.js: the phone and the Windows desktop the app is shown in, and W.Screen, which picks the screen for
   the route. Frames are plain elements (no iframe), so the comment tool can reach everything inside them. */
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

/* screens register themselves by the first part of their route: W.screen("today", Today) */
W.SCREENS = {};
W.screen = function (name, Component) { W.SCREENS[name] = Component; };
var TABBED = { today: 1, adhkar: 1, more: 1 };

W.Screen = function Screen() {
  var st = W.useApp(), route = st.ui.route || "today";
  if (!(st.eng && st.eng.prefs) && route.indexOf("onboarding/") !== 0) route = "onboarding/1";
  var parts = route.split("/"), C = W.SCREENS[parts[0]];
  return html`<div class="screen-wrap">
    <div class="screen m-screen" key=${route} data-screen=${route}>
      ${C ? html`<${C} route=${route} arg=${parts.slice(1).join("/")} />`
        : html`<div class="screen-todo" data-id="screen-todo"><p class="title">${route}</p></div>`}
    </div>
    ${TABBED[route] ? html`<${W.TabBar} route=${route} />` : null}
  </div>`;
};

/* popups (the reminder card, the moment card, the lock screen) are drawn by W.Popup once it exists */
function Over() { return W.Popup ? html`<${W.Popup} />` : null; }

W.PhoneFrame = function PhoneFrame(p) {
  var ui = W.useApp().ui, rtl = ui.lang !== "en";
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
  var ui = W.useApp().ui, rtl = ui.lang !== "en";
  return html`<${Fit} w=${DESK.w} h=${DESK.h}>
    <div class="desktop" data-id="desktop" dir=${rtl ? "rtl" : "ltr"} lang=${rtl ? "ar" : "en"}>
      <div class="desktop-window app" data-id="desktop-window">
        <div class="desktop-titlebar" data-id="desktop-titlebar">
          <span class="desktop-title">${W.t("app.name")}</span>
          <span class="desktop-winbtns" dir="ltr"><i></i><i></i><i></i></span>
        </div>
        <div class="desktop-body">${p.children}</div>
      </div>
      <div class="desktop-corner app" data-id="desktop-corner"><${Over} /></div>
      <div class="desktop-taskbar" data-id="desktop-taskbar">
        <span class="desktop-start"><i></i><i></i><i></i></span>
        <span class="desktop-tray" data-id="desktop-tray"><span class="desktop-trayicon" data-id="tray-icon"></span><span class="num">${W.clock(W.now())}</span></span>
      </div>
    </div>
  <//>`;
};
})();
