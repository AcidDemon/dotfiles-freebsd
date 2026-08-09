# web-noise

Generate realistic web traffic noise for privacy by simulating human browsing patterns.

## Motivation

Traffic analysis is cheap. Your ISP, a transit provider, or anyone with a tap sees which
hosts you talk to and when, and that pattern alone says a lot about you even when the
payload is encrypted.

Generating plausible browsing alongside your real browsing does not hide anything, but it
does raise the cost of picking the real requests out of the total. That is the whole idea.
It is a blunt instrument and it is not a substitute for a VPN or Tor.

## What it does

Runs one or more simulated users, each in its own thread. A user picks one of the bundled
browser profiles and keeps it for the whole session: the profile carries a matching
User-Agent alongside its headers, so a Chrome profile does not go out with a Firefox
User-Agent. Each user starts from a random root URL, extracts links, follows a random
subset of them up to `max_depth`, and sleeps a variable amount between requests. Cookies
are kept per user in a `requests.Session`.

Sleep is randomised around `min_sleep` and `max_sleep`, with a 10% chance of a long pause
(2 to 5 times the base) and a 5% chance of a quick one (half the base).

## Installation

### NixOS

The package lives in this flake's `pkgs/` and is exposed through the `additions` overlay,
so it is `pkgs.web-noise` once the overlay is in scope. It is not in nixpkgs.

```nix
home.packages = with pkgs; [ web-noise ];
```

There is also a Home Manager module at `modules/cli/web-noise/`, which writes the config
and wires up a systemd user service. See `USAGE-NIXOS.md`.

### Anywhere else

Python 3.6 or newer and `requests`. From this directory:

```bash
python3 -m venv venv
source venv/bin/activate
pip install .
```

`pip install .` puts `browser_profiles.json` and `config.example.json` in
`$VIRTUAL_ENV/share/web-noise/`, which the program finds on its own. Pass `--profiles` if
you keep them somewhere else.

## Usage

Copy the example config, edit it, and point the tool at it. `--config` is required.

```bash
cp config.example.json ~/.config/web-noise/config.json
web-noise -c ~/.config/web-noise/config.json
```

On NixOS the example lives at `${pkgs.web-noise}/share/web-noise/config.example.json`.

```bash
web-noise --help
web-noise -c CONFIG --users 3          # three concurrent users, max 64
web-noise -c CONFIG --timeout 7200     # stop after two hours
web-noise -c CONFIG --timeout 0        # run until interrupted
web-noise -c CONFIG --profiles ./my_profiles.json
web-noise -c CONFIG --log debug
```

`--timeout` overrides whatever the config says.

To keep it running after you log out, use your init system, or `nohup`/`tmux` if you do not
have one handy:

```bash
nohup web-noise -c ~/.config/web-noise/config.json -u 2 -t 0 > ~/web-noise.log 2>&1 &
```

## Configuration

`config.example.json` is a working starting point. Required keys: `root_urls`,
`blacklisted_urls`, `min_sleep`, `max_sleep`, `max_depth`, `timeout`. The program refuses
to start and names what is missing rather than dying on a KeyError halfway through.

| Key | Meaning |
|---|---|
| `max_depth` | how many links deep to go from each root URL |
| `min_sleep` / `max_sleep` | seconds between requests, before the random multiplier |
| `timeout` | total runtime in seconds. `0`, `false` and `null` all mean run until interrupted |
| `root_urls` | where each browsing run starts |
| `blacklisted_urls` | substring patterns to skip: tracking domains, file extensions |
| `user_agents` | fallback only, used when a profile carries no `user_agent` of its own |
| `request_timeout` | optional, per-request timeout in seconds (default 10) |

URLs that turn out to be dead ends are remembered for the rest of the session, separately
from `blacklisted_urls`, so a dead `https://site/a` does not also block
`https://site/a?b=1`.

Response bodies are read up to 2 MB and truncated past that. Links worth following are near
the top of a page, and a crawler should not buffer whatever a random host decides to send.

## Browser profiles

`browser_profiles.json` holds 15 profiles with headers collected from real browsers via
<https://requestheaders.dev/>. Each has a `name`, a `user_agent`, and its `headers`.

Coverage: Chrome 106/107 on Windows, macOS and Linux; Firefox 106/107 on Windows, macOS and
Linux; Safari 15/16 on macOS and iOS; Edge 105/106 on Windows and macOS. Locales vary
(en-US, en-GB, de-DE, fr-FR, es-ES, it-IT, nl-NL, en-AU), and `DNT` is present on some
profiles and absent on others, which is what real populations look like.

The `user_agent` on each profile agrees with that profile's `Sec-Ch-Ua`. This matters:
Firefox and Safari never send `Sec-Ch-Ua`, so a Firefox User-Agent arriving with Chrome
client hints is an obvious tell. Two of the 15 User-Agent strings (Edge 105 on Windows,
Firefox 106 on Windows) were derived by version substitution from a sibling string rather
than captured directly.

## Running as a service

On NixOS, use the Home Manager module rather than writing a unit by hand. Otherwise:

```ini
[Unit]
Description=Web Traffic Noise Generator
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/web-noise -c %h/.config/web-noise/config.json -u 2 -t 0
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
```

Install it as a user unit (`~/.config/systemd/user/web-noise.service`) so `%h` resolves and
it does not need root.

## Caveats

This generates random traffic, not traffic that looks like yours. Volume, timing and the
choice of root URLs are all distinguishable from real browsing under analysis that bothers
to look. Treat it as noise, not cover.

Concurrent users cost bandwidth and CPU, and some sites rate-limit or block automated
requests. It follows links only, so it never clicks ads or costs a site owner money.

## License

MIT. See `LICENSE`.

Use it on your own connection and mind the terms of service of the sites you point it at.
