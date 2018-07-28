#!/bin/sh
RPM_C=$(rpm -qa | grep -i vrtsvcs | wc -l )
if [ $RPM_C -ne 0 ]; then
                NODES=$(/opt/VRTSvcs/bin/hasys -list | tr '\n' '  ' | sed 's/ $/\n/')
        NODE_C=$(/opt/VRTSvcs/bin/hasys -list | wc -l)
		echo -e "\t No of nodes in cluster              : $NODE_C"
        echo -e "\t+-----------------+-------------+--------+"
        echo -e "\t|     System      |    State    | Frozen |"
        echo -e "\t+-----------------+-------------+--------+"

        for i in $(echo $NODES)
                do
                C_HST=$(/opt/VRTSvcs/bin/hastatus -sum | grep "\-\- System" -A`expr "$NODE_C" + 1` | sed '/^$/d' | grep "$i" | awk '{print $2}')
                C_STAT=$(/opt/VRTSvcs/bin/hastatus -sum | grep "\-\- System" -A`expr "$NODE_C" + 1` | sed '/^$/d' | grep "$i" | awk '{print $3}')
                C_FROZ=$(/opt/VRTSvcs/bin/hastatus -sum | grep "\-\- System" -A`expr "$NODE_C" + 1` | sed '/^$/d' | grep "$i" | awk '{print $4}')
                printf "\t""| %-15s | %-11s | %-6s |\n" "$C_HST" "$C_STAT" "$C_FROZ"
                done
        echo -e "\t+-----------------+-------------+--------+"
        CLUS_S=$(/opt/VRTSvcs/bin/hastatus -sum | grep "ClusterService" | awk '{print $6}' | grep "ONLINE" -c)
                if [ $CLUS_S -eq 0 ]; then
                                CLUS_SER=$(/opt/VRTSvcs/bin/hastatus -sum | grep "ClusterService" | grep -v "ONLINE" | awk '{print $3}' | tr '\n' ' ')
                                CLUS_SER="Cluster service is not running $CLUS_SER"
                        else
                                CLUS_SER="Cluster Service runnig fine."
                fi

        CVM=$(/opt/VRTSvcs/bin/hastatus -sum | grep cvm | grep "ONLINE" | wc -l)
                if [ $CVM -ne $NODE_C ]; then
                                CVM_STAT=$(/opt/VRTSvcs/bin/hastatus -sum | grep cvm | grep -v "ONLINE" | awk '{print $3}')
                                CVM_STAT="Cvm is not online for $CVM_STAT"
                        else
                                CVM_STAT="All cvm service are running fine"
                fi


                PSG=$(/opt/VRTSvcs/bin/hastatus -sum | grep psg | awk '{print $2}'| uniq)
                for i in $PSG;
                do
                        #if [ "$(/opt/VRTSvcs/bin/hastatus -sum | grep "\-psg" |grep "db-ucsmsvt-psg" | grep "ONLINE" -c)" -ne $NODE_C ]; then
                        #if [ "$(/opt/VRTSvcs/bin/hastatus -sum | grep "\-psg" |grep "$i" | grep "ONLINE" -c)" -ne 1 ]; then
                        if [ "$(/opt/VRTSvcs/bin/hastatus -sum | grep "\-psg" |grep "$i" | grep "ONLINE" -c)" -ne $NODE_C ]; then
                                #PSG_STAT="$PSG_STAT;$i"
                                PSG_STAT="$PSG_STAT;$i"
                        fi

                done
                if [ -z "$PSG_STAT" ]; then

                        PSG_STATUS="All psg group are running fine."
                else

                        PSG_STATUS="Psg group is offline for (`echo $PSG_STAT | sed -e 's/;/ /g'`)"
                fi
                
				
				FSG=$(/opt/VRTSvcs/bin/hastatus -sum | grep fsg | awk '{print $2}'| uniq)
                for i in $FSG;
                do
                        if [ "$(/opt/VRTSvcs/bin/hastatus -sum | grep "\-fsg" |grep "$i" | grep "ONLINE" -c)" -ne 1  ]; then
                                FSG_STAT="$FSG_STAT;$i"
                        fi

                done
                if [ -z "$FSG_STAT" ]; then

                        FSG_STATUS="All fsg group are running fine."
                else

                        FSG_STATUS="Fsg group is offline for (`echo $FSG_STAT | sed -e 's/;/ /g'`)"
                fi

        echo -e "\n"
        echo -e "\t Cluster Status                      : $CLUS_SER"
        echo -e "\t Cvm Status                          : $CVM_STAT"
        echo -e "\t Psg Status                          : $PSG_STATUS"
		echo -e "\t Fsg Status                          : $FSG_STATUS"

        else
                echo "Host is not in cluster"
fi
