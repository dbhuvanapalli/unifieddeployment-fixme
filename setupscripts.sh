#!/bin/bash

rgName="$1"
prefix="$2"
clusterName="$3"
msiResoruceId="$4"
subscriptionId="$5"

echo "az login with managed identity"
az login --identity --username $msiResoruceId
az account set --subscription $subscriptionId

echo "installing dependencies"
apk update 
apk add wget unzip curl dpkg dotnet-sdk-6.0 aspnetcore-runtime-6.0
#apk add ca-certificates libc6 libgcc-s1 libgssapi-krb5-2 libicu70 liblttng-ust1 libssl3 libstdc++6 libunwind zlib1g
apk add ca-certificates gcc libssl3 libunwind icu-libs icu-dev

#export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0

echo "installing sqlpackage"
apk add dotnet-sdk-6.0 aspnetcore-runtime-6.0
dotnet tool install -g microsoft.sqlpackage
export PATH="$PATH:/root/.dotnet/tools"

echo "installing kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

echo "installing kubelogin"
az aks install-cli
export KUBECONFIG=/path/to/kubeconfig

echo "deploy sql scripts"
sqlpackage /Action:Publish /SourceFile:"./fix.me.sql.dacpac" /TargetConnectionString:"$AZURESQLDB_CONN_STR"

echo "create appsettings.json file with sql connection string"
sed -i "s/PLACEHOLDER/$AZURESQLDB_CONN_STR/" ./appsettings.json

az aks get-credentials --resource-group $rgName --name $clusterName #switch context to aks cluster
msiClientId=$(az identity show --ids $msiResoruceId --query clientId --output tsv)
kubelogin convert-kubeconfig -l msi --client-id $msiClientId

echo "create namespace and deploy fixmeapi and fixmeweb"
kubectl create namespace "fixme"
kubectl create secret generic "sqlconnectionstring" --from-literal=sql-connection-string="$AZURESQLDB_CONN_STR" --namespace "fixme"
kubectl apply -f ./deploy-fixmeapi.yml --namespace "fixme"
kubectl apply -f ./deploy-fixmeweb.yml --namespace "fixme"

sleep 20s
