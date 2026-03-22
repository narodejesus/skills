# Ruby & Bundler Setup

## Gemfile

Create at the **project root** (not inside `ios/` or `android/`):

```ruby
source "https://rubygems.org"

gem "fastlane", ">= 2.228.0"
```

## .ruby-version

Create at the **project root**:

```
3.3.8
```

This file tells rbenv/rvm which Ruby version to use in this directory. No explanation needed — rbenv reads it automatically.

## Install Dependencies

```bash
cd {project_root}
bundle install
```

This installs Fastlane and all its dependencies into the project's bundle. Always use `bundle exec fastlane` (not just `fastlane`) to ensure the bundled version is used.

## Running Fastlane Lanes

From the platform directory (where `fastlane/` lives):

```bash
# iOS
cd ios/{ProjectName}
bundle exec fastlane ios beta

# Android
cd android
bundle exec fastlane android deploy_production

# Or from project root using relative path
bundle exec fastlane --env ios beta
```

## Vendoring (Optional for CI)

To avoid downloading gems on every CI run:

```bash
bundle install --path vendor/bundle
```

Add to `.gitignore`:
```
vendor/bundle/
.bundle/
```

Add to CI config:
```bash
bundle install --path vendor/bundle --jobs 4 --retry 3
```
