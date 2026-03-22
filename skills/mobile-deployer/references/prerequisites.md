# Prerequisites

## Required Tools

### All Platforms
| Tool | Check | Install |
|---|---|---|
| Ruby 3.0+ | `ruby --version` | `brew install rbenv && rbenv install 3.3.8 && rbenv global 3.3.8` |
| Bundler | `bundler --version` | `gem install bundler` |
| gh CLI | `gh --version` | `brew install gh` |

### iOS Only
| Tool | Check | Install |
|---|---|---|
| Xcode | Open from Applications | Mac App Store |
| Xcode CLI Tools | `xcode-select -p` | `xcode-select --install` |

### Android Only
| Tool | Check | Install |
|---|---|---|
| JDK 11+ | `java -version` | `brew install openjdk@17` |
| Android SDK | `echo $ANDROID_HOME` | Android Studio → SDK Manager |
| keytool | `keytool -help` | Included with JDK |

---

## rbenv Setup (Recommended)

```bash
brew install rbenv ruby-build
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc
rbenv install 3.3.8
rbenv global 3.3.8
ruby --version  # should show 3.3.8
gem install bundler
```

---

## gh CLI Auth

```bash
gh auth login
# Choose: GitHub.com → HTTPS → Yes → Login with web browser
```

Verify: `gh auth status`

---

## ANDROID_HOME Setup

Add to `~/.zshrc` or `~/.bashrc`:

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

Then `source ~/.zshrc`.

---

## Troubleshooting

**`bundle exec fastlane` crashes with OpenSSL error** — Ruby was compiled against the wrong OpenSSL. Use rbenv with a fresh Ruby install: `rbenv install 3.3.8`.

**`xcode-select: error: tool 'xcodebuild' requires Xcode`** — the full Xcode app is not installed, only the CLI tools. Install Xcode from the App Store, then run `sudo xcode-select -s /Applications/Xcode.app`.

**`ANDROID_HOME not found` during Fastlane run** — add `ANDROID_HOME` to `.zshrc` and ensure it's exported before running `bundle exec fastlane`.

**`keytool: command not found`** — JDK is not installed or not on PATH. After installing: `export PATH=$PATH:/opt/homebrew/opt/openjdk@17/bin`.
