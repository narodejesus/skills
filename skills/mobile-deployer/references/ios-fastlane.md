# iOS Fastlane Reference

## Fastfile Template

Generate this file at `{ios_fastlane_dir}/Fastfile`. Substitute all `{{PLACEHOLDERS}}` with gathered values.

```ruby
default_platform(:ios)

API_KEY_ID = "{{API_KEY_ID}}"
ISSUER_ID = "{{ISSUER_ID}}"
API_KEY_PATH = "fastlane/AuthKey_{{API_KEY_ID}}.p8"
APP_IDENTIFIER = "{{APP_IDENTIFIER}}"
MATCH_KEYCHAIN_NAME = "{{MATCH_KEYCHAIN_NAME}}"
MATCH_KEYCHAIN_PASSWORD = "{{MATCH_KEYCHAIN_PASSWORD}}"

platform :ios do
  private_lane :app_store_connect_api_credentials do
    app_store_connect_api_key(
      key_id: API_KEY_ID,
      issuer_id: ISSUER_ID,
      key_filepath: API_KEY_PATH
    )
  end

  private_lane :prepare_signing_keychain do
    delete_keychain(name: MATCH_KEYCHAIN_NAME) if File.exist?(File.expand_path("~/Library/Keychains/#{MATCH_KEYCHAIN_NAME}-db"))
    create_keychain(
      name: MATCH_KEYCHAIN_NAME,
      password: MATCH_KEYCHAIN_PASSWORD,
      default_keychain: true,
      unlock: true,
      timeout: 3600,
      lock_when_sleeps: false
    )
  end

  private_lane :sync_signing do
    prepare_signing_keychain
    match(
      type: "appstore",
      api_key: app_store_connect_api_credentials,
      keychain_name: MATCH_KEYCHAIN_NAME,
      keychain_password: MATCH_KEYCHAIN_PASSWORD,
      readonly: ENV["MATCH_READONLY"] == "true"
    )
  end

  desc "Run iOS unit tests"
  lane :test do
    scan(
      {{PROJECT_TYPE}}: "{{PROJECT_FILE}}",
      scheme: "{{SCHEME}}",
      devices: ["{{SIMULATOR_DEVICE}}"]
    )
  end

  desc "Build iOS app for simulator (no signing needed)"
  lane :build_simulator do
    build_app(
      {{PROJECT_TYPE}}: "{{PROJECT_FILE}}",
      scheme: "{{SCHEME}}",
      configuration: "Debug",
      destination: "generic/platform=iOS Simulator",
      skip_package_ipa: true,
      skip_archive: true
    )
  end

  desc "Archive iOS app for App Store distribution"
  lane :build_release do
    sync_signing
    profile_name = ENV["sigh_#{APP_IDENTIFIER}_appstore_profile-name"]
    build_app(
      {{PROJECT_TYPE}}: "{{PROJECT_FILE}}",
      scheme: "{{SCHEME}}",
      configuration: "Release",
      destination: "generic/platform=iOS",
      export_method: "app-store",
      codesigning_identity: "Apple Distribution",
      xcargs: "CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM={{TEAM_ID}} PROVISIONING_PROFILE_SPECIFIER='#{profile_name}'",
      export_options: {
        provisioningProfiles: {
          APP_IDENTIFIER => profile_name
        }
      }
    )
  end

  desc "Increment build number, archive, and upload to TestFlight"
  lane :beta do
    build_number = increment_build_number(
      xcodeproj: "{{XCODEPROJ_FILE}}"
    )
    UI.message("Created iOS build number #{build_number}")
    build_release
    upload_to_testflight(
      api_key: app_store_connect_api_credentials,
      skip_waiting_for_build_processing: false
    )
    UI.success("TestFlight processing finished for build #{build_number}")
  end
end
```

### Placeholder Reference

| Placeholder | Example | Where to find |
|---|---|---|
| `{{API_KEY_ID}}` | `84SY78WP85` | App Store Connect → API Keys |
| `{{ISSUER_ID}}` | `b038bb97-...` | App Store Connect → API Keys |
| `{{APP_IDENTIFIER}}` | `com.company.appname` | Xcode → Target → General |
| `{{TEAM_ID}}` | `3XM7W52JJK` | developer.apple.com → Membership |
| `{{MATCH_KEYCHAIN_NAME}}` | `myapp-fastlane` | Choose any unique name |
| `{{MATCH_KEYCHAIN_PASSWORD}}` | `myapp-fastlane-pass` | Choose any password |
| `{{PROJECT_TYPE}}` | `project` or `workspace` | `.xcodeproj` → `project`, `.xcworkspace` → `workspace` |
| `{{PROJECT_FILE}}` | `MyApp.xcodeproj` | Filename of the project/workspace |
| `{{XCODEPROJ_FILE}}` | `MyApp.xcodeproj` | Always the `.xcodeproj` file (even for workspace projects) |
| `{{SCHEME}}` | `MyApp` | Xcode → Product → Scheme |
| `{{SIMULATOR_DEVICE}}` | `iPhone 16` | Any Xcode simulator name |

### Notes on `{{PROJECT_TYPE}}`

- Use `project:` if the project uses **no CocoaPods** (just a `.xcodeproj`)
- Use `workspace:` if the project uses **CocoaPods or SwiftPM workspace** (`.xcworkspace`)
- `increment_build_number` always uses `xcodeproj:` regardless

---

## Appfile Template

Generate at `{ios_fastlane_dir}/Appfile`:

```ruby
app_identifier("{{APP_IDENTIFIER}}")
apple_id(ENV.fetch("FASTLANE_APPLE_ID", ""))
team_id("{{TEAM_ID}}")
itc_team_id(ENV["ITC_TEAM_ID"] || "")
```

---

## Matchfile Template

Generate at `{ios_fastlane_dir}/Matchfile`:

```ruby
git_url(ENV.fetch("MATCH_GIT_URL"))

storage_mode("git")
type("appstore")
app_identifier(["{{APP_IDENTIFIER}}"])
team_id("{{TEAM_ID}}")

readonly(ENV["MATCH_READONLY"] == "true")
generate_apple_certs(true)
skip_provisioning_profiles(false)
force_legacy_encryption(true)
```

**`force_legacy_encryption(true)`** ensures compatibility with older Fastlane versions and avoids OpenSSL issues on some macOS versions.

---

## .env Template

Generate at `{ios_fastlane_dir}/.env`:

```
MATCH_GIT_URL={{MATCH_GIT_URL}}
MATCH_PASSWORD={{MATCH_PASSWORD}}
```

**Never commit this file.** It is loaded automatically by Fastlane when running lanes from the `fastlane/` directory.

---

## How Match Works

Match stores encrypted iOS certificates and provisioning profiles in a git repository. On each build:

1. Fastlane clones the Match git repo
2. Decrypts the certificates using `MATCH_PASSWORD`
3. Installs them into a temporary macOS keychain (`MATCH_KEYCHAIN_NAME`)
4. Xcode picks up the signing identity from that keychain

**First run** (`bundle exec fastlane match appstore`):
- Connects to App Store Connect via the API key
- Generates a new Apple Distribution certificate (if none exists)
- Generates a provisioning profile for the app ID
- Encrypts both and pushes to the Match git repo

**Subsequent runs** (`readonly: true` on CI):
- Just downloads and decrypts existing certs — no Apple API writes

### Match Storage Options

| Option | `MATCH_GIT_URL` format | Notes |
|---|---|---|
| GitHub private repo | `https://github.com/user/repo.git` | Recommended; use PAT or SSH |
| Local git repo | `/absolute/path/to/signing` | Good for solo devs; no remote needed |
| SSH GitHub | `git@github.com:user/repo.git` | Requires SSH key configured |

---

## Troubleshooting

**"Certificate has been revoked"** — someone else regenerated certs; run `match appstore --force` to regenerate and re-push.

**"No provisioning profiles found"** — the app ID may not be registered; run `match appstore` (not readonly) to create it.

**"User interaction is not allowed"** — keychain is locked; the `prepare_signing_keychain` lane handles this by creating a temporary unlocked keychain.

**Xcode ignores the signing config** — ensure `CODE_SIGN_STYLE=Manual` is in `xcargs`; automatic signing overrides match.
