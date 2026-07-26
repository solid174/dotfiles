# Fresh Windows setup — agent prompt

You are an agent on a fresh (or reset) Windows machine. Recreate my environment with
**scoop** as the package manager. Same vibe as my Mac (see below), translated to Windows
idioms — where a tool has no Windows build, install the closest equivalent and tell me.
This prompt is self-contained — everything you need is here. Work top to bottom, verify
each block. Ask before anything destructive.

## Vibe

- **Catppuccin Mocha** everywhere: terminal scheme, bat, delta, fzf, lazygit, superfile,
  pi.
- **JetBrainsMono Nerd Font** in the terminal.
- Preference order: **good TUI > GUI > bare CLI** — lazygit, btop-equivalent, superfile
  (`spf`), one-letter aliases.
- **fzf with previews** wired into the shell.
- Minimal fast starship prompt. Secrets in an untracked local profile file, never in
  the main profile.
- No version pins: current stable everything. Project-specific SDK versions are the
  project's concern (`global.json`, `mise.toml`), not this setup.
- Runtimes are **mise**'s job, not scoop's (see §2).
- IDE settings are not tracked in this repo — shell/CLI/TUI config only.
- Secrets and local-only wrappers stay out of this repo; document the *shape*, not the
  contents.

## 1. scoop + packages

Install scoop, add buckets: `main extras nerd-fonts`.

Core: `pwsh git gh lazygit delta bat eza fd ripgrep fzf zoxide jq neovim starship
bottom mise uv shfmt stylua wezterm superfile`

- `pwsh` must be the **latest** PowerShell, not the built-in Windows PowerShell 5.
- `bottom` (`btm`) is the btop stand-in — btop4win is unmaintained, don't bother.
- No `fnm`, no `nodejs`, no `dotnet-sdk` here — mise owns runtimes (§2).

Font: `JetBrainsMono-NF` from the nerd-fonts bucket.

GUI apps (scoop extras where available, otherwise winget/direct): browser of choice,
Claude + Claude Code, VS Code, OBS, Transmission-like client, AnyDesk, Tailscale.
Docker: Docker Desktop or WSL2 engine — ask me which this machine needs.

## 2. mise — runtimes and global env

Same single source of runtime truth as my other machines: node, go, rust, dotnet.
`~/.config/mise/config.toml` (mise reads that path on Windows too):

```toml
[tools]
node = "24"
go   = "1.26"
rust = "stable"
# Both .NET SDKs share one dotnet-root so the single `dotnet` muxer resolves each repo's
# global.json natively. Do NOT enable idiomatic global.json — mise would read the pin
# literally, fail to match an install, and drop dotnet from PATH.
dotnet = ["10", "8.0.129"]

[env]
EDITOR = "nvim"
VISUAL = "nvim"
DOTNET_CLI_TELEMETRY_OPTOUT = "1"
```

Then `mise install`, and activate in `$PROFILE` (§3.8). Python stays outside mise —
`uv python install <ver> --default` provides it.

mise's Windows support is younger than its Unix side. If runtime resolution misbehaves
(shims not picked up, dotnet muxer not finding a `global.json`), fall back to scoop's
`fnm` + `dotnet-sdk` for this machine only — and tell me, don't silently switch.

## 3. Shell: latest PowerShell, full add-on kit

Configure `$PROFILE` (pwsh, not Windows PowerShell 5) with all the usual quality-of-life
modules — this shell should feel as complete as a tuned zsh:

