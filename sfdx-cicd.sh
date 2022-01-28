#!/bin/bash
set -o errexit -o pipefail -o noclobber -o nounset

# Download sfdx binary and setup
wget -q $SFDX_DOWNLOAD_URL
mkdir ~/sfdx-cli
tar xJf sfdx-linux-x64.tar.xz -C ~/sfdx-cli --strip-components 1
export PATH=~/sfdx-cli/bin:$PATH

# Install sfpowerkit
echo 'y' | sfdx plugins:install sfpowerkit


VALIDATE_ONLY=`echo $VALIDATE_ONLY | tr '[:upper:]' '[:lower:]'`
echo $VALIDATE_ONLY
if [[ $VALIDATE_ONLY = true ]]; then
  VALIDATE_FLAG='-c';
elif [[ $VALIDATE_ONLY = false ]]; then
  VALIDATE_FLAG='';
else
  echo "Bad Validate param...choose true or false"
  exit 2
fi

TEST_LEVEL=`echo $TEST_LEVEL | tr '[:upper:]' '[:lower:]'`
if [[ $TEST_LEVEL = 'runspecifiedtests' ]]; then
  TEST_LEVEL='--testlevel RunSpecifiedTests';
elif [[ $TEST_LEVEL = 'runlocaltests' ]]; then
  TEST_LEVEL='--testlevel RunLocalTests';
elif [[ $TEST_LEVEL = 'notestrun' ]]; then
  TEST_LEVEL='--testlevel NoTestRun';
else 
  TEST_LEVEL='';
  echo "Setting testlevel to run org defaults. RunLocalTests for Prod, NoTestRun for Sandbox"
fi

SPECIFIED_TESTS=`echo $SPECIFIED_TESTS | tr -d ' '`
echo 'Test Level: ' $TEST_LEVEL 'specificTest: ' $SPECIFIED_TESTS
if [[ $TEST_LEVEL = '--testlevel RunSpecifiedTests' ]]; then
  SPECIFIED_TESTS="--runtests $SPECIFIED_TESTS";
else
  SPECIFIED_TESTS='';
fi

# Auth sfdx into org with auth url
echo $SFDX_AUTH_URL > sfdx_auth.txt
sfdx force:auth:sfdxurl:store -f sfdx_auth.txt -s -a SFOrg
rm sfdx_auth.txt

echo "sfdx diff command: sfdx sfpowerkit:project:diff -r $REVISION_FROM -t $REVISION_TO -d diffdeploy"
# Prepare diff
sfdx sfpowerkit:project:diff -r $REVISION_FROM -t $REVISION_TO -d diffdeploy

echo "sfdx deploy command: sfdx force:source:deploy -p diffdeploy/force-app -u SFOrg --json --loglevel fatal $VALIDATE_FLAG $TEST_LEVEL $SPECIFIED_TESTS --apiversion=$API_VERSION"
# Deploy diff
sfdx force:source:deploy -p diffdeploy/force-app -u SFOrg --json --loglevel fatal $VALIDATE_FLAG $TEST_LEVEL $SPECIFIED_TESTS --apiversion=$API_VERSION