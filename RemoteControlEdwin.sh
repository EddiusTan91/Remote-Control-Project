#!/bin/bash
# This script is used for remote scanning of a target, by connecting to a remote server and run the scans from there.

## to have a sense of what we have, we just update and upgrade the kali to ensure that the kali is up to date
function forupdate()
	{
		sudo apt-get -y update 
		sudo apt-get -y upgrade
	}

## the script here is to make a folder to contain the script within this folder. 
## By containing the whole script process in the folder, everything will be more controllable.

function crefldr()
	{
		mkdir NRprobase
		cd NRprobase
	}
		
# Checking Kali Version
# With the below code, I am trying out different ways to check if the machine is up to date, 
# however, we can just run the above code to without the need to check the system info as the update and upgrade will just install everthing to the latest version.
# happened across this function while exploring options for the version check.

## lsb_release is the Linux Standard base release. By running the lsb_release, you will be looking for the infoirmation of the linux installed in the current machine.
## hostnameclt is the information of the machine you are on.
## also by changing the code into a function, I can use it later for something else

function chkmac()
{
lsb_release -a
hostnamectl
service --status-all
ifconfig
}

#because I am running my route in accesspoint mode, due to the requirements of singtel,
#using this function will show the actual IP instead of the accesspoint IP.
function ownip()
{
	curl ifconfig.me
}
# Installing the tools for the job
# list of tools we will need for this project
# Geany, nipe, nmap, curl, whois
## Having a title at the start of each command, 
## helps the user to identify which part of of the script have gone wrong 
## or any error in the code.
### Also, even if the tools is already installed, we can make sure that they are updated using this method 
### as the apt-get install will also check the version of the tools and do an update if required. 

function instools()
{
	echo "Installing the tools for the job"
	echo "-----Installing GEANY-----"
	sudo apt-get install -y geany
	echo "-----Installing NMAP-----"
	sudo apt-get install -y nmap
	echo "-----Installing CURL-----"
	sudo apt-get install curl
	echo "-----Installing whois-----"
	sudo apt-get install whois
	echo "-----Installing SSHPASS-----"
	sudo apt-get install sshpass
	echo "-----Installing net-tools-----"
	sudo apt-get install net-tools
	echo "-----Removing files that are not required-----"
	sudo apt autoremove
	echo "----------------------------------------------"
	
}

function insnipe()
{
	echo "INSTALLING NIPE"
	git clone https://github.com/htrgouvea/nipe 
	#~ pwd
	cd nipe
	sudo cpan install Try::Tiny Config::Simple JSON
	sudo perl nipe.pl install
}	

## Function for checking Nipe Status
function nipestatus()
	{
		sudo perl nipe.pl status
	}
## Function for starting Nipe
function nipestart()
	{
		sudo perl nipe.pl start
	}
## Function for restarting Nipe
function niperestart()
	{
		sudo perl nipe.pl restart
	}

## Function for stopping Nipe
function nipestop()
	{
		sudo perl nipe.pl stop
	}

# Automating status script 
function nstat()
	{
		nistat=$(nipestatus | grep Status | awk '{print $3}')
		echo "your Nipe is currently $nistat"
	}
	
# Automating ipchecking script
function ipcheck()
	{
		nipestatus | grep Ip | awk '{print $3}'
	}

##	automation for nipe status, to filter for the status of the nipe(extra)
##	nistat=$(nipestatus | grep Status | awk '{print $3}')
##	echo "your Nipe is currently $nistat"

#Nipe start script
function nstart()
	{
		echo 'Starting Nipe'
		nipestart
		print $nipestatus
		nistat=$(nipestatus | grep Status | awk '{print $3}')
		
		if [[ $nistat != activated ]]
			then 
				echo "Restarting nipe"
				niperestart
		else
				echo "your Nipe is currently $nistat"
		fi
	}
	
