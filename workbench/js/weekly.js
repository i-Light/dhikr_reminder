/* weekly.js: the once-a-week review card. Up, down (neutral, no blame), suggestions, and heavy adhkar. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

function sunnahOf(eng, id, it) {
  if (it && it.sunnah !== undefined) return it.sunnah;
  return eng.sunnah && eng.sunnah[id] != null ? eng.sunnah[id] : null;
}

function WeeklyScreen() {
  var st = W.useApp(), eng = E.rollDay(st.eng, W.now()), en = st.ui.lang === "en";
  var rv = eng.review;

  var refSt = W.useState({}), refused = refSt[0], setRefused = refSt[1];
  var accSt = W.useState({}), accepted = accSt[0], setAccepted = accSt[1];
  var hvySt = W.useState({}), heavyChoice = hvySt[0], setHeavy = hvySt[1];

  if (!rv) {
    return html`<div class="weekly-page" data-id="weekly-page">
      <div class="sub-bar">
        <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="weekly-back"
          onClick=${function () { W.go("today"); }} />
      </div>
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
  var hasUp = changes.some(function (c) { return c.to > c.from; }) || suggest.length > 0;
  var praise = hasUp;

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
    <div class="sub-bar">
      <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="weekly-back"
        onClick=${function () { W.go("today"); }} />
    </div>

    <div class="weekly-head">
      <${W.Ornament} />
      <h1 class="title weekly-title" data-id="weekly-title">${W.t(praise ? "weekly.up.title" : "weekly.neutral.title")}</h1>
      <p class="quiet weekly-sub">${W.t(praise ? "weekly.up.sub" : "weekly.neutral.sub")}</p>
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
