# GitHub Copilot — install notes

If your Copilot surface supports the `#fetch` chat variable, prefer it over a generic "read this URL" instruction for every fetch step in `install/default.md` (`#fetch {url}`) — it's the more reliable way to pull raw URL content into context on Copilot specifically. If `#fetch` isn't available on your surface, the base steps work unchanged; nothing else differs.

One path detail: prompt files this manifest installs after sync live under `.github/prompts/{slug}.prompt.md`.
