#!/bin/bash

_echo_info ()
{
  echo "Info: $@"
}

_echo_error ()
{
  echo "Error: $@"
}

_usage ()
{
  _echo_info
  _echo_info "This entry point \`$PATHANDNAME_SCRIPT\` accepts these arguments (called 'CMD' in \`docker\`)"
  _echo_info
  _echo_info '  continous'
  _echo_info "    This is the normal run state. The container runs forever and \`cron\` is working."
  _echo_info "    Therefore, \`storeBackup\` wakes up one time a day and does its job."
  _echo_info
  _echo_info "    You have to ensure, that \`docker\` calls this command after bringing up the container."
  _echo_info "    That is the default behavior with the default 'Dockerfile'."
  _echo_info
  _echo_info '  health-check'
  _echo_info "    If you want \`docker\` to check the health of the container,"
  _echo_info "    let \`docker\` run this command."
  _echo_info "    That is the default behavior with the default 'Dockerfile'."
  _echo_info "    Because of \`storeBackup\` is not running the whole day, the health check"
  _echo_info "    only reports the state of \`cron\`."
  _echo_info
  _echo_info '  run'
  _echo_info "    You can use the \`run\` command to run \`storeBackup\` out of the regular \`cron\` schedules."
  _echo_info "    But remember that \`storeBackup\` prevents itself from running more then once."
  _echo_info '    Please check the logfile.'
  _echo_info
  _echo_info '  stop'
  _echo_info "    Stops/kills a running \`storeBackup\` no matter if \`storeBackup\` is started"
  _echo_info "    via \`cron\` or the 'run' command."
  _echo_info "    It does not stop or shut down the container. Therefore, \`storeBackup\` will"
  _echo_info "    restart with its new \`cron\` cycle or by the 'run' command."
  _echo_info
  _echo_info '    Stopping the container cannot be done within this script.'
  _echo_info "    Please use the \`docker\` mechanisms."
  _echo_info
  _echo_info '  timezones'
  _echo_info '    Lists the <continent>/<city> combinations you can use with the'
  _echo_info '    image environment variable TIMEZONE.'
  _echo_info '    Finally these combinations are noting else then one selected file'
  _echo_info "    from '/usr/share/zoneinfo/*/*'."
  _echo_info '    A few of them deviates from the <continent>/<city> scheme but can also be used.'
  _echo_info
  _echo_info '  timezone <continent>/<city>'
  _echo_info '    Sets the timezone during runtime.'
  _echo_info "    See 'timezones' above for further information."
  _echo_info
}

_get_storebackup_pid ()
{
  PID=''
  SUPPOSED_PID="`cat /tmp/storeBackup.lock 2>/dev/null`"

  if [ -n "$SUPPOSED_PID" ]
  then
    if [ -n "`ps -x | grep \"$SUPPOSED_PID\" | sed -e 's/[[:space:]]\+/ /g' -e 's/^[[:space:]]\+//' | cut -d\  -f5- | grep 'perl /bin/storeBackup'`" ]
    then
      PID="$SUPPOSED_PID"
    fi
  fi
  
  echo "$PID"
}

_stop_storeBackup ()
{
  __list_pid ()
  {       
    PARENT_PID=$1

    echo $PARENT_PID
    for PID in `pgrep --parent $PARENT_PID`
    do      
      __list_pid $PID
    done
  }

  __terminate_or_kill_pid ()
  {
    ___now ()
    {
      date +%s
    }

    PID=$1
    kill $PID 2>/dev/null

    GRACE_PERIOD=15
    WAIT='true'
    FIRST='true'
    START_TIME=`___now`
    while [ "$WAIT" == 'true' ]
    do
      PID_TEXT="`ps -x | grep \"$PID\" | sed -e 's/[[:space:]]\+/ /g' -e 's/^[[:space:]]\+//' | grep -v ' grep ' | cut -d\  -f5-`"
      if [ \( -n "$PID_TEXT" \) ]
      then
        ((WAIT_TIME = `___now` - START_TIME))
        if [ \( "$GRACE_PERIOD" -gt "$WAIT_TIME" \) ]
        then
          if [ "$FIRST" == 'true' ]
          then
            FIRST='false'
            #_echo_info "PID $PID (\"$PID_TEXT\") does not to terminate, start grace period"
          fi
          sleep 1
        else
          #_echo_info "PID $PID (\"$PID_TEXT\") refused to terminated during grace period"
          WAIT='false'
        fi
      else
        #_echo_info "PID $PID terminated during grace period"
        WAIT='false'
      fi
    done

    if [ -n "$PID_TEXT" ]
    then
      #_echo_info "killing PID $PID (\"$PID_TEXT\")"
      kill -9 $PID 2>/dev/null
    fi
  }
      
  PARENT_PID="`_get_storebackup_pid`"
  if [ -n "$PARENT_PID" ]
  then
    for PID in $PARENT_PID `__list_pid $PARENT_PID`
    do
      __terminate_or_kill_pid $PID &
    done
    _echo_info 'waiting until `storeBackup` stoped'
    wait
  else
    _echo_info 'no `storeBackup` running'
  fi
}

