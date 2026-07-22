# Fresh Windows setup — agent prompt

You are an agent on a fresh (or reset) Windows machine. Recreate my environment with
**scoop** as the package manager. Same vibe as my Mac (see below), translated to Windows
idioms — where a tool has no Windows build, install the closest equivalent and tell me.
This prompt is self-contained — everything you need is here. Work top to bottom, verify
each block. Ask before anything destructive.

## Vibe

- **Catppuccin Mocha** everywhere: terminal scheme, bat, delta, fzf, lazygit, superfile.
- **JetBrainsMono Nerd Font** in the terminal.
- Preference order: **good TUI > GUI > bare CLI** — lazygit, btop-equivalent, superfile
  (`spf`), one-letter aliases.
- **fzf with previews** wired into the shell.
- Minimal fast starship prompt. Secrets in an untracked local profile file, never in
  the main profile.
- No version pins: current stable everything. Project-specific SDK versions are the
  project's concern (global.json, .nvmrc), not this setup.

## 1. scoop + packages

Install scoop, add buckets: `main extras nerd-fonts`.

Core: `pwsh git gh lazygit delta bat eza fd ripgrep fzf zoxide jq neovim starship
bottom btop4win fnm uv shfmt stylua dotnet-sdk wezterm superfile`
(bottom/btop4win — pick whichever works better as the btop equivalent; fnm replaces nvm;
`pwsh` must be the **latest** PowerShell, not the built-in Windows PowerShell 5).

Font: `JetBrainsMono-NF` from the nerd-fonts bucket.

GUI apps (scoop extras where available, otherwise winget/direct): browser of choice,
Claude + Claude Code, VS Code, Rider, OBS, Transmission-like client, AnyDesk,
Tailscale. Docker: Docker Desktop or WSL2 engine — ask me which this machine needs.

## 2. Terminal: WezTerm

WezTerm as the terminal (`~/.wezterm.lua`): Catppuccin Mocha color scheme,
JetBrainsMono Nerd Font 14, light window padding, background opacity ~0.85 (deliberate
translucency, like my Mac — lets nvim/superfile transparent backgrounds show through), latest
pwsh as the default program, tab bar tidy (no fancy plugins needed), keybinds:
ctrl+shift+t/w tabs, ctrl+shift+d / ctrl+shift+alt+d splits, ctrl+shift+arrows pane
navigation, a zoom-pane toggle.

## 3. Shell: latest PowerShell, full add-on kit

Configure `$PROFILE` (pwsh, not Windows PowerShell 5) with all the usual quality-of-life
modules — this shell should feel as complete as a tuned zsh:

1. Env: `$env:EDITOR = "nvim"`, `DOTNET_CLI_TELEMETRY_OPTOUT=1`.
2. **PSReadLine** (latest): predictive IntelliSense from history (ListView),
   emacs-ish editing keys, history search on up/down when typing a prefix.
3. **PSFzf**: ctrl-t (file picker with bat preview) and ctrl-r bindings.
   (atuin has no PowerShell support — PSFzf + PSReadLine history is the equivalent.)
4. **Terminal-Icons**: icons in Get-ChildItem output.
5. **CompletionPredictor** + native completers for the tools that ship them
   (`gh completion`, `starship`, dotnet CLI tab completion, etc.).
6. **posh-git** for git tab completion (prompt itself stays starship).
7. Aliases/functions: `ll`/`la`/`ls` → eza (icons, group-directories-first, git),
   `cat`→bat, `lg`→lazygit, `tree`→`eza --tree --icons=auto`, `..`/`...`.
8. Tool inits: `fnm env`, `zoxide init pwsh`, `starship init powershell`.
9. Secrets: dot-source `$HOME\.profile.local.ps1` if it exists; create it and ask me
   what goes in. Never write secret values into $PROFILE itself.

If you find other well-maintained pwsh add-ons that fit the vibe, propose them.

## 4. superfile — file manager

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

## 5. git

Same config as everywhere:

- Global identity = `No Name <none@local.invalid>` (deliberate guard). Per-directory
  identity via `includeIf "gitdir/i:<src-root>/work/"` and `.../hobby/` pointing to
  `.gitconfig` files inside those roots (real name/email there — ask me). Source layout
  on Windows: a dedicated drive/folder like `D:/src/work`, `D:/src/hobby` — confirm with
  me before writing paths. Note: `gitdir/i:` (case-insensitive) on Windows.
- `core.ignorecase=false`, pager delta, `pull.rebase`, `push.autoSetupRemote`,
  `init.defaultBranch=main`, `merge.conflictStyle=zdiff3`, `diff.colorMoved=default`,
  pretty one-line log (yellow hash, dim green date, orange refs, cyan subject).
- delta: line-numbers, navigate, `syntax-theme = Catppuccin Mocha`; side-by-side via a
  feature section (NOT the main `[delta]` section — main overrides features and breaks
  the lazygit opt-out):
  ```ini
  [delta]
      features = wide-view
  [delta "wide-view"]
      side-by-side = true
  [delta "lazygit"]
      side-by-side = false
  ```
- lazygit config: nerdFontsVersion "3", Catppuccin Mocha colors,
  pager `delta --dark --paging=never --features=lazygit`.
- Aliases: st/co/sw/br/cm/amend/lg (same as my other machines).

See .gitconfig file for details.

## 6. Neovim

Clone LazyVim starter into `$env:LOCALAPPDATA\nvim`, remove `.git`, headless sync.
Make sure `win32yank`/clipboard works and treesitter compiles (needs a C compiler —
`scoop install gcc` or zig if anything fails).

## 7. Optional: WSL2

If I say this machine needs Linux tooling: enable WSL2 + Ubuntu, then build an
equivalent zsh environment inside it (same vibe: zsh + starship + fzf-tab + atuin +
eza/bat/fd/rg/delta/lazygit, Catppuccin Mocha).

## 8. Verification

- WezTerm: Mocha scheme, Nerd Font glyphs render (`eza --icons`, starship
  symbols, lazygit borders); tab/split/zoom keybinds work
- ctrl-r fuzzy history, ctrl-t file picker with preview
- `lg` in a repo: single-column delta diff; `git diff` in a wide window: side-by-side
- `spf` → navigate somewhere → quit with `Q` → shell followed the cd; Catppuccin theme,
  Nerd Font icons, and bat file previews render
- `git config user.email` inside work/hobby roots returns the right identity, elsewhere
  the placeholder
- `dotnet --list-sdks`, `node -v` (via fnm), `nvim` opens with LazyVim dashboard
