#!/bin/bash

export _POSIX2_VERSION=199209

# Function to convert to uppercase
function f_uppercase(){
    echo $1 | tr '[a-z]' '[A-Z]'
}

# Function to convert to lowercase
function f_lowercase(){
    echo $1 | tr '[A-Z]' '[a-z]'
}


#Function to exit from the program
function f_die(){
    echo -e "$1";
    exit 1
}

# Function to check if Root user is executing the script
function f_rootUserCheck(){
    echo -e "Checking whether root user is executing the script";

    local name_l=`id -un`
    local uname_l=`f_uppercase $name_l`

    if [ "$uname_l" != "ROOT" ]; then
        f_die "Only user 'root' should execute this script." 
    fi
}

function f_tarFileCheck(){
    local v_fileName_l="$1"
    
    echo -e "\tChecking file $v_fileName_l"
    
    if [ ! -f "${v_fileName_l}" ]; then
	   echo -e "\t$v_fileName_l : File does not exist"
           f_inputTarFileName
    elif [ -f "${v_fileName_l}" ]; then
            echo -e "\tNew tar file name will be saved"
    elif [ ! -r "$v_fileName_l" ]; then
	    f_die "\t$v_fileName_l : File does not have read permission"
    else
        f_inputTarFileName        
    fi
}

#########################################################
############## Check for Installation ###################
#########################################################


#Function to check if ssh is installed
function f_sshInstallCheck(){
    echo -e "Cheking for ssh installtion";
    v_ssh=`which ssh`
    if [ "$v_ssh" = "/usr/bin/ssh" ]; then
        echo "ssh is installed"; 
    else     
        f_die  "Please install ssh"; 
    fi

    #$v_ssh_status=ssh $host "echo 2>&1" && echo $host OK || echo $host NOK
    
    #if [ "$v_ssh_status" = "NOK" ]; then
    #	f_die "Please install ssh before starting this script"
    #fi   
}

# Function to check if the system has been upgraded to work with JDK1.6.0 and above
function f_javaCheck(){
    echo -e "Checking for JAVA 1.6.0 or higher";

    local msgInstall="Please install java 1.6.0 or higher before running this script."
    local msgUpgrade="JAVA has to be upgraded to version 1.6.0 or higher before running this script."
    
    javaInstalled=`which java 2>&1`
    if [ "$?" -ne 0 ]; then
        f_die "$msgInstall"
    fi

    javaFullVerInfo=`java -fullversion 2>&1`
    if [ "$?" -ne 0 ]; then
        f_die "$msgInstall"
    fi

    javaFullVerInfo=`java -fullversion 2>&1 | awk '{print $4}' 2>&1`
    javaVerInfo=`echo $javaFullVerInfo | sed -e 's/"/''/g' -e 's/-/./g' -e 's/_/./g'`

    if [ "$javaVerInfo" = "" ]; then
         f_die "$msgInstall"
    fi
    javaSubVer1=`echo $javaVerInfo | awk -F. '{print $1}'`
    javaSubVer2=`echo $javaVerInfo | awk -F. '{print $2}'`
    javaSubVer3=`echo $javaVerInfo | awk -F. '{print $3}'`
    
    if [ ! $javaSubVer1 -ge 1 -o ! $javaSubVer2 -ge 6 -o ! $javaSubVer3 -ge 0 ]; then
        f_die "$msgUpgrade"
    fi
    
    echo -e "Found java $javaVerInfo installed on this system"
     
    if [ "$JAVA_HOME" = "" ]; then
    	f_die "Please set JAVA_HOME Environment variable before starting this script"
    fi
   
    local javacFlag_l=`find $JAVA_HOME/bin -name 'javac'`
    local javacFlag_l=`basename ${javacFlag_l}`
    if [ "$javacFlag_l" != "javac" ]; then
    	f_die "Please check whether java jdk is installed properly. We are unable to find javac executable file. It seems like you have installed only JRE. Also check whether JAVA_HOME environmetn variable is set properly"
    fi
}

##########################################
############## General ###################
##########################################


function f_decEscapeCharacters(){
    # Escape characters
    e_bold="\033[1m"
    e_underline="\033[4m"
    e_red="\033[0;31m"
    e_green="\033[0;32m"
    e_blue="\033[0;34m"
    e_normal="\033[0m"
    
    e_success="${e_bold}[${e_normal} ${e_green}OK${e_normal} ${e_bold}]${e_normal}"
    e_failure="${e_bold}[${e_normal} ${e_red}Failed${e_normal} ${e_bold}]${e_normal}"
}

function f_info(){
    echo -e "========================================================================================================================"
    echo -e "\t\t\t${e_bold}Hadoop Installer${e_normal}"

    echo -e "\tThis script will install Hadoop and setup single node cluster."
    echo -e "\t${e_red}Only root user should execute this script${e_normal}" 
    echo -e "========================================================================================================================"
}



function f_usage(){
    local scriptName=$(basename "$0")
    echo -e "${e_bold}USAGE${e_normal}"
    echo -e "\t$scriptName [-h] [-g ${e_underline}HadoopGroup${e_normal}] [-u ${e_underline}HadoopUser${e_normal}] -t ${e_underline}tarFileName${e_normal}"
    
    echo -e "${e_bold}OPTIONS${e_normal}"
    
    echo -e "\t${e_bold}-h${e_normal}\t\t\tHelp - Flag used to display 'usage help' for the script"    
    
    echo -e "\n\t${e_bold}-g ${e_underline}HadoopGroup${e_normal}\t\tHadoop Group Name - This group will be created (if not exists)"
    echo -e "\t\t\t\t  If HadoopGroup is not specified it defaults to ${e_bold}'hadoop'${e_normal}"

    echo -e "\n\t${e_bold}-u ${e_underline}HadoopUser${e_normal}\t\tHadoop User Name - This user will be created (if not exists)"
    echo -e "\t\t\t\t  If HadoopUser is not specified it defaults to ${e_bold}'hduser'${e_normal}"    
   
    
    echo -e "\n\t${e_bold}-t ${e_underline}tarFileName${e_normal}\t\tHadoop Tar File Name - This tar file will be used"
    echo -e "\t\t\t\tto set-up Hadoop environment. If tarFileName is not specified, then"
    echo -e "\t\t\t\tyou will be prompted to specify during the execution of the script"    
   

    echo -e "${e_bold}AUTHOR${e_normal}"
    echo -e "\t ${e_green}${e_bold}Puneetha B M${e_normal} - puneethabm@gmail.com \n"



    exit 0;
}

##########################################################
############## Input Related Functions ###################
##########################################################
# Read Input using prompt
function f_readInput(){
    local v_promptMsg="$1"
    local v_defaultVal="${2:-}"

    echo -e -n "${v_promptMsg} ${e_bold}[${e_normal} ${e_blue}${e_bold}${v_defaultVal}${e_normal} ${e_bold}]${e_normal} "
    read REPLY

    if [ -z "${REPLY}" ]; then
        REPLY=${v_defaultVal}
    fi
}


# Y/N Prompt
function f_confirm() {
    local v_promptMsg="$1"
    local v_defaultVal="${2:-}"

    if [ "${v_defaultVal}" = "Y" ]; then
        v_defaultPrompt="${e_blue}${e_bold}Y${e_normal}/n"
    elif [ "${v_defaultVal}" = "N" ]; then
        v_defaultPrompt="y/${e_blue}${e_bold}N${e_normal}"
    else
        v_defaultPrompt="y/n"
    fi

    echo -e -n "${v_promptMsg} ${e_bold}[${e_normal} ${v_defaultPrompt} ${e_bold}]${e_normal} "
    read REPLY

    if [ -z "${REPLY}" ]; then
        REPLY=${v_defaultVal}
    fi

    case "$REPLY" in
        Y*|y*) return 0 ;;
        N*|n*) return 1 ;;
    esac
}

##########################################################
##########################################################
