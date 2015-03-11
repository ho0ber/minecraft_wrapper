#!/bin/bash

MEM=512M

control_c()
{
  echo " "
  echo "**********************************************" | tee -a server.log
  echo "[`date +%H:%M:%S`] SERVER TERMINATED BY CONTROL-C" | tee -a server.log
  echo "**********************************************" | tee -a server.log
  exit $?
}

run_server()
{
  echo "**********************************************" | tee -a server.log
  echo "[`date +%H:%M:%S`] CHECKING FOR UPDATES" | tee -a server.log
  echo "**********************************************" | tee -a server.log

  current_version=$(ls minecraft_server.* | sed -En 's/.*minecraft_server\.([^\s]*)\.jar.*/\1/p' | tail -n1)
  latest_version=$(curl -s https://minecraft.net/download | sed -En 's/.*minecraft_server\.([^\s]*)\.jar.*/\1/p')

  if [[ "$current_version" != "$latest_version" ]]
  then
    echo "[`date +%H:%M:%S`] NOT CURRENT: GETTING $latest_version" | tee -a server.log
    curl -sO https://s3.amazonaws.com/Minecraft.Download/versions/$latest_version/minecraft_server.$latest_version.jar
    current_version=$latest_version
  else
    echo "[`date +%H:%M:%S`] Up to date! Version $latest_version" | tee -a server.log
  fi

  echo "**********************************************" | tee -a server.log
  echo "[`date +%H:%M:%S`] STARTING UP SERVER" | tee -a server.log
  echo "**********************************************" | tee -a server.log

  sed -i -e 's/^eula=false*$/eula=true/' eula.txt

  chatrx="\[\S+\] \[Server thread\/INFO\]: <(\S+)> (.+)"

  java -Xmx$MEM -Xms$MEM -jar minecraft_server.$latest_version.jar nogui | while read -r line
  do
    if [[ $line =~ $chatrx ]]
    then
      if [ "${BASH_REMATCH[2]}" = "!restart" ]
      then
        echo "**********************************************" | tee -a server.log
        echo "[`date +%H:%M:%S`] SERVER TERMINATED BY ${BASH_REMATCH[1]}" | tee -a server.log
        echo "**********************************************" | tee -a server.log
        killall java #whaaaaaat.
        exit
      fi
    fi

    echo "[`date +%H:%M:%S`]  $line" | tee -a server.log
  done
}

trap control_c SIGINT

# MAIN
while true; do run_server; done