#nipe stop script
function nstop()
	{
		echo 'stopping Nipe'
		nipestop
		nistat=$(nipestatus | grep Status | awk '{print $3}')
		echo "your Nipe is currently $nistat"
	}

#Nipe restart script
function nrestart()
	{
		echo 'Restarting Nipe'
		niperestart
		nistat=$(nipestatus | grep Status | awk '{print $3}')
		echo "your Nipe is currently $nistat"
	}

# This function is to do a comparison of the new ip and old ip, to ensure that the ip has changed. 
# if it does not change the NRESTART function restart the nipe.
function anoncheckip()
	{ 
		
		if [ $oip == $nip ]
		then 
			echo 'You are not anonymous'
			echo 'Restarting NIPE'
			nrestart
		else 
			echo 'you are anonymous ' 
		fi
	}

# This function is to do a check in the country of the IP address, by using the curl to get the ip information, then the grep, awk and tr commands to isolcate the country code.
# Nip in this case is the New IP, gotten after activating the NIPE.
function anoncheckcc()
	{ 
		echo "WHat is your 2 letter country code?"
		read ogc
		ncc=$(curl -s ipinfo.io/$nip | grep country | awk '{print $2}' | tr -cd [:alpha:])
		if [ $ncc != $ogc ]
			then
			echo "You are anonymous"
		else
			echo "You are not anonymous"
		fi
	}

# This function here is to let the user input the intended target's info for the sshpass to run.
# The reason why I chose this method is that, it allows the script to be more diverse, it will apply the sshpass to the specified user and ip.
function getsvrinfo()	
	{
		echo "Whats the IP to connect to?"
		read nrip
		echo "Who is the user?"
		read nrus
		echo "What is the password for this user?"	
		read nrpwd
	}

# the following 2 functions are to scan the target specified. I used the && to run multiple commands at the target.
# That is because if we run 1 by 1 the command will return to root with each entry. So by taking that each line is 
# 1 session in the target, using the && helps to do more things within that 1 session
function nmapinsp()
	{
	echo "Installing Nmap on Remote Machine"
	sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip sudo -S apt install nmap
	sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip "cd scanresults && sudo -S nmap 8.8.8.8 -oG nrsnmap.scan"
	}
function massinsp()
	{
	echo "Installing Masscan on Remote Machine"
	sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no "$nrus@$nrip" sudo -S apt install masscan
	sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no "$nrus@$nrip" "cd scanresults && sudo -S masscan 8.8.8.8 -p 20-80 -oG nrsmas.scan"
	}
	
function whoisinsp()
	{
	sshpass -p $nrpwd ssh $nrus@$nrip sudo -S apt install whois
	#sshpass -p $nrpwd ssh $nrus@$nrip whoisrs.txt
	sshpass -p $nrpwd ssh $nrus@$nrip "cd scanresults && sudo -S whois 8.8.8.8 >> whoisrs.txt"
	}
		
# this function is used for sending the result files as the whole folder named scanresults to the local host.
# scp -r allows us to the whole folder instead just the individual file to the local host.

function sendrs()
	{
	scp -r  $nrus@$nrip:~/scanresults ~/NRprobase
	}
# Created this function to delete the file from the remote server. However, I did not use it as it is not part of the requirements
function rmrs()
	{
	sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip "cd scanresults && rm nrsmas.scan && rm nrsnmap.scan && rm whoisrs.txt"
	sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip "cd scanresults && rm  && ls"
	sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip rmdir scanresults
	sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip ls
	}
	
function gotoSdatafmnipe()
	{
		cd 
		cd NRprobase/scanresults
	}
function rddlfiles()
	{
		echo "--------------------Nmap results--------------------"
		cat nrsnmap.scan 
		echo "--------------------Masscan results--------------------"
		cat nrsmas.scan
		echo "--------------------Whois Results--------------------"
		cat whoisrs.txt
	}	
	
