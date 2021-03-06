#!/bin/sh

#Script arguments
domainHost=${1}
domainName=${2}
domainUser=${3}
domainPassword=${4}
nodeName=${5}
nodePort=${6}

dbType=${7}
dbName=${8}
dbUser=${9}
dbPassword=${10}
dbHost=${11}
dbPort=${12}

sitekeyKeyword=${13}

joinDomain=${14}
osUserName=${15}

storageName=${16}
storageKey=${17}

domainLicenseURL=${18}

mrsdbusername=${19}
mrsdbpwd=${20}
mrsservicename=${21}
disservicename=${22}


HDIClusterName=${23}
HDIClusterLoginUsername=${24}
HDIClusterLoginPassword=${25}
HDIClusterSSHHostname=${26}
HDIClusterSSHUsername=${27}
HDIClusterSSHPassword=${28}



ambariport=${29}
HIVE_USER_NAME=${30}
HDFS_USER_NAME=${31}
BLAZE_USER=${32}
SPARK_EVENTLOG_DIR=${33}
SPARK_PARAMETER_LIST=${34}
IMPERSONATION_USER=${35}
ZOOKEEPER_HOSTS=${36}
SPARK_HDFS_STAGING_DIR=${37}
HIVE_EXECUTION_MODE=${38}

