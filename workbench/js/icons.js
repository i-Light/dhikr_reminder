/* icons.js: the app's one icon family, drawn for it on a 24 grid.
   One stroke width (1.75), round caps and joins, currentColor, no fills except the filled "done" state.
   W.Icon({name, size}) renders <svg data-icon="name">. An icon always sits beside a word, never alone.
   Icons that point a way (back, forward, undo) mirror in right-to-left text. */
(function () {
"use strict";
var W = window.W, html = W.html;

var ICONS = {
  /* the three places */
  "today": '<rect x="4" y="5" width="16" height="15.5" rx="2.5"/><path d="M8.5 3v4M15.5 3v4M4 10h16"/><circle cx="12" cy="15.25" r="2"/>',
  "adhkar": '<circle cx="8.9" cy="14.37" r=".5"/><circle cx="6.63" cy="12.1" r=".5"/><circle cx="5.8" cy="9" r=".5"/><circle cx="6.63" cy="5.9" r=".5"/><circle cx="8.9" cy="3.63" r=".5"/><circle cx="12" cy="2.8" r=".5"/><circle cx="15.1" cy="3.63" r=".5"/><circle cx="17.37" cy="5.9" r=".5"/><circle cx="18.2" cy="9" r=".5"/><circle cx="17.37" cy="12.1" r=".5"/><circle cx="15.1" cy="14.37" r=".5"/><circle cx="12" cy="15.5" r="1.35"/><path d="M12 16.85v1.5M10.6 21.1 12 18.4l1.4 2.7z"/>',
  "more": '<rect x="4" y="4" width="6.5" height="6.5" rx="1.75"/><rect x="13.5" y="4" width="6.5" height="6.5" rx="1.75"/><rect x="4" y="13.5" width="6.5" height="6.5" rx="1.75"/><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="1.75"/>',

  /* the four times of day */
  "sunrise": '<path d="M3 16.5h18M8 19.75h8M7.5 16.5a4.5 4.5 0 0 1 9 0M12 7.25v2.5M5.46 9.96l1.77 1.77M18.54 9.96l-1.77 1.77"/>',
  "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 2.75v2.5M12 18.75v2.5M2.75 12h2.5M18.75 12h2.5M5.46 5.46l1.77 1.77M16.77 16.77l1.77 1.77M5.46 18.54l1.77-1.77M16.77 7.23l1.77-1.77"/>',
  "moon": '<path d="M19.5 14.6A8 8 0 1 1 9.4 4.5a6.5 6.5 0 0 0 10.1 10.1z"/>',
  "bed": '<path d="M3 5.5v14M3 16h18v3.5M21 16v-3.5a2.5 2.5 0 0 0-2.5-2.5h-8v6"/><circle cx="6.75" cy="12.5" r="1.75"/>',

  /* actions */
  "add": '<path d="M12 5v14M5 12h14"/>',
  "minus": '<path d="M5 12h14"/>',
  "check": '<path d="M4.75 12.5l4.75 4.75L19.25 7"/>',
  "done": '<circle cx="12" cy="12" r="9" fill="currentColor"/><path class="ic-knock" d="M7.75 12.25l3 3 5.5-6"/>',
  "close": '<path d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>',
  "later": '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  "back": '<path d="M14.5 5.5 8 12l6.5 6.5"/>',
  "forward": '<path d="M9.5 5.5 16 12l-6.5 6.5"/>',
  "pause": '<path d="M9 6v12M15 6v12"/>',
  "play": '<path d="M8 5.5v13L18.5 12z"/>',
  "undo": '<path d="M9 13.5 4.5 9 9 4.5"/><path d="M4.5 9H14a5.5 5.5 0 0 1 0 11h-3.5"/>',
  "search": '<circle cx="10.75" cy="10.75" r="6.25"/><path d="M15.4 15.4 20 20"/>',
  "rest": '<path d="M3.75 13.5h4.5l1.5 2.5h4.5l1.5-2.5h4.5v4.75A1.75 1.75 0 0 1 18.5 20h-13a1.75 1.75 0 0 1-1.75-1.75z"/><path d="M12 3.75v7.5M8.75 8 12 11.25 15.25 8"/>',
  "return": '<path d="M3.75 13.5h4.5l1.5 2.5h4.5l1.5-2.5h4.5v4.75A1.75 1.75 0 0 1 18.5 20h-13a1.75 1.75 0 0 1-1.75-1.75z"/><path d="M12 11.25v-7.5M8.75 7 12 3.75 15.25 7"/>',
  "sparkle": '<path d="M11 3c.6 4.6 2.4 6.4 7 7-4.6.6-6.4 2.4-7 7-.6-4.6-2.4-6.4-7-7 4.6-.6 6.4-2.4 7-7z"/><path d="M18.5 16v5M16 18.5h5"/>',

  /* reminders and settings */
  "bell": '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z"/><path d="M10 21.25h4M12 3v2"/>',
  "card-small": '<rect x="5.5" y="2.5" width="13" height="19" rx="2.75"/><rect x="8.25" y="5.75" width="7.5" height="4.5" rx="1"/>',
  "card-full": '<rect x="5.5" y="2.5" width="13" height="19" rx="2.75"/><rect x="8.25" y="5.75" width="7.5" height="12.5" rx="1"/>',
  "language": '<circle cx="12" cy="12" r="8.75"/><path d="M3.25 12h17.5M12 3.25c-2.4 2.5-3.6 5.4-3.6 8.75s1.2 6.25 3.6 8.75c2.4-2.5 3.6-5.4 3.6-8.75S14.4 5.75 12 3.25z"/>',
  "text-size": '<path d="M3 19 8.25 5.5 13.5 19M4.9 14.5h6.7M14.5 19l3.25-8 3.25 8M15.75 16.25h4"/>',
  "sound": '<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z"/><path d="M15.5 9.25a4 4 0 0 1 0 5.5M18.25 6.5a8 8 0 0 1 0 11"/>',
  "history": '<path d="M4.25 12a7.75 7.75 0 1 0 2.3-5.5L4.25 8.75"/><path d="M4.25 4.5v4.25H8.5M12 8v4.25l2.75 1.75"/>',
  "backup": '<rect x="3.5" y="4" width="17" height="4.5" rx="1.25"/><path d="M5 8.5v9.75A1.75 1.75 0 0 0 6.75 20h10.5A1.75 1.75 0 0 0 19 18.25V8.5M10 12.5h4"/>',
  "help": '<circle cx="12" cy="12" r="8.75"/><path d="M9.6 9.4a2.5 2.5 0 1 1 3.6 2.25c-.75.4-1.2 1-1.2 1.85v.5M12 17h.01"/>',
  "comment": '<path d="M4 6.75A2.25 2.25 0 0 1 6.25 4.5h11.5A2.25 2.25 0 0 1 20 6.75v8.5a2.25 2.25 0 0 1-2.25 2.25H11l-4.5 3.5v-3.5h-.25A2.25 2.25 0 0 1 4 15.25z"/>',
  "wrench": '<path transform="rotate(45 12 12)" d="M10.6 3.2C8.6 3.7 7.5 5.2 7.5 7c0 1.9 1.25 3.45 3 4v9a1.5 1.5 0 0 0 3 0v-9c1.75-.55 3-2.1 3-4 0-1.8-1.1-3.3-3.1-3.8v3.4a1.4 1.4 0 0 1-2.8 0z"/>',
  "pin": '<path d="M12 21.25s-6.75-5.75-6.75-11.5a6.75 6.75 0 0 1 13.5 0c0 5.75-6.75 11.5-6.75 11.5z"/><circle cx="12" cy="9.75" r="2.4"/>'
};
var FLIP = { back: 1, forward: 1, undo: 1 };

W.ICONS = ICONS;
W.Icon = function (p) {
  var name = p.name, size = p.size || 24, body = ICONS[name];
  return html`<svg class=${W.cx("ic", FLIP[name] && "ic-flip", p.className)} data-icon=${name}
    data-missing=${body == null ? "1" : null} width=${size} height=${size} viewBox="0 0 24 24"
    fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round"
    aria-hidden="true" focusable="false" dangerouslySetInnerHTML=${{ __html: body || "" }}></svg>`;
};
})();
