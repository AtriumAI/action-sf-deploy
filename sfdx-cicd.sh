# Download sfdx binary and setup
wget -q https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/stable/sfdx-linux-x64.tar.xz
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

echo "Validate flag"
echo $VALIDATE_FLAG

echo $INPUT_SFDX-AUTH-URL > sfdx_auth.txt

sfdx force:auth:sfdxurl:store -f sfdx_auth.txt -s -a SFOrg

rm sfdx_auth.txt

sfdx sfpowerkit:project:diff -r $INPUT_REVISION-FROM -t $INPUT_REVISION-TO -d diffdeploy

sfdx force:source:deploy -p diffdeploy/force-app -u SFOrg --json --loglevel fatal -c --apiversion=$INPUT_API-VERION