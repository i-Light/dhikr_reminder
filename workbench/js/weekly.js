/* weekly.js: the once-a-week review check-up with motivating stats, warm words, glow effects, and gentle target tuning. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

function sunnahOf(eng, id, it) {
  if (it && it.sunnah !== undefined) return it.sunnah;
  return eng.sunnah && eng.sunnah[id] != null ? eng.sunnah[id] : null;
}

function computeWeekStats(eng) {
  var days = ((eng.week && eng.week.days) || []).slice(-7);
  var hist = eng.history || {};
  var said = 0, activeDays = 0, goalsMet = 0;
  var dots = [];
  days.forEach(function (d) {
    var h = hist[d.key];
    var daySaid = h ? (h.said || 0) : 0;
    var finCount = 0;
    Object.keys(d.finished || {}).forEach(function (id) {
      if (d.finished[id]) {
        finCount++;
        if (!h) {
          var a = (eng.adhkar || []).filter(function (x) { return x.id === id; })[0];
          daySaid += a ? a.target : 10;
        }
      }
    });
    said += daySaid;
    goalsMet += finCount;
    var lit = daySaid > 0 || finCount > 0;
    if (lit) activeDays++;
    dots.push({ key: d.key, lit: lit, complete: h ? !!h.complete : false });
  });
  while (dots.length < 7) dots.unshift({ key: "p" + dots.length, lit: false, complete: false });
  return { said: said, activeDays: activeDays, goalsMet: goalsMet, dots: dots };
}

function computeWeeklyTip(eng, tone) {
  var days = ((eng.week && eng.week.days) || []).slice(-7);
  var hist = eng.history || {};
  var mp = (eng.prefs && eng.prefs.moments) || {};
  var order = ["sleep", "evening", "morning", "waking"];
  var missedMost = null, worstMissed = 0;
  if (days.length) {
    order.forEach(function (k) {
      if (mp[k] && mp[k].on === false) return;
      var doneDays = 0;
      days.forEach(function (d) {
        var h = hist[d.key];
        if (h && h.moments && h.moments[k]) doneDays++;
      });
      var missed = days.length - doneDays;
      if (missed >= 4 && missed > worstMissed) {
        worstMissed = missed;
        missedMost = k;
      }
    });
  }
  if (missedMost === "sleep" || (!missedMost && tone === "down")) {
    return {
      icon: "bed",
      text: W.t("weekly.tip.sleep"),
      btn: W.t("weekly.tip.sleep.btn"),
      action: function () { W.U().backRoute = "weekly"; W.go("count/d5962298b6d"); }
    };
  }
  if (missedMost) {
    var mName = W.t("moment." + missedMost);
    return {
      icon: missedMost === "evening" ? "moon" : missedMost === "morning" ? "sun" : "sunrise",
      text: W.t("weekly.tip.moment", { name: mName }),
      btn: W.t("weekly.tip.moment.btn", { name: mName }),
      action: function () { W.U().adhkarView = missedMost; W.U().backRoute = "weekly"; W.go("adhkar"); }
    };
  }
  return {
    icon: "bed",
    text: W.t("weekly.tip.steady"),
    btn: W.t("weekly.tip.steady.btn"),
    action: function () { W.U().backRoute = "weekly"; W.go("count/d5962298b6d"); }
  };
}

function WeeklyScreen() {
  var st = W.useApp(), eng = E.rollDay(st.eng, W.now()), en = st.ui.lang === "en";
  var rv = eng.review;

  var refSt = W.useState({}), refused = refSt[0], setRefused = refSt[1];
  var accSt = W.useState({}), accepted = accSt[0], setAccepted = accSt[1];
  var hvySt = W.useState({}), heavyChoice = hvySt[0], setHeavy = hvySt[1];

  if (!rv) {
    return html`<div class="weekly-page" data-id="weekly-page">
      <div class="panel now-card">
        <p class="title now-text">${W.t("weekly.none")}</p>
        <${W.Btn} kind="main" wide=${true} label=${W.t("btn.back")} id="weekly-done"
          onClick=${function () { W.go("today"); }} />
      </div>
    </div>`;
  }

  var changes = rv.changes || [];
  var heavy = rv.heavy || [];
  var suggest = rv.suggest || [];
  var upCount = changes.filter(function (c) { return c.to > c.from; }).length + suggest.length;
  var downCount = changes.filter(function (c) { return c.to < c.from; }).length;
  var tone = downCount > 0 && downCount >= upCount ? "down" : upCount > 0 ? "up" : "steady";
  var stats = computeWeekStats(eng);
  var tip = computeWeeklyTip(eng, tone);

  var titleKey = tone === "up" ? "weekly.up.title" : tone === "down" ? "weekly.down.title" : "weekly.neutral.title";
  var subKey = tone === "up" ? "weekly.up.sub" : tone === "down" ? "weekly.down.sub" : "weekly.neutral.sub";
  var quoteKey = "weekly.quote." + tone;

  function toggleRefuse(id) {
    var nx = Object.assign({}, refused);
    nx[id] = !nx[id];
    setRefused(nx);
  }
  function toggleAccept(id) {
    var nx = Object.assign({}, accepted);
    nx[id] = !nx[id];
    setAccepted(nx);
  }
  function pickHeavy(id, val) {
    var nx = Object.assign({}, heavyChoice);
    nx[id] = val;
    setHeavy(nx);
  }
  function submit() {
    var refuseList = Object.keys(refused).filter(function (k) { return refused[k]; });
    var acceptList = Object.keys(accepted).filter(function (k) { return accepted[k]; });
    var heavyMap = {};
    heavy.forEach(function (id) { heavyMap[id] = heavyChoice[id] || "keep"; });
    W.act("weekly", function (s) {
      s.eng = E.rollDay(s.eng, W.now());
      s.eng = E.answerReview(s.eng, { refuse: refuseList, heavy: heavyMap, accept: acceptList });
    });
    W.go("today");
  }

  return html`<div class="weekly-page" data-id="weekly-page">
    <div class="panel weekly-hero m-day-done" data-id="weekly-hero">
      <div class="weekly-glow-mark m-day-mark">
        <${W.Ornament} bare=${true} size=${48} />
      </div>
      <h1 class="title weekly-title m-day-text" data-id="weekly-title">${W.t(titleKey)}</h1>
      <p class="quiet weekly-sub">${W.t(subKey)}</p>

      <div class="stats-grid weekly-stats" data-id="weekly-stats">
        <div class="stat-box">
          <span class="stat-val num m-count">${stats.said}</span>
          <span class="stat-lbl quiet">${W.t("weekly.stats.said")}</span>
        </div>
        <div class="stat-box">
          <span class="stat-val num m-count">${stats.activeDays} / 7</span>
          <span class="stat-lbl quiet">${W.t("weekly.stats.days")}</span>
        </div>
        <div class="stat-box">
          <span class="stat-val num m-count">${stats.goalsMet}</span>
          <span class="stat-lbl quiet">${W.t("weekly.stats.goals")}</span>
        </div>
      </div>

      <div class="weekly-dots" aria-hidden="true">
        ${stats.dots.map(function (d, idx) {
          return html`<span key=${d.key + idx} class=${W.cx("weekly-dot", d.lit && "is-lit", d.complete && "is-complete")}></span>`;
        })}
      </div>

      <p class="weekly-motivate" data-id="weekly-motivate">
        ${W.Icon({ name: "sparkle", size: 20 })}
        <span>${W.t(quoteKey)}</span>
      </p>

      ${tip ? html`<div class="weekly-tip" data-id="weekly-tip">
        <div class="weekly-tip-head">
          ${W.Icon({ name: tip.icon, size: 18 })}
          <span>${W.t("weekly.tip.badge")}</span>
        </div>
        <p class="weekly-tip-text">${tip.text}</p>
        <button type="button" class="weekly-tip-btn" data-id="weekly-tip-btn" onClick=${tip.action}>
          <span>${tip.btn}</span>
          ${W.Icon({ name: "forward", size: 16 })}
        </button>
      </div>` : null}
    </div>

    ${changes.length ? html`<div class="adhkar-rows" data-id="weekly-changes">
      ${changes.map(function (c) {
        var it = W.lib(c.id), sn = sunnahOf(eng, c.id, it), isRef = !!refused[c.id];
        var line = sn != null
          ? W.t("weekly.change.sunnah", { from: c.from, to: c.to, sunnah: sn })
          : W.t("weekly.change.plain", { from: c.from, to: c.to });
        return html`<div key=${c.id} class=${W.cx("panel", "weekly-item", isRef && "is-refused")}
          data-id=${"weekly-change-" + c.id}>
          <p class="dhikr weekly-dhikr" dir="rtl" lang="ar">${it ? it.ar : c.id}</p>
          ${en && it && it.translit ? html`<p class="card-translit" dir="ltr" lang="en">${it.translit}</p>` : null}
          <p class="weekly-line num">${line}</p>
          <div class="weekly-item-foot">
            <${W.Btn} kind=${isRef ? "soft" : "text"} icon=${isRef ? "done" : "undo"}
              label=${W.t(isRef ? "weekly.kept" : "weekly.refuse", { n: c.from })}
              id=${"weekly-refuse-" + c.id}
              onClick=${function () { toggleRefuse(c.id); }} />
          </div>
        </div>`;
      })}
    </div>` : null}

    ${suggest.length ? html`<div class="adhkar-rows" data-id="weekly-suggestions">
      ${suggest.map(function (g) {
        var it = W.lib(g.id), isAcc = !!accepted[g.id];
        return html`<div key=${g.id} class="panel weekly-item" data-id=${"weekly-suggest-" + g.id}>
          <p class="dhikr weekly-dhikr" dir="rtl" lang="ar">${it ? it.ar : g.id}</p>
          ${en && it && it.translit ? html`<p class="card-translit" dir="ltr" lang="en">${it.translit}</p>` : null}
          <p class="weekly-line num">${W.t("weekly.suggest", { to: g.to })}</p>
          <div class="weekly-item-foot">
            <${W.Btn} kind=${isAcc ? "soft" : "text"} icon=${isAcc ? "done" : "add"}
              label=${W.t("weekly.suggest.accept", { to: g.to })}
              id=${"weekly-accept-" + g.id}
              onClick=${function () { toggleAccept(g.id); }} />
          </div>
        </div>`;
      })}
    </div>` : null}

    ${heavy.map(function (hId, i) {
      var it = W.lib(hId);
      return html`<div key=${hId} class="panel weekly-heavy" data-id=${"weekly-heavy-" + hId}>
        <h2 class="title weekly-heavy-title">${W.t("weekly.heavy.title")}</h2>
        <p class="dhikr weekly-dhikr" dir="rtl" lang="ar">${it ? it.ar : hId}</p>
        ${en && it && it.translit ? html`<p class="card-translit" dir="ltr" lang="en">${it.translit}</p>` : null}
        <${W.Choice} id=${i === 0 ? "heavy" : "heavy" + i}
          value=${heavyChoice[hId] || "keep"}
          onChange=${function (v) { pickHeavy(hId, v); }}
          options=${[
            { value: "keep", label: W.t("weekly.heavy.keep"), icon: "check" },
            { value: "lighter", label: W.t("weekly.heavy.lighter"), icon: "minus" },
            { value: "rest", label: W.t("weekly.heavy.rest"), icon: "rest" }
          ]} />
      </div>`;
    })}

    <${W.Btn} kind="main" wide=${true} icon="check" label=${W.t("weekly.done")}
      id="weekly-done" onClick=${submit} />
  </div>`;
}

W.screen("weekly", WeeklyScreen);
})();
