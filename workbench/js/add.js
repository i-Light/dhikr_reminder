/* add.js: adding a dhikr without asking for a number. Search, six suggestions, and six group tiles. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

var G_ICONS = {
  morning: "sun", evening: "moon", sleep: "bed",
  afterPrayer: "adhkar", tasabih: "sparkle", duas: "today"
};

function norm(s) {
  return String(s || "").toLowerCase()
    .replace(/[\u064b-\u065f\u0670\u06d6-\u06ed]/g, "")
    .replace(/[\u0622\u0623\u0625\u0671]/g, "\u0627")
    .replace(/\u0649/g, "\u064a")
    .replace(/\u0629/g, "\u0647");
}

function haveMap(eng) {
  var m = {};
  (eng.adhkar || []).forEach(function (a) { m[a.id] = true; });
  return m;
}

function LibRow(p) {
  var it = p.it, added = p.added, en = W.U().lang === "en";
  var sub = it.sunnah === 1 ? W.t("add.once") : it.sunnah > 1 ? W.t("step.mark", { n: it.sunnah }) : null;
  return html`<div class=${W.cx("row", "lib-row", added && "is-done")}
    data-id=${"lib-row-" + it.id} data-suggest=${p.suggest ? "1" : null}>
    <span class="row-main">
      <span class="row-title is-dhikr" dir="rtl" lang="ar">${it.ar}</span>
      ${en && it.translit ? html`<span class="row-sub" dir="ltr" lang="en">${it.translit}</span>` : null}
      ${sub ? html`<span class="row-sub num">${sub}</span>` : null}
    </span>
    <span class="row-end">
      <${W.Btn} kind=${added ? "text" : "soft"} icon=${added ? "done" : "add"}
        label=${W.t(added ? "add.added" : "btn.add")} id=${"add-" + it.id} disabled=${added}
        onClick=${function () { W.act("add", function (s) { s.eng = E.add(s.eng, it); }); }} />
    </span>
  </div>`;
}

function AddHome() {
  var eng = E.rollDay(W.useApp().eng, W.now());
  var have = haveMap(eng);
  var qSt = W.useState(""), q = qSt[0], setQ = qSt[1];

  var sugSt = W.useState(function () {
    var initHave = haveMap(eng);
    var pool = W.LIB.filter(function (x) { return !initHave[x.id]; });
    pool.sort(function (a, b) {
      var sa = a.starter == null ? 99 : a.starter, sb = b.starter == null ? 99 : b.starter;
      return sa !== sb ? sa - sb : 0;
    });
    return pool.slice(0, 6).map(function (x) { return x.id; });
  });
  var sugIds = sugSt[0];

  var nq = norm(q).trim();
  var hits = nq ? W.LIB.filter(function (it) {
    return norm(it.ar).indexOf(nq) >= 0 || norm(it.translit).indexOf(nq) >= 0 || norm(it.en).indexOf(nq) >= 0;
  }) : [];

  return html`<div class="add-page" data-id="add-page">
    <div class="sub-bar">
      <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="add-back"
        onClick=${function () { W.go((eng.adhkar && eng.adhkar.length) ? "adhkar" : "today"); }} />
      <h1 class="title">${W.t("add.title")}</h1>
      <span class="sub-bar-gap"></span>
    </div>

    <label class="search-box">
      <span class="search-ic">${W.Icon({ name: "search", size: 22 })}</span>
      <input type="search" class="search-in" data-id="add-search" value=${q}
        placeholder=${W.t("add.search")}
        onInput=${function (e) { setQ(e.target.value); }} />
      ${q ? html`<button type="button" class="search-clear" data-id="add-search-clear"
        aria-label=${W.t("btn.close")} onClick=${function () { setQ(""); }}>
        ${W.Icon({ name: "close", size: 20 })}
      </button>` : null}
    </label>

    ${nq ? html`<div class="adhkar-rows" data-id="add-results">
      ${hits.length ? hits.map(function (it) {
        return html`<${LibRow} key=${it.id} it=${it} added=${!!have[it.id]} />`;
      }) : html`<p class="add-empty quiet" data-id="add-empty">${W.t("add.empty")}</p>`}
    </div>` : html`<${W.R.Fragment}>
      ${sugIds.length ? html`<section class="today-sec" data-id="add-suggested">
        <h2 class="today-sec-title quiet">${W.t("add.suggested")}</h2>
        <div class="adhkar-rows">
          ${sugIds.map(function (id) {
            var it = W.lib(id);
            return it ? html`<${LibRow} key=${id} it=${it} added=${!!have[id]} suggest=${true} />` : null;
          })}
        </div>
      </section>` : null}

      <section class="today-sec" data-id="add-groups">
        <h2 class="today-sec-title quiet">${W.t("add.groups")}</h2>
        <div class="group-grid">
          ${W.GROUPS.map(function (g) {
            var cnt = W.LIB.filter(function (x) { return (x.groups || []).indexOf(g.id) >= 0; }).length;
            return html`<button type="button" key=${g.id} class="group-tile" data-id=${"group-" + g.id}
              onClick=${function () { W.go("add/" + g.id); }}>
              <span class="group-tile-ic">${W.Icon({ name: G_ICONS[g.id] || "adhkar", size: 28 })}</span>
              <span class="group-tile-name">${W.t(g.label)}</span>
              <span class="group-tile-sub quiet num">${W.t("add.group.count", { n: cnt })}</span>
            </button>`;
          })}
        </div>
      </section>
    <//>`}
  </div>`;
}

function AddGroup(p) {
  var group = p.group, eng = E.rollDay(W.useApp().eng, W.now()), have = haveMap(eng);
  var gObj = W.GROUPS.filter(function (g) { return g.id === group; })[0];
  var items = W.LIB.filter(function (x) { return (x.groups || []).indexOf(group) >= 0; });

  return html`<div class="add-page" data-id="add-group">
    <div class="sub-bar">
      <${W.Btn} kind="text" icon="back" label=${W.t("btn.back")} id="add-back"
        onClick=${function () { W.go("add"); }} />
      <h1 class="title">${gObj ? W.t(gObj.label) : group}</h1>
      <span class="sub-bar-gap"></span>
    </div>
    <div class="adhkar-rows">
      ${items.map(function (it) {
        return html`<${LibRow} key=${it.id} it=${it} added=${!!have[it.id]} />`;
      })}
    </div>
  </div>`;
}

W.screen("add", function AddScreen(p) {
  return p.arg ? html`<${AddGroup} key=${p.arg} group=${p.arg} />` : html`<${AddHome} />`;
});
})();
