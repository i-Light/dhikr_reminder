/* adhkar.js: My adhkar (add button first, active list, daily moments row, resting last) and adhkar/<id>. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

function sunnahOf(eng, id, it) {
  if (it && it.sunnah !== undefined) return it.sunnah;
  return eng.sunnah && eng.sunnah[id] != null ? eng.sunnah[id] : null;
}

function subFor(a, sn) {
  return sn != null
    ? W.t("adhkar.sub.sunnah", { target: a.target, sunnah: sn })
    : W.t("adhkar.sub.plain", { target: a.target });
}

function AdhkarList() {
  var eng = E.rollDay(W.useApp().eng, W.now());
  var all = eng.adhkar || [];
  var active = all.filter(function (a) { return !a.resting; });
  var resting = all.filter(function (a) { return a.resting; });

  return html`<div class="adhkar" data-id="adhkar">
    <${W.Btn} kind="main" wide=${true} icon="add" label=${W.t("today.add")} id="add-dhikr"
      onClick=${function () { W.go("add"); }} />

    ${active.length ? html`<div class="adhkar-rows" data-id="adhkar-list">
      ${active.map(function (a) {
        var it = W.lib(a.id), sn = sunnahOf(eng, a.id, it);
        return html`<${W.Row} key=${a.id} id=${"adhkar-row-" + a.id} dhikr=${true}
          title=${it ? it.ar : a.id} sub=${subFor(a, sn)}
          onClick=${function () { W.go("adhkar/" + a.id); }} />`;
      })}
    </div>` : null}

    <${W.Row} id="adhkar-moments" icon="sun"
      title=${W.t("adhkar.moments.title")} sub=${W.t("adhkar.moments.sub")}
      onClick=${function () { W.go("moments"); }} />

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
  </div>`;
}

function DhikrPage(p) {
  var id = p.id, st = W.useApp(), eng = E.rollDay(st.eng, W.now()), en = st.ui.lang === "en";
  var it = W.lib(id);
  var a = (eng.adhkar || []).filter(function (x) { return x.id === id; })[0];
  var sn = sunnahOf(eng, id, it);
  var note = en && it && it.en ? it.en : (it && it.source ? it.source : null);

  return html`<div class="dhikr-page" data-id="dhikr-page">
    <div class="sub-bar">
      <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="dhikr-back"
        onClick=${function () { W.go("adhkar"); }} />
    </div>

    <div class="panel dhikr-card">
      <${W.Ornament} />
      <${W.DhikrText} id=${id} dataId="dhikr-text" />
      ${note ? html`<p class="dhikr-note quiet" data-id="dhikr-note">${note}</p>` : null}
    </div>

    ${a ? html`<div class="panel dhikr-amount">
      <p class="dhikr-amount-label quiet">${W.t("adhkar.todayamount")}</p>
      <${W.Stepper} id="stepper" value=${a.target} step=${a.target >= 15 ? 5 : 1} min=${1} max=${1000}
        mark=${sn} unit=${W.t("step.aday")}
        onChange=${function (n) { W.act("target", function (s) { s.eng = E.setTarget(s.eng, id, n); }); }} />
      ${sn != null && a.target > sn ? html`<p class="dhikr-above num" data-id="above-sunnah">
        ${W.t("adhkar.above", { sunnah: sn })}
      </p>` : null}
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
    </div>` : html`<${W.Btn} kind="main" wide=${true} icon="add" label=${W.t("btn.add")} id=${"add-" + id}
      onClick=${function () { if (it) W.act("add", function (s) { s.eng = E.add(s.eng, it); }); }} />`}
  </div>`;
}

W.screen("adhkar", function AdhkarScreen(p) {
  return p.arg ? html`<${DhikrPage} key=${p.arg} id=${p.arg} />` : html`<${AdhkarList} />`;
});
})();
