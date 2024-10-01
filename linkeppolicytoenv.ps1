param(
    [string] [Parameter(Mandatory=$true)] $envId,
    [string] [Parameter(Mandatory=$true)] $policyArmId,
    [string] [Parameter(Mandatory=$true)] $endPoint
)

Connect-AzAccount -Identity
git clone https://github.com/microsoft/PowerApps-Samples.git
cd PowerApps-Samples\powershell\enterprisePolicies\SubnetInjection
.\SubnetInjection.ps1 -envId $envId -policyArmId $policyArmId -endpoint $endPoint
