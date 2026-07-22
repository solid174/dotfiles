# Fresh Linux setup — agent prompt

You are an agent on a fresh Linux machine (distro unknown in advance — could be a
desktop, a VM, a WSL instance, or a headless server). Recreate my environment. This plan
is deliberately abstract and self-contained: detect the context, map it to my vibe, and
translate the specifics yourself. Ask before anything destructive.

## Vibe

- **Catppuccin Mocha** everywhere: terminal, bat, delta, fzf, LS_COLORS (vivid), lazygit.
- **JetBrainsMono Nerd Font** (skip fonts on headless).
- Preference order: **good TUI > GUI > bare CLI** — lazygit, lazydocker, btop,
  one-letter aliases (`lg`, `ld`).
- **fzf with previews** in tab completion (fzf-tab), ctrl-t, ctrl-r (atuin).
- Minimal fast starship prompt; zsh startup under ~0.5s.
- Secrets only in `~/.zshrc.local` (chmod 600), never in tracked files.
- No version pins — current stable. Project SDK versions are per-project concerns.

## 1. Detect and choose

- Identify distro + package manager (apt/dnf/pacman/zypper). If the distro's repos ship
  stale versions of the core CLI tools, prefer **Homebrew on Linux** for the tool layer
  and keep the system PM for system things — decide and tell me what you picked.
- Headless vs desktop: skip terminal-emulator/GUI/font steps on headless.

## 2. Core tool layer

Install (names vary per distro — e.g. `bat`→`batcat`, `fd`→`fd-find` on Debian; fix
with aliases or symlinks so canonical names work):

`zsh git gh neovim lazygit lazydocker btop atuin bat eza fd ripgrep fzf zoxide jq
git-delta starship vivid direnv fastfetch uv tree-sitter-cli shfmt stylua superfile`

(`superfile` may be stale/absent in distro repos — prefer Homebrew-on-Linux
`brew install superfile` or the official install script if so.)

plus zsh plugins: `zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf-tab`
(package or git-clone, whatever the distro supports cleanly).

Node via a fast version manager (fnm preferred over nvm). .NET SDK via the distro's
supported channel or Microsoft's install script.

Make zsh the login shell.

## 3. Configs — same shape as my other machines

**zsh** (`~/.zshrc`), blocks in order: env (EDITOR=nvim, dotnet telemetry opt-out) →
vivid LS_COLORS + BAT_THEME Mocha → fzf defaults (fd-based, Mocha colors, 60% height,
right-side preview: eza for dirs, bat for files) → compinit with 24h dump-age check
(full rebuild if stale, `-C` otherwise) → fzf-tab with previews → history options
(share, dedupe, 100k) → emacs keybinds + alt-word-jumps → aliases (eza `ll`/`la`/`ls`,
`cat`=bat, `grep`=rg, `lg`, `ld`, `tree`=eza --tree) → cdpath project jumps (ask my
source layout) → tool inits (fnm, fzf, zoxide, starship, direnv) → source
`~/.zshrc.local` if present → autosuggestions → syntax-highlighting →
`atuin init zsh --disable-ai` (keep `?` unhijacked; `atuin import auto` if history
exists).

**git**: global identity = `No Name <none@local.invalid>` guard; real identities via
`includeIf gitdir:` per work/hobby source roots (ask me for emails). pull.rebase,
push.autoSetupRemote, defaultBranch main, zdiff3 conflicts, colorMoved, pretty one-line
log, delta pager with `syntax-theme = Catppuccin Mocha` and side-by-side in a *feature*
section (`[delta] features = wide-view` + `[delta "wide-view"] side-by-side = true` +
`[delta "lazygit"] side-by-side = false`) — never in the main section, main overrides
features. See .gitconfig file for details.

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

## 4. Desktop only (skip on headless)

- Terminal: Ghostty if packaged for the distro, otherwise WezTerm/kitty — Mocha theme,
  JetBrainsMono Nerd Font 14, light padding. Transparency is deliberate: background
  opacity ~0.85 + a little blur (like my Mac), so nvim/superfile transparent backgrounds
  show through. Keybinds: new tab / close, split right + down, arrows to navigate panes,
  zoom-pane toggle.
- Browser, Claude + Claude Code, VS Code / Rider as needed — ask what this machine is for.
- Docker: engine + compose plugin (no Docker Desktop), user in docker group.
- Tailscale via official script if this machine should join the tailnet — ask.

## 5. Verification

- `time zsh -i -c exit` < 0.5s, no compinit/compaudit warnings
- tab completion = fzf-tab with previews; ctrl-r = atuin; icons render (desktop)
- `lg` diff single-column; `git diff` side-by-side in a wide terminal
- identity: work/hobby repos resolve real emails, elsewhere placeholder
- `spf` launches with Catppuccin theme + icons + previews; quit with `Q` cd's the shell
- `btop`, `fastfetch` run; `node -v`, `dotnet --list-sdks` (if installed) resolve
- headless: everything above minus GUI still holds over ssh
