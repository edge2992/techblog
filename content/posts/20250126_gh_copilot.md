---
title: "gh copilotでshellコマンドをCLI上で補完/説明してくれる"
author: ["えじっさ"]
date: 2025-01-26T02:01:09+09:00
tags: ["zsh", "copilot", "dotfile"]
images:
  - "img/og/20250126_gh_copilot.png"
categories: ["zsh", "copilot"]
draft: false
---

Github CLIのghコマンドの拡張機能で、shellコマンドをcopilotで補完/説明してくれる機能がある。
曖昧なコマンドを検索せずにターミナル内でコマンドを生成できるので便利だった。

## 事前準備

ghコマンドを[インストール](https://github.com/cli/cli#installation)しておく。

copilotのextensionをインストールしておく。

```bash
gh extension install github/gh-copilot
```

## alias登録

gh copilotには主にコマンド生成(suggest)とコマンド説明(explain)の2つの機能がある。

aliasを登録しておくことでgh copilot suggest と gh copilot explain の代わりに ghcs と ghce を実行できる。

https://docs.github.com/ja/copilot/managing-copilot/configure-personal-settings/configuring-github-copilot-in-the-cli

以下を.zshrcや.bashrcに追記しておく。

```bash
# Check if `gh` is installed and `gh-copilot` extension is available
# gh extension install github/gh-copilot
if command -v gh >/dev/null 2>&1 && gh extension list | grep -q 'gh-copilot'; then
  eval "$(gh copilot alias zsh)"
else
  echo "gh or gh-copilot is not installed. Skipping copilot alias."
fi
```

### 使用例

favicon.icoを検索するコマンドを生成する。

#### Suggest

```bash
$ ghcs

Welcome to GitHub Copilot in the CLI!
version 1.0.6 (2025-01-06)

I'm powered by AI, so surprises and mistakes are possible. Make sure to verify any generated code or suggestions, and share feedback so that we can learn and improve. For more information, see https://gh.io/gh-copilot-transparency

? What would you like the shell command to do?
> find favicon.ico

Suggestion:

  find . -name "favicon.ico"

? Select an option  [Use arrows to move, type to filter]
> Copy command to clipboard
  Explain command
  Execute command
  Revise command
  Rate response
  Exit
```

Executeをするとコマンドが実行される。Explainをするとコマンドの説明が表示される。

```bash
? Select an option
> Explain command

Explanation:

  • find is used to search for files and directories.
    • . specifies the directory to start the search from.
    • -name "favicon.ico" specifies that we are searching for files with the name "favicon.ico".
```

### Explain

hugo serverの説明を表示する。

```bash
$ ghce

Welcome to GitHub Copilot in the CLI!
version 1.0.6 (2025-01-06)

I'm powered by AI, so surprises and mistakes are possible. Make sure to verify any generated code or suggestions, and share feedback so that we can learn and improve. For more information, see https://gh.io/gh-copilot-transparency

? Which command would you like to explain?
> hugo server

Explanation:

  • hugo is a static site generator.
    • server is a sub-command of hugo that starts a local web server to serve the generated site.
      • The server provides a live preview of the site during development.
      • It watches for changes in the source files and automatically rebuilds and refreshes the preview.
```

## まとめ

あれってどうやってやるんだっけ？というときに便利そう。
historyを永続化して、fzfで検索しても見つからないときに使えそう。
