git_url(ENV.fetch("MATCH_GIT_URL"))

storage_mode("git")
type("appstore")
app_identifier(["{{APP_IDENTIFIER}}"])
team_id("{{TEAM_ID}}")

readonly(ENV["MATCH_READONLY"] == "true")
generate_apple_certs(true)
skip_provisioning_profiles(false)
force_legacy_encryption(true)
