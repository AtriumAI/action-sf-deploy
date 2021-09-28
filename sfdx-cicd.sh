# Download sfdx binary and setup
wget https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/stable/sfdx-linux-x64.tar.xz
mkdir ~/sfdx-cli
tar xJf sfdx-linux-x64.tar.xz -C ~/sfdx-cli --strip-components 1
echo "Path 1"
echo $PATH
export PATH=~/sfdx-cli/bin:$PATH
echo "Path 2"
echo $PATH

# Instal sfpowerkit
echo 'y' | sfdx plugins:install sfpowerkit

# Echo test
echo $INPUT_VALIDATE_ONLY

if [[ $INPUT_VALIDATE_ONLY = true ]]; then
  VALIDATE_FLAG='-c';
else
  VALIDATE_FLAG='';
fi

echo $INPUT_SFDX-AUTH-URL > SFDX_AUTH

sfdx force:auth:sfdxurl:store -f SFDX_AUTH -s -a SFOrg

sfdx sfpowerkit:project:diff -r {{ inputs.revision-from }} -t {{ inputs.revision-to }} -d diffdeploy

sfdx force:source:deploy -p diffdeploy/force-app -u SFOrg --json --loglevel fatal -c --apiversion={{ inputs.api-version }}