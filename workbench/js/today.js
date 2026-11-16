/* today.js: the Today place (the Now card, today's adhkar, the four moments strip, pause) and count/<id>. */
(function () {
"use strict";
var W = window.W, html = W.html, E = W.E;

var MOMENTS = ["waking", "morning", "evening", "sleep"];
var M_ICONS = { waking: "sunrise", morning: "sun", evening: "moon", sleep: "bed" };

function openCount(id) {
  if (!id) return;
  W.U().backRoute = "today";
  W.go("count/" + id);
}

function Today() {
  var st = W.useApp(), ui = st.ui, nowTs = W.now();
  var eng = E.rollDay(st.eng, nowTs);
  var now = E.nowCard(eng, nowTs, { permissionMissing: !!ui.permissionMissing });
  var away = E.awayDays(eng) >= 3;
  var paused = (eng.pausedUntil || 0) > nowTs;

  /* play the day-complete celebration once per day */
  var celRef = W.useRef(false);
  var uncelebrated = now.kind === "complete" && !(st.eng.day && st.eng.day.key === eng.day.key && st.eng.day.celebrated);
  if (uncelebrated) celRef.current = true;
  W.useEffect(function () {
    if (now.kind === "complete") {
      if (!st.eng.day || st.eng.day.key !== eng.day.key) W.S.state.eng = eng;
      if (!W.S.state.eng.day.celebrated) {
        W.S.state.eng.day.celebrated = true;
        W.save();
      }
    }
  }, [now.kind, eng.day.key]);

  var act = E.active(eng);
  var openRows = act.filter(function (a) { return E.left(eng, a.id) > 0; });
  var doneRows = act.filter(function (a) { return E.left(eng, a.id) === 0; });
  var rows = openRows.concat(doneRows);
  var ms = E.momentState(eng, nowTs);
  var firstDays = now.kind !== "empty" && (!eng.week || !eng.week.days || eng.week.days.length < 3);

  function renderNow() {
    if (now.kind === "fix") {
      return html`<p class="now-text title">${W.t("today.fix.text")}</p>
        <${W.Btn} kind="main" wide=${true} icon="bell" label=${W.t("today.fix.btn")} id="now-button"
          onClick=${function () { W.U().permissionMissing = false; W.toast(W.t("today.fix.done")); }} />`;
    }
    if (now.kind === "weekly") {
      return html`<p class="now-text title">${W.t("today.weekly.text")}</p>
        <${W.Btn} kind="main" wide=${true} icon="sparkle" label=${W.t("today.weekly.btn")} id="now-button"
          onClick=${function () { W.go("weekly"); }} />`;
    }
    if (now.kind === "moment") {
      var mName = W.t("moment." + now.key);
      return html`<p class="now-text title">${W.t(now.running ? "today.moment.run" : "today.moment.wait", { name: mName })}</p>
        <${W.Btn} kind="main" wide=${true} icon=${M_ICONS[now.key] || "sun"}
          label=${W.t(now.running ? "btn.continue" : "btn.start")} id="now-button"
          onClick=${function () { W.U().backRoute = "today"; W.go("session/" + now.key); }} />`;
    }
    if (now.kind === "continue") {
      var cIt = W.lib(now.id);
      return html`<p class="now-text title">${W.t("today.continue.text")}</p>
        ${cIt ? html`<p class="now-dhikr dhikr" dir="rtl" lang="ar">${cIt.ar}</p>` : null}
        <${W.Btn} kind="main" wide=${true} icon="play" label=${W.t("btn.continue")} id="now-button"
          onClick=${function () { openCount(now.id); }} />`;
    }
    if (now.kind === "empty") {
      return html`<p class="now-text title">${W.t("today.empty.text")}</p>
        <${W.Btn} kind="main" wide=${true} icon="add" label=${W.t("today.add")} id="now-button"
          onClick=${function () { W.go("add"); }} />`;
    }
    if (now.kind === "say") {
      var subLine = paused
        ? W.t("today.paused.until", { time: W.timeLabel(W.clock(eng.pausedUntil)) })
        : now.nextAt ? W.t("today.next", { time: W.timeLabel(W.clock(now.nextAt)) }) : null;
      return html`<p class="now-text title">${W.t("today.say.text")}</p>
        <${W.Btn} kind="main" wide=${true} icon="adhkar" label=${W.t("today.say.btn")} id="now-button"
          onClick=${function () { openCount(now.id); }} />
        ${subLine ? html`<p class="now-sub quiet num" data-id="now-next">${subLine}</p>` : null}`;
    }
    var pickExtra = act.filter(function (a) { return a.id !== eng.day.lastShown; })[0] || act[0];
    return html`<div class="now-done-mark m-day-mark"><${W.Ornament} bare=${true} size=${44} /></div>
      <p class="now-text title m-day-text">${W.t("today.complete.title")}</p>
      <p class="now-sub quiet">${W.t("today.complete.sub")}</p>
      <${W.Btn} kind="soft" wide=${true} icon="add" label=${W.t("today.saymore")} id="now-button"
        onClick=${function () { if (pickExtra) openCount(pickExtra.id); }} />`;
  }

  return html`<div class="today" data-id="today">
    ${away ? html`<div class="today-welcome" data-id="welcome-back">
      ${W.Icon({ name: "sparkle", size: 22 })}<span>${W.t("today.welcome")}</span>
    </div>` : null}

    <section class=${W.cx("panel", "now-card", now.kind === "complete" && celRef.current && "m-day-done")}
      data-id="now-card" data-kind=${now.kind}>
      ${renderNow()}
    </section>

    ${firstDays ? html`<p class="today-hint quiet" data-id="today-hint">${W.t("today.hint")}</p>` : null}

    <section class="today-sec" data-id="moments-sec">
      <h2 class="today-sec-title quiet">${W.t("today.moments")}</h2>
      <div class="moments-strip" data-id="moments-strip">
        ${MOMENTS.map(function (k) {
          var state = ms[k];
          return html`<button type="button" key=${k}
            class=${W.cx("moment-chip", "is-" + state)}
            data-id=${"moment-" + k} data-state=${state}
            onClick=${function () {
              if (state === "off") W.go("moments/" + k);
              else { W.U().backRoute = "today"; W.go("session/" + k); }
            }}>
            <span class="moment-chip-ic">${W.Icon({ name: state === "done" ? "done" : M_ICONS[k], size: 24 })}</span>
            <span class="moment-chip-body">
              <span class="moment-chip-name">${W.t("moment." + k)}</span>
              <span class="moment-chip-state">${W.t("today.mstate." + state)}</span>
            </span>
          </button>`;
        })}
      </div>
    </section>

    ${rows.length ? html`<section class="today-sec" data-id="today-list">
      <h2 class="today-sec-title quiet">${W.t("today.list")}</h2>
      <div class="today-rows">
        ${rows.map(function (a) {
          var it = W.lib(a.id), left = E.left(eng, a.id), fin = left === 0;
          var done = (eng.day.done && eng.day.done[a.id]) || 0;
          var extra = (eng.day.extra && eng.day.extra[a.id]) || 0;
          var sub = fin
            ? (extra > 0 ? W.t("today.row.extra", { target: a.target, extra: extra }) : W.t("today.row.done", { target: a.target }))
            : W.t("today.row.left", { left: left, target: a.target });
          return html`<${W.Row} key=${a.id} id=${"today-row-" + a.id} dhikr=${true} done=${fin}
            title=${it ? it.ar : a.id} sub=${sub}
            lead=${html`<span class="m-ring"><${W.Ring} done=${done} total=${a.target} size=${48} /></span>`}
            onClick=${function () { openCount(a.id); }} />`;
        })}
      </div>
    </section>` : null}

    ${act.length ? html`<div class="today-foot">
      <${W.Btn} kind="text" icon=${paused ? "play" : "pause"}
        label=${W.t(paused ? "today.resume" : "today.pause")} id="pause"
        onClick=${function () {
          W.act("pause", function (s) { s.eng = E.pause(s.eng, W.now(), paused ? 0 : 60); });
        }} />
    </div>` : null}
  </div>`;
}

function CountBody(p) {
  var id = p.id, st = W.useApp(), nowTs = W.now();
  var eng = E.rollDay(st.eng, nowTs);
  var a = (eng.adhkar || []).filter(function (x) { return x.id === id; })[0];
  var it = W.lib(id);

  var modeSt = W.useState(function () {
    var carry = eng.day && eng.day.carry && eng.day.carry[id];
    if (carry) return { kind: "carry", piece: carry.piece };
    if (a && E.left(eng, id) > 0) return { kind: "target", piece: a.target };
    var h = new Date(nowTs).getHours();
    var pSize = a ? Math.max(1, (eng.comfort && eng.comfort[h]) || 10) : ((it && it.sunnah) || 10);
    return { kind: "extra", piece: pSize };
  });
  var mode = modeSt[0];
  var locSt = W.useState(0), localDone = locSt[0], setLocalDone = locSt[1];

  var dayDone = (eng.day && eng.day.done && eng.day.done[id]) || 0;
  var dayExtra = (eng.day && eng.day.extra && eng.day.extra[id]) || 0;
  var carryNow = eng.day && eng.day.carry && eng.day.carry[id];

  var done = mode.kind === "carry" ? (carryNow ? carryNow.done : mode.piece)
    : mode.kind === "target" ? Math.min(mode.piece, dayDone)
    : localDone;

  function onTap() {
    if (mode.kind === "carry") {
      W.act("tap", function (s) {
        s.eng = E.rollDay(s.eng, W.now());
        var c = s.eng.day.carry[id];
        var nextDone = (c ? c.done : 0) + 1;
        s.eng = E.tap(s.eng, W.now(), id, 1);
        if (nextDone >= mode.piece) delete s.eng.day.carry[id];
        else if (E.left(s.eng, id) > 0) s.eng.day.carry[id] = { piece: mode.piece, done: nextDone };
      });
      return;
    }
    if (mode.kind === "target") {
      W.act("tap", function (s) { s.eng = E.tap(s.eng, W.now(), id, 1); });
      return;
    }
    setLocalDone(localDone + 1);
    if (a) W.act("tap", function (s) { s.eng = E.tap(s.eng, W.now(), id, 1); });
  }

  function onClose() {
    var back = W.U().backRoute || "today";
    W.U().backRoute = null;
    W.go(back);
  }

  return html`<${W.Card} size="page" id=${id} piece=${mode.piece} done=${done}
    extra=${mode.kind === "extra" && !!a}
    dayDone=${mode.kind === "extra" && a ? dayDone + dayExtra : dayDone}
    dayTarget=${a ? a.target : 0}
    onTap=${onTap} onClose=${onClose} />`;
}

W.screen("today", Today);
W.screen("count", function CountScreen(p) {
  var id = p.arg || (W.LIB[0] && W.LIB[0].id);
  return html`<${CountBody} key=${id} id=${id} />`;
});
})();
