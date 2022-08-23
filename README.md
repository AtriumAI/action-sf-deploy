# action-sf-cicd
This is a github action to assist in automating Salesforce deployment. It leverages sfdx and [sfpowerkit](https://github.com/dxatscale/sfpowerkit) to enable 2 main workflows:
1. Validate potential changes against a CI sandbox when a pull request is created or updated.
2. Automatically deploy changes to a CI sandbox when a pull request is merged.

## Validate PR
Info here
### Sample CI Validate config
```yaml
name: CI Validate

on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - master
    paths:
      - 'force-app/**'

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: AtriumAI/action-sf-cicd@v1
        with:
          validate-only: True
          sfdx-auth-url: ${{ secrets.SFDX_AUTH_URL_CI }}
          revision-from: 'origin/main'
          api-version: '55.0'
```

## Deploy PR Merge
Info here

### Sample CI Deploy config
```yaml
name: CI Deploy

on:
  pull_request:
    types: [closed]
    branches:
      - master
    paths:
      - 'force-app/**'

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

jobs:
  deploy:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: AtriumAI/action-sf-cicd@v1
        with:
          validate-only: False
          sfdx-auth-url: ${{ secrets.SFDX_AUTH_URL_CI }}
          revision-from: ${{ github.event.pull_request.base.sha }}
          revision-to: ${{ github.event.pull_request.merge_commit_sha }}
          api-version: '55.0'
```
