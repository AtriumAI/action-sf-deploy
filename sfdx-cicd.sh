#!/bin/bash
set -o errexit -o pipefail -o noclobber -o nounset

# Download sfdx binary and setup
wget -q https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/stable/sfdx-linux-x64.tar.xz
mkdir ~/sfdx-cli
tar xJf sfdx-linux-x64.tar.xz -C ~/sfdx-cli --strip-components 1
export PATH=~/sfdx-cli/bin:$PATH

# Install sfpowerkit
echo 'y' | sfdx plugins:install sfpowerkit

VALIDATE_ONLY=`echo $VALIDATE_ONLY | tr '[:upper:]' '[:lower:]'`
if [[ $VALIDATE_ONLY = true ]]; then
  VALIDATE_FLAG='-c';
elif [[ $VALIDATE_ONLY = false ]]; then
  VALIDATE_FLAG='';
else
  echo "Bad Validate param...choose true or false"
  exit 2
fi

echo "Validate flag"
echo $VALIDATE_FLAG

# Auth sfdx into org with auth url
echo $SFDX_AUTH_URL > sfdx_auth.txt
sfdx force:auth:sfdxurl:store -f sfdx_auth.txt -s -a SFOrg
rm sfdx_auth.txt

# Prepare diff
sfdx sfpowerkit:project:diff -r $REVISION_FROM -t $REVISION_TO -d diffdeploy

# Deploy diff
sfdx force:source:deploy -p diffdeploy/force-app -u SFOrg --json --loglevel fatal $VALIDATE_FLAG --apiversion=$API_VERSION