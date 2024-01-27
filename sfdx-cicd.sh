#!/bin/bash
set -o errexit -o pipefail -o noclobber -o nounset
export PATH=$(pwd)/node_modules/.bin:$PATH
sf version

# Ensure we're linked to sfdx-git-delta
sf plugins link node_modules/sfdx-git-delta
sf plugins

# Set the default logging level
SF_LOG_LEVEL='info'

# Auth sfdx into org with auth url
# Generate this with:
#  sf org display --verbose --json (pass in sfdxAuthUrl value starting with force:// )
echo $SFDX_AUTH_URL > sfdx_auth.txt
sf org login sfdx-url --sfdx-url-file sfdx_auth.txt --set-default --alias SFOrg
rm sfdx_auth.txt

echo "Diff creation command: sf sgd source delta --to $REVISION_TO --from $REVISION_FROM --output diffdeploy/ --generate-delta --source force-app/"
# Prepare diff
rm -rf diffdeploy
mkdir diffdeploy
sf sgd source delta --to $REVISION_TO --from $REVISION_FROM --output diffdeploy/ --generate-delta --source force-app/

# If debugging, output the delta file system and package.xml
if [[ $DEBUG_LOGGING = true ]]; then
  # Raise logging level
  SF_LOG_LEVEL='debug'

  # Output the directory tree
  echo "Diff directory contents:"
  echo "------------------------"
  ls -lR diffdeploy/
  echo ""

  # Output the package.xml
  echo "Package.xml contents:"
  echo "------------------------"
  cat diffdeploy/package/package.xml
  echo ""
  
  # Also display the destructive changes package.xml if it exists
  if test -f diffdeploy/destructiveChanges/package.xml; then
    echo ""
    echo "Destructive changes package.xml:"
    echo "------------------------"
    cat diffdeploy/destructiveChanges/package.xml
    echo ""
    echo "Destructive changes destructiveChanges.xml:"
    echo "------------------------"
    cat diffdeploy/destructiveChanges/destructiveChanges.xml
    echo ""
  fi
fi

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
  echo "INFO: API_VERSION $API_VERSION specified. will use that unless overridden by sfdx-project.json sourceApiVersion"
  API_VERSION="--api-version=$API_VERSION"
else
  echo "WARN: API_VERSION not specified. Will use sourceApiVersion from sfdx-project.json, or current latest API version if that is unavailable"
fi

# Deploy diff
echo "sfdx deploy command: sf project deploy start --source-dir diffdeploy/force-app --target-org SFOrg --json $VALIDATE_FLAG $TEST_LEVEL $SPECIFIED_TESTS $API_VERSION"
sf project deploy start --source-dir diffdeploy/force-app --target-org SFOrg --json $VALIDATE_FLAG $TEST_LEVEL $SPECIFIED_TESTS $API_VERSION
