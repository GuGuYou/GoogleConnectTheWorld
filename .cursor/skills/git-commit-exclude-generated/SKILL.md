---
name: git-commit-exclude-generated
description: >-
  Exclude Flutter auto-generated plugin registrant files from git commits in
  this repo. Use whenever the user asks to commit, stage changes, create a git
  commit, amend a commit, or prepare a pull request — including following the
  committing-changes-with-git user rule workflow.
---

# Git Commit: Exclude Generated Files

This Flutter project tracks platform plugin registrant files that **Flutter regenerates** on `flutter run`, `flutter build`, or plugin changes. They are **not business code** and must **never** be staged or committed.

## Excluded paths (always skip)

Never `git add`, stage, or commit these 7 paths:

```
linux/flutter/generated_plugin_registrant.cc
linux/flutter/generated_plugin_registrant.h
linux/flutter/generated_plugins.cmake
macos/Flutter/GeneratedPluginRegistrant.swift
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugin_registrant.h
windows/flutter/generated_plugins.cmake
```

## Required workflow (every commit)

Integrate into the standard commit flow **before** `git add`:

1. Run `git status` and note if any excluded paths appear under "Changes not staged" or "Changes to be committed".
2. **Do not** use `git add -A`, `git add .`, or broad globs that would pick up excluded files.
3. Stage **only** intentional business/source files (typically under `lib/`, `test/`, `assets/`, `openspec/`, config the user requested, etc.).
4. Before `git commit`, verify the index is clean of excluded files:

   ```bash
   git diff --cached --name-only
   ```

   If any excluded path appears, unstage it:

   ```bash
   git restore --staged linux/flutter/generated_plugin_registrant.cc linux/flutter/generated_plugin_registrant.h linux/flutter/generated_plugins.cmake macos/Flutter/GeneratedPluginRegistrant.swift windows/flutter/generated_plugin_registrant.cc windows/flutter/generated_plugin_registrant.h windows/flutter/generated_plugins.cmake
   ```

5. Commit as usual. After commit, if `git status` still lists the 7 files as modified, **that is expected** — do not stage them unless the user explicitly asks to commit generated registrants.

## Optional: clean working tree after commit

Only if the user wants a tidy `git status` (not required for commits):

```bash
git restore linux/flutter/generated_plugin_registrant.cc linux/flutter/generated_plugin_registrant.h linux/flutter/generated_plugins.cmake macos/Flutter/GeneratedPluginRegistrant.swift windows/flutter/generated_plugin_registrant.cc windows/flutter/generated_plugin_registrant.h windows/flutter/generated_plugins.cmake
```

Changes will reappear after the next Flutter command; that is normal.

## What counts as business code here

Include: `lib/`, `test/`, `assets/`, `openspec/`, `tool/`, `web/` (except generated maps config if sensitive), `pubspec.yaml`, intentional config/docs.

Exclude by default unless the user explicitly requests them: the 7 paths above, `build/`, `.dart_tool/`, and files under `secrets/` that contain API keys.
