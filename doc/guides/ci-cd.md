# CI/CD Integration

This guide covers setting up continuous integration and deployment for i18n workflows.

## Overview

A robust CI/CD pipeline for i18n ensures:

- ✅ All keys in code have translations
- ✅ All locales are in sync
- ✅ No orphaned translations
- ✅ Placeholders match between code and JSON
- ✅ Plural forms are properly defined

## GitHub Actions

### Basic Workflow

```yaml
# .github/workflows/i18n.yml
name: i18n Check

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  i18n:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Extract and verify i18n keys
        run: dart run shard_i18n_cli extract --strict --format=json > i18n-report.json

      - name: Verify cross-locale consistency
        run: dart run shard_i18n_cli verify

      - name: Upload i18n report
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: i18n-report
          path: i18n-report.json
```

### With Caching

```yaml
jobs:
  i18n:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1

      - name: Cache Dart packages
        uses: actions/cache@v3
        with:
          path: ~/.pub-cache
          key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
          restore-keys: |
            ${{ runner.os }}-pub-

      - run: dart pub get
      - run: dart run shard_i18n_cli extract --strict
      - run: dart run shard_i18n_cli verify
```

### PR Comment with Results

```yaml
jobs:
  i18n:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1

      - run: dart pub get

      - name: Run i18n check
        id: i18n
        run: |
          OUTPUT=$(dart run shard_i18n_cli extract --format=text 2>&1)
          echo "result<<EOF" >> $GITHUB_OUTPUT
          echo "$OUTPUT" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 🌐 i18n Report\n\`\`\`\n${{ steps.i18n.outputs.result }}\n\`\`\``
            })
```

## GitLab CI

### Basic Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - test

i18n-check:
  stage: test
  image: dart:stable
  script:
    - dart pub get
    - dart run shard_i18n_cli extract --strict --format=json > i18n-report.json
    - dart run shard_i18n_cli verify
  artifacts:
    reports:
      dotenv: i18n-report.json
    when: always
```

### With Multiple Stages

```yaml
stages:
  - validate
  - test
  - deploy

i18n-validate:
  stage: validate
  script:
    - dart pub get
    - dart run shard_i18n_cli extract --strict
  allow_failure: false

i18n-verify:
  stage: validate
  script:
    - dart pub get
    - dart run shard_i18n_cli verify
  needs: [i18n-validate]

test:
  stage: test
  script:
    - flutter test
  needs: [i18n-validate, i18n-verify]
```

## Bitbucket Pipelines

```yaml
# bitbucket-pipelines.yml
image: dart:stable

pipelines:
  default:
    - step:
        name: i18n Check
        caches:
          - pub
        script:
          - dart pub get
          - dart run shard_i18n_cli extract --strict
          - dart run shard_i18n_cli verify

definitions:
  caches:
    pub: ~/.pub-cache
```

## Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UseDotNet@2
    inputs:
      packageType: 'sdk'
      version: '6.x'

  - script: |
      dart pub get
      dart run shard_i18n_cli extract --strict
      dart run shard_i18n_cli verify
    displayName: 'i18n Check'
```

## Pre-commit Hooks

### Using Husky (Node.js)

```json
// package.json
{
  "devDependencies": {
    "husky": "^8.0.0"
  },
  "scripts": {
    "prepare": "husky install"
  }
}
```

```bash
# .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

dart run shard_i18n_cli extract --strict
```

### Using Git Hooks Directly

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Check i18n consistency
echo "Checking i18n consistency..."
dart run shard_i18n_cli extract --strict

if [ $? -ne 0 ]; then
  echo "❌ i18n check failed!"
  echo "Run 'dart run shard_i18n_cli extract' to see details."
  exit 1
fi

echo "✅ i18n check passed"
```

### Using lefthook

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    i18n:
      run: dart run shard_i18n_cli extract --strict
      glob: "*.dart"
    verify:
      run: dart run shard_i18n_cli verify
      glob: "*.json"
```

## Automated Translation Workflow

### On New Keys (GitHub Actions)

```yaml
# .github/workflows/auto-translate.yml
name: Auto Translate

on:
  push:
    paths:
      - 'assets/i18n/en/**'
    branches:
      - develop

jobs:
  translate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1

      - run: dart pub get

      - name: Translate missing keys
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          dart run shard_i18n_cli fill \
            --from=en \
            --to=de,fr,es \
            --provider=openai \
            --key=$OPENAI_API_KEY

      - name: Create PR with translations
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: 'chore(i18n): auto-translate new keys'
          title: '🌐 Auto-translated new keys'
          body: |
            This PR contains automatically translated keys.

            Please review the translations before merging.
          branch: auto-translate
          delete-branch: true
```

### Scheduled Translation Check

```yaml
name: Weekly Translation Sync

on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1

      - run: dart pub get

      - name: Check for missing translations
        run: |
          MISSING=$(dart run shard_i18n_cli extract --format=json | jq '.missingInJson | length')
          if [ "$MISSING" -gt 0 ]; then
            echo "Found $MISSING missing translations"
            # Send notification (Slack, email, etc.)
          fi
```

## Quality Gates

### Fail Build on Issues

```yaml
- name: i18n Quality Gate
  run: |
    RESULT=$(dart run shard_i18n_cli extract --format=json)
    MISSING=$(echo $RESULT | jq '.statistics.missingCount')
    ORPHANED=$(echo $RESULT | jq '.statistics.orphanedCount')

    if [ "$MISSING" -gt 0 ]; then
      echo "❌ Found $MISSING missing translations"
      exit 1
    fi

    if [ "$ORPHANED" -gt 10 ]; then
      echo "⚠️ Found $ORPHANED orphaned keys (threshold: 10)"
      exit 1
    fi

    echo "✅ i18n quality gate passed"
```

### Coverage Threshold

```yaml
- name: Translation Coverage Check
  run: |
    COVERAGE=$(dart run shard_i18n_cli extract --format=json | jq '.statistics.coveragePercent')
    THRESHOLD=95

    if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
      echo "❌ Translation coverage $COVERAGE% is below threshold $THRESHOLD%"
      exit 1
    fi

    echo "✅ Translation coverage: $COVERAGE%"
```

## Notifications

### Slack Notification

```yaml
- name: Notify Slack on i18n Issues
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    fields: repo,message,commit,author
    text: '🌐 i18n check failed! Please review missing translations.'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Email Notification (GitLab)

```yaml
i18n-check:
  script:
    - dart run shard_i18n_cli extract --strict
  after_script:
    - |
      if [ "$CI_JOB_STATUS" == "failed" ]; then
        curl -X POST "https://api.mailgun.net/v3/$DOMAIN/messages" \
          -F "from=CI <ci@$DOMAIN>" \
          -F "to=team@example.com" \
          -F "subject=i18n Check Failed" \
          -F "text=i18n check failed in $CI_PROJECT_NAME"
      fi
```

## Best Practices

### 1. Run Early, Run Often

Check i18n on every commit, not just before release.

### 2. Block Merges on Failures

Configure branch protection to require i18n checks:

```yaml
# GitHub branch protection
status_checks:
  - i18n-check
```

### 3. Keep Translation Files Small

Sharded files are faster to process in CI.

### 4. Cache Dependencies

Always cache `~/.pub-cache` to speed up builds.

### 5. Use JSON Output for Automation

```bash
# Parse with jq for automation
dart run shard_i18n_cli extract --format=json | jq '.statistics'
```

### 6. Separate Validation from Testing

Run i18n checks in parallel with unit tests to save time:

```yaml
jobs:
  i18n:
    runs-on: ubuntu-latest
    # ...

  test:
    runs-on: ubuntu-latest
    # ...
```
