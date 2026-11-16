# Dhikr workbench

A clickable web prototype of the dhikr reminder app. No install, no build.

## Open it

Double-click `index.html`. Everything works from the file.

## Run the server (optional)

The server adds a shared comments file. It needs Node 20 or newer.

    node workbench/serve.mjs

Then open http://127.0.0.1:4173/. Set `PORT` to change the port.

## Run the tests

    node --test "workbench/test/*.test.mjs"

The browser tests use Edge or Chrome when found and skip with a message when not.

## Fonts

All fonts are local files in `fonts/`, loaded with `@font-face` in `css/tokens.css`. Nothing is fetched.

- IBM Plex Sans Arabic, Regular, Medium and SemiBold (`IBMPlexSansArabic-*.ttf`): SIL Open Font License 1.1. Copied from the app's `assets/fonts/`. The words of look a.
- Noto Sans Arabic, variable weight (`NotoSansArabic-Variable.ttf`): SIL Open Font License 1.1. Copied from the app's `assets/fonts/`. The words of look b.
- Amiri, Regular and Bold (`Amiri-Regular.ttf`, `Amiri-Bold.ttf`): SIL Open Font License 1.1, licence text in `fonts/Amiri-OFL.txt`. From github.com/google/fonts, folder `ofl/amiri/`. The dhikr text of both looks (Regular in look a, Bold in look b).

## Looks, icons and motion

Open `index.html?route=gallery` to see both looks' tokens, every icon, every shared part and every motion.
Add `look=a|b`, `theme=light|dark`, `size=1|2|3` or `lang=ar|en` to compare.
