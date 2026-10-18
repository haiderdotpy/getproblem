# getproblem

Fetch a competitive-programming problem statement plus its sample input/output
and pipe it to your clipboard. Supports **Codeforces**, **AtCoder**,
**LeetCode**, and **CodeChef**. Built for Linux/Wayland, one file, no daemon.

```console
$ getproblem 1831B
Copied Codeforces 1831B - Array merging (1 samples)

$ getproblem two-sum --stdout | head
# 1. Two Sum

## Statement
...
```

## Features

- Grab a problem by id from four platforms, with optional explicit prefixes.
- Copies to the clipboard via `wl-copy` (falls back to `xclip`, then stdout).
- Prints a clean, markdown-ish statement with limits, statement, input/output
  spec, constraints, examples, note, and the source URL.
- Math handling per platform:
  - Codeforces `$$$...$$$` → `$...$`
  - AtCoder `<var>` → `$...$`
  - LeetCode / CodeChef left untouched
  - `--raw` keeps the original delimiters (Codeforces/AtCoder)
- Caches fetched data per platform under `~/.cache/getproblem/`; `--refresh`
  re-fetches.
- Gets past Cloudflare using `curl_cffi` with Chrome TLS impersonation
  (falls back to `requests` with a realistic User-Agent).
- Works from any directory; no config files.

## Requirements

- Linux with a Wayland session (for `wl-copy`). X11 works too if `xclip` is installed.
- Python 3.8+
- [`beautifulsoup4`](https://pypi.org/project/beautifulsoup4/) (required)
- [`curl_cffi`](https://pypi.org/project/curl_cffi/) (recommended — needed to
  reliably bypass Cloudflare) or [`requests`](https://pypi.org/project/requests/)

## Install

### One-liner (recommended)

```sh
git clone https://github.com/<you>/getproblem.git
cd getproblem
./install.sh
```

`install.sh` installs the dependencies with `pip --user` and symlinks the script
into `~/.local/bin`. Override the target with `BIN_DIR=... ./install.sh`.

### Manual

```sh
pip install --user curl_cffi beautifulsoup4
chmod +x getproblem
ln -sf "$PWD/getproblem" ~/.local/bin/getproblem
```

Make sure `~/.local/bin` is on your `PATH`:

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # or ~/.bashrc
```

## Usage

```console
getproblem 1831B            # Codeforces
getproblem 1831/B           # same problem, alternate form
getproblem 1800F2           # multi-char index (E2/F2/B1)
getproblem abc300_a         # AtCoder (abc300a also accepted)
getproblem 1                # LeetCode by frontend number
getproblem two-sum          # LeetCode by title slug
getproblem FLOW001          # CodeChef
getproblem cf:1A            # explicit platform prefixes: cf, atc, lc, cc

getproblem 1831B --print         # copy AND print to stdout
getproblem 1831B --stdout        # print only, no clipboard
getproblem 1831B --samples-only  # just the samples
getproblem 1831B --refresh       # bypass the cache
getproblem 1831B --raw           # keep original math delimiters
```

### ID detection (first match wins)

| Pattern                                    | Platform   |
| ------------------------------------------ | ---------- |
| `cf:` / `atc:` / `lc:` / `cc:` prefix       | explicit   |
| `^\d+/?[A-Za-z]\d?$`                        | Codeforces |
| `^[a-z]+\d+_?[a-z0-9]+$` (abc/arc/agc/ahc) | AtCoder    |
| `^\d+$` or `^[a-z0-9]+(-[a-z0-9]+)+$`      | LeetCode   |
| `^[A-Z]+\d+[A-Z]*$`                         | CodeChef   |

Bare digits go to LeetCode; Codeforces always needs a letter, so there is no
ambiguity. Anything else prints usage and exits `2`.

| Flag             | Effect                                              |
| ---------------- | --------------------------------------------------- |
| `--print`        | Copy to the clipboard **and** print to stdout       |
| `--stdout`       | Print to stdout only (no clipboard)                 |
| `--samples-only` | Emit only the sample inputs/outputs                 |
| `--refresh`      | Ignore the cache and re-fetch                       |
| `--raw`          | Keep original math delimiters (CF/AtCoder)          |

On success a single status line is written to stderr, so stdout stays clean for
piping:

```
Copied Codeforces 1831B - Array merging (1 samples)
```

## Output format

````text
# 1831B - Array merging
Time limit: 1 second | Memory limit: 256 megabytes

## Statement
...

## Input
...

## Constraints          (only when the source provides them)
...

## Output
...

## Examples
### Input 1
```
...
```

### Output 1
```
...
```

## Note
...

URL: https://codeforces.com/contest/1831/problem/B
````

- LeetCode uses `# {frontend_id}. {title}` for the header and has no limits line.
- The limits line is omitted entirely when the platform exposes neither limit
  (e.g. LeetCode).
- For Codeforces problems with non-standard I/O files the limit line gains
  `| Input: ... | Output: ...` (e.g. `4A` reports `Input: stdin | Output: stdout`).

## How it works

1. Detects the platform from the id and dispatches to a provider
   (`fetch_cf`, `fetch_atc`, `fetch_lc`, `fetch_cc`), each returning a
   `Problem` dataclass.
2. HTTP goes through `curl_cffi` (`impersonate="chrome"`) first, then
   `requests`; timeout 15s with 2 retries. Finished text is written to the
   clipboard in one shot — never a partial clipboard.
3. Codeforces: fetches `.../contest/{id}/problem/{index}`, falling back to
   `.../problemset/problem/{id}/{index}`, and parses `div.problem-statement`.
4. AtCoder: fetches `.../contests/{contest}/tasks/{contest}_{letter}?lang=en`;
   if that 404s (older numeric task ids), it reads the contest task list and
   follows the matching label. Parses `#task-statement` sections by their `<h3>`.
5. LeetCode: resolves numbers to slugs via `api/problems/all/` (cached 7 days)
   and queries the GraphQL endpoint. Parses examples from both `<pre>` blocks
   and newer `div.example-block` markup.
6. CodeChef: uses the `api/contests/PRACTICE/problems/{CODE}` JSON endpoint and
   the structured `problemComponents` fields, falling back to splitting `body`
   by its headings.
7. Math: Codeforces `$$$...$$$` and AtCoder `<var>` become `$...$` unless
   `--raw`; LeetCode and CodeChef are left as-is.

## Cache

Per-platform under `${XDG_CACHE_HOME:-~/.cache}/getproblem/`:

```
codeforces/1831B.html
atcoder/abc300_a.json        # {"url": ..., "html": ...}
leetcode/all.json            # problem list, 7-day TTL
leetcode/two-sum.json
codechef/FLOW001.json
```

Legacy flat `~/.cache/getproblem/*.html` Codeforces files are migrated into
`codeforces/` automatically on first run.

## Troubleshooting

- **`<Platform> blocked the request (Cloudflare)`** — install `curl_cffi`
  (`pip install --user curl_cffi`) and retry, or wait a moment and run again.
- **`wl-copy/xclip not found; printing to stdout instead`** — install
  `wl-clipboard` (Wayland) or `xclip` (X11); the text is still printed.
- **`LeetCode problem is premium; no content available.`** — the problem is
  locked behind LeetCode Premium.
- **Stale output** — run with `--refresh`, or delete `~/.cache/getproblem/`.
- **`problem 1800F2 not found`** — the id is valid in form, but that exact
  problem does not exist on the detected platform.

## Uninstall

```sh
rm -f ~/.local/bin/getproblem
rm -rf ~/.cache/getproblem
```

## License

MIT © 2026 Syed Mohammad Haider — see [LICENSE](LICENSE).