_delete_tempdir_content ()
{
  _echo_info 'deleting /tmp content'
  rm -rfv /tmp/*
}


################################################
# commands

#------------------------------------------------
# got the health check argument / CMD
# the container is healthy while cron is running
_health_check ()
{
  _echo_info 'checking health…'

  /etc/init.d/cron status
  HEALTHSTATUS=$?
  
  if [ $HEALTHSTATUS -eq 0 ]
  then
    HEALTHSTATUS_TEXT='healthy'
  else
    HEALTHSTATUS_TEXT='unhealthy'
  fi
  
  _echo_info "…health checked: $HEALTHSTATUS_TEXT"
  return $HEALTHSTATUS
}

#------------------------------------------------
# got the continous running argument / CMD
_continous ()
{
  __set_timezone ()
  {
    NEW_TIMEZONE="$1"
    SYSTEM_TIMEZONE=`cat '/etc/timezone'`

    if [ "$NEW_TIMEZONE" == "$SYSTEM_TIMEZONE" ]
    then
      STATUS=0
    else
      _timezone "$NEW_TIMEZONE"
      STATUS=$?
    fi

    return "$STATUS"
  }

  __gen_example_configfile ()
  {
    # generate an example storeBackup config file

    if [ -z "`run-parts --list \"$CONFIGDIR\"`" ]
    then
      CONFIGFILE_EXAMPLE="$CONFIGDIR/.example"
      if [ ! -e "$CONFIGFILE_EXAMPLE" ]
      then
        _echo_info "generateing an example config file \"$CONFIGFILE_EXAMPLE\""
        CONFIGFILE_EXAMPLE_RAW="`mktemp --dry-run`"
        storeBackup --generate "$CONFIGFILE_EXAMPLE_RAW"
        sed -e "s|;[[:space:]]*\(sourceDir[[:space:]]*=[[:space:]]*\)|\1$INDIR|" -e "s|;[[:space:]]*\(backupDir[[:space:]]*=[[:space:]]*\)|\1$OUTDIR|" -e "s|;[[:space:]]*\(logFile[[:space:]]*=[[:space:]]*\)|\1$OUTDIR/logFile|" "$CONFIGFILE_EXAMPLE_RAW" > "$CONFIGFILE_EXAMPLE"
        rm -f "$CONFIGFILE_EXAMPLE_RAW"
      fi
    fi
  }

  __start_cron ()
  {
    # cron does the daily start of storeBackup

    _echo_info 'starting `cron`'
    /etc/init.d/cron start
  }

  __run_content ()
  {
    # running forever

    _echo_info 'entered continous mode…'
    while true
    do
      sleep 2
    done
  }

  __stop_content ()
  {
    _echo_info 'stoping content…'

    _echo_info 'stoping `storeBackup` if running…'
    _stop_storeBackup

    _echo_info 'stoping `cron`…'
    /etc/init.d/cron status && /etc/init.d/cron stop

    # /tmp should be empty after bringing up the container again
    _delete_tempdir_content

    _echo_info '… stoped content'
    exit 0
  }


  _echo_info 'entering continous mode…'

  # check if we are already in continous running mode
  _health_check
  HEALTH=$?
  if [ $HEALTH -eq 0 ]
  then
    _echo_info 'being healthy at this point is not good!'
    _echo_error 'already running in continous mode, refusing to run more then once.'
  else
    _echo_info 'being unhealthy at this point is good!'

    # set the timezone
    __set_timezone "$TIMEZONE"
    STATUS=$?

    if [ "$STATUS" -eq 0 ]
    then
      # /tmp is not empty after bringing up a container
      _delete_tempdir_content

      # generate an example storeBackup config file
      # when there is no usable configfile at all and the example dont exist yet
      __gen_example_configfile

      # start the `cron` daemon
      __start_cron

      # catch docker signals:
      # docker stop = SIGTERM
      _echo_info 'traping docker signals'
      trap __stop_content SIGTERM

      # run the container content forever
      __run_content
      # this line is never reached
    fi
  fi
}

#------------------------------------------------
# got the run argument / CMD
# `storeBackup` shall run once
_run ()
{
  _echo_info 'running once…'

  PID="`_get_storebackup_pid`"
  if [ -n "$PID" ]
  then
    _echo_error '`storeBackup` is already running, refusing to run more then one.'
  else
    # /tmp maybe not clean after a cron cyclus
    _delete_tempdir_content

    # start `storeBackup`
    _echo_info 'running `storeBackup`…'
    /etc/cron.daily/storebackup

    # keep /tmp clean as possible
    _delete_tempdir_content
  fi

  _echo_info '…ran once'
}


#------------------------------------------------
# got the stop argument / CMD
# `storeBackup` shall stop
_stop ()
{
  _echo_info 'stopping `storeBackup`…'

  _stop_storeBackup

  # keep /tmp clean as possible
  _delete_tempdir_content

  _echo_info '…stoped `storeBackup`'
}


#------------------------------------------------
# got the timezones argument / CMD
# show all possible timezones
_timezones ()
{
  _echo_info 'show timezones…'

  (
    cd /usr/share/zoneinfo/

    for POSSIBLE_TIMEZONE in */*
    do
      if [ -f "$POSSIBLE_TIMEZONE" ]
      then
        echo "$POSSIBLE_TIMEZONE"
      fi
    done
  )

  _echo_info '…shown timezones'
}


