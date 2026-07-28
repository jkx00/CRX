# crx

Automated reconnaissance pipeline for bug bounty / authorised pentesting,
modelled on [jkx00/CRX](https://github.com/jkx00/CRX.git).

Wraps 16 tools into a single command:

```
crx -d target_domain
```

## Pipeline

| # | Stage | Tool(s) |
|---|-------|---------|
| 1 | Subdomain enumeration | `subfinder` |
| 2 | Live host probing | `httpx` |
| 3 | DNS resolution | `dnsx` |
| 4 | CDN / WAF fingerprint | `cdncheck` |
| 5 | Technology fingerprint | `whatweb` |
| 6 | URL collection | `waybackurls` `gau` `katana` `hakrawler` `urlfinder` |
| 7 | Deduplicate / normalise | `uro` `urless` `urldedupe` |
| 8 | Sensitive files / JS / params extraction | grep filters |
| 9 | Subdomain takeover | `subzy` |
| 10 | CORS misconfiguration | `corsy` (`Corsy`) |
| 11 | Vulnerability scan + open redirect | `nuclei` |

## Install

```bash
cd ~/Downloads/CRX
bash install.sh
```

`install.sh` installs the Go tools (nuclei, httpx, subfinder, katana, dnsx,
cdncheck, urlfinder, subzy, gau, hakrawler, waybackurls, urldedupe), the pip
tools (uro, urless) into `~/.venv`, clones Corsy, and links `crx` onto your
`PATH`. WhatWeb comes from your distro (`sudo pacman -S whatweb`).

Make sure your shell PATH includes the Go bin dir and `~/.local/bin`:

```fish
# fish
fish_add_path ~/go/bin ~/.local/bin
```
```bash
# bash/zsh
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
```

## Usage

```
crx -d example.com              # full run, output -> ./example.com-crx/
crx -d example.com -o /tmp/out  # custom output directory
crx -d example.com -t 100       # bump concurrency
crx -h                          # help
crx -c                          # about
```

## Output layout

```
<domain>-crx/
├── subs/
│   ├── subdomains.txt        all discovered subdomains
│   ├── httpx-detailed.txt    status / title / tech per host
│   ├── live.txt              live URLs
│   ├── resolved.txt          A records (dnsx)
│   ├── cdn.txt               CDN/WAF (cdncheck)
│   └── whatweb.txt           tech fingerprint
├── urls/
│   ├── all-urls.txt          raw collected URLs
│   ├── clean-urls.txt        deduped / normalised
│   ├── sensitive-files.txt   .json .db .config .bak .sql .env ...
│   ├── js-files.txt          JavaScript URLs
│   └── params.txt            URLs with query parameters
└── vulns/
    ├── takeover.txt          subzy
    ├── cors.json             corsy
    ├── nuclei.txt            nuclei findings
    └── open-redirect.txt     nuclei redirect templates
```

## Note

Only run this against domains you own or are explicitly authorised to test.
Missing tools are detected at runtime and their stages are skipped with a
warning rather than aborting the whole run.
