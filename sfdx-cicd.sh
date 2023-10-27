#!/bin/bash
set -o errexit -o pipefail -o noclobber -o nounset
export PATH=($pwd)/node_modules/.bin:$PATH

# Install sfpowerkit (only if missing)
if [[ -z $(sf plugins | grep sfpowerkit) ]]; then
  echo 'y' | sf plugins install sfpowerkit
fi

# Set logging level
SF_LOG_LEVEL='fatal'

# Auth sfdx into org with auth url
# Generate this with:
#  sf org display --verbose --json (pass in sfdxAuthUrl value starting with force:// )
echo $SFDX_AUTH_URL > sfdx_auth.txt
sf org login sfdx-url --sfdx-url-file sfdx_auth.txt --set-default --alias SFOrg
rm sfdx_auth.txt

echo "sfdx diff command: sf sfpowerkit project diff -r $REVISION_FROM -t $REVISION_TO -d diffdeploy"
# Prepare diff
sf sfpowerkit project diff -r $REVISION_FROM -t $REVISION_TO -d diffdeploy

# Set Validate_only flag
VALIDATE_ONLY=`echo $VALIDATE_ONLY | tr '[:upper:]' '[:lower:]'`
if [[ $VALIDATE_ONLY = true ]]; then
  VALIDATE_FLAG='--dry-run'
elif [[ $VALIDATE_ONLY = false ]]; then
  VALIDATE_FLAG=''
else
  echo "Bad Validate param...choose true or false"
  exit 2
fi

# Set Test_Level (or use org default)
TEST_LEVEL=`echo $TEST_LEVEL | tr '[:upper:]' '[:lower:]'`
if [[ $TEST_LEVEL = 'runspecifiedtests' ]]; then
  TEST_LEVEL='--test-level RunSpecifiedTests'
elif [[ $TEST_LEVEL = 'runlocaltests' ]]; then
  TEST_LEVEL='--test-level RunLocalTests'
elif [[ $TEST_LEVEL = 'notestrun' ]]; then
  TEST_LEVEL='--test-level NoTestRun'
else 
  TEST_LEVEL=''
  echo "Setting test-level to run org defaults. RunLocalTests for Prod, NoTestRun for Sandbox"
fi

# If RunSpecifiedTests Test_Level, parse the tests requested
SPECIFIED_TESTS=`echo $SPECIFIED_TESTS | tr -d ' '`
if [[ $TEST_LEVEL = '--test-level RunSpecifiedTests' ]]; then
  SPECIFIED_TESTS="--tests $SPECIFIED_TESTS"
else
  SPECIFIED_TESTS=''
fi

# Check if API_VERSION was specified
if [[ $API_VERSION != '' ]]; then
  API_VERSION="--api-version=$API_VERSION"
fi

# Deploy diff
echo "sfdx deploy command: sf project deploy start --source-dir diffdeploy/force-app --target-org SFOrg --json $VALIDATE_FLAG $TEST_LEVEL $SPECIFIED_TESTS $API_VERSION"
sf project deploy start --source-dir diffdeploy/force-app --target-org SFOrg --json $VALIDATE_FLAG $TEST_LEVEL $SPECIFIED_TESTS $API_VERSION