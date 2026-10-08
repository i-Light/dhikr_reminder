# Links

Double-click a shortcut to open that page in the browser.

| Shortcut | Opens |
| --- | --- |
| Dhikr admin | The private page where requests are answered (needs the admin token) |
| Service health | A tiny page that says `{"ok":true}` when the service is up |
| Cloudflare Worker | The Worker's dashboard: logs, metrics, settings |
| Cloudflare database | The D1 database: tables and their rows |
| GitHub repository | The code |
| GitHub releases | The Windows installers the updater downloads |
| GitHub issues | Bug reports and data deletion requests |
| Google Play Console | Where the Android app is published |

The `.url` files and `icons\` are made by `scripts\make_links.ps1`, which reads
the addresses from the code (`requests_config.dart`, `server\wrangler.toml` and
the git remote) so they are never typed twice. A `.url` file needs the full path
of its icon, so after moving or cloning the repository run it again:

```powershell
.\scripts\make_links.ps1
```

`-RedrawIcons` draws the icons again too. Nothing secret is in these files: the
admin token is never part of a link, you paste it into the page.
