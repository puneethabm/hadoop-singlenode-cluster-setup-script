#!/bin/bash

########################################
######### Hadoop Installation ##########
######### Author: Puneetha B M #########
########################################

export _POSIX2_VERSION=199209

wdir=`dirname $0`
pushd "$wdir" >> /dev/null 2>&1


#Initialization
function f_initialize() {
    source ./commonFunctions.sh
    source ./properties.txt
    source $HOME/.bashrc

    f_decEscapeCharacters
}


function f_updateVariables() {
    HADOOP_USER_PREFIX="su - ${hadoopGroupUser} -c"

}

function f_pre_install() {
    variable="hello"

}

function f_displayParams() {
    echo -e "----------------------------------------";
    echo -e "\tParameters";
    echo -e "----------------------------------------";
    echo -e "Hadoop Group : ${hadoopGroup}";
    echo -e "Hadoop Group User: ${hadoopGroupUser}";
    echo -e "Tar File Name: ${tarFileName}";
    echo -e "----------------------------------------";

}


function f_inputTarFileName(){
    echo "Please enter the tar file name (Ex: hadoop-1.2.0.tar.gz)"
    
    f_readInput "\ttar file name" ${tarFileName}
    tarFileName=${REPLY}
    
    echo -e "\tPlease confirm the tar file name"
    echo -e "\t${e_bold}tar file name:${e_normal} $tarFileName"

    if f_confirm "\tIs the details correct" Y; then
        f_tarFileCheck $tarFileName
    else
        f_inputTarFileName
    fi    
}

#Set Parameters
function f_input() {
    #Flag Variables description
    #:h flag
    #u: option
    
    #Example to override default parameters
    #hadoopGroupUser="override_user"

    tarFileName=""
    while getopts ":hg:u:t:" option; do
	case "$option" in
	    h) f_info; f_usage ;;
        g) hadoopGroup="$OPTARG" ;;
	    u) hadoopGroupUser="$OPTARG" ;;
        t) tarFileName="$OPTARG" ;;
	    ?) echo "Illegal option: $OPTARG"; f_usage ;;
	esac
    done

    hadoopGroup=$(f_lowercase $hadoopGroup)
    hadoopGroupUser=$(f_lowercase $hadoopGroupUser)   
}

function f_inputCheck() {
    #Read tar file name
    if [ "z$tarFileName" = "z" ]; then
        f_inputTarFileName
    fi
    f_tarFileCheck $tarFileName

    f_groupExists ${hadoopGroup}
    f_userExists ${hadoopGroupUser}

}



###############################################
############## Check Status ###################
###############################################

function f_groupExists(){
    if [ ! -z "$(getent group $1)" ]; then  
        #group does  exist
        echo -e "Group $1 already exists. Please enter a new name";
         f_readInput "\tGroup Name" $v_HadoopGroupTmp
         v_HadoopGroupTmp=${REPLY}
         f_groupExists ${v_HadoopGroupTmp}
    else 
        echo -e "Creating Group $1"
        #group does NOT exist
        
        echo -e "\tPlease confirm the Group name"
        echo -e "\t${e_bold}Group name:${e_normal} $1"


        if f_confirm "\tIs the details correct" Y; then
            #add user command here
            hadoopGroup="$1"
            addgroup $1
            echo -e "Group Name '$1' is saved"
        else
             f_readInput "\tPlease enter new Group Name" $v_HadoopGroupTmp1
             v_HadoopGroupTmp1=${REPLY}
             f_groupExists ${v_HadoopGroupTmp1}
        fi
    fi    
}


function f_userExists(){
    if [ ! -z "$(getent passwd $1)" ]; then  
        #user does  exist
        echo -e "User $1 already exists. Please enter a new name";
         f_readInput "\tUser Name" $v_HadoopUserTmp
         v_HadoopUserTmp=${REPLY}
         f_userExists ${v_HadoopUserTmp}
    else 
        echo -e "Creating user $1"
        #user does NOT exist
        
        echo -e "\tPlease confirm the user name"
        echo -e "\t${e_bold}user name:${e_normal} $1"


        if f_confirm "\tIs the details correct" Y; then
            #add user command here
            hadoopGroupUser="$1"
            adduser --ingroup ${hadoopGroup} $1
            echo -e "User Name '$1' is saved"
        else
             f_readInput "\tPlease enter new User Name" $v_HadoopUserTmp1
             v_HadoopUserTmp1=${REPLY}
             f_userExists ${v_HadoopUserTmp1}
        fi
    fi    
}

###############################################
###############################################

