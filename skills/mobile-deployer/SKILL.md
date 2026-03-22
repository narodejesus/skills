---
name: mobile-deployer
description: Onboard a fresh iOS or Android project with a complete Fastlane deployment pipeline. Use this skill whenever the user wants to set up Fastlane from scratch, configure code signing (Match for iOS, keystore for Android), set up TestFlight or Google Play uploads, create CI/CD for a mobile app, generate iOS certificates and provisioning profiles, configure App Store Connect API keys, or automate mobile builds and deployments. Also triggers on mentions of Match setup, fastlane init, mobile release automation, or TestFlight/Play Store configuration.
---

# Mobile Deployer — Fastlane Onboarding

This skill walks through setting up a complete Fastlane deployment pipeline for iOS and/or Android. Work through each step in order, verifying before proceeding.

---

## Step 1: Check Prerequisites

Run these checks before doing anything else. If something is missing, provide the install command and wait for confirmation before continuing.

```bash
ruby --version        # Need 3.0+
bundler --version     # Need bundler installed
xcode-select -p       # iOS only — must return a path
java -version         # Android only
echo $ANDROID_HOME    # Android only — must be set
gh --version          # For Match GitHub repo creation
```

**If missing:**
- Ruby: `brew install rbenv && rbenv install 3.3.8 && rbenv global 3.3.8`
- Bundler: `gem install bundler`
- Xcode CLI: `xcode-select --install`
- gh CLI: `brew install gh && gh auth login`

---

## Step 2: Detect Project Type

Search the project root for these indicators:

| What to look for | Platform |
|---|---|
| `*.xcodeproj` or `*.xcworkspace` | iOS present |
| `android/build.gradle.kts` or `android/build.gradle` | Android present |
| `pubspec.yaml` | Flutter (both platforms) |
| `"react-native"` in `package.json` | React Native (both platforms) |

**Confirm with the user** what was detected, then determine fastlane directory locations:

| Framework | iOS fastlane dir | Android fastlane dir |
|---|---|---|
| Native Swift | `ios/{ProjectName}/fastlane/` | N/A |
| Native Android | N/A | `android/fastlane/` |
| Flutter | `ios/fastlane/` | `android/fastlane/` |
| React Native | `ios/fastlane/` | `android/fastlane/` |

Also identify:
- The `.xcodeproj` or `.xcworkspace` filename (for iOS Fastfile)
- The scheme name (usually matches the project name)
- Whether `build.gradle` uses Kotlin DSL (`.kts`) or Groovy (`.gradle`)

---

## Step 3: Gather Credentials

Collect all needed values before generating any files. Present this as a checklist grouped by platform.

### iOS Credentials

Ask the user for:

