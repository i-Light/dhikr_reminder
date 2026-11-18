/* adhkar.js: My adhkar (6-button top switcher, compact clickable moment summary opening a settings popup per Comment #14,
   More categories sheet, sticky bottom Add button) and adhkar/<id> with full virtue & reflection. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

var M_KEYS = ["morning", "evening", "sleep", "waking"];
var M_ICONS = { morning: "sun", evening: "moon", sleep: "bed", waking: "sunrise" };
var EXTRA_CATS = [
  { id: "mine", label: "adhkar.filter.mine", icon: "adhkar" },
  { id: "jumuah", label: "group.jumuah", icon: "mosque" },
  { id: "afterPrayer", label: "group.afterprayer", icon: "adhkar" },
  { id: "tasabih", label: "group.tasabih", icon: "sparkle" },
  { id: "duas", label: "group.duas", icon: "today" },
  { id: "all", label: "adhkar.filter.all", icon: "search" }
];

function sunnahOf(eng, id, it) {
  if (it && it.sunnah !== undefined) return it.sunnah;
  return eng.sunnah && eng.sunnah[id] != null ? eng.sunnah[id] : null;
}

function subFor(a, sn) {
  return sn != null
    ? W.t("adhkar.sub.sunnah", { target: a.target, sunnah: sn })
    : W.t("adhkar.sub.plain", { target: a.target });
}

function minToHhmm(m) {
  var t = ((Math.round(m) % 1440) + 1440) % 1440;
  var h = Math.floor(t / 60), mn = t % 60;
  return (h < 10 ? "0" : "") + h + ":" + (mn < 10 ? "0" : "") + mn;
}

function estMinutes(key) {
  var items = (W.SETS && W.SETS[key]) || [], words = 0;
  items.forEach(function (x) {
    var it = W.lib(x.id);
    words += ((it && it.words) || 5) * (x.count || 1);
  });
  return Math.max(1, Math.round(words / 90));
}

function SwitchBtn(p) {
  return html`<button type="button" role="switch" aria-checked=${p.on ? "true" : "false"}
    class=${W.cx("switch-btn", p.on && "is-on")} data-id=${p.id} onClick=${p.onClick}>
    <span class="switch-track"><span class="switch-knob"></span></span>
    <span class="switch-word">${W.t(p.on ? "moments.on" : "moments.off")}</span>
  </button>`;
}

function MomentInline(p) {
  var key = p.mkey, eng = p.eng, en = W.U().lang === "en";
  var popSt = W.useState(false), popOpen = popSt[0], setPopOpen = popSt[1];
  var mt = E.momentTimes(eng.prefs);
  var mp = (eng.prefs && eng.prefs.moments && eng.prefs.moments[key]) || { on: true, at: null };
  var on = mp.on !== false;
  var hhmm = minToHhmm(mt[key].start);
  var timeStr = W.timeLabel(hhmm);
  var items = (W.SETS && W.SETS[key]) || [];
  var skipMap = (eng.prefs && eng.prefs.momentSkip && eng.prefs.momentSkip[key]) || {};
  var activeCount = items.filter(function (x) { return !skipMap[x.id]; }).length || items.length;
  var mins = estMinutes(key);

  function toggleSkipItem(itemId) {
    W.act("moment-item", function (s) {
      var curPrefs = Object.assign({}, s.eng.prefs);
      var allSkips = Object.assign({}, curPrefs.momentSkip || {});
      var curKeySkips = Object.assign({}, allSkips[key] || {});
      if (curKeySkips[itemId]) {
        delete curKeySkips[itemId];
      } else {
        var rem = items.filter(function (x) { return x.id !== itemId && !curKeySkips[x.id]; }).length;
        if (rem < 1) return false;
        curKeySkips[itemId] = true;
      }
      allSkips[key] = curKeySkips;
      curPrefs.momentSkip = allSkips;
      s.eng = Object.assign({}, s.eng, { prefs: curPrefs });
    });
  }
  var minLine = mins === 1 ? W.t("moments.min.one") : W.t("moments.min.many", { n: mins });
  var mName = W.t("moment." + key);

  function setTime(v) {
    var m = E.min(v);
    if (m < E.dayStartMin(eng.prefs)) m += 1440;
    W.act("moment-time", function (s) { s.eng = E.setMoment(s.eng, key, { at: m }); });
  }

  return html`<div class="adhkar-moment-box" data-id="adhkar-moment-ctrl">
    <button type="button" class=${W.cx("moment-compact-btn", !on && "is-off")}
      data-id="moment-compact-open" onClick=${function () { setPopOpen(true); }}>
      <span class="moment-compact-ic">${W.Icon({ name: M_ICONS[key] || "sun", size: 20 })}</span>
      <span class="moment-compact-meta">
        <span class="moment-compact-top">
          <span class="moment-compact-name">${mName}</span>
          <span class="moment-compact-chips num">
            <span class=${W.cx("mc-chip", on && "is-on")}>
              ${W.Icon({ name: on ? "bell" : "pause", size: 13 })}
              <span>${W.t(on ? "moments.on" : "moments.off")}</span>
            </span>
            <span class="mc-chip">
              ${W.Icon({ name: "later", size: 13 })}
              <span>${timeStr}</span>
            </span>
            <span class="mc-chip">
              ${W.Icon({ name: "adhkar", size: 13 })}
              <span>${activeCount}</span>
            </span>
          </span>
        </span>
        <span class="moment-compact-sub quiet num">${minLine}</span>
      </span>
      <span class="moment-compact-edit" aria-hidden="true">
        ${W.Icon({ name: "wrench", size: 15 })}
      </span>
    </button>

    <${W.Btn} kind="main" wide=${true} icon="play"
      label=${W.t("adhkar.moment.start", { name: mName })}
      id="adhkar-moment-start"
      onClick=${function () { W.U().backRoute = "adhkar"; W.go("session/" + key); }} />

    <section class="today-sec" data-id="moment-items">
      <h2 class="today-sec-title quiet">${W.t("moments.contents")}</h2>
      <div class="adhkar-rows">
        ${items.map(function (entry) {
          var it = W.lib(entry.id);
          var isSkipped = !!skipMap[entry.id];
          var baseSub = entry.count === 1 ? W.t("add.once") : W.t("moments.item.count", { n: entry.count });
          var sub = isSkipped ? W.t("moments.item.skipped") : (en && it && it.translit ? it.translit + " . " + baseSub : baseSub);
          return html`<div key=${entry.id} class=${W.cx("row", "lib-row", isSkipped && "is-done")} data-id=${"set-item-" + entry.id}>
            <button type="button" class="lib-row-open" data-id=${"set-open-" + entry.id}
              onClick=${function () { W.U().backRoute = "adhkar"; W.go("adhkar/" + entry.id); }}>
              <span class="row-main">
                <span class="row-title is-dhikr" dir="rtl" lang="ar">${it ? it.ar : entry.id}</span>
                <span class="row-sub num">${sub}</span>
              </span>
            </button>
            ${items.length > 1 ? html`<span class="row-end">
              <${W.Btn} kind=${isSkipped ? "soft" : "text"} icon=${isSkipped ? "return" : "rest"}
                label=${W.t(isSkipped ? "moments.item.include" : "moments.item.skip")}
                id=${"set-toggle-" + entry.id}
                onClick=${function () { toggleSkipItem(entry.id); }} />
            </span>` : null}
          </div>`;
        })}
      </div>
    </section>

    <${W.Sheet} id="moment-settings-sheet" popup=${true} open=${popOpen}
      title=${W.t("adhkar.moment.sheet", { name: mName })}
      onClose=${function () { setPopOpen(false); }}
      footer=${html`<${W.Btn} kind="main" wide=${true} icon="check" label=${W.t("btn.done")} id="moment-sheet-done"
        onClick=${function () { setPopOpen(false); }} />`}>
      <div class="moment-sheet-body">
        <div class="adhkar-moment-head">
          <span class="title">${mName}</span>
          <${SwitchBtn} id=${"moment-switch-" + key} on=${on}
            onClick=${function () { W.act("moment", function (s) { s.eng = E.setMoment(s.eng, key, { on: !on }); }); }} />
        </div>
        <${W.TimeStep} id="moment-inline-time" label=${W.t("moments.time")} value=${hhmm} onChange=${setTime} />
        ${mp.at != null ? html`<div class="moment-reset-wrap">
          <${W.Btn} kind="text" icon="undo" label=${W.t("moments.reset")} id="moment-inline-reset"
            onClick=${function () { W.act("moment-reset", function (s) { s.eng = E.setMoment(s.eng, key, { at: null }); }); }} />
        </div>` : null}
      </div>
    <//>
  </div>`;
}

function JumuahInline(p) {
  var eng = p.eng, en = W.U().lang === "en";
  var items = W.JUMUAH_SET || [];
  var pos = (eng.day && eng.day.moments && eng.day.moments.jumuah) || { i: 0, n: 0, done: false };
  var doneItems = pos.done ? items.length : W.clamp(pos.i || 0, 0, items.length);
  var jName = W.t("group.jumuah");

  return html`<div class="adhkar-moment-box" data-id="adhkar-jumuah-section">
    <div class="panel jumuah-sec-head">
      <div class="jumuah-sec-row">
        <span class="moment-compact-ic">${W.Icon({ name: "mosque", size: 22 })}</span>
        <div class="moment-compact-meta">
          <span class="moment-compact-name">${jName}</span>
          <span class="quiet num">${doneItems} / ${items.length}</span>
        </div>
      </div>
      <${W.Btn} kind="main" wide=${true} icon="play"
        label=${W.t("adhkar.moment.start", { name: jName })}
        id="adhkar-jumuah-start"
        onClick=${function () { W.U().backRoute = "adhkar"; W.go("session/jumuah"); }} />
    </div>
    <section class="today-sec" data-id="jumuah-items">
      <h2 class="today-sec-title quiet">${W.t("moments.contents")}</h2>
      <div class="adhkar-rows">
        ${items.map(function (entry, idx) {
          var it = W.lib(entry.id);
          var isItemDone = pos.done || idx < (pos.i || 0);
          var sub = entry.count === 1 ? W.t("add.once") : W.t("moments.item.count", { n: entry.count });
          return html`<${W.Row} key=${entry.id} id=${"jumuah-item-" + entry.id} dhikr=${true} done=${isItemDone}
            lead=${html`<${W.Ring} done=${isItemDone ? entry.count : (idx === (pos.i || 0) ? (pos.n || 0) : 0)} total=${entry.count} size=${40} />`}
            title=${it ? it.ar : entry.id}
            sub=${en && it && it.translit ? it.translit + " . " + sub : sub}
            onClick=${function () { W.U().backRoute = "adhkar"; W.go("count/" + entry.id); }} />`;
        })}
      </div>
    </section>
  </div>`;
}

function CategoryInline(p) {
  var cat = p.cat, eng = p.eng, en = W.U().lang === "en";
  var have = {};
  (eng.adhkar || []).forEach(function (a) { have[a.id] = a; });
  var items = cat === "all" ? W.LIB : W.LIB.filter(function (x) { return (x.groups || []).indexOf(cat) >= 0; });

  return html`<div class="adhkar-rows" data-id="adhkar-cat-list">
    ${items.map(function (it) {
      var a = have[it.id], sn = sunnahOf(eng, it.id, it);
      var sub = a ? subFor(a, sn) : (sn === 1 ? W.t("add.once") : sn > 1 ? W.t("step.mark", { n: sn }) : null);
      return html`<div key=${it.id} class=${W.cx("row", "lib-row", a && "is-in-list")} data-id=${"cat-row-" + it.id}>
        <button type="button" class="lib-row-open" data-id=${"cat-open-" + it.id}
          onClick=${function () { W.U().backRoute = "adhkar"; W.go("adhkar/" + it.id); }}>
          <span class="row-main">
            <span class="row-title is-dhikr" dir="rtl" lang="ar">${it.ar}</span>
            ${en && it.translit ? html`<span class="row-sub" dir="ltr" lang="en">${it.translit}</span>` : null}
            ${sub ? html`<span class="row-sub num">${sub}</span>` : null}
          </span>
        </button>
        <span class="row-end">
          <${W.Btn} kind=${a ? "text" : "soft"} icon=${a ? "done" : "add"}
            label=${W.t(a ? "add.added" : "btn.add")} id=${"cat-add-" + it.id} disabled=${!!a}
            onClick=${function () { W.act("add", function (s) { s.eng = E.add(s.eng, it); }); }} />
        </span>
      </div>`;
    })}
  </div>`;
}

function AdhkarList() {
  var st = W.useApp(), ui = st.ui, eng = E.rollDay(st.eng, W.now());
  var sheetSt = W.useState(false), sheetOpen = sheetSt[0], setSheetOpen = sheetSt[1];
  var view = ui.adhkarView || "mine";
  var all = eng.adhkar || [];
  var active = all.filter(function (a) { return !a.resting; });
  var resting = all.filter(function (a) { return a.resting; });

  function pickView(v) {
    ui.adhkarView = v;
    W.save();
    W.emit();
  }

  var isExtraCat = view !== "mine" && M_KEYS.indexOf(view) < 0;
  var extraMeta = EXTRA_CATS.filter(function (c) { return c.id === view; })[0];
  var moreLabel = isExtraCat && extraMeta ? W.t(extraMeta.label) : W.t("adhkar.filter.more");

  var topButtons = [
    { id: "mine", icon: "adhkar", label: W.t("adhkar.filter.mine"), on: view === "mine", click: function () { pickView("mine"); } },
    { id: "morning", icon: M_ICONS.morning, label: W.t("moment.morning"), on: view === "morning", click: function () { pickView("morning"); } },
    { id: "evening", icon: M_ICONS.evening, label: W.t("moment.evening"), on: view === "evening", click: function () { pickView("evening"); } },
    { id: "sleep", icon: M_ICONS.sleep, label: W.t("adhkar.filter.sleep"), on: view === "sleep", click: function () { pickView("sleep"); } },
    { id: "waking", icon: M_ICONS.waking, label: W.t("adhkar.filter.waking"), on: view === "waking", click: function () { pickView("waking"); } },
    { id: "more", icon: "more", label: moreLabel, on: isExtraCat, click: function () { setSheetOpen(true); } }
  ];

  return html`<div class="adhkar" data-id="adhkar">
    <div class="adhkar-views" data-id="adhkar-views" role="tablist">
      ${topButtons.map(function (b) {
        return html`<button type="button" key=${b.id} role="tab" aria-selected=${b.on ? "true" : "false"}
          class=${W.cx("adhkar-view-btn", b.on && "is-on")}
          data-id=${b.id === "morning" ? "adhkar-moments" : "adhkar-view-" + b.id}
          onClick=${b.click}>
          <span class="adhkar-view-ic">${W.Icon({ name: b.icon, size: 22 })}</span>
          <span class="adhkar-view-lbl">${b.label}</span>
        </button>`;
      })}
    </div>

    ${view === "mine" ? html`<${W.R.Fragment}>
      <p class="quiet adhkar-track-hint" data-id="adhkar-mine-hint">${W.t("adhkar.mine.hint")}</p>
      ${active.length ? html`<div class="adhkar-rows" data-id="adhkar-list">
        ${active.map(function (a) {
          var it = W.lib(a.id), sn = sunnahOf(eng, a.id, it);
          return html`<${W.Row} key=${a.id} id=${"adhkar-row-" + a.id} dhikr=${true}
            title=${it ? it.ar : a.id} sub=${subFor(a, sn)}
            onClick=${function () { W.U().backRoute = "adhkar"; W.go("adhkar/" + a.id); }} />`;
        })}
      </div>` : html`<div class="panel adhkar-empty">
        <p class="quiet">${W.t("today.empty.text")}</p>
      </div>`}

      ${resting.length ? html`<section class="today-sec" data-id="resting-group">
        <h2 class="today-sec-title quiet">${W.t("adhkar.resting")}</h2>
        <div class="adhkar-rows">
          ${resting.map(function (a) {
            var it = W.lib(a.id), sn = sunnahOf(eng, a.id, it);
            return html`<${W.Row} key=${a.id} id=${"adhkar-row-" + a.id} dhikr=${true} done=${true}
              title=${it ? it.ar : a.id} sub=${subFor(a, sn)}
              end=${html`<${W.Btn} kind="soft" icon="return" label=${W.t("adhkar.bringback")}
                id=${"bring-back-" + a.id}
                onClick=${function () { W.act("return", function (s) { s.eng = E.rest(s.eng, a.id, false); }); }} />`} />`;
          })}
        </div>
      </section>` : null}
    <//>` : M_KEYS.indexOf(view) >= 0 ? html`<${MomentInline} key=${view} mkey=${view} eng=${eng} />`
      : view === "jumuah" ? html`<${JumuahInline} key="jumuah" eng=${eng} />`
      : html`<${CategoryInline} key=${view} cat=${view} eng=${eng} />`}

    <div class="adhkar-fab" data-id="adhkar-fab">
      <${W.Btn} kind="main" wide=${true} icon="add" label=${W.t("today.add")} id="add-dhikr"
        onClick=${function () { W.go("add"); }} />
    </div>

    <${W.Sheet} id="adhkar-cat-sheet" open=${sheetOpen} title=${W.t("adhkar.filter.sheet")}
      onClose=${function () { setSheetOpen(false); }}>
      <${W.Choice} id="adhkar-cat-choice" value=${view}
        onChange=${function (v) { pickView(v); setSheetOpen(false); }}
        options=${EXTRA_CATS.map(function (c) {
          return { value: c.id, label: W.t(c.label), icon: c.icon };
        })} />
    <//>
  </div>`;
}

function DhikrPage(p) {
  var id = p.id, st = W.useApp(), eng = E.rollDay(st.eng, W.now()), en = st.ui.lang === "en";
  var it = W.lib(id);
  var a = (eng.adhkar || []).filter(function (x) { return x.id === id; })[0];
  var sn = sunnahOf(eng, id, it);
  var fadl = it ? (en ? (it.en || it.arNote) : (it.arNote || it.en)) : null;
  var tad = it ? (en ? (it.tadabburEn || it.tadabburAr) : (it.tadabburAr || it.tadabburEn)) : null;
  var src = it ? (en ? (it.sourceEn || it.source) : (it.source || it.sourceEn)) : null;

  return html`<div class="dhikr-page" data-id="dhikr-page">
    <div class="panel dhikr-card">
      <${W.Ornament} />
      <${W.DhikrText} id=${id} dataId="dhikr-text" />
      ${fadl || tad || src ? html`<div class="dhikr-fadl" data-id="dhikr-fadl">
        <div class="dhikr-fadl-head">
          ${W.Icon({ name: "sparkle", size: 22 })}
          <span class="dhikr-fadl-title">${W.t("adhkar.fadl.title")}</span>
        </div>
        ${fadl ? html`<p class="dhikr-note" data-id="dhikr-note">${fadl}</p>` : null}
        ${tad && tad !== fadl ? html`<p class="dhikr-note quiet">${tad}</p>` : null}
        ${src ? html`<p class="dhikr-src quiet">${src}</p>` : null}
      </div>` : null}
    </div>

    ${a ? html`<div class="panel dhikr-amount">
      <p class="dhikr-amount-label quiet">${W.t("adhkar.todayamount")}</p>
      <${W.Stepper} id="stepper" value=${a.target} step=${a.target >= 15 ? 5 : 1} min=${1} max=${1000}
        mark=${sn} unit=${W.t("step.aday")}
        onChange=${function (n) { W.act("target", function (s) { s.eng = E.setTarget(s.eng, id, n); }); }} />
      ${sn != null && a.target > sn ? html`<p class="dhikr-above num" data-id="above-sunnah">
        ${W.t("adhkar.above", { sunnah: sn })}
      </p>` : null}
      <div class="dhikr-auto-row" data-id="dhikr-auto">
        <div class="dhikr-auto-copy">
          <span class="dhikr-auto-title">${W.t("adhkar.auto.title")}</span>
          <span class="quiet dhikr-auto-sub">${W.t(a.auto ? "adhkar.auto.on" : "adhkar.auto.off")}</span>
        </div>
        <${SwitchBtn} id="dhikr-auto-switch" on=${!!a.auto}
          onClick=${function () { W.act("auto", function (s) { s.eng = E.setAuto ? E.setAuto(s.eng, id, !a.auto) : s.eng; }); }} />
      </div>
    </div>

    <${W.Btn} kind="main" wide=${true} icon="adhkar" label=${W.t("adhkar.countnow")} id="count-now"
      onClick=${function () { W.U().backRoute = "adhkar/" + id; W.go("count/" + id); }} />

    <div class="dhikr-actions">
      <${W.Btn} kind="soft" icon=${a.resting ? "return" : "rest"}
        label=${W.t(a.resting ? "adhkar.bringback" : "adhkar.rest")} id="rest"
        onClick=${function () {
          W.act("rest", function (s) { s.eng = E.rest(s.eng, id, !a.resting); });
          W.go("adhkar");
        }} />
      <${W.Btn} kind="text" icon="close" label=${W.t("adhkar.remove")} id="remove"
        onClick=${function () {
          W.act("remove", function (s) { s.eng = E.remove(s.eng, id); });
          W.go("adhkar");
          W.toast(W.t("adhkar.removed"), true);
        }} />
    </div>` : html`<div class="dhikr-unadded-actions">
      <${W.Btn} kind="main" wide=${true} icon="add" label=${W.t("adhkar.add.hourly")} id=${"add-" + id}
        onClick=${function () { if (it) W.act("add", function (s) { s.eng = E.add(s.eng, it); }); }} />
      <${W.Btn} kind="soft" wide=${true} icon="adhkar" label=${W.t("adhkar.countnow")} id="count-now"
        onClick=${function () { W.U().backRoute = "adhkar/" + id; W.go("count/" + id); }} />
    </div>`}
  </div>`;
}

W.screen("adhkar", function AdhkarScreen(p) {
  return p.arg ? html`<${DhikrPage} key=${p.arg} id=${p.arg} />` : html`<${AdhkarList} />`;
});
})();
