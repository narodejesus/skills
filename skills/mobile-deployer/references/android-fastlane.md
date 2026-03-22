# Android Fastlane Reference

## Fastfile Template

Generate at `android/fastlane/Fastfile`. Substitute all `{{PLACEHOLDERS}}`.

```ruby
default_platform(:android)

ANDROID_AAB_PATH = "app/build/outputs/bundle/release/app-release.aab"

platform :android do
  before_all do
    gradle(task: "clean")
  end

  desc "Run Android unit tests"
  lane :test do
    gradle(task: "test")
  end

  desc "Build debug APK"
  lane :build_debug do
    gradle(task: "assembleDebug")
  end

  desc "Build signed release APK"
  lane :build_release do
    gradle(task: "assembleRelease")
  end

  desc "Build signed release AAB"
  lane :build_bundle do
    gradle(task: "bundleRelease")
  end

  desc "Increment version code and build release AAB"
  lane :beta do
    increment_version_code(
      gradle_file_path: "{{GRADLE_FILE_PATH}}"
    )
    build_bundle
  end

  desc "Upload release AAB to Google Play internal track"
  lane :deploy_internal do
    build_bundle
    upload_to_play_store(
      track: "internal",
      aab: ANDROID_AAB_PATH,
      json_key: ENV["SUPPLY_JSON_KEY"],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      release_status: "draft"
    )
  end

  desc "Upload release AAB to Google Play closed beta track"
  lane :deploy_beta do
    build_bundle
    upload_to_play_store(
      track: "beta",
      aab: ANDROID_AAB_PATH,
      json_key: ENV["SUPPLY_JSON_KEY"],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      release_status: "draft"
    )
  end

  desc "Upload release AAB to Google Play production track"
  lane :deploy_production do
    build_bundle
    upload_to_play_store(
      track: "production",
      aab: ANDROID_AAB_PATH,
      json_key: ENV["SUPPLY_JSON_KEY"],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      release_status: "draft"
    )
  end
end
```

### Placeholder Reference

| Placeholder | Example | Notes |
|---|---|---|
| `{{GRADLE_FILE_PATH}}` | `app/build.gradle.kts` | Path from `android/` directory |

---

## Appfile Template

Generate at `android/fastlane/Appfile`:

```ruby
json_key_file(ENV.fetch("SUPPLY_JSON_KEY", ""))
package_name("{{PACKAGE_NAME}}")
```

The `SUPPLY_JSON_KEY` env var should point to the Google Play service account JSON key file. Set it in the shell before running Fastlane:

```bash
export SUPPLY_JSON_KEY=/path/to/google-play-key.json
```

---

## Lane Explanations

### `beta`
Increments the `versionCode` in `build.gradle.kts` automatically, then builds a release AAB. Use this before deploying to keep version codes sequential.

### `deploy_internal` / `deploy_beta` / `deploy_production`
Each lane builds a fresh AAB and uploads to the corresponding Play Store track with `release_status: "draft"` — meaning the release won't go live automatically. You still need to manually promote in Play Console. Remove `release_status: "draft"` to publish immediately.

### `before_all`
Runs `gradle clean` before every lane to ensure a fresh build state.

---

## Google Play JSON Key Setup

If the user doesn't have a JSON key yet:

1. Go to [Google Play Console](https://play.google.com/console) → Setup → API access
2. Link to a Google Cloud project (or create one)
3. Click "Create new service account" → follow the Google Cloud Console link
4. In Google Cloud Console → IAM & Admin → Service Accounts → Create service account
5. After creating, go back to Play Console and grant the service account "Release Manager" permissions
6. In Google Cloud Console, create a JSON key for the service account and download it
7. Store the JSON file securely — add its path to `SUPPLY_JSON_KEY`

---

## Troubleshooting

**"Google Play API: release not found"** — the app must already exist in Play Console (at least uploaded once manually) before `upload_to_play_store` can work.

**"Version code already exists"** — run `beta` lane to auto-increment, or manually bump `versionCode` in `build.gradle.kts`.

**"APK/AAB is not signed"** — the signing config is missing from `build.gradle.kts`; see `references/android-signing.md`.