1. Env: `$env:EDITOR = "nvim"` (mise's `[env]` covers most of it; PATH-ish bits here).
2. **PSReadLine** (latest): predictive IntelliSense from history (ListView),
   emacs-ish editing keys, history search on up/down when typing a prefix.
3. **PSFzf**: ctrl-t (file picker with bat preview) and ctrl-r bindings.
   (atuin has no PowerShell support — PSFzf + PSReadLine history is the equivalent.)
4. **Terminal-Icons**: icons in Get-ChildItem output.
5. **CompletionPredictor** + native completers for the tools that ship them
   (`gh completion`, `starship`, dotnet CLI tab completion, etc.).
6. **posh-git** for git tab completion (prompt itself stays starship).
7. Aliases/functions: `ll`/`la`/`ls` → eza (icons, group-directories-first, git),
   `cat`→bat, `lg`→lazygit, `tree`→`eza --tree --icons=auto`, `..`/`...`,
   `codex`→`codex --yolo`. (No `grep`→rg alias here — it would shadow nothing useful and
   PowerShell's `Select-String` idioms differ; use `rg` directly.)
8. Tool inits: `zoxide init pwsh`, `starship init powershell`, `mise activate pwsh`.
9. Project jumping: zoxide + superfile Pins only. Deliberately no per-repo functions and
   no path-list tricks — they duplicate the pins and go stale.
10. Secrets: dot-source `$HOME\.profile.local.ps1` if it exists; create it and ask me
    what goes in. Never write secret values into $PROFILE itself.

If you find other well-maintained pwsh add-ons that fit the vibe, propose them.

## 4. Terminal: WezTerm

WezTerm as the terminal (`~/.wezterm.lua`): Catppuccin Mocha color scheme,
JetBrainsMono Nerd Font 14, light window padding, background opacity ~0.85 (deliberate
translucency, like my Mac — lets nvim/superfile transparent backgrounds show through),
latest pwsh as the default program, tab bar tidy (no fancy plugins needed), keybinds:
ctrl+shift+t/w tabs, ctrl+shift+d / ctrl+shift+alt+d splits, ctrl+shift+arrows pane
navigation, a zoom-pane toggle.

WezTerm's own panes are the multiplexer here — `herdr` (what I use on macOS/Linux) has no
native Windows build. If I need herdr on this machine, it goes inside WSL2 (§7); ask.

## 5. git

Copy `.gitconfig` from this repo — it's the source of truth for every machine (pager
delta, pretty one-line log, pull.rebase, push.autoSetupRemote, defaultBranch main, zdiff3,
colorMoved, aliases `st/co/sw/br/cm/amend/lg`). The Windows-specific and non-obvious bits:

- Global identity `No Name <none@local.invalid>` is a deliberate guard forcing
  per-directory identity. Real name/email live in `.gitconfig` files inside the work and
  hobby source roots, pulled in by `includeIf "gitdir/i:<src-root>/work/"` and
  `.../hobby/` — note the **`/i:`** (case-insensitive) form on Windows. Source layout is a
  dedicated drive/folder like `D:/src/work`, `D:/src/hobby` — confirm with me before
  writing paths. Ask me for the emails; never set a global real identity.
- `core.ignorecase = false` and `core.autocrlf = input` are intentional, keep them.
- delta side-by-side goes in a **feature**, never in the main `[delta]` section — main
  overrides features and silently breaks lazygit's single-column opt-out:
  ```ini
  [delta]
      features = wide-view
  [delta "wide-view"]
      side-by-side = true
  [delta "lazygit"]
      side-by-side = false
  ```
- lazygit config: nerdFontsVersion "3", Catppuccin Mocha colors, pager
  `delta --dark --paging=never --features=lazygit`.

## 6. superfile — file manager

Same file manager as my Mac/Linux (`spf`), so keep the config identical to those machines:

- `scoop install superfile` (or `winget install --id yorukot.superfile`). Preview/runtime
  deps that make it shine: `bat fd ripgrep fzf zoxide` (already in §1).
- Config lives in `%LOCALAPPDATA%\superfile\` (`config.toml` + `hotkeys.toml`). Key
  settings: `theme = "catppuccin-mocha"`, `nerdfont = true` + `show_select_icons`,
  `code_previewer = "bat"`, `zoxide_support = true`, `transparent_background = true`
  (matches the WezTerm opacity), previews on, `default_sort_type = 4` (natural),
  `file_panel_extra_columns = 2`, sidebar `home/pinned/disks`. Hotkeys stay default.
- **Shell integration** (`cd_on_quit = true`): a `spf` function in $PROFILE so quitting
  with `Q` cd's the shell to the last dir — run `spf` (the binary), then read the
  `cd`-line superfile writes to its `lastdir` file under `%LOCALAPPDATA%\superfile\` and
  `Set-Location` to it. Don't capture stdout — TUI escapes would garble the screen.
- Editor opens in nvim (`editor` inherits `$EDITOR`).

## 7. Neovim

Clone LazyVim starter into `$env:LOCALAPPDATA\nvim`, remove `.git`, headless sync.
Make sure `win32yank`/clipboard works and treesitter compiles (needs a C compiler —
`scoop install gcc` or zig if anything fails). Keep the transparent background
(tokyonight `transparent = true`, transparent sidebars/floats) so the WezTerm opacity
shows through.

## 8. Agent CLIs

- **Claude Code**, **codex** (aliased `--yolo`), **opencode**, **pi** (Catppuccin Mocha
  theme, blue `#89b4fa` accent to match lazygit). Ask which ones this machine needs.

## 9. Optional: WSL2

If I say this machine needs Linux tooling: enable WSL2 + Ubuntu, then build an
equivalent zsh environment inside it by following `setup-linux.md` from this repo (same
vibe: zsh + starship + fzf-tab + atuin + eza/bat/fd/rg/delta/lazygit + mise + herdr,
Catppuccin Mocha).

## 10. Verification

- WezTerm: Mocha scheme, Nerd Font glyphs render (`eza --icons`, starship
  symbols, lazygit borders); tab/split/zoom keybinds work
- ctrl-r fuzzy history, ctrl-t file picker with preview
- `lg` in a repo: single-column delta diff; `git diff` in a wide window: side-by-side
- `spf` → navigate somewhere → quit with `Q` → shell followed the cd; Catppuccin theme,
  Nerd Font icons, and bat file previews render
- `git config user.email` inside work/hobby roots returns the right identity, elsewhere
  the placeholder
- `mise ls` lists the runtimes; `dotnet --list-sdks` and `node -v` resolve through mise
- `nvim` opens with the LazyVim dashboard
