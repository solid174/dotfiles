# Fresh macOS setup — agent prompt

You are an agent on a fresh (or reset) Mac. Recreate my full environment from this
document. Work top to bottom, verify each block before moving on. Ask before anything
destructive; everything else — just do it.

## Vibe (applies to every choice you make)

- **Catppuccin Mocha** everywhere: terminal, bat, delta, fzf colors, LS_COLORS, lazygit.
- **JetBrainsMono Nerd Font** as the terminal font.
- Preference order: **good TUI > GUI > bare CLI** — lazygit, lazydocker, btop, bbrew,
  one-letter aliases.
- **fzf with rich previews** wired into everything (tab completion, ctrl-t, cd).
- Minimal, fast, informative prompt (starship). Shell startup must stay under ~0.5s
  (`time zsh -i -c exit`) — if a step slows it down, find a lazier way.
- Secrets never live in tracked files — `~/.zshrc.local` (chmod 600), sourced if present.
- No version pins in this doc: always install current stable. If a tool needs a specific
  version for a project, that's the project's concern (global.json, mise.toml), not this setup.
- Runtimes are **mise**'s job, never the package manager's (see §1b).
- IDE settings are not tracked here — this repo holds shell/CLI/TUI config only; editors
  sync their own settings through their own accounts.
- Secrets and local-only wrappers stay out of this repo; document the *shape*, not the
  contents.

## 1. Homebrew + packages

Install Homebrew, then:

**Formulae:**
`atuin bat btop coreutils docker docker-completion eza fastfetch fd fzf fzf-tab gh git-delta jq lazydocker lazygit mise neovim opencode ripgrep shfmt starship stylua superfile tailscale tree-sitter-cli uv vivid zoxide zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting`

`coreutils` is here only for `timeout`, which macOS does not ship — agent sessions use it
to bound long test runs. Commands macOS already provides keep the `g` prefix; the GNU
`gnubin` directory is deliberately **not** on `PATH`, so `ls`/`date`/`sed` stay BSD.

Tap + install: `valkyrie00/bbrew/bbrew` (TUI for brew itself).

**Casks:**
`anydesk audiorelay blackhole-2ch blackhole-16ch claude claude-code codex cyberduck font-jetbrains-mono-nerd-font ghostty google-chrome lm-studio logi-options+ middleclick obs openvpn-connect orbstack pearcleaner t3-code transmission visual-studio-code`

Notes:
- `orbstack` replaces Docker Desktop; the `docker` formula is just the CLI client.
- Language runtimes (node, go, rust, dotnet) are **not** brew formulae — `mise` owns them
  (see §1b). No `dotnet-sdk` cask: the standard lookup path `/usr/local/share/dotnet` is a
  symlink to mise's dotnet-root, so anything that probes that path (IDEs, editor
  extensions) sees the same SDKs as the CLI —
  `sudo ln -s ~/.local/share/mise/dotnet-root /usr/local/share/dotnet`.
- Python is not a brew formula either — `uv` provides the system `python3`
  (`uv python install <ver> --default`; shims land in `~/.local/bin`, which is on PATH).
- After install run `chmod g-w /opt/homebrew/share` — otherwise zsh compaudit complains
  and full compinit aborts.

## 1b. mise (runtime version manager)

`mise` replaces nvm (node), the ad-hoc brew go/rust/dotnet installs, and direnv (dir-local
env). One binary, per-project version switching on `cd`, honours in-repo `global.json` /
`mise.toml`. Install is the `mise` formula (above); activation lives in the zsh tool-inits
block (§2.9).

Write `~/.config/mise/config.toml` — global defaults are current-stable **only**, no
project pins (a project pins its own via `global.json` / `mise.toml`):

```toml
[tools]
node = "24"
go   = "1.26"
rust = "stable"          # installed via rustup under the hood; CARGO_HOME=~/.cargo
# Both .NET SDKs share one dotnet-root, so the single `dotnet` muxer resolves each
# repo's global.json natively: 10 is the default, work repos pinning 8.0.11x roll
# forward to 8.0.129. Do NOT enable idiomatic global.json — mise would read the pin
# literally, not find it as a mise install, and drop dotnet from PATH.
dotnet = ["10", "8.0.129"]

[env]
EDITOR = "nvim"
VISUAL = "nvim"
PAGER = "less"
LESS = "-FRX"
DOTNET_CLI_TELEMETRY_OPTOUT = "1"
```

Then `mise install`. Python is deliberately absent — uv owns it: `uv python install 3.14
--default` creates `python` / `python3` shims in `~/.local/bin` (that dir is prepended to
PATH in §2.1's env block).

Plain global env vars (no PATH surgery, no shell-load-order dependency) live in this
`[env]` block, not `~/.zshrc` — `mise activate zsh` exports them on every shell.
Directory-scoped env (e.g. a work API endpoint that should only apply under one source
tree) goes in a `mise.toml` dropped at the root of that tree instead — e.g.
`~/coding/src/work/<org>/mise.toml` holds `LITELLM_BASE_URL`, picked up on `cd` into any
repo under that tree, not machine-wide.

## 2. zsh (`~/.zshrc`)

Build it with these blocks, in this order:

1. **Env**: `PATH+=~/.dotnet/tools`, and `PATH="$HOME/.local/bin:$PATH"` (holds uv's
   default python3 shims). Plain (non-PATH) env vars — `EDITOR`, `DOTNET_CLI_TELEMETRY_OPTOUT`,
   etc. — live in mise's `[env]` block instead (§1b), not here.
2. **Colors + fzf**: `LS_COLORS="$(vivid generate catppuccin-mocha)"`,
   `BAT_THEME="Catppuccin Mocha"`. fzf default command = `fd --hidden --strip-cwd-prefix
   --exclude .git`; alt-c = dirs only. `FZF_DEFAULT_OPTS`: height 60%, reverse, border,
   right 60% preview window, full Catppuccin Mocha color set. ctrl-t preview: eza for
   dirs / bat with line numbers for files.
3. **Completions**: put `/opt/homebrew/share/zsh-completions` and brew `site-functions`
   on `fpath` *before* compinit. Then:
   ```zsh
   autoload -Uz compinit
   if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then compinit; else compinit -C; fi
   ```
   (full rebuild if dump older than 24h, cached fast path otherwise).
   zstyles: case-insensitive matcher, `list-colors` from LS_COLORS, group headers
   `[%d]`, `menu no` (fzf-tab owns selection).
4. **fzf-tab**: source after compinit; previews for cd and generic completions
   (eza for dirs, bat for files), height 60% reverse, `,`/`.` switch groups.
5. **Options/history**: auto_cd, auto_pushd, pushd_ignore_dups, hist_ignore_all_dups,
   hist_reduce_blanks, hist_save_no_dups, inc_append_history, share_history.
   HISTSIZE=SAVEHIST=100000.
6. **Keybinds**: emacs mode (`bindkey -e`), ctrl-a/e/u/k/w, alt-arrows + alt-b/f word
   jumps, alt-backspace kill word.
7. **Aliases**: `ll`/`la` = eza long with icons/git/group-dirs-first, `ls` = eza,
   `cat`=bat, `grep`=rg, `lg`=lazygit, `ld`=lazydocker, `tree`=`eza --tree --icons=auto`,
   `..`/`...`, `codex`=`codex --yolo`. Plus a `spf` **function** (not an alias) so
   superfile can cd-on-quit:
   ```zsh
   spf() {
     command spf "$@"
     local f="$HOME/Library/Application Support/superfile/lastdir"
     [ -r "$f" ] && source "$f"
   }
   ```
   superfile writes a `cd '/path'` line to that lastdir file on quit; source it (never
   capture with `$(...)` — the TUI escape sequences would garble the screen).
8. **Project jumps**: nothing in the shell — superfile Pins (`spf`, then cd-on-quit) plus
   zoxide cover it. Deliberately no `cdpath` and no one-word per-repo functions; they
   duplicated the pins and went stale every time a repo moved. Pins live in
   `~/Library/Application Support/superfile/pinned.json`.
9. **Tool inits**: `fzf --zsh` (guarded interactive-only), `zoxide init zsh`,
   `starship init zsh`, then `eval "$(mise activate zsh)"` (hook mode — replaces the old
   nvm sourcing and `direnv hook`; switches runtime versions on `cd`).
10. **Secrets**: `[ -f ~/.zshrc.local ] && source ~/.zshrc.local`; create that file
    chmod 600. Ask me which env vars to put there — never write values into ~/.zshrc.
11. **Plugins, order matters**: `eval "$(atuin init zsh --disable-ai)"` (ctrl-r + up
    arrow; the `--disable-ai` flag matters — I don't want `?` hijacked) → then
    zsh-autosuggestions → zsh-syntax-highlighting **last**. atuin goes *before*
    syntax-highlighting: that plugin only wraps widgets declared before it. If there's
    existing shell history, run `atuin import auto`.

## 3. git (`~/.gitconfig`)

**Copy `.gitconfig` from this repo** — it is the source of truth for every machine
(pager/delta, pretty log, pull.rebase, push.autoSetupRemote, defaultBranch, zdiff3,
colorMoved, aliases `st/co/sw/br/cm/amend/lg`). The two things the file can't explain
itself:

- **Identity guard**: global user = `No Name <none@local.invalid>` is deliberate — it
  forces per-directory identity, so a forgotten repo fails loudly instead of committing
  under the wrong name. Real name/email live in `.gitconfig` files *inside* the work and
  hobby source roots, pulled in by the `includeIf "gitdir:"` blocks. Ask me for the
  emails at setup time; don't invent them, and don't set a global real identity.
- **delta side-by-side lives in a *feature*, never in `[delta]`** — main-section values
  override features, which silently breaks lazygit's single-column opt-out:
  ```ini
  [delta]
      features = wide-view
  [delta "wide-view"]
      side-by-side = true
  [delta "lazygit"]
      side-by-side = false
  ```

## 4. Ghostty (`~/.config/ghostty/config`)

JetBrainsMono Nerd Font Mono 14pt, theme Catppuccin Mocha, padding-x 15 / padding-y 12.
Transparency is a deliberate part of the vibe: `background-opacity = 0.85`,
`background-blur = 2`, `background-opacity-cells = true`, and `unfocused-split-opacity =
0.94` so the inactive split dims. Plus `macos-option-as-alt`, `copy-on-select=clipboard`,
no close confirmation (`confirm-close-surface=false`), `window-save-state=always`,
`mouse-hide-while-typing`.
Quick terminal: F12 global toggle, `position=top`, `size=100%,100%`, `screen=main`,
`animation-duration=0.18`, `autohide=true`, `space-behavior=move`.
Keybinds: cmd-t/w tabs, cmd-d / cmd-shift-d splits, cmd-arrows split navigation,
cmd-shift-left/right tabs, cmd-shift-enter zoom split, cmd-shift-e equalize.
Validate with `ghostty +validate-config`.

## 5. lazygit (`~/.config/lazygit/config.yml`)

`nerdFontsVersion: "3"`, Catppuccin Mocha border/selection colors, and:
```yaml
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never --features=lazygit
```
(the `--features=lazygit` picks up the single-column override from gitconfig).

## 6. starship (`~/.config/starship.toml`)

`add_newline = false`. Format: directory → git branch/status → dotnet → nodejs →
cmd_duration → newline → character. Directory bold cyan, truncation 4, full repo path.
Git branch `git:` prefix bold purple; status bold yellow. `.NET ` / `node ` version
segments. cmd_duration only above 1.5s. Prompt char `>` green/red.

## 7. superfile (`~/Library/Application Support/superfile/`)

My file manager (`spf`). Install `brew install superfile`; config lives in
`config.toml` + `hotkeys.toml` under that dir. Key settings:
`theme = "catppuccin-mocha"`, `nerdfont = true` + `show_select_icons = true`,
`code_previewer = "bat"` (bat, not the builtin chroma), `cd_on_quit = true` (paired with
the `spf` shell function from §2.7), `zoxide_support = true`,
`transparent_background = true` (matches the Ghostty opacity). File previews on
(`default_open_file_preview`, `show_image_preview`, `show_panel_footer_info`),
`default_sort_type = 4` (natural), `file_panel_extra_columns = 2`, sidebar with
`home / pinned / disks`. Hotkeys are left at defaults.

## 8. Neovim

Clone the LazyVim starter into `~/.config/nvim`, remove its `.git`, run headless plugin
sync. On top of the starter I keep a transparent background (`lua/plugins/transparent.lua`
— tokyonight `transparent = true`, transparent sidebars/floats) so the Ghostty
opacity/blur shows through; the rest I customize in-repo per machine.

## 9. herdr (`~/.config/herdr/config.toml`)

Install via `brew install herdr` (tap: `herdr`). It's a tmux-like terminal workspace
manager for AI coding agents. No standalone tmux config on this machine — herdr is the
terminal multiplexer. Keybindings:
- `theme.name = "catppuccin"` (Mocha).
- `keys.prefix = "ctrl+b"` (herdr's own default — `ctrl+a` would shadow zsh's
  `beginning-of-line` and vim's number-increment, with no tmux habit to justify it).
- `focus_pane_{left,down,up,right} = prefix+{h,j,k,l}` — vim-style pane focus (herdr's
  default already, pinned explicitly so it survives upstream default changes).
- `split_horizontal = prefix+minus`, `split_vertical = prefix+v` (default mnemonic —
  herdr only documents minus/comma/ampersand/plus/backtick as named punctuation keys,
  so pipe/bar isn't reliably bindable for a `|` split key).
- `new_tab = prefix+c`.
- `reload_config = prefix+shift+r` (plain `prefix+r` is already `resize_mode`).
- `[[keys.command]]` popup: `prefix+alt+g` opens `lazygit` in an 80%x80% popup.
- `ui.accent = "#89b4fa"` (Catppuccin Mocha blue) — same accent lazygit uses.

After editing config.toml: `herdr config check` to validate, `herdr server
reload-config` to apply without restarting the session.

This is also the remote-access story: the `tailscale` formula puts this Mac on the tailnet
(MagicDNS name `mac`), so I ssh in from the phone with no port-forwarding and
`herdr session attach default` picks up the very session running on the desktop.

## 10. pi coding agent (`~/.pi/agent/`)

Install via `brew install pi-coding-agent` (cask/formula name, binary is `pi`). Multi-provider
terminal coding agent — Claude Code stays the daily driver for Claude models; pi is for
everything else (Codex, NVIDIA, and whatever gets added later).

- **Theme**: `~/.pi/agent/themes/catppuccin-mocha.json`, set as `"theme"` in
  `settings.json`. Full Mocha palette, **accent = blue `#89b4fa`** — same accent lazygit
  and herdr use, kept consistent on purpose. Syntax colors follow the official Catppuccin
  style guide (keywords=mauve, strings=green, functions=blue, numbers=peach, types=yellow).
- **Packages** (`settings.json` → `packages`, npm unless noted):
  - `pi-multi-account` — multi-account rotation/failover pools, managed via the `/subs`
    and `/pool` TUI commands inside pi, not config files. Currently pinned to
    `git:github.com/lfoscari/pi-multi-account@9366f48` (a fork commit): the npm release
    crashes on load because `@earendil-works/pi-ai` ≥0.80.10 dropped the OAuth runtime
    exports. Swap back to `npm:pi-multi-account` once upstream PR #4 is merged+published.
  - `@narumitw/pi-plan-mode` — Codex-like read-only `/plan` mode before any file edit.
  - `@narumitw/pi-starship` — native TOML statusline in starship's style.
  - `pi-web-access` — web search/fetch (Exa MCP, zero-config, no API key needed).
  - `@upstash/context7-pi` — Context7 docs lookup (`resolve-library-id`/`query-docs`),
    same service as the Context7 MCP used elsewhere.
  - `@tintinweb/pi-subagents` — Claude-Code-style sub-agents (parallel, in-process).
  - `~/.vibe-island/pi-extension` — menu-bar status (pre-existing, unrelated to the above).
- **Custom extension**: `~/.pi/agent/extensions/herdr-subagent-bridge.ts` — bridges
  pi-subagents lifecycle events (start/complete/fail) to herdr, since subagents run
  in-process (no separate PID/pane to hand herdr directly). Reports each subagent as a
  tracked agent on the current pane (`herdr pane report-agent`) plus a toast
  (`herdr notification show`). No-ops if herdr isn't running.

### herdr integration

```
herdr integration install pi
herdr integration install claude
herdr integration install codex
```
Gives all three agent CLIs live state tracking in herdr's sidebar and pane borders.
Plan mode gets its own popup, bound like the existing lazygit one:
```toml
[[keys.command]]
key = "prefix+alt+p"
type = "popup"
command = "pi --plan"
width = "80%"
height = "80%"
```

## 11. Not in scope for this repo

Don't recreate or track: IDE settings (they sync through their own accounts), anything
holding a secret (see `~/.zshrc.local`), and per-project runtime pins.

## 12. Verification

- new Ghostty window: font/theme right, background is translucent+blurred (opacity 0.85),
  F12 quick terminal works
- `spf` launches: Catppuccin theme, Nerd Font icons, bat file previews, translucent
  background; navigate somewhere and quit with `Q` — the shell cd's to that dir
- `time zsh -i -c exit` < 0.5s, no compinit warnings
- tab completion shows fzf-tab with previews; ctrl-r opens atuin; ctrl-t previews files
- `lg` in any repo: diff is single-column with line numbers; `git diff` in a wide
  terminal: side-by-side
- `git -C <work-repo> config user.email` returns the work identity; a repo outside the
  source roots returns `none@local.invalid`
- `btop`, `fastfetch`, `bbrew` launch; `mise ls` lists node/go/rust/dotnet, and
  `dotnet --list-sdks` (both 8 + 10 from mise's dotnet-root) and `node -v` resolve
- `herdr config check` reports ok; inside herdr, `ctrl+b` then `h/j/k/l` moves focus
  between panes and `ctrl+b alt+g` pops open lazygit; `ctrl+b alt+p` pops open pi in
  Plan mode
- `pi` launches with the Catppuccin Mocha theme (blue accent); `herdr integration status`
  shows `pi`, `claude`, `codex` all `current`
