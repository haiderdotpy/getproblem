# getproblem

Fetch a [Codeforces](https://codeforces.com) problem statement plus its sample
input/output and pipe it to your clipboard. Built for Linux/Wayland, one file,
no daemon.

```console
$ getproblem 1831B
Copied 1831B - Array merging (1 samples)

$ wl-paste | head
# 1831B - Array merging

Time limit: 1 second | Memory limit: 256 megabytes

## Statement
...
```

## Features

- Grab a problem by id: `1831B`, `1831/B`, `1800F2`, `1856E2` (multi-char indices work).
- Copies to the clipboard via `wl-copy` (falls back to `xclip`, then stdout).
- Prints a clean, markdown-ish statement with time/memory limits, statement,
  input/output spec, examples, note, and the source URL.
- Converts Codeforces `$$$...$$$` LaTeX to standard `$...$` markdown math.
  Use `--raw` to keep the original delimiters.
- Caches the fetched HTML under `~/.cache/getproblem/`; `--refresh` re-fetches.
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
getproblem 1831B            # copy to clipboard
getproblem 1831/B           # same problem, alternate form
getproblem 1800F2           # multi-char index (E2/F2/B1)
getproblem 1831B --print    # copy AND print to stdout
getproblem 1831B --stdout   # print only, no clipboard
getproblem 1831B --samples-only
getproblem 1831B --refresh  # bypass the HTML cache
getproblem 1831B --raw      # keep $$$...$$$ math delimiters
```

| Flag             | Effect                                              |
| ---------------- | --------------------------------------------------- |
| `--print`        | Copy to the clipboard **and** print to stdout       |
| `--stdout`       | Print to stdout only (no clipboard)                 |
| `--samples-only` | Emit only the sample inputs/outputs                 |
| `--refresh`      | Ignore the cached HTML and re-fetch                 |
| `--raw`          | Keep the original `$$$...$$$` math delimiters       |

On success a single status line is written to stderr, so stdout stays clean for
piping:

```
Copied 1831B - Array merging (1 samples)
```

## Output format

````text
# 1831B - Array merging
Time limit: 1 second | Memory limit: 256 megabytes

## Statement
...

## Input
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

For problems with non-standard I/O files the limit line gains
`| Input: ... | Output: ...` (e.g. `4A` reports `Input: stdin | Output: stdout`).

## How it works

1. Parses the id with `^(\d+)/?([A-Za-z]\d?)$` and uppercases the index letter.
2. Fetches `https://codeforces.com/contest/{id}/problem/{index}`, falling back
   to `https://codeforces.com/problemset/problem/{id}/{index}` on a 404 or an
   odd redirect.
3. Requests go through `curl_cffi` (`impersonate="chrome"`) first, then
   `requests`; timeout 15s with 2 retries. Raw HTML is cached at
   `${XDG_CACHE_HOME:-~/.cache}/getproblem/{id}{index}.html`.
4. Parses `div.problem-statement`, preserving sample line breaks
   (`div.test-example-line`), converting `<br>` to newlines, `<ul>/<li>` to
   bullets, `<sub>/<sup>` to `_x`/`^x` (only outside math), and images to
   `[image: URL]` placeholders. LaTeX is left intact during parsing.
5. Optionally converts `$$$...$$$` to `$...$` on the finished text.
6. Writes the complete text to the clipboard in one shot — never a partial
   clipboard.

## Troubleshooting

- **`Codeforces blocked the request (Cloudflare)`** — install `curl_cffi`
  (`pip install --user curl_cffi`) and retry, or wait a moment and run again.
- **`wl-copy/xclip not found; printing to stdout instead`** — install
  `wl-clipboard` (Wayland) or `xclip` (X11); the text is still printed.
- **Stale output** — run with `--refresh`, or delete `~/.cache/getproblem/`.
- **`problem 1800F2 not found`** — the id is valid in form, but that exact
  contest/index does not exist.

## Uninstall

```sh
rm -f ~/.local/bin/getproblem
rm -rf ~/.cache/getproblem
```

## License

MIT © 2026 Syed Mohammad Haider — see [LICENSE](LICENSE).
