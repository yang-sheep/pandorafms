#!/usr/bin/ksh
# **********************************************************************
# Pandora Agent for Solaris
# v1.2
# (c) Sancho Lerena 2003-2006, slerena@gmail.com
# Este codigo esta licenciado bajo la licencia GPL 2.0 o posterior
# This code is licenced under GPL 2.0 licence or later
# **********************************************************************

AGENT_VERSION="1.2"

OLDIFS=$IFS
# Stupid trick to use IFS in Solaris/AIX ... doesnt work standard $'\n' :-?
NEWIFS="
"

# Begin cycle for adquire primary config tokens
TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`

if [ -z "$1" ]
then
    echo " "
    echo "FATAL ERROR: I need an argument to PANDORA AGENT home path"
    echo " "
    echo " example:   /usr/share/pandora_ng/pandora_agent.sh /usr/share/pandora_ng  "
    echo " "
    exit
else
    PANDORA_HOME=$1
fi

if [ -z "`cat $PANDORA_HOME/pandora_agent.conf`" ]
then
    echo " "
    echo "FATAL ERROR: Cannot load $PANDORA_HOME/pandora_agent.conf"
    echo " "
    exit 
fi

echo "$TIMESTAMP - Reading general config parameters from .conf file" >> $PANDORA_HOME/pandora.log

# Default values
DEBUG_MODE=0
CHECKSUM_MODE=0

IFS=$NEWIFS
for a in `cat $PANDORA_HOME/pandora_agent.conf | grep -v "^#" | grep -v "^module" `
do
    a=`echo $a | tr -s " " " "`
    # Get general configuration parameters from config file
    if [ ! -z "`echo $a | grep '^server_ip'`" ]
    then
        SERVER_IP=`echo $a | awk '{ print $2 }'`
        echo "$TIMESTAMP - [SETUP] - Server IP Address is $SERVER_IP" >> $PANDORA_HOME/pandora.log
    fi
    if [ ! -z "`echo $a | grep '^server_path'`" ]
    then
        SERVER_PATH=`echo $a | awk '{ print $2 }'`
        echo "$TIMESTAMP - [SETUP] - Server Path is $SERVER_PATH" >> $PANDORA_HOME/pandora.log
    fi
    if [ ! -z "`echo $a | grep '^temporal'`" ]
    then
        TEMP=`echo $a | awk '{ print $2 }'`
        echo "$TIMESTAMP - [SETUP] - Temporal Path is $TEMP" >> $PANDORA_HOME/pandora.log
    fi
    if [ ! -z "`echo $a | grep '^interval'`" ]
    then
        INTERVAL=`echo $a | awk '{ print $2 }'`
        echo "$TIMESTAMP - [SETUP] - Interval is $INTERVAL seconds" >> $PANDORA_HOME/pandora.log
    fi
    if [ ! -z "`echo $a | grep '^agent_name'`" ]
    then
        NOMBRE_HOST=`echo $a | awk '{ print $2 }' `
        echo "$TIMESTAMP - [SETUP] - Agent name is $NOMBRE_HOST " >> $PANDORA_HOME/pandora.log
    fi
    if [ ! -z "`echo $a | grep '^debug'`" ]
    then
        DEBUG_MODE=`echo $a | awk '{ print $2 }' `
        echo "$TIMESTAMP - [SETUP] - Debug mode $DEBUG_MODE " >> $PANDORA_HOME/pandora.log
    fi
    if [ ! -z "`echo $a | grep '^checksum'`" ]
    then
        CHECKSUM_MODE=`echo $a | awk '{ print $2 }' `
        echo "$TIMESTAMP - [SETUP] - Checksum mode is $CHECKSUM_MODE " >> $PANDORA_HOME/pandora.log
    fi
done


# MAIN Program loop begin
# OS Data
OS_VERSION=`uname -v`
OS_VERSION=$OS_VERSION.`uname -r`
OS_NAME=`uname -s`
# Hostname
if [ -z "$NOMBRE_HOST" ]
then
    NOMBRE_HOST=`/bin/hostname`
fi

# Default values
CONTADOR=0
EXECUTE=1
MODULE_END=0

while [ "1" = "1" ]
do
    # Fecha y hora. Se genera un serial (numero de segundos desde 1970) para cada paquete generado.
    TIMESTAMP=`date +"%Y/%m/%d %H:%M:%S"`
    SERIAL=`date +"%S%M%m%H"`
    
    # Nombre de los archivos
    DATA=$TEMP/$NOMBRE_HOST.$SERIAL.data
    CHECKSUM=$TEMP/$NOMBRE_HOST.$SERIAL.checksum
    PANDORA_FILES="$TEMP/$NOMBRE_HOST.$SERIAL.*"
    DATA2=$TEMP/$NOMBRE_HOST.$SERIAL.data_temp

    # Makes data packet
    echo "<agent_data os_name='$OS_NAME' os_version='$OS_VERSION' interval='$INTERVAL' version='$AGENT_VERSION' timestamp='$TIMESTAMP' agent_name='$NOMBRE_HOST'>" > $DATA 
    if [ "$DEBUG_MODE" = "1" ]
    then
	echo "$TIMESTAMP - Reading module adquisition data from .conf file" >> $PANDORA_HOME/pandora.log
	DEBUGOUTPUT=$PANDORA_HOME/pandora.log
    else
	DEBUGOUTPUT=/dev/null
    fi
    
    for a in `cat $PANDORA_HOME/pandora_agent.conf | grep -v "^#" | grep "^module" ` 
    do
	a=`echo $a | tr -s " " " "`
	
        if [ ! -z "`echo $a | grep '^module_exec'`" ]
        then
	    if [ $EXECUTE -eq 0 ]
	    then
            	execution=`echo $a | cut -c 13-`
            	res=`eval $execution 2> /dev/null`
            	if [ -z "$flux_string" ]
            	then
             	    res=`eval expr $res 2> /dev/null`
     		fi
	        echo "<data>$res</data>" >> $DATA2
	    fi
	fi
	
	if [ ! -z "`echo $a | grep '^module_name'`" ]
	then
	    name=`echo $a | cut -c 13-`
	    echo "<name>$name</name>" >> $DATA2
	fi
	
	if [ ! -z "`echo $a | grep '^module_begin'`" ]
	then
	    echo "<module>" >> $DATA2
	    EXECUTE=0
	fi
	
	if [ ! -z "`echo $a | grep '^module_max' `" ]
        then
            max=`echo $a | awk '{ print $2 }' `
            echo "<max>$max</max>" >> $DATA2
        fi
        
	if [ ! -z "`echo $a | grep '^module_min'`" ]
        then
            min=`echo $a | awk '{ print $2 }' `
            echo "<min>$min</min>" >> $DATA2
        fi
        
	if [ ! -z "`echo $a | grep '^module_description'`" ]
        then
            desc=`echo $a | cut -c 20- `
            echo "<description>$desc</description>" >> $DATA2
        fi

        if [ ! -z "`echo $a | grep '^module_end'`" ]
        then
            MODULE_END=1
	    echo "</module>" >> $DATA2
	else
	    MODULE_END=0
        fi
	
        if [ ! -z "`echo $a | grep '^module_type'`" ]
        then
            mtype=`echo $a | cut -c 13-`
            if [ ! -z "`echo $mtype | grep 'generic_data_string'`" ]
      	    then
   		flux_string=1
     	    else
                flux_string=0
                unset flux_string
            fi
            echo "<type>$mtype</type>" >> $DATA2
        fi
	
	if [ ! -z "`echo $a | grep '^module_interval'`" ]
  	then
            # Determine if execution is to be done
            MODULEINTERVAL=`echo $a | awk '{ print $2 }'`
	    EXECUTE=`expr \( $CONTADOR + 1 \) % $MODULEINTERVAL`
  	fi

	# If module end, and execute for this module is enabled
	# then write 
	if [ $MODULE_END -eq "1" ]
	then
	    if [ $EXECUTE -eq "0" ]
	    then
		cat $DATA2 >> $DATA
	    fi
	    rm -Rf $DATA2 #> /dev/null 2> /dev/null
	fi

    done

    # Count number of agent runs
    CONTADOR=`expr $CONTADOR + 1`
    # Keep a limit of 100 for overflow reasons
    if [ $CONTADOR -eq 100 ]
    then
	CONTADOR=0
    fi

    # Call for user-defined script for data adquisition
    if [ -f "$PANDORA_HOME/pandora_user.conf" ]
    then
	/bin/sh $PANDORA_HOME/pandora_user.conf >> $DATA 2> /dev/null 
    fi

    # Finish data packet
    echo "</agent_data>" >> $DATA
    echo "$TIMESTAMP - Finish writing XML $DATA" >> $DEBUGOUTPUT
    # Calculate Checksum and prepare MD5 file
    if [ "$CHECKSUM_MODE" = 1 ]
    then
	CHECKSUM_DATA=`cat $DATA | md5 `
	echo $CHECKSUM_DATA $DATA> $CHECKSUM
    else
	echo "NO MD5 CHECKSUM AVAILABLE" > $CHECKSUM
    fi
    # Send packets to server and delete it
    scp $PANDORA_FILES pandora@$SERVER_IP:$SERVER_PATH
    if [ "$DEBUG_MODE" = 1 ] 
    then
  	echo "$TIMESTAMP - DEBUG :Copying $PANDORA_FILES to $SERVER_IP:$SERVER_PATH" >> $PANDORA_HOME/pandora.log
    else
	# Delete it 
  	rm -f $PANDORA_FILES> /dev/null
    fi
    # Go to bed :-)
    sleep $INTERVAL
done 
# forever! 
