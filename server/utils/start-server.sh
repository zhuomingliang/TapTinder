#!/bin/bash

function echo_help {
cat <<USAGE_END
Usage:
  utils/start-server.sh dev|copy|prod d|dp|f start|stop

  dev ... devel
  copy ... copy of production
  prod ... production
  
  d ... http server, normal engine
  dp ... http server, Prefork::Engine
  f ... FastCGI

Example:
  utils/start-server.sh dev d
  utils/start-server.sh dev f start
  utils/start-server.sh dev f stop

USAGE_END
}


function start_fastcgi {
    TYPE=$1
    CMD=$2
    CMD_PAR=$3
    PORT_DEV=$4
    PORT_FCGI=$5
    PIDFNAME=$6

    if [ "$CMD" == "d" -o "$CMD" == "dp" ]; then 
        # devel debugging
        if [ "$TYPE" == "dev" ]; then
            export DBIC_TRACE=1
            export CATALYST_DEBUG=1
        fi
    
        # prefork engine
        if [ "$CMD" == "dp" ]; then
          export CATALYST_ENGINE='HTTP::Prefork'
        fi 
        
        # start normal engine
        perl script/taptinder_web_server.pl -r -p $PORT_DEV
        exit
    fi
    
    
    if [ "$CMD" == "f" ]; then 
        if [ "$CMD_PAR" == "start" ]; then 
            # start fastcgi engine
            perl script/taptinder_web_fastcgi.pl -l :$PORT_FCGI -n 2 -p $PIDFNAME -d
            exit
        fi
 
        if [ "$CMD_PAR" == "stop" ]; then 
            if [ -f "$PIDFNAME" ]; then
                kill `cat $PIDFNAME`
            else
                echo "Can't find file '$PIDFNAME'."
            fi
            exit
        fi
    fi

    echo_help
    exit
}


TYPE="$1"
CMD="$2"
CMD_PAR="$3"

if [ "$TYPE" == "dev" ]; then
    start_fastcgi "$TYPE" "$CMD" "$CMD_PAR" 2000 3000 "temp/ttdev.pid"
fi

if [ "$TYPE" == "copy" ]; then
    start_fastcgi "$TYPE" "$CMD" "$CMD_PAR" 2000 4000 "temp/ttcopy.pid"
fi

if [ "$TYPE" == "prod" ]; then
    start_fastcgi "$TYPE" "$CMD" "$CMD_PAR" 2000 5000 "temp/tt.pid"
fi


echo_help
