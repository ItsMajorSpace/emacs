# Emacs Configuration

This repository contains a modern Emacs 31+ configuration tailored for software development, utilizing native features and declarative package management.

## Core Setup
- **Package Manager**: `straight.el` with `use-package`.
- **Initialization**: `init.el` requires the files in `modules/`:
  - `init-core.el` defaults and global keys, `init-ui.el`, `init-completion.el`
  - `init-editor.el` editing, formatting, projects and perspectives
  - `init-prog.el` generic tooling: tree-sitter, flymake, eglot, dape
  - `init-lang.el` one section per language: mode, language server, debugger, keys
  - `init-tools.el` magit, docker, agent-shell, logs
  - `init-org.el` org, journal, pomodoro, org-roam
- **Minimum Version**: Emacs 31 (uses built-in `treesit`, `eglot`, `which-key`, `editorconfig` and Emacs 31 window/eldoc commands).

## Features & Packages

### UI & Aesthetics
- **Theme**: `doom-gruvbox`.
- **UI Enhancements**: `spacious-padding` for clean window layouts, disabled scrollbars and toolbars.
- **Font**: Iosevka Nerd Font Mono.

### Completion & Navigation
- **Minibuffer**: `vertico` (vertical completion), `orderless` (pattern matching), `marginalia` (annotations), `consult` (enhanced search/navigation), `embark` (context actions).
- **In-buffer Completion**: `corfu` (completion popup) and `cape` (completion at point extensions), powered by built-in `capf`.
- **Snippets**: `yasnippet` and `yasnippet-snippets`.

### Development & Languages
- **Syntax Highlighting**: Built-in tree-sitter (`treesit`) with native major modes (`*-ts-mode`). Auto-installs missing grammars. Supported out-of-the-box: TypeScript, JavaScript, HTML, CSS, JSON, YAML, Go, C, C#, Astro, Dockerfile.
- **Language Server Protocol (LSP)**: `eglot` (built-in). Pre-configured for C, C#, Go, TypeScript, HTML/CSS, JSON, YAML, Dockerfile/Compose, Angular, Razor, Astro, and Dart/Flutter.
- **Debugging (DAP)**: `dape`. Configured for .NET Core (`netcoredbg`), Go (`dlv`), Node.js/Next.js (`js-debug`), and Flutter (`flutter debug_adapter`).
- **Diagnostics**: Built-in `flymake`.
- **Formatting**: `apheleia` (asynchronous, cursor-preserving formatting).
- **Dart/Flutter**: `dart-mode` with `dart language-server` via eglot, `flutter.el` for hot reload/restart, devices and tests (`C-c f`). Needs `dart` and `flutter` on `PATH`.
- **Project Management**: built-in `project.el` (`C-x p` / `C-c p`) combined with `perspective` (`persp-mode`); switching projects (`C-c p p`) opens a perspective per project.

### Git & Org
- **Version Control**: `magit` and `forge`.
- **Org-mode**: `modules/init-org.el` including custom agenda views, capture templates, time tracking, and Azure DevOps integration.

## Installation

1. Ensure Emacs 31+ is installed.
2. Clone this repository to the user config directory:
   ```bash
   git clone <repository-url> ~/.config/emacs
   ```
3. Ensure you have a working C compiler (or `zig`) in your `PATH` for compiling tree-sitter grammars.
4. On first launch, `straight.el` will bootstrap and install all packages automatically.

## Notes
- Custom variables are saved to `custom-vars.el`.
- Language servers and debug adapters must be installed externally (e.g., via `npm` or `dotnet tool`).
