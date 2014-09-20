Hadoop Singlenode Cluster Setup Script - Ubuntu

================================================================
Mandatory
================================================================
1) Only root user can execute this script
2) HadoopSetUp.sh file must have execute permission
   (We can do this by using following command 
    $chmod +x HadoopSetUp.sh    
   )
3) Download any hadoop tar file (Ex: hadoop-1.2.0.tar.gz)
   From the below site:
   http://www.apache.org/dyn/closer.cgi/hadoop/core

================================================================
Pre Requisites
================================================================
1) JDK 1.6 or above
   set JAVA_HOME environment variable
2) openssh-server and openssh-client should be installed
   (To install in ubuntu 
      apt-get install openssh-server openssh-client
   )

================================================================
How to see Usage help for the following script
================================================================
 $./HadoopSetUp.sh -h

================================================================
To override default parameters for the following script
================================================================
1) To enter the hadoop tar file name as an option
    $./HadoopSetUp.sh -t hadoop-1.2.0.tar.gz

2) To override default Hadoop Group Name --> default 'hadoop'
    $./HadoopSetUp.sh -g hadoopGroup

3) To override default Hadoop User Name --> default 'hduser'
    $./HadoopSetUp.sh -u hadoopUser

================================================================
Order of Set Up
================================================================
1) Please make sure you have installed all the prerequisites
2) Install Hadoop Cluster Set Up
	$./HadoopSetUp.sh
		( will install with default values. See Usage help for more customization )
	
	Default Values
        hadoopGroup defaults to 'hadoop'
        hadoopGroupUser defaults to 'hduser'
	
================================================================
Post Hadoop Set Up
================================================================
How to verify Hadoop Set Up 
1) Login as hadoopGroupUser i.e. default 'hduser' by using the command
    $su - hduser
2) Start
    hduser@ubuntu:~$ /usr/local/hadoop/bin/start-all.sh
3) JPS (Java Process Status)
    hduser@ubuntu:~$ jps
4) Hadoop Web Interfaces
    http://localhost:50070/ - web UI of the NameNode daemon
    http://localhost:50030/ - web UI of the JobTracker daemon
    http://localhost:50060/ - web UI of the TaskTracker daemon
===============================================================

