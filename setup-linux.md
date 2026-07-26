# Fresh Linux setup — agent prompt

You are an agent on a fresh Linux machine (distro unknown in advance — could be a
desktop, a VM, a WSL instance, or a headless server). Recreate my environment. This plan
is deliberately abstract and self-contained: detect the context, map it to my vibe, and
translate the specifics yourself. Ask before anything destructive.

## Vibe

- **Catppuccin Mocha** everywhere: terminal, bat, delta, fzf, LS_COLORS (vivid), lazygit,
  superfile, herdr, pi.
- **JetBrainsMono Nerd Font** (skip fonts on headless).
- Preference order: **good TUI > GUI > bare CLI** — lazygit, lazydocker, btop,
  one-letter aliases (`lg`, `ld`).
- **fzf with previews** in tab completion (fzf-tab), ctrl-t, ctrl-r (atuin).
- Minimal fast starship prompt; zsh startup under ~0.5s (`time zsh -i -c exit`).
- Secrets only in `~/.zshrc.local` (chmod 600), never in tracked files.
- No version pins — current stable. Project SDK versions are per-project concerns
  (`global.json`, `mise.toml`).
- Runtimes are **mise**'s job, never the distro package manager's (see §3).
- IDE settings are not tracked in this repo — shell/CLI/TUI config only.
- Secrets and local-only wrappers stay out of this repo; document the *shape*, not the
  contents.

## 1. Detect and choose

- Identify distro + package manager (apt/dnf/pacman/zypper). If the distro's repos ship
  stale versions of the core CLI tools, prefer **Homebrew on Linux** for the tool layer
  and keep the system PM for system things — decide and tell me what you picked.
- Headless vs desktop: skip terminal-emulator/GUI/font steps on headless.

## 2. Core tool layer

Install (names vary per distro — e.g. `bat`→`batcat`, `fd`→`fd-find` on Debian; fix
with aliases or symlinks so canonical names work):

`zsh git gh neovim lazygit lazydocker btop atuin bat eza fd ripgrep fzf zoxide jq
git-delta starship vivid mise fastfetch uv tree-sitter-cli shfmt stylua superfile`

(`superfile`, `mise` and `herdr` may be stale/absent in distro repos — prefer
Homebrew-on-Linux or the upstream install script for those.)

plus zsh plugins: `zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf-tab`
(package or git-clone, whatever the distro supports cleanly).

Make zsh the login shell.

## 3. mise — runtimes and global env

One binary owns node, go, rust and dotnet; do **not** install those from the distro PM or
brew. mise also replaces direnv for dir-local env. `~/.config/mise/config.toml`:

```toml
[tools]
node = "24"
go   = "1.26"
rust = "stable"          # rustup under the hood; CARGO_HOME=~/.cargo
# Both .NET SDKs share one dotnet-root so the single `dotnet` muxer resolves each repo's
# global.json natively. Do NOT enable idiomatic global.json — mise would read the pin
# literally, fail to match an install, and drop dotnet from PATH.
dotnet = ["10", "8.0.129"]

[env]
EDITOR = "nvim"
VISUAL = "nvim"
PAGER = "less"
LESS = "-FRX"
DOTNET_CLI_TELEMETRY_OPTOUT = "1"
```

Then `mise install`. Plain global env vars live in that `[env]` block, not `~/.zshrc`.
Directory-scoped env goes in a `mise.toml` at the root of the tree it applies to.
Python is deliberately outside mise — `uv` owns it (`uv python install <ver> --default`,
shims in `~/.local/bin`, which must be on PATH).

Drop the .NET block on a headless box that will never build .NET — ask if unsure.

## 4. Configs — same shape as my other machines

