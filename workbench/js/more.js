/* more.js: More (onboarding questions word for word, My days, and folded Other) and route days. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

function setPref(label, patch) {
  W.act(label, function (s) {
    var prefs = Object.assign({}, s.eng.prefs, patch);
    s.eng = E.rollDay(Object.assign({}, s.eng, { prefs: prefs }), W.now());
  });
}

function MoreHome() {
  var st = W.useApp(), ui = st.ui, eng = E.rollDay(st.eng, W.now());
  var prefs = eng.prefs || W.ANSWER_DEFAULTS;
  var openSt = W.useState(false), open = openSt[0], setOpen = openSt[1];

  var cardSize = prefs.cardSize || "small";
  var sound = prefs.sound || "soft";

  return html`<div class="more-page" data-id="more-page">
    <div class="adhkar-rows">
      <${W.Row} id="more-row-freq" icon="bell"
        title=${W.t("ob.freq.q")} sub=${W.t("freq." + (prefs.freq || "hour"))}
        onClick=${function () { W.go("more/freq"); }} />

      <${W.Row} id="more-row-sleep" icon="bed"
        title=${W.t("ob.sleep.q")}
        sub=${W.timeLabel(prefs.wake || "06:00") + " . " + W.timeLabel(prefs.sleep || "23:00")}
        onClick=${function () { W.go("more/sleep"); }} />

      <${W.Row} id="more-row-look" icon=${cardSize === "full" ? "card-full" : "card-small"}
        title=${W.t("ob.try.pick")}
        sub=${W.t("ob.size." + cardSize) + " . " + W.t("more.theme." + ui.theme)}
        onClick=${function () { W.go("more/look"); }} />

      <${W.Row} id="more-row-sound" icon="sound"
        title=${W.t("more.sound.q")} sub=${W.t("more.sound." + sound)}
        onClick=${function () { W.go("more/sound"); }} />

      <${W.Row} id="more-row-lang" icon="language"
        title=${W.t("ob.lang.q")} sub=${W.t("ob.lang." + ui.lang)}
        onClick=${function () { W.go("more/lang"); }} />

      <${W.Row} id="more-row-size" icon="text-size"
        title=${W.t("more.size.q")} sub=${W.t("more.size." + ui.size)}
        onClick=${function () { W.go("more/size"); }} />

      <${W.Row} id="more-row-days" icon="history"
        title=${W.t("more.days.title")} sub=${W.t("more.days.sub")}
        onClick=${function () { W.go("days"); }} />
    </div>

    <div class="more-other-wrap">
      <button type="button" class=${W.cx("row", "more-other-btn", open && "is-open")}
        data-id="more-other" aria-expanded=${open ? "true" : "false"}
        onClick=${function () { setOpen(!open); }}>
        <span class="row-icon">${W.Icon({ name: "more", size: 28 })}</span>
        <span class="row-main"><span class="row-title">${W.t("more.other")}</span></span>
        <span class="row-end more-other-chev">${W.Icon({ name: "forward", size: 22, className: "row-go" })}</span>
      </button>

      ${open ? html`<div class="adhkar-rows more-other-list" data-id="more-other-list">
        <${W.Row} id="more-row-backup" icon="backup" title=${W.t("more.backup.t")}
          onClick=${function () { W.go("more/backup"); }} />
        <${W.Row} id="more-row-request" icon="add" title=${W.t("more.request.t")}
          onClick=${function () { W.go("more/request"); }} />
        <${W.Row} id="more-row-problem" icon="wrench" title=${W.t("more.problem.t")}
          onClick=${function () { W.go("more/problem"); }} />
        <${W.Row} id="more-row-updates" icon="sparkle" title=${W.t("more.updates.t")}
          onClick=${function () { W.go("more/updates"); }} />
        <${W.Row} id="more-row-about" icon="help" title=${W.t("more.about.t")}
          onClick=${function () { W.go("more/about"); }} />
      </div>` : null}
    </div>
  </div>`;
}

function SubShell(p) {
  return html`<div class="more-sub" data-id=${"more-" + p.name}>
    <div class="sub-bar">
      <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="more-back"
        onClick=${function () { W.go("more"); }} />
    </div>
    <h1 class="title more-sub-title">${p.title}</h1>
    ${p.sub ? html`<p class="quiet more-sub-p">${p.sub}</p>` : null}
    ${p.children}
  </div>`;
}

function MoreSub(p) {
  var row = p.row, st = W.useApp(), ui = st.ui, eng = E.rollDay(st.eng, W.now());
  var prefs = eng.prefs || W.ANSWER_DEFAULTS;
  var txtSt = W.useState(""), txt = txtSt[0], setTxt = txtSt[1];

  if (row === "freq") {
    return html`<${SubShell} name="freq" title=${W.t("ob.freq.q")} sub=${W.t("ob.freq.sub")}>
      <${W.Choice} id="more-freq" value=${prefs.freq || "hour"}
        onChange=${function (v) { setPref("freq", { freq: v }); }}
        options=${["few", "hour", "often"].map(function (k) { return { value: k, label: W.t("freq." + k) }; })} />
    <//>`;
  }

  if (row === "sleep") {
    return html`<${SubShell} name="sleep" title=${W.t("ob.sleep.q")} sub=${W.t("ob.sleep.sub")}>
      <${W.TimeStep} id="more-wake" label=${W.t("ob.wake")} value=${prefs.wake || "06:00"}
        onChange=${function (v) { setPref("wake", { wake: v }); }} />
      <${W.TimeStep} id="more-sleeptime" label=${W.t("ob.sleep")} value=${prefs.sleep || "23:00"}
        onChange=${function (v) { setPref("sleep", { sleep: v }); }} />
    <//>`;
  }

  if (row === "look") {
    var cs = prefs.cardSize || "small";
    return html`<${SubShell} name="look" title=${W.t("ob.try.pick")}>
      <${W.Choice} id="more-cardsize" value=${cs}
        onChange=${function (v) { setPref("cardSize", { cardSize: v }); }}
        options=${[
          { value: "small", label: W.t("ob.size.small"), sub: W.t("ob.size.small.sub"), icon: "card-small" },
          { value: "full", label: W.t("ob.size.full"), sub: W.t("ob.size.full.sub"), icon: "card-full" }
        ]} />
      <section class="today-sec">
        <h2 class="today-sec-title quiet">${W.t("more.theme.q")}</h2>
        <${W.Choice} id="more-theme" value=${ui.theme}
          onChange=${function (v) { W.setTheme(v); }}
          options=${[
            { value: "light", label: W.t("more.theme.light"), icon: "sun" },
            { value: "dark", label: W.t("more.theme.dark"), icon: "moon" }
          ]} />
      </section>
    <//>`;
  }

  if (row === "sound") {
    return html`<${SubShell} name="sound" title=${W.t("more.sound.q")}>
      <${W.Choice} id="more-sound" value=${prefs.sound || "soft"}
        onChange=${function (v) { setPref("sound", { sound: v }); }}
        options=${["soft", "vibrate", "silent"].map(function (k) {
          return { value: k, label: W.t("more.sound." + k), icon: "sound" };
        })} />
    <//>`;
  }

  if (row === "lang") {
    return html`<${SubShell} name="lang" title=${W.t("ob.lang.q")}>
      <${W.Choice} id="more-lang" value=${ui.lang}
        onChange=${function (v) { W.setLang(v); }}
        options=${[
          { value: "ar", label: W.t("ob.lang.ar"), icon: "language" },
          { value: "en", label: W.t("ob.lang.en"), icon: "language" }
        ]} />
    <//>`;
  }

  if (row === "size") {
    var sample = W.LIB[0];
    return html`<${SubShell} name="size" title=${W.t("more.size.q")}>
      <div class="panel">
        <p class="dhikr" dir="rtl" lang="ar">${sample ? sample.ar : ""}</p>
      </div>
      <${W.Choice} id="more-size" value=${ui.size}
        onChange=${function (v) { W.setSize(Number(v)); }}
        options=${[1, 2, 3].map(function (n) { return { value: n, label: W.t("more.size." + n), icon: "text-size" }; })} />
    <//>`;
  }

  if (row === "backup") {
    return html`<${SubShell} name="backup" title=${W.t("more.backup.t")} sub=${W.t("more.backup.p")}>
      <${W.Btn} kind="main" wide=${true} icon="backup" label=${W.t("more.backup.save")} id="backup-save"
        onClick=${function () { W.toast(W.t("more.backup.done")); }} />
      <${W.Btn} kind="soft" wide=${true} icon="return" label=${W.t("more.backup.restore")} id="backup-restore"
        onClick=${function () { W.toast(W.t("more.backup.done")); }} />
    <//>`;
  }

  if (row === "request" || row === "problem") {
    var pfx = "more." + row;
    return html`<${SubShell} name=${row} title=${W.t(pfx + ".t")} sub=${W.t(pfx + ".p")}>
      <textarea class="more-ta" rows="4" data-id=${row + "-input"} value=${txt}
        onInput=${function (e) { setTxt(e.target.value); }}></textarea>
      <${W.Btn} kind="main" wide=${true} icon="check" label=${W.t("more.send")} id=${row + "-send"}
        onClick=${function () { setTxt(""); W.toast(W.t("more.sent")); W.go("more"); }} />
    <//>`;
  }

  if (row === "updates") {
    return html`<${SubShell} name="updates" title=${W.t("more.updates.t")} sub=${W.t("more.updates.p")}>
      <${W.Btn} kind="main" wide=${true} icon="sparkle" label=${W.t("more.updates.btn")} id="updates-check"
        onClick=${function () { W.toast(W.t("more.updates.ok")); }} />
    <//>`;
  }

  return html`<${SubShell} name="about" title=${W.t("more.about.t")} sub=${W.t("more.about.p")}>
    <${W.Ornament} />
  <//>`;
}

function keyShift(key, delta) {
  var p = key.split("-");
  var d = new Date(+p[0], +p[1] - 1, +p[2] + delta);
  var two = function (n) { return (n < 10 ? "0" : "") + n; };
  return d.getFullYear() + "-" + two(d.getMonth() + 1) + "-" + two(d.getDate());
}

function dayScore(eng, key) {
  if (eng.day && eng.day.key === key) {
    var act = E.active(eng);
    if (!act.length) return { ratio: 0, count: 0 };
    var goal = 0, got = 0, totalSaid = 0;
    act.forEach(function (a) {
      var d = (eng.day.done && eng.day.done[a.id]) || 0;
      var ex = (eng.day.extra && eng.day.extra[a.id]) || 0;
      goal += a.target;
      got += Math.min(a.target, d);
      totalSaid += d + ex;
    });
    return { ratio: goal > 0 ? got / goal : 0, count: totalSaid };
  }
  var filed = (eng.week && eng.week.days || []).filter(function (x) { return x.key === key; })[0];
  if (!filed || !filed.finished) return { ratio: 0, count: 0 };
  var ids = Object.keys(filed.finished);
  if (!ids.length) return { ratio: 0, count: 0 };
  var fin = 0, est = 0;
  ids.forEach(function (id) {
    if (filed.finished[id]) {
      fin++;
      var a = (eng.adhkar || []).filter(function (x) { return x.id === id; })[0];
      est += a ? a.target : 10;
    }
  });
  return { ratio: fin / ids.length, count: est };
}

function BarStrip(p) {
  var total = 0;
  var bars = [];
  for (var i = p.count - 1; i >= 0; i--) {
    var k = keyShift(p.todayKey, -i);
    var sc = dayScore(p.eng, k);
    total += sc.count;
    bars.push({ key: k, ratio: sc.ratio, dayNum: Number(k.split("-")[2]) });
  }
  return html`<section class="panel days-card" data-id=${p.id}>
    <div class="days-head">
      <h2 class="title days-sec-title">${p.title}</h2>
      <span class="quiet num">${W.t("days.total", { n: total })}</span>
    </div>
    <div class=${W.cx("days-bars", p.count > 10 && "is-dense")}>
      ${bars.map(function (b) {
        var h = b.ratio > 0 ? Math.max(16, Math.round(b.ratio * 100)) : 5;
        return html`<div key=${b.key} class="days-col" data-day=${b.key}>
          <div class="days-track">
            <span class=${W.cx("days-bar", b.ratio > 0 && "is-lit")} style=${{ height: h + "%" }}></span>
          </div>
          ${p.count <= 7 ? html`<span class="days-lbl quiet num">${b.dayNum}</span>` : null}
        </div>`;
      })}
    </div>
  </section>`;
}

function DaysScreen() {
  var eng = E.rollDay(W.useApp().eng, W.now());
  var todayKey = E.dayKey(W.now(), eng.prefs || W.ANSWER_DEFAULTS);

  return html`<div class="more-page" data-id="days-page">
    <div class="sub-bar">
      <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="days-back"
        onClick=${function () { W.go("more"); }} />
      <h1 class="title">${W.t("more.days.title")}</h1>
      <span class="sub-bar-gap"></span>
    </div>

    <${BarStrip} id="days-7" title=${W.t("days.week")} count=${7} eng=${eng} todayKey=${todayKey} />
    <${BarStrip} id="days-30" title=${W.t("days.month")} count=${30} eng=${eng} todayKey=${todayKey} />
    <p class="today-hint quiet">${W.t("days.private")}</p>
  </div>`;
}

W.screen("more", function MoreScreen(p) {
  return p.arg ? html`<${MoreSub} key=${p.arg} row=${p.arg} />` : html`<${MoreHome} />`;
});
W.screen("days", DaysScreen);
})();
