# web-noise

Home Manager module wrapping the `web-noise` package, a Python crawler that generates decoy HTTP traffic by following links from a set of root URLs. The module lives at `modules/cli/web-noise/default.nix` (defining `flake.modules.homeManager.cli_web-noise`) and exposes options under `cli.web-noise`. It is not imported per-host: every Home Manager module is bulk-loaded into `home-manager.sharedModules` via `builtins.attrValues (self.modules.homeManager or {})` (`parts/hosts.nix:56-57`), so the module is always present and gated only by `cli.web-noise.enable`. The package directory (`pkgs/web-noise/`) ships only the app and its data files; the module is defined in the flake module tree, not bundled in the package.

## Deployment

| Host | Profile | `enable` | `service.enable` | `service.timer.enable` |
|------|---------|----------|------------------|------------------------|
| ted | `home/profiles/desktop.nix` | true | false | false |

Only the desktop profile sets `enable = true` (`home/profiles/desktop.nix:512`), install-only: the package and generated config are present but no service or timer runs. Activate by flipping `service.enable` (and optionally `service.timer.enable`) on the host. The module is loaded on every host (bulk `sharedModules` import) but stays inert wherever `cli.web-noise.enable` is left at its `false` default.

## What `enable` does

Setting `cli.web-noise.enable = true` adds the package to `home.packages`, writes `~/.config/web-noise/config.json` from the module options, and copies the bundled `browser_profiles.json` and `config.example.json` alongside it for reference. A `web-noise` shell alias is set to run the binary against the generated config.

Run manually:

```sh
web-noise -c ~/.config/web-noise/config.json -u 2 -t 3600
```

## Options

| Option | Type | Default | Effect |
|--------|------|---------|--------|
| `enable` | bool | `false` | Install package, generate config |
| `package` | package | `pkgs.web-noise` | Package to use |
| `enablePersistence` | bool | `config.impermanence.enable` | Persist `.config/web-noise` to `/persist` |
| `maxDepth` | int | `10` | Max links followed from each root |
| `minSleep` | int | `2` | Min sleep between requests (s) |
| `maxSleep` | int | `5` | Max sleep between requests (s) |
| `timeout` | int\|bool | `3600` | Total runtime (s), or `false` for unlimited |
| `rootUrls` | list str | 16 URLs | Starting URLs (see below) |
| `blacklistedUrls` | list str | 28 patterns | URL patterns to skip |
| `userAgents` | list str | 7 agents | Fallback only; each bundled profile now carries its own matching User-Agent |
| `browserProfilesFile` | null\|path | `null` | Custom profiles JSON; `null` uses bundled |
| `service.enable` | bool | `false` | systemd user service |
| `service.users` | int | `2` | Concurrent simulated users |
| `service.logLevel` | enum | `"info"` | `debug`\|`info`\|`warning`\|`error` |
| `service.serviceTimeout` | int\|bool | `0` | Continuous-mode timeout; `0` = indefinite |
| `service.timer.enable` | bool | `false` | Periodic timer instead of continuous run |
| `service.timer.interval` | str | `"30min"` | `OnUnitActiveSec`/`OnBootSec` |
| `service.timer.randomizedDelay` | str | `"5min"` | `RandomizedDelaySec` (0 to this) |
| `service.timer.runDuration` | int | `600` | Base seconds per run |
| `service.timer.runDurationVariance` | int | `180` | Wrapper adds random ±variance to `runDuration`; `0` disables |
| `service.timer.persistent` | bool | `true` | `Persistent=`, catch up missed runs |

The `rootUrls` default is German-news heavy: `wikipedia.org`, `news.google.com`, `reddit.com`, `bbc.com/news`, `theguardian.com`, `nytimes.com`, `arstechnica.com`, `heise.de`, `stern.de`, `spiegel.de`, `amazon.de`, `n-tv.de`, `welt.de`, `focus.de`, `ebay.de`, `github.com/explore`.

## Service modes

Two mutually exclusive modes once `service.enable = true`:

- **Continuous** (`timer.enable = false`): `Type=simple`, `Restart=on-failure`, runs `web-noise -t <serviceTimeout>` with `0` meaning forever. `Install.WantedBy = default.target`.
- **Timer** (`timer.enable = true`): `Type=oneshot`, no restart, not wanted by `default.target`. A `web-noise.timer` fires every `interval` (+`randomizedDelay` jitter). A wrapper script recomputes the run length each fire as `runDuration ± runDurationVariance` before exec, so each run differs.

## Enabling (ted)

The desktop profile sets the install-only baseline. Flip `service.enable` to run it:

```nix
cli.web-noise = {
  enable = true;
  service = {
    enable = false;        # install-only on ted
    users = 2;
    logLevel = "info";
    timer = {
      enable = false;
      interval = "30min";
      randomizedDelay = "5min";
      runDurationVariance = 180;
      runDuration = 600;
    };
  };
};
```

Custom browser profiles override the bundled set:

```nix
cli.web-noise.browserProfilesFile = ./my-browser-profiles.json;
```

## Persistence

`enablePersistence` defaults to `config.impermanence.enable`. When the system uses impermanence, `.config/web-noise` is added to `home.persistence."/persist"` so the generated config survives a wipe.

## Generated files

```
~/.config/web-noise/config.json          # generated from options
~/.config/web-noise/config.example.json  # bundled reference
~/.config/web-noise/browser_profiles.json
```

## Operations

```sh
systemctl --user status web-noise              # continuous service
systemctl --user status web-noise.timer        # timer state
systemctl --user list-timers --all web-noise   # next scheduled run
journalctl --user -u web-noise -f              # logs (timer prints chosen runtime)
systemctl --user start web-noise.service       # trigger a run now
systemctl --user stop web-noise.timer          # pause periodic runs
```

After editing config, rebuild then restart:

```sh
nh home switch .
systemctl --user restart web-noise
```

## See also

- `pkgs/web-noise/README.md`, the underlying Python tool and its CLI flags.