function f_pre_install() {
    echo "Checking for Pre-Requisites"
	
    #Check whether JDK is correctly set up
    f_javaCheck
    
    #Check whether ssh is installed
    f_sshInstallCheck

    echo "# Setting PATH variable" >> ~/.bashrc
    echo "export PATH=$JAVA_HOME/bin:$PATH" >> ~/.bashrc
}



function f_previlege() {
    echo -e "\nPre Requisites Installation Started...\n";

    #Give sudo privileges for Hadoop system user
    adduser ${hadoopGroupUser} sudo
    
    #Generate an SSH key for the Hadoop system user    
    ${HADOOP_USER_PREFIX} "ssh-keygen -t rsa -P ''"

    #Enable SSH access to your local machine with this newly created key.
    ${HADOOP_USER_PREFIX} "cat /home/${hadoopGroupUser}/.ssh/id_rsa.pub >> /home/${hadoopGroupUser}/.ssh/authorized_keys"

}


#Connect to localhost --> ssh 
function f_sshLoginCheck(){
    echo -e "\n";

    ${HADOOP_USER_PREFIX} "cp /home/${hadoopGroupUser}/.bashrc /home/${hadoopGroupUser}/.bashrc.ssh.orig1"

    echo -e "Sleeping";

    ${HADOOP_USER_PREFIX} "echo 'sleep 5; logout' >> /home/${hadoopGroupUser}/.bashrc"    
    ${HADOOP_USER_PREFIX} "ssh ${hadoopGroupUser}@localhost" 
    ${HADOOP_USER_PREFIX} "cp -f /home/${hadoopGroupUser}/.bashrc.ssh.orig1 /home/${hadoopGroupUser}/.bashrc"
    
}

# Function to Disable IPv6
function f_disable_ipv6(){
    local sysctl_path="/etc/sysctl.conf"
    #Creating a back up of the file
    cp /etc/sysctl.conf /etc/sysctl.conf.orig

    echo "# disable ipv6" >> ${sysctl_path}
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> ${sysctl_path}
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> ${sysctl_path}
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> ${sysctl_path}

    #Restart Network 
    #Activate the change in the kernel without rebooting
    sysctl -p ${sysctl_path}
}

function f_chk_disable_ipv6(){
    local chk_disable_ipv6=`cat /proc/sys/net/ipv6/conf/all/disable_ipv6`;
    if [ $chk_disable_ipv6 -eq 0 ]; then
    	echo "Please disable IPv6"
 		exit 0;
    fi
}

function f_hadoop_install(){
    #Moving Hadoop package to /usr/local location
    cp ${tarFileName} /usr/local
    
    pushd /usr/local    
    #Extract the contents of the Hadoop package
    tar xzf ${tarFileName}
    

    local tarFileBaseName_l=$(echo ${tarFileName} | awk -F ".tar.gz" '{ print $1 }')

    #Renaming
    mv ${tarFileBaseName_l} hadoop
    

    #Make sure to change the owner of all the files to the hduser user and hadoop group
    chown -R ${hadoopGroupUser}:${hadoopGroup} hadoop

    popd
}

#Function to Update $HOME/.bashrc of Hadoop System User
function f_update_bashrc(){
    local HADOOP_USER_HOME="/home/${hadoopGroupUser}/.bashrc"
    

    cp ${HADOOP_USER_HOME} /home/${hadoopGroupUser}/.bashrc.orig2

    local append_bashrc="
        # Set Hadoop-related environment variables \n
        export HADOOP_HOME=/usr/local/hadoop \n
        # Set JAVA_HOME (we will also configure JAVA_HOME directly for Hadoop later on) \n
        export JAVA_HOME=$JAVA_HOME \n
        # Some convenient aliases and functions for running Hadoop-related commands \n
        unalias fs &> /dev/null \n
        alias fs=\"hadoop fs\" \n
        unalias hls &> /dev/null \n
        alias hls=\"fs -ls\" \n
        # If you have LZO compression enabled in your Hadoop cluster and \n
        # compress job outputs with LZOP (not covered in this tutorial): \n
        # Conveniently inspect an LZOP compressed file from the command \n
        # line; run via: \n
        # \n
        # $ lzohead /hdfs/path/to/lzop/compressed/file.lzo \n
        # \n
        # Requires installed 'lzop' command. \n
        # \n
        lzohead () { \n
            hadoop fs -cat \$1 | lzop -dc | head -1000 | less \n
        } \n
        # Add Hadoop bin/ directory to PATH \n
            export PATH=\$PATH:\$HADOOP_HOME/bin \n
        "
        echo -e "${append_bashrc}" >> ${HADOOP_USER_HOME}
}


#Function to edit hadoop-env
function f_hadoop_env_config(){
    local hadoop_env_path="/usr/local/hadoop/conf/hadoop-env.sh"
    echo "# The java implementation to use. Required." >> ${hadoop_env_path}
    echo "export JAVA_HOME=$JAVA_HOME" >> ${hadoop_env_path}
}