**zsh** (`~/.zshrc`), blocks in order: env (`PATH=~/.local/bin:$PATH`, `~/.dotnet/tools`;
non-PATH vars live in mise's `[env]`) → vivid LS_COLORS + BAT_THEME Mocha → fzf defaults
(fd-based, Mocha colors, 60% height, right-side preview: eza for dirs, bat for files) →
compinit with 24h dump-age check (full rebuild if stale, `-C` otherwise) → fzf-tab with
previews → history options (share, dedupe, 100k) → emacs keybinds + alt-word-jumps →
aliases (eza `ll`/`la`/`ls`, `cat`=bat, `grep`=rg, `lg`, `ld`, `tree`=eza --tree) + the
`spf` function → tool inits (fzf, zoxide, starship, `mise activate zsh`) → source
`~/.zshrc.local` if present → `atuin init zsh --disable-ai` (keep `?` unhijacked;
`atuin import auto` if history exists) → autosuggestions → syntax-highlighting **last**
(it only wraps widgets declared before it).

**Project jumping**: superfile Pins + zoxide, nothing else. Deliberately **no `cdpath`**
and no per-repo shell functions — they duplicated the pins and went stale on every move.

**git**: copy `.gitconfig` from this repo — it's the source of truth for every machine.
Two things it can't explain itself:
- Global identity `No Name <none@local.invalid>` is a deliberate guard forcing
  per-directory identity; real name/email live in `.gitconfig` files inside the work and
  hobby source roots, pulled in by `includeIf "gitdir:"`. Ask me for the emails; never set
  a global real identity. Confirm the source layout on this machine before writing paths.
- delta side-by-side goes in a **feature**, never in `[delta]` — main-section values
  override features and silently break lazygit's single-column opt-out:
  `[delta] features = wide-view` + `[delta "wide-view"] side-by-side = true` +
  `[delta "lazygit"] side-by-side = false`.

**lazygit**: nerdFontsVersion "3", Mocha colors, pager
`delta --dark --paging=never --features=lazygit`.

**starship**: add_newline=false; directory → git → dotnet → nodejs → cmd_duration
(>1.5s) → `>` prompt char green/red.

**superfile** (`~/.config/superfile/config.toml` + `hotkeys.toml`): my file manager
(`spf`). `theme = "catppuccin-mocha"`, `nerdfont = true` + `show_select_icons`,
`code_previewer = "bat"`, `cd_on_quit = true`, `zoxide_support = true`,
`transparent_background = true`, previews on, `default_sort_type = 4` (natural),
`file_panel_extra_columns = 2`, sidebar `home/pinned/disks`. cd_on_quit needs a `spf`
shell function: run `command spf`, then `source ~/.config/superfile/lastdir` (never via
`$(...)` — TUI escapes would garble the screen); superfile writes a `cd '/path'` line
there on quit. Hotkeys stay default.

**nvim**: LazyVim starter clone, `.git` removed, headless sync. Ensure a C compiler
exists for treesitter. Keep a transparent background (tokyonight `transparent = true`,
transparent sidebars/floats) so the terminal opacity/blur shows through.

## 5. herdr — terminal multiplexer

`herdr` (tmux-like workspace manager built for AI coding agents) is the multiplexer on my
machines — no standalone tmux config anywhere. Install from upstream (brew-on-Linux or the
official script). `~/.config/herdr/config.toml`:
`theme.name = "catppuccin"`, `keys.prefix = "ctrl+b"` (ctrl+a would shadow zsh
`beginning-of-line`), `focus_pane_{left,down,up,right} = prefix+{h,j,k,l}`,
`split_horizontal = prefix+minus`, `split_vertical = prefix+v`, `new_tab = prefix+c`,
`reload_config = prefix+shift+r` (plain `prefix+r` is `resize_mode`),
`ui.accent = "#89b4fa"`, and a `[[keys.command]]` popup on `prefix+alt+g` running lazygit
at 80%x80%. Validate with `herdr config check`, apply with `herdr server reload-config`.

This is also the remote-access story: ssh in (Tailscale, no port-forwarding) and
`herdr session attach default` picks up the session already running on the desktop.

## 6. Docker / Tailscale (ask first)

- Docker: engine + compose plugin (no Docker Desktop), user in the docker group.
- Tailscale via the official script if this machine should join the tailnet — ask.

## 7. Agent CLIs

Ask which of these this machine needs before installing; on a headless box they're often
the whole point of the machine.

- **Claude Code**, **codex** (aliased `--yolo`), **opencode**, **pi** (Catppuccin Mocha
  theme, blue `#89b4fa` accent to match lazygit/herdr).
- `herdr integration install {claude,codex,pi}` for live agent state in herdr's sidebar.

## 8. Desktop only (skip on headless)

- Terminal: Ghostty if packaged for the distro, otherwise WezTerm/kitty — Mocha theme,
  JetBrainsMono Nerd Font 14, light padding. Transparency is deliberate: background
  opacity ~0.85 + a little blur (like my Mac), so nvim/superfile transparent backgrounds
  show through. Keybinds: new tab / close, split right + down, arrows to navigate panes,
  zoom-pane toggle.
- Browser, Claude desktop, VS Code as needed — ask what this machine is for.

## 9. Verification

- `time zsh -i -c exit` < 0.5s, no compinit/compaudit warnings
- tab completion = fzf-tab with previews; ctrl-r = atuin; icons render (desktop)
- `lg` diff single-column; `git diff` side-by-side in a wide terminal
- identity: work/hobby repos resolve real emails, elsewhere placeholder
- `spf` launches with Catppuccin theme + icons + previews; quit with `Q` cd's the shell
- `btop`, `fastfetch` run; `mise ls` lists the runtimes, `node -v` and
  `dotnet --list-sdks` (if installed) resolve
- `herdr config check` ok; `ctrl+b h/j/k/l` moves pane focus, `ctrl+b alt+g` pops lazygit
- headless: everything above minus GUI still holds over ssh