echo Number of parameters $#
  if [ $# -ne 38 ]
  then
	echo lininfainstaller.sh domainHost domainName domainUser domainPassword nodeName nodePort dbType dbName dbUser dbPassword dbHost dbPort sitekeyKeyword joinDomain  osUserName storageName storageKey domainLicenseURL
	exit -1
  fi


dbaddress=$dbHost:$dbPort
hostname=`hostname`

informaticaopt=/home/$osUserName
#echo "Informatica opt location is:".$informaticaopt
infainstallerloc=$informaticaopt/InstallerFiles/Server
#echo "Installer location:".$infainstallerloc
infainstallionloc=$informaticaopt/Informatica/10.1.1
defaultkeylocation=$infainstallionloc/isp/config/keys
licensekeylocation=$informaticaopt/license.key
#echo "license key location is:".$licensekeylocation


informaticaopt1=\\/home\\/$osUserName
infainstallionloc1=$informaticaopt1\\/Informatica\\/10.1.1
defaultkeylocation1=$infainstallionloc1\\/isp\\/config\\/keys
licensekeylocation1=$informaticaopt1\\/license.key

utilityhome=$informaticaopt/utilites
createDomain=1

JRE_HOME="$infainstallionloc/java/jre"
export JRE_HOME		
PATH="$JRE_HOME/bin":"$PATH"
export PATH
chmod -R 777 $JRE_HOME


updateFirewallsettings()
{
  echo Adding firewall rules for Informatica domain service ports
  iptables -A IN_public_allow -p tcp -m tcp --dport 6005:6008 -m conntrack --ctstate NEW -j ACCEPT
  iptables -A IN_public_allow -p tcp -m tcp --dport 6014:6114 -m conntrack --ctstate NEW -j ACCEPT
  iptables -A IN_public_allow -p tcp -m tcp --dport 18059:18065 -m conntrack --ctstate NEW -j ACCEPT
}

downloadlicense()
{
  cloudsupportenable=1
  if [ "$domainLicenseURL" != "nolicense" -a $joinDomain -eq 0 ]
  then
	cloudsupportenable=0
	cd $utilityhome
	echo Getting Informatica license
	java -jar iadutility.jar downloadHttpUrlFile -url $domainLicenseURL -localpath $informaticaopt/license.key
  fi
}

checkforjoindomain()
{
  if [ $joinDomain -eq 1 ]
   then
	#echo "inside if" >> /home/$osUserName/output.out
    createDomain=0
	# This is buffer time for master node to start
	sleep 600
   else
	#echo "inside else" >> /home/$osUserName/output.out
	cd $utilityhome
    java -jar iadutility.jar createAzureFileShare -storageaccesskey $storageKey -storagename $storageName	
   fi
}

editsilentpropertyfilesforserverinstall()
{
    echo Editing Informatica silent installation file
#echo "License key location is :"$licensekeylocation
sed -i s/^LICENSE_KEY_LOC=.*/LICENSE_KEY_LOC=$licensekeylocation1/ $infainstallerloc/SilentInput.properties

#echo done edition of licnse key
sed -i s/^USER_INSTALL_DIR=.*/USER_INSTALL_DIR=$infainstallionloc1/ $infainstallerloc/SilentInput.properties

sed -i s/^CREATE_DOMAIN=.*/CREATE_DOMAIN=$createDomain/ $infainstallerloc/SilentInput.properties

sed -i s/^JOIN_DOMAIN=.*/JOIN_DOMAIN=$joinDomain/ $infainstallerloc/SilentInput.properties

sed -i s/^CLOUD_SUPPORT_ENABLE=.*/CLOUD_SUPPORT_ENABLE=$cloudsupportenable/ $infainstallerloc/SilentInput.properties

sed -i s/^ENABLE_USAGE_COLLECTION=.*/ENABLE_USAGE_COLLECTION=1/ $infainstallerloc/SilentInput.properties

sed -i s/^KEY_DEST_LOCATION=.*/KEY_DEST_LOCATION=$defaultkeylocation1/ $infainstallerloc/SilentInput.properties

sed -i s/^PASS_PHRASE_PASSWD=.*/PASS_PHRASE_PASSWD=$(echo $sitekeyKeyword | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties

sed -i s/^SERVES_AS_GATEWAY=.*/SERVES_AS_GATEWAY=1/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_TYPE=.*/DB_TYPE=$dbType/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_UNAME=.*/DB_UNAME=$dbUser/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_PASSWD=.*/DB_PASSWD=$(echo $dbPassword | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_SERVICENAME=.*/DB_SERVICENAME=$dbName/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_ADDRESS=.*/DB_ADDRESS=$dbaddress/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_NAME=.*/DOMAIN_NAME=$domainName/ $infainstallerloc/SilentInput.properties

sed -i s/^NODE_NAME=.*/NODE_NAME=$nodeName/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_PORT=.*/DOMAIN_PORT=$nodePort/ $infainstallerloc/SilentInput.properties

sed -i s/^JOIN_NODE_NAME=.*/JOIN_NODE_NAME=$nodeName/ $infainstallerloc/SilentInput.properties

sed -i s/^JOIN_HOST_NAME=.*/JOIN_HOST_NAME=$hostname/ $infainstallerloc/SilentInput.properties

sed -i s/^JOIN_DOMAIN_PORT=.*/JOIN_DOMAIN_PORT=$nodePort/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_USER=.*/DOMAIN_USER=$domainUser/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_HOST_NAME=.*/DOMAIN_HOST_NAME=$domainHost/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_PSSWD=.*/DOMAIN_PSSWD=$(echo $domainPassword | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_CNFRM_PSSWD=.*/DOMAIN_CNFRM_PSSWD=$(echo $domainPassword | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties

sed -i s/^CREATE_SERVICES=.*/CREATE_SERVICES=1/ $infainstallerloc/SilentInput.properties

sed -i s/^MRS_DB_TYPE=.*/MRS_DB_TYPE=$dbType/ $infainstallerloc/SilentInput.properties
sed -i s/^MRS_DB_UNAME=.*/MRS_DB_UNAME=$mrsdbusername/ $infainstallerloc/SilentInput.properties
sed -i s/^MRS_DB_PASSWD=.*/MRS_DB_PASSWD=$(echo $mrsdbpwd | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties
sed -i s/^MRS_DB_SERVICENAME=.*/MRS_DB_SERVICENAME=$dbName/ $infainstallerloc/SilentInput.properties
sed -i s/^MRS_DB_ADDRESS=.*/MRS_DB_ADDRESS=$dbaddress/ $infainstallerloc/SilentInput.properties
sed -i s/^MRS_SERVICE_NAME=.*/MRS_SERVICE_NAME=$mrsservicename/ $infainstallerloc/SilentInput.properties
sed -i s/^DIS_SERVICE_NAME=.*/DIS_SERVICE_NAME=$disservicename/ $infainstallerloc/SilentInput.properties
sed -i s/^DIS_PROTOCOL_TYPE=.*/DIS_PROTOCOL_TYPE=http/ $infainstallerloc/SilentInput.properties
sed -i s/^DIS_HTTP_PORT=.*/DIS_HTTP_PORT=18059/ $infainstallerloc/SilentInput.properties
}

Performspeedupinstalloperation()
{
  mv $infainstallerloc/source $infainstallerloc/source_temp
  mkdir $infainstallerloc/source
  mv $infainstallerloc/unjar_esd.sh $infainstallerloc/unjar_esd.sh_temp
  head -1 $infainstallerloc/unjar_esd.sh_temp > $infainstallerloc/unjar_esd.sh
  echo exit_value_unjar_esd=0 >> $infainstallerloc/unjar_esd.sh
  chmod 777 $infainstallerloc/unjar_esd.sh
}


installdomain()
{
  echo Installing Informatica domain
  cd $infainstallerloc
  echo Y Y | sh silentinstall.sh
}

revertspeedupoperations()
{
#sleep 30
 mv $infainstallerloc/source_temp/* $infainstallerloc/source
 rm $infainstallerloc/unjar_esd.sh
 mv $infainstallerloc/unjar_esd.sh_temp $infainstallerloc/unjar_esd.sh
 if [ -f $informaticaopt/license.key ]
 then
	rm $informaticaopt/license.key
 fi
 echo Informatica domain setup Complete.

}

configureDebian()
{
  echo $HDIClusterName $HDIClusterLoginUsername $HDIClusterLoginPassword $HDIClusterSSHHostname $HDIClusterSSHUsername $HDIClusterSSHPassword
  #Change sh to bash in server machine
  #sudo ln -f -s /bin/bash /bin/sh
  cd $informaticaopt/InstallerFiles/debian/InformaticaHadoop-10.1.1-Deb
  
  #Ambari API calls to extract Head node and Data nodes
  #echo "Getting list of hosts from ambari"
  hostsJson=$(curl -u $HDIClusterLoginUsername:$HDIClusterLoginPassword -X GET https://$HDIClusterName.azurehdinsight.net/api/v1/clusters/$HDIClusterName/hosts)
  echo $hostsJson 

  echo "Parsing list of hosts"
  hosts=$(echo $hostsJson | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w 'host_name')
  echo $hosts
 
  echo "Extracting headnode0"
  headnode0=$(echo $hosts | grep -Eo '\bhn0-([^[:space:]]*)\b') 
  echo $headnode0
  echo "Extracting headnode0 IP addresses"
  headnode0ip=$(dig +short $headnode0) 
  echo "headnode0 IP: $headnode0ip"

  #Add a new line to the end of hosts file
  #echo "">>/etc/hosts
  #echo "Adding headnode IP addresses"
  #echo "$headnode0ip headnode0">>/etc/hosts

  echo "Extracting workernode"
  workernodes=$(echo $hosts | grep -Eo '\bwn([^[:space:]]*)\b') 
  echo "Extracting workernodes IP addresses"
  echo "workernodes : $workernodes" 
  wnArr=$(echo $workernodes | tr "\n" "\n")
  
  
  #sudo apt-get install sshpass
  #rpm -ivh $informaticaopt/sshpass-1.05-5.el7.x86_64.rpm
  #Change sh to bash in headnode
  sshpass -p $HDIClusterSSHPassword ssh -o StrictHostKeyChecking=no $HDIClusterSSHUsername@$headnode0ip "sudo ln -f -s /bin/bash /bin/sh"

  
  for workernode in $wnArr
  do
    echo "[$workernode]" 
	workernodeip=$(dig +short $workernode)
	echo "workernodeip $workernodeip" 
	#create temp folder
        sshpass -p $HDIClusterSSHPassword ssh -o StrictHostKeyChecking=no $HDIClusterSSHUsername@$workernodeip "sudo mkdir ~/rpmtemp" 
	#Give permission to rpm folder
	sshpass -p $HDIClusterSSHPassword ssh -o StrictHostKeyChecking=no $HDIClusterSSHUsername@$workernodeip "sudo chmod 777 ~/rpmtemp"
	#SCP infa binaries
	sshpass -p $HDIClusterSSHPassword scp informatica_10.1.1-1.deb $HDIClusterSSHUsername@$workernodeip:"~/rpmtemp/" 
	#extract the binaries
	sshpass -p $HDIClusterSSHPassword ssh -o StrictHostKeyChecking=no $HDIClusterSSHUsername@$workernodeip "sudo dpkg -i ~/rpmtemp/informatica_10.1.1-1.deb"
	#Clean the temp folder
	sshpass -p $HDIClusterSSHPassword ssh -o StrictHostKeyChecking=no $HDIClusterSSHUsername@$workernodeip "sudo rm -rf ~/rpmtemp"
	#Change sh to bash in worker nodes
	 sshpass -p $HDIClusterSSHPassword ssh -o StrictHostKeyChecking=no $HDIClusterSSHUsername@$workernodeip "sudo ln -f -s /bin/bash /bin/sh"
  done

  cd /home/$osUserName
  
  echo "Debian installation successful"
}

editsilentpropfiletoBDMutil()
{
  echo "editing the silent prop file for BDM utility"
  bdm_silpropfile=$infainstallionloc/tools/BDMUtil/SilentInput.properties
  sed -i s/^CLOUDERA_SELECTION=1/CLOUDERA_SELECTION=0/ $bdm_silpropfile
  sed -i s/^HD_INSIGHT=0/HD_INSIGHT=1/  $bdm_silpropfile
  sed -i s/^DIST_FOLDER__NAME=cloudera_cdh5u8/DIST_FOLDER__NAME=HDInsight_3.4/ $bdm_silpropfile
  sed -i s/^INSTALL_TYPE=0/INSTALL_TYPE=3/ $bdm_silpropfile
  sed -i s/^AMBARI_HOSTNAME=/AMBARI_HOSTNAME=$HDIClusterName.azurehdinsight.net/ $bdm_silpropfile
  sed -i s/^AMBARI_USER_NAME=/AMBARI_USER_NAME=$HDIClusterLoginUsername/ $bdm_silpropfile
  sed -i s/^AMBARI_USER_PASSWD=/AMBARI_USER_PASSWD=$HDIClusterLoginPassword/ $bdm_silpropfile
  sed -i s/^AMBARI_PORT=/AMBARI_PORT=$ambariport/ $bdm_silpropfile
  sed -i s/^UPDATE_DIS=0/UPDATE_DIS=1/ $bdm_silpropfile
  sed -i s/^DOMAIN_USER=/DOMAIN_USER=$domainUser/ $bdm_silpropfile
  sed -i s/^DOMAIN_PSSWD=/DOMAIN_PSSWD=$domainPassword/ $bdm_silpropfile
  sed -i s/^DIS_SERVICE_NAME=/DIS_SERVICE_NAME=$DIS_SERVICE_NAME/ $bdm_silpropfile
  sed -i s/^HIVE_USER_NAME=/HIVE_USER_NAME=$HIVE_USER_NAME/ $bdm_silpropfile
  sed -i s/^HDFS_USER_NAME=/HDFS_USER_NAME=$HDFS_USER_NAME/ $bdm_silpropfile
  sed -i s/^BLAZE_USER=/BLAZE_USER=$BLAZE_USER/ $bdm_silpropfile
  sed -i s/^SPARK_EVENTLOG_DIR=/SPARK_EVENTLOG_DIR=$SPARK_EVENTLOG_DIR/ $bdm_silpropfile
  sed -i s/^SPARK_PARAMETER_LIST=/SPARK_PARAMETER_LIST=$SPARK_PARAMETER_LIST/ $bdm_silpropfile
  sed -i s/^IMPERSONATION_USER=/IMPERSONATION_USER=$IMPERSONATION_USER/ $bdm_silpropfile
  sed -i s/^ZOOKEEPER_HOSTS=/ZOOKEEPER_HOSTS=$ZOOKEEPER_HOSTS/ $bdm_silpropfile
  sed -i s/^HIVE_EXECUTION_MODE=Remote/HIVE_EXECUTION_MODE=$HIVE_EXECUTION_MODE/ $bdm_silpropfile
  sed -i s/^SPARK_HDFS_STAGING_DIR=/SPARK_HDFS_STAGING_DIR=$SPARK_EVENTLOG_DIR/ $bdm_silpropfile

}

runbdmutility()
{
  echo "running BDM UTILITY"
  cd $infainstallionloc/tools/BDMUtil
  echo Y Y | sh BDMSilentConfig.sh
  echo "BDM util configuration complete"

}


#updateFirewallsettings
#downloadlicense
checkforjoindomain
editsilentpropertyfilesforserverinstall
Performspeedupinstalloperation
#installdomain
revertspeedupoperations
configureDebian
editsilentpropfiletoBDMutil
runbdmutility
