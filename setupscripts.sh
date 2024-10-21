#!/bin/bash

rgName="$1"
prefix="$2"
clusterName="$3"
msiResoruceId="$4"

az login --identity --username $msiResoruceId

echo "executing setup scripts"

apk update 
apk add wget unzip curl dpkg dotnet-sdk-6.0 aspnetcore-runtime-6.0
#apk add ca-certificates libc6 libgcc-s1 libgssapi-krb5-2 libicu70 liblttng-ust1 libssl3 libstdc++6 libunwind zlib1g
apk add ca-certificates gcc libssl3 libunwind icu-libs icu-dev

#export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0

echo "installing kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

echo "installing sqlpackage"
apk add dotnet-sdk-6.0 aspnetcore-runtime-6.0
dotnet tool install -g microsoft.sqlpackage
export PATH="$PATH:/root/.dotnet/tools"

# wget -q http://snapshot.debian.org/archive/debian/20190501T215844Z/pool/main/g/glibc/multiarch-support_2.28-10_amd64.deb && dpkg -i multiarch-support*.deb
# wget -q http://snapshot.debian.org/archive/debian/20170705T160707Z/pool/main/o/openssl/libssl1.0.0_1.0.2l-1%7Ebpo8%2B1_amd64.deb && dpkg -i libssl1.0.0*.deb 
# wget -q http://ftp.us.debian.org/debian/pool/main/i/icu/libicu67_67.1-7_amd64.deb && dpkg -i libicu67_67.1-7_amd64.deb 

# wget -q -O sqlpackage.zip https://go.microsoft.com/fwlink/?linkid=2113331 
# unzip -qq sqlpackage.zip -d /opt/sqlpackage  
# chmod a+x /opt/sqlpackage/sqlpackage 

echo "deploy sql scripts"
echo $AZURESQLDB_CONN_STR

# sqlpackage /Action:Publish /SourceFile:"./fix.me.sql.dacpac" /TargetConnectionString:"$AZURESQLDB_CONN_STR" 2>&1 | tee $AZ_SCRIPTS_OUTPUT_PATH

echo "create appsettings.json file with sql connection string"
sed -i "s/PLACEHOLDER/$AZURESQLDB_CONN_STR/" ./appsettings.json

echo "get aks credentials and set context"
echo $clusterName

az aks get-credentials --resource-group $rgName --name $clusterName --admin
kubectl use-context $clusterName

echo "create namespace and deploy fixmeapi and fixmeweb"
kubectl create namespace "fixme"
kubectl create secret generic "sqlconnectionstring" --from-literal=sql-connection-string="$AZURESQLDB_CONN_STR" --namespace "fixme"
kubectl apply -f ./deploy-fixmeapi.yml --namespace "fixme"
kubectl apply -f ./deploy-fixmeweb.yml --namespace "fixme"

sleep 20s
