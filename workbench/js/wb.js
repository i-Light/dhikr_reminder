/* wb.js: the Workbench menu. English only, outside the frames, and marked data-cmt-ui so the comment tool
   ignores it. It changes what the prototype shows: example day, frame, language, theme, text size, look. */
(function () {
"use strict";
var W = window.W, html = W.html;

W.DAYS = [
  ["first", "First open"], ["noon", "A normal day at noon"], ["complete", "Everything complete"],
  ["missed", "Back after a missed week"], ["weekup", "Weekly card: going up"],
  ["weekdown", "Weekly card: going down"], ["weekheavy", "Weekly card: one heavy dhikr"]
];

function setUi(key, value) {
  W.U()[key] = value;
  W.save();
  W.emit();
}

/* loads an example day: a state the simulator really produced, and the pretend time that goes with it */
W.setDay = function (key, opts) {
  opts = opts || {};
  var d = W.Sim.day(key), ui = W.U();
  W.S.state.eng = d.state || {};
  W.S.undo = [];
  ui.day = key;
  ui.now = d.now;
  if (!opts.keepPopup) ui.popup = null;
  if (!opts.keepRoute) ui.route = d.state ? "today" : "onboarding/1";
  W.save();
  W.emit();
};
W.setLang = function (v) { setUi("lang", v); };
W.setTheme = function (v) { setUi("theme", v); };
W.setSize = function (v) { setUi("size", v); };
W.setLook = function (v) { setUi("look", v); };
W.setFrame = function (v) { setUi("frame", v); };
/* example data back to how the chosen day starts; comments are kept */
W.resetAll = function () { W.setDay(W.U().day); };

function Seg(p) {
  return html`<span class="wb-seg" role="group" aria-label=${p.label} data-id=${p.id} data-cmt-ui="1">
    <span class="wb-seg-label">${p.label}</span>
    ${p.options.map(function (o) {
      return html`<button type="button" key=${String(o[0])} class=${W.cx("wb-seg-btn", o[0] === p.value && "is-on")}
        data-id=${p.id + "-" + o[0]} aria-pressed=${o[0] === p.value} onClick=${function () { p.onChange(o[0]); }}>${o[1]}</button>`;
    })}
  </span>`;
}

/* one short line from the workbench itself, shown in the menu for a few seconds */
var noteTimer = 0;
W.wbNote = function (msg) {
  W.U().wbNote = msg;
  clearTimeout(noteTimer);
  noteTimer = setTimeout(function () { W.U().wbNote = null; W.emit(); }, 5000);
  W.emit();
};

/* extra buttons other tasks add to the menu: W.wbTools.push(function () { return html`...`; }) */
W.wbTools = [];

W.WbMenu = function WbMenu() {
  var ui = W.useApp().ui, inGallery = ui.route === "gallery";
  return html`<div class="wb-menu" data-id="wb-menu" data-cmt-ui="1" dir="ltr">
    <label class="wb-pick"><span class="wb-seg-label">Example day</span>
      <select data-id="wb-day" value=${ui.day} onChange=${function (e) { W.setDay(e.target.value); }}>
        ${W.DAYS.map(function (d) { return html`<option key=${d[0]} value=${d[0]}>${d[1]}</option>`; })}
      </select>
    </label>
    <${Seg} id="wb-frame" label="Frame" value=${ui.frame} options=${[["phone", "Phone"], ["windows", "Windows"]]} onChange=${W.setFrame} />
    <${Seg} id="wb-lang" label="Language" value=${ui.lang} options=${[["ar", "Arabic"], ["en", "English"]]} onChange=${W.setLang} />
    <${Seg} id="wb-theme" label="Theme" value=${ui.theme} options=${[["light", "Light"], ["dark", "Dark"]]} onChange=${W.setTheme} />
    <${Seg} id="wb-size" label="Text" value=${ui.size} options=${[[1, "A"], [2, "A+"], [3, "A++"]]} onChange=${W.setSize} />
    <${Seg} id="wb-look" label="Look" value=${ui.look} options=${[["a", "A Olive"], ["b", "B Iznik"]]} onChange=${W.setLook} />
    ${W.wbTools.map(function (tool, i) { return html`<span key=${i} class="wb-tool">${tool()}</span>`; })}
    <button type="button" class="wb-btn" data-id="wb-gallery" onClick=${function () {
      if (inGallery) W.go(ui.backRoute || "today"); else { ui.backRoute = ui.route; W.go("gallery"); }
    }}>${inGallery ? "Back to the app" : "Icons and motion"}</button>
    <button type="button" class="wb-btn" data-id="wb-reset" onClick=${W.resetAll}>Reset example data</button>
    ${ui.wbNote ? html`<span class="wb-note" data-id="wb-note" role="status">${ui.wbNote}</span>` : null}
  </div>`;
};
})();