#------------------------------------------------
# got the timezone argument / CMD
# set the timezone
_timezone ()
{
  _echo_info 'set timezone…'
  
  TIMEZONE="$1"
  ZONEINFOFILE="/usr/share/zoneinfo/$TIMEZONE"

  if [ -f "$ZONEINFOFILE" ]
  then
    rm -f '/etc/localtime'
    ln -sfv "$ZONEINFOFILE" '/etc/localtime'
    echo "$TIMEZONE" > '/etc/timezone'
    dpkg-reconfigure --frontend noninteractive tzdata
    STATUS=0
  else
    _echo_error "timezone \"$TIMEZONE\" does not exist."
    STATUS=1
  fi
  _echo_info '…set timezone'
  return "$STATUS"
}


#------------------------------------------------
# got an unknown argument / CMD
_unknown ()
{
  # show usage
  _usage
}


#################################################
# Argument / CMD dispatcher

DIR_WORKING="`pwd`";cd "`dirname \"$0\"`";DIR_SCRIPT="`pwd`";cd "$DIR_WORKING";NAME_SCRIPT="`basename \"$0\"`"
PATHANDNAME_SCRIPT="`echo \"$DIR_SCRIPT/$NAME_SCRIPT\"|sed 'sX/\+X/Xg'`"

_echo_info "entering \`$PATHANDNAME_SCRIPT\` with CMD \"$@\""

export INDIR='/in'
export OUTDIR='/out'
export CONFIGDIR='/etc/storebackup.d'

case "$1" in
  health-check) \
    _health_check
    exit $?
    ;;
  continous) \
    _continous
    # this line is only reached in case of an error
    exit 1
    ;;
  run) \
    _run
    exit 0
    ;;
  stop) \
    _stop
    exit 0
    ;;
  timezones) \
    _timezones
    exit 0
    ;;
  timezone) \
    _timezone "$2"
    exit $?
    ;;
  *) \
    _unknown
    exit 1
    ;;
esac

_echo_error 'unexpected termination! Aborting!'
exit 1
