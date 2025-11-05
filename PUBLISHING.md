# Publishing Guide

This document describes how to publish `shard_i18n` to pub.dev using our automated CI/CD pipeline.

## Prerequisites

1. **pub.dev Account**: You need a verified pub.dev account
2. **Package Ownership**: You must be added as an uploader for the `shard_i18n` package
3. **GitHub Repository Access**: Push access to the repository

## One-Time Setup

### 1. Enable Automated Publishing on pub.dev

The package uses **OpenID Connect (OIDC)** for secure, automated publishing from GitHub Actions without storing credentials.

**Steps:**

1. Go to https://pub.dev
2. Sign in with your Google account
3. Navigate to the `shard_i18n` package page (after initial manual publish)
4. Go to **Admin** tab → **Automated publishing**
5. Click **Enable publishing from GitHub Actions**
6. Follow the instructions to link your GitHub repository

**Note:** The first version (v0.1.0) must be published manually to create the package on pub.dev.

### 2. First Manual Publication

Before automated publishing works, you need to publish the first version manually:

```bash
# 1. Ensure you're logged in to pub.dev
dart pub login

# 2. Verify the package is ready
dart pub publish --dry-run

# 3. Publish the package
dart pub publish
```

After the first manual publish:
- The package will exist on pub.dev
- You can enable automated publishing in the Admin panel
- Future versions will be published automatically via GitHub Actions

## Publishing a New Version

Once automated publishing is set up, releasing a new version is simple:

### 1. Update Version

Update the version in three places:

**pubspec.yaml:**
```yaml
version: 0.2.0  # Update to new version
```

**CHANGELOG.md:**
```markdown
## [0.2.0] - 2025-01-15

### Added
- New feature description

### Fixed
- Bug fix description
```

**README.md** (if needed):
Update version references in installation instructions.

### 2. Commit Changes

```bash
git add pubspec.yaml CHANGELOG.md README.md
git commit -m "chore: bump version to 0.2.0"
git push origin main
```

### 3. Create and Push Tag

```bash
# Create an annotated tag
git tag -a v0.2.0 -m "Release version 0.2.0"

# Push the tag to GitHub
git push origin v0.2.0
```

### 4. Automated Publication

Once you push the tag:

1. GitHub Actions automatically triggers the publish workflow
2. The workflow runs tests and analysis
3. If all checks pass, the package is published to pub.dev
4. You'll receive a notification of success/failure

**Monitor the workflow:**
- Go to: https://github.com/moinsen-dev/shard_i18n/actions
- View the "Publish to pub.dev" workflow run
- Check logs if there are any issues

## Workflow Details

### CI Workflow (`.github/workflows/ci.yml`)

Runs on every push and pull request to `main`/`develop`:
- ✅ Code formatting check (`dart format`)
- ✅ Static analysis with strict mode (`flutter analyze --fatal-infos`)
- ✅ Unit tests with coverage (`flutter test --coverage`)
- ✅ Example app analysis
- ✅ Dry-run publish check

**Optimizations:**
- ⚡ Flutter SDK caching (30-50% faster runs)
- ⚡ Pub dependency caching
- 📌 Pinned Flutter version (3.24.5) for reproducibility

### Publish Workflow (`.github/workflows/publish.yml`)

Runs when you push a version tag (e.g., `v0.1.0`):
- ✅ Uses **official dart-lang reusable workflow**
- ✅ Maintained by the Dart team
- ✅ Automatic OIDC authentication
- ✅ Built-in validation and checks
- ✅ Handles edge cases and best practices

**Note:** This workflow is much simpler and more reliable than custom implementations. The Dart team maintains it and ensures compatibility with pub.dev changes.

## Version Numbering

Follow [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** version (1.0.0): Breaking changes
- **MINOR** version (0.2.0): New features, backward compatible
- **PATCH** version (0.1.1): Bug fixes, backward compatible

**Pre-release versions:**
- Beta: `0.2.0-beta.1`
- Alpha: `0.2.0-alpha.1`
- Release candidate: `0.2.0-rc.1`

## Troubleshooting

### "Package already exists" Error

If you try to publish manually before enabling automated publishing:
- The first version must be published manually
- Enable automated publishing in pub.dev Admin panel
- Future versions will be automated

### GitHub Actions Permission Error

If you see "OIDC token validation failed":
1. Ensure automated publishing is enabled on pub.dev
2. Verify the GitHub repository URL matches exactly
3. Check that `id-token: write` permission is set in workflow

### Tag Already Exists

If you need to re-release a version:
```bash
# Delete local tag
git tag -d v0.2.0

# Delete remote tag
git push origin :refs/tags/v0.2.0

# Create new tag
git tag -a v0.2.0 -m "Release version 0.2.0"
git push origin v0.2.0
```

### Workflow Fails on Tests

If the publish workflow fails:
1. Check the Actions logs for specific error
2. Run tests locally: `flutter test`
3. Fix issues and create a new patch version
4. Don't push failed version tags to pub.dev

## Best Practices

1. **Always run locally first:**
   ```bash
   dart format .
   flutter analyze
   flutter test
   dart pub publish --dry-run
   ```

2. **Test the example app:**
   ```bash
   cd example
   flutter pub get
   flutter run
   ```

3. **Update documentation:**
   - Keep CHANGELOG.md up-to-date
   - Update README.md if API changes
   - Add migration notes for breaking changes

4. **Use meaningful commit messages:**
   ```
   feat: add new translation feature
   fix: resolve plural form issue for Russian
   docs: update installation instructions
   chore: bump version to 0.2.0
   ```

5. **Create GitHub Releases:**
   After automated publish succeeds, create a GitHub release:
   - Go to https://github.com/moinsen-dev/shard_i18n/releases/new
   - Select the tag you just pushed
   - Copy content from CHANGELOG.md
   - Add any additional release notes

## Security

- **Never commit pub.dev credentials** to the repository
- **Use OIDC authentication** (automated via GitHub Actions)
- **Review all code** before publishing
- **Enable 2FA** on your pub.dev account

## Support

If you encounter issues with publishing:
- Check [pub.dev documentation](https://dart.dev/tools/pub/automated-publishing)
- Review [GitHub Actions logs](https://github.com/moinsen-dev/shard_i18n/actions)
- Contact package maintainers

---

**Quick Reference:**

```bash
# Publishing checklist
1. Update pubspec.yaml version
2. Update CHANGELOG.md
3. git commit -m "chore: bump version to X.Y.Z"
4. git push
5. git tag -a vX.Y.Z -m "Release version X.Y.Z"
6. git push origin vX.Y.Z
7. Monitor GitHub Actions
8. Create GitHub Release (optional)
```
