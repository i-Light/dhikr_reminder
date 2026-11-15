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
