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

  desc "Build iOS app for simulator"
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