function chkdlfiles()
	{
		nmrs=$(grep nrsnmap.scan | wc -l)
		msrs=$(grep nrsmas.scan | wc -l)
		if [ $nmrs == 1 ]
			then
			if [ $msrs == 1 ]
				then echo ' Both results files are downloaded'
			else
				echo ' Only 1 of the scan files are downloaded.'
			fi
		else 
			echo ' no Files are down downloaded.'
			
		fi
 	}
	

############################## End of function section ##########################################		

#For the scripting portion I will go according to the project outline
#step 1
#Install relevant applications on the local computer
#step 2
#Check if the connection is anonymous (not from your origin country).
#step 3
#Once the connection is anonymous, communicate via SSH / SSHPASS and execute nmap scans / masscan and whois queries
#step 4
#Save the result on your local computer

############################## Start of Scripting Section ##########################################

# Create a container to contain the script. 
forupdate
crefldr
echo "--------------------Force Update completed--------------------"

#Step 1 Install tools

instools
insnipe
echo "--------------------Tools installation completed--------------------"

#~ #Step 2 Start Nipe
#~ #pwd
#~ cd nipe
#~ #pwd
#~ oip=$(ipcheck)
#~ echo "Your Current IP : $oip"
#~ nstart
#~ nip=$(nipestatus | grep Ip | awk '{print $3}')
#~ echo "Your New Ip : $nip"
#~ nstat
#~ anoncheckip
#~ anoncheckcc

#check own ip
#~ cd nipe
ogip=$(hostname -I)
echo "Your Current IP : $ogip"
#start nipe
echo "Starting NIPE"
nipestart
#check status
echo "NIPE started"
nipestatus
# check new IP
newip=$(nipestatus | grep Ip | awk '{print $3}')
echo "Your Current IP : $newip"
# check if nipe did its job, if not do a restart for nipe
if [ $ogip == $newip ]
		then 
			echo 'You are not anonymous'
			echo 'Restarting NIPE'
			nrestart
		else 
			echo 'you are anonymous ' 
		fi


echo "--------------------Nipe initialisation completed--------------------"

#~ #step 3 sshpass to the ip scan for info


echo "sshpass into the remote machine"
#~ echo "Initialise the connection"
#~ ssh root@134.122.122.48 exit

# with the  Flag -o StrictHostKeyChecking=no, there is no requirements to do a 
# manual ssh to add the remote computer to the ssh server.

getsvrinfo

echo "Starting SHHPASS"
# similar to the start of the script, I want to create a contained environment 
# for the script to continue running in the remote machine
sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip mkdir scanresults

echo "installing askpass"
sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip sudo apt-get install ssh-askpass
# Running the installations and scan individually so that if 1 of 
#the script goes wrong, it will be easier to rectify
nmapinsp
massinsp
whoisinsp

# Checking that the saves are successfully saved in the scanresults folder
sshpass -p $nrpwd ssh -o StrictHostKeyChecking=no $nrus@$nrip "cd scanresults && ls"


echo "--------------------Machine has been accessed and scanned--------------------"

# Step 4, Save the result on your local computer

# USing the SCP to copy the files from the remote server back to the local computer,
# then stopping the NIPE, then to cd into the scanresults folder to see the downloaded files

sendrs
#~ rmrs

#stopping nipe and making sure it is stopped
nstop
nistatus

# To ensure that the folder I am in is the base folder, 
# I would CD to the Home Folder, then do a CD from there.
gotoSdatafmnipe
ls
# then by reading the files, we can check that 
# the files have been successful copied.
# rddlfiles				# Your can remove the # to have the script  check the existent of the file on your computer.

filelocation= locate scanresults

echo " the results files are here$filelocation "

echo "--------------------Scan results downloaded--------------------"
echo "--------------------Project Run completed--------------------"

#Credits
# SSHPASS - https://www.tecmint.com/sshpass-non-interactive-ssh-login-shell-script-ssh-password/
# Instructor: Centre for CyberSecurity James Lim


# This Script was created and maintain by Edwin Tan student code S5/2407