function f_create_base_temp_dir(){
    mkdir -p /app/hadoop/tmp
    chown ${hadoopGroupUser}:${hadoopGroup} /app/hadoop/tmp
    chmod 777 /app/hadoop/tmp
}


#Function to edit core-site.xml
function f_core_site(){
    local core_site_path="/usr/local/hadoop/conf/core-site.xml"

     local append_core_site="
        <configuration>\n
             \t<property>
                    \t\t<name>hadoop.tmp.dir</name>
                    \t\t<value>/app/hadoop/tmp</value>
                    \t\t<description>A base for other temporary directories.</description>
            \t</property>\n\n
            \t<property>
                    \t\t<name>fs.default.name</name>
                    \t\t<value>hdfs://localhost:54310</value>
                    \t\t<description>The name of the default file system. \n
                    \t\tA URI whose scheme and authority determine the FileSystem implementation.\n
                    \t\tThe uri scheme determines the config property (fs.SCHEME.impl)
                        naming the FileSystem implementation class. \n
                    \t\tThe uri authority is used to determine the host, port, etc. for a filesystem.\n
                    \t\t</description>
            \t</property>\n
        </configuration>\n
        "
    echo -e $append_core_site > ${core_site_path}
    #su - ${hadoopGroupUser} -c "echo -e ${append_core_site} > ${core_site_path}"
}

#Function to edit mapred-site.xml
function f_mapred_site(){
    local mapred_site_path="/usr/local/hadoop/conf/mapred-site.xml"

    local append_mapred_site="
        <configuration>\n
        \t<property>\n
            \t\t<name>mapred.job.tracker</name>\n
            \t\t<value>localhost:54311</value>\n
            \t\t<description>The host and port that the MapReduce job tracker runs at. \n
                        \t\tIf "locall", then jobs are run in-process as a single map and reduce task.\n
            \t\t</description>\n
        \t</property>\n
        </configuration>\n
        "
    echo -e ${append_mapred_site} > ${mapred_site_path}
    #su - ${hadoopGroupUser} -c "echo -e ${append_mapred_site} > ${mapred_site_path}" 
}

#Function to edit hdfs-site.xml
function f_hdfs_site(){
    local hdfs_site_path="/usr/local/hadoop/conf/hdfs-site.xml"

    local append_hdfs_site="
        <configuration>\n
        \t<property>
            \t\t<name>dfs.replication</name>
            \t\t<value>1</value>
            \t\t<description>Default block replication.
                \t\tThe actual number of replications can be specified when the file is created.
                \t\tThe default is used if replication is not specified in create time.
            \t\t</description>
        \t</property>
        </configuration>\n
        "
    echo -e ${append_hdfs_site} > ${hdfs_site_path}
    #su - ${hadoopGroupUser} -c "echo -e ${append_hdfs_site} > ${hdfs_site_path}" 
}



#Function to start Hadoop
function f_start_hadoop(){
    su - ${hadoopGroupUser} -c "/usr/local/hadoop/bin/hadoop namenode -format"
    su - ${hadoopGroupUser} -c "/usr/local/hadoop/bin/start-all.sh"
    su - ${hadoopGroupUser} -c "$JAVA_HOME/bin/jps"
    su - ${hadoopGroupUser} -c "/usr/local/hadoop/bin/stop-all.sh"
}



function main(){
    local scriptStartTime_l=`date +%s`

    #Initialization - import source files
    f_initialize

    # Check if Root user is executing the script
    f_rootUserCheck
    
    #Check for pre-installated softwares    
    f_pre_install

    

    #Set Parameters
    f_input $*
    f_inputCheck

    f_updateVariables

    f_displayParams


    #Pre-Install
    f_previlege 
    f_sshLoginCheck

    #Function to Disable IPv6   
    f_disable_ipv6
    f_chk_disable_ipv6

    #Hadoop Installation
    f_hadoop_install
    
    #Function to Update $HOME/.bashrc
    f_update_bashrc
    

    #Configuration
    f_hadoop_env_config
    f_create_base_temp_dir
    f_core_site
    f_mapred_site
    f_hdfs_site

    #Function to run Hadoop (Start and Stop)
    f_start_hadoop

    local scriptEndTime_l=`date +%s`
    
    local scriptTotalTime_l=`echo "scale=0; ($scriptEndTime_l - $scriptStartTime_l)" | bc `
    echo -e "Hadoop Installation Successful. (Total Time Taken is $scriptTotalTime_l seconds )"
    echo -e "-----End of the Script-----";
 
    popd >> /dev/null 2>&1
}

main $*




