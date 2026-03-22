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
