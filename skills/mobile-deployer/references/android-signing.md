# Android Signing Configuration

## Generate a Release Keystore

If the user doesn't have a keystore yet, generate one with `keytool` (ships with JDK):

```bash
keytool -genkey -v \
  -keystore android/release-keystore.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias {{KEY_ALIAS}}
```

You'll be prompted to enter:
- Store password (use `{{STORE_PASSWORD}}`)
- Key password (use `{{KEY_PASSWORD}}` — can be the same as store password)
- Distinguished name fields (CN, OU, O, L, ST, C) — these can be anything

**Important:** Keep the `.jks` file and passwords backed up. If lost, you cannot update the app on Google Play.

---

## keystore.properties Template

Create `android/keystore.properties` (one level up from `app/`):

```properties
storeFile=../release-keystore.jks
storePassword={{STORE_PASSWORD}}
keyAlias={{KEY_ALIAS}}
keyPassword={{KEY_PASSWORD}}
```

The `storeFile` path is relative to the `app/` directory (where `build.gradle.kts` lives).

---

## build.gradle.kts — Kotlin DSL Signing Config

Add these blocks to `android/app/build.gradle.kts`. The file must already have `android { }` block.

**1. At the very top of the file (before `plugins {`):**

```kotlin
import java.util.Properties
```

**2. After the `plugins { }` block and before `android { }`:**

```kotlin
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
```

**3. Inside the `android { }` block, before `buildTypes { }`:**

```kotlin
signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }
}
```

**4. Inside `buildTypes { release { } }`**, add after `proguardFiles(...)`:

```kotlin
if (keystorePropertiesFile.exists()) {
    signingConfig = signingConfigs.getByName("release")
}
```

### Full Example of the android { } block

```kotlin
android {
    namespace = "{{PACKAGE_NAME}}"
    compileSdk = 36

    defaultConfig {
        applicationId = "{{PACKAGE_NAME}}"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}
```

---

## build.gradle — Groovy DSL Signing Config

For projects using `android/app/build.gradle` (not `.kts`):

**1. At the top of the file, before `android { }`:**

```groovy
def keystorePropertiesFile = rootProject.file("keystore.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

**2. Inside `android { }`, before `buildTypes { }`:**

```groovy
signingConfigs {
    release {
        if (keystorePropertiesFile.exists()) {
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
        }
    }
}
```

**3. Inside `buildTypes { release { } }`:**

```groovy
if (keystorePropertiesFile.exists()) {
    signingConfig signingConfigs.release
}
```

---

## Checking for Existing Signing Config

Before modifying `build.gradle.kts`, check if `signingConfigs` already exists:

```bash
grep -n "signingConfigs" android/app/build.gradle.kts
```

- If found → ask user whether to overwrite or skip
- If not found → proceed with inserting the blocks above

---

## .gitignore Entries

Add to the project root `.gitignore`:

```gitignore
# Android signing secrets — never commit these
android/keystore.properties
android/release-keystore.jks
android/**/*-key.json
android/**/google-play*.json
```

---

## Troubleshooting

**"Keystore was tampered with, or password was incorrect"** — wrong `storePassword` in `keystore.properties`.

**"Failed to find keystore file"** — the `storeFile` path in `keystore.properties` is wrong; it's relative to `app/`, so `../release-keystore.jks` means `android/release-keystore.jks`.

**"Release build not signed"** — ensure `signingConfig` is set inside `buildTypes { release { } }`, not just defined in `signingConfigs { }`.