1. **Bundle ID** (e.g., `com.company.appname`) — found in Xcode > Target > General
2. **Apple Developer Team ID** — found at [developer.apple.com](https://developer.apple.com) → Account → Membership
3. **Apple ID email** — the developer account email
4. **App Store Connect API Key** — create at App Store Connect → Users and Access → Integrations → API Keys:
   - Key ID (e.g., `84SY78WP85`)
   - Issuer ID (UUID format)
   - Download the `.p8` private key file — **can only be downloaded once**
   - Ask for the local path to the `.p8` file
5. **Match encryption password** — a strong password used to encrypt certs in the repo (store safely in a password manager)
6. **Keychain name** — suggest `{appname}-fastlane` (used during CI builds)
7. **Keychain password** — suggest `{appname}-fastlane-pass`

### iOS Match Storage (Certificate Repository)

Ask the user:

> "Where do you want to store your iOS signing certificates (Match)?
> 1. **New GitHub repo** (recommended) — I'll create a private repo using `gh`
> 2. **Existing GitHub repo** — provide the URL
> 3. **Local git repo** — I'll initialize one on your machine"

**Option 1 — New GitHub repo:**
```bash
gh repo create {app-name}-certificates --private --description "iOS signing certificates for {app-name}" --confirm
# Then get the URL:
gh repo view {app-name}-certificates --json url -q .url
```
Use the HTTPS URL as `MATCH_GIT_URL`.

**Option 2 — Existing repo:** Use the provided URL as-is.

**Option 3 — Local git repo:**
```bash
mkdir -p {ios_fastlane_dir}/.fastlane-match/signing
git init {ios_fastlane_dir}/.fastlane-match/signing
```
Use the absolute path as `MATCH_GIT_URL`.

### Android Credentials

Ask the user for:

1. **Package name** (e.g., `com.company.appname`)
2. **Google Play JSON key** — path to a service account JSON file. If they don't have one, provide these instructions:
   - Google Play Console → Setup → API access → Link to Google Cloud project
   - Google Cloud Console → IAM & Admin → Service Accounts → Create service account
   - Grant "Release Manager" role in Play Console
   - Create JSON key and download it
3. **Release keystore** — ask:
   > "Do you have an existing release keystore (.jks file), or should I generate a new one?"
   - If existing: get path, key alias, store password, key password
   - If new: collect key alias (suggest app name), passwords (suggest same for both), then generate

---

## Step 4: Ruby/Fastlane Setup

Check if `Gemfile` already exists at the project root.

- If it exists and contains `fastlane`, skip this step.
- If it exists but lacks `fastlane`, add the gem to the existing file.
- If it doesn't exist, create it from `templates/Gemfile.tpl`.

Also create `.ruby-version` at project root if missing.

```bash
cd {project_root}
bundle install
```

---

## Step 5: iOS Fastlane Setup

Read `references/ios-fastlane.md` for full template content and explanations.

1. Create the fastlane directory: `mkdir -p {ios_fastlane_dir}`

2. Generate `Fastfile` from `templates/ios/Fastfile.tpl` — substitute all `{{PLACEHOLDERS}}`

3. Generate `Appfile` from `templates/ios/Appfile.tpl`

4. Generate `Matchfile` from `templates/ios/Matchfile.tpl`

5. Generate `.env` from `templates/ios/env.tpl`

6. Copy the `.p8` key file into the fastlane directory:
   ```bash
   cp {p8_source_path} {ios_fastlane_dir}/AuthKey_{{API_KEY_ID}}.p8
   ```

7. **Initialize Match certificates** (see Step 5a below)

8. Add to `.gitignore` at project root:
   ```
   # Fastlane secrets
   **/fastlane/.env
   **/fastlane/*.p8
   **/fastlane/api_key.json
   ios/**/.fastlane-match/
   ```

### Step 5a: Initialize Match Certificates

Match needs the certificate repo initialized before first use.

```bash
cd {ios_fastlane_dir}/..
bundle exec fastlane match init
```

This will prompt for the git URL — enter the `MATCH_GIT_URL` value.

Then **generate the certificates** for the first time:

```bash
bundle exec fastlane match appstore
```

This will:
- Clone the Match git repo
- Generate an Apple Distribution certificate + provisioning profile via App Store Connect API
- Encrypt them with the Match password
- Push to the git repo

If the Apple Developer account hasn't registered the app ID yet, match will create it automatically (requires Apple ID credentials or API key with sufficient permissions).

**Verify certificates were created:**
```bash
bundle exec fastlane match appstore --readonly
```

---

## Step 6: Android Fastlane Setup

Read `references/android-fastlane.md` and `references/android-signing.md` for full details.

1. Create the fastlane directory: `mkdir -p {android_fastlane_dir}`

2. Generate `Fastfile` from `templates/android/Fastfile.tpl`

3. Generate `Appfile` from `templates/android/Appfile.tpl`

4. **Keystore setup:**

   If generating a new keystore:
   ```bash
   keytool -genkey -v \
     -keystore android/release-keystore.jks \
     -keyalg RSA -keysize 2048 \
     -validity 10000 \
     -alias {{KEY_ALIAS}}
   ```
   Enter the store password and key password when prompted.

5. Generate `android/keystore.properties` from `templates/android/keystore.properties.tpl`

6. **Modify `android/app/build.gradle.kts`** to add signing config — read `references/android-signing.md` for the exact Kotlin DSL blocks to insert. Check if `signingConfigs` already exists before modifying.

7. Add to `.gitignore`:
   ```
   # Android signing secrets
   android/keystore.properties
   android/release-keystore.jks
   android/**/*.json
   ```

---

## Step 7: Verify Setup

```bash
# Check lanes are recognized
cd {project_root}
bundle exec fastlane lanes

# iOS — quick smoke test (no network needed)
cd {ios_fastlane_dir}/..
bundle exec fastlane ios build_simulator

# Android — quick smoke test
cd android/
bundle exec fastlane android build_debug
```

Print a summary of all created files and the next steps:
- How to run `fastlane ios beta` for TestFlight
- How to run `fastlane android deploy_internal` for Play Store internal track
- Reminder to store secrets (Match password, keystore passwords) in a password manager

---

## Edge Cases

- **Existing partial setup**: Before creating any file, check if it exists. If so, ask the user whether to overwrite, merge, or skip.
- **Groovy build.gradle**: If the Android project uses `build.gradle` (not `.kts`), use the Groovy signing config from `references/android-signing.md`.
- **Workspace vs project**: If `.xcworkspace` exists (e.g., CocoaPods project), use `workspace:` instead of `project:` in the Fastfile.
- **Match first run errors**: If `match appstore` fails with "certificate not found", ensure the Apple Developer account has accepted the latest agreements at developer.apple.com.
- **`MATCH_READONLY`**: Set `MATCH_READONLY=true` in CI environments so match never tries to regenerate certs.

---

## Reference Files

| File | When to read |
|---|---|
| `references/prerequisites.md` | Troubleshooting missing tools |
| `references/ios-fastlane.md` | iOS Fastfile/Appfile/Matchfile templates + lane explanations |
| `references/android-fastlane.md` | Android Fastfile/Appfile templates + lane explanations |
| `references/android-signing.md` | Keystore generation + build.gradle.kts/Groovy signing config |
| `references/ruby-setup.md` | Gemfile/bundler details |
