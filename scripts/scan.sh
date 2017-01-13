#!/bin/bash -u
#
# See https://nmap.org/book/ndiff-man-periodic.html
#
# TARGETS should be set by env variable
# MAILTO should be set by env variable
# SLEEP how many to wait between runs
#

if [ "${TARGETS:-}" == "" ]; then
    echo "TARGETS not set (space separated list of servers to scan)"
    exit
fi

if [ "${MAILTO:-}" == "" ]; then
    echo "MAILTO not set (email to send diffs to)"
    exit
fi

if [ "${INTERVAL:-}" == "" ]; then
    echo "INTERVAL not set (second to sleep between runs)"
    exit
fi

if [ "${OPTIONS:-}" == "" ]; then
    OPTIONS='-Pn'
fi

cd /results
LAST_RUN_FILE='.lastrun'

while true; do

    # If the last run file exists, we should only sleep for the time
    # specified minus the time that's already elapsed.
    if [ -e "${LAST_RUN_FILE}" ]; then
        LAST_RUN_TS=$(date -r ${LAST_RUN_FILE} +%s)
        NOW_TS=$(date +%s)
        LAST_RUN_SECS=$(expr ${NOW_TS} - ${LAST_RUN_TS})
        SLEEP=$(expr ${INTERVAL} - ${LAST_RUN_SECS})
        if [ ${SLEEP} -gt 0 ]; then
            UNTIL_SECS=$(expr ${NOW_TS} + ${SLEEP})
            echo $(date) "- sleeping until" $(date --date="@${UNTIL_SECS}") "(${SLEEP}) seconds"
            sleep ${SLEEP}
        fi
    fi

    START_TIME=$(date +%s)
    echo $(date) '- starting all targets, options: ' ${OPTIONS}
    echo '=================='

    DATE=`date +%Y-%m-%d_%H-%M-%S`
    for TARGET in ${TARGETS}; do
        CUR_LOG=scan-${TARGET/\//-}-${DATE}.xml
        PREV_LOG=scan-${TARGET/\//-}-prev.xml
        DIFF_LOG=scan-${TARGET/\//-}-diff

        echo
        echo $(date) "- starting ${TARGET}"
        echo "------------------"

        # Scan the target
        nmap ${OPTIONS} ${TARGET} -oX ${CUR_LOG}

        # If there's a previous log, diff it
        if [ -e ${PREV_LOG} ]; then

            # Exclude the Nmap version and current date - the date always changes
            ndiff ${PREV_LOG} ${CUR_LOG} | egrep -v '^(\+|-)Nmap ' > ${DIFF_LOG}
            if [ -s ${DIFF_LOG} ]; then
                # The diff isn't empty, show it on screen for docker logs and email it
                echo 'Emailing diff log:'
                cat ${DIFF_LOG}
                cat ${DIFF_LOG} | mail -s "nmap scan diff for ${TARGET}" ${MAILTO}

                # Set the current nmap log file to reflect the last date changed
                ln -sf ${CUR_LOG} ${PREV_LOG}
            else
                # No changes so remove our current log
                rm ${CUR_LOG}
            fi
            rm ${DIFF_LOG}
        else
            # Create the previous scan log
            ln -sf ${CUR_LOG} ${PREV_LOG}
        fi
    done

    touch ${LAST_RUN_FILE}
    END_TIME=$(date +%s)
    echo
    echo $(date) "- finished all targets in" $(expr ${END_TIME} - ${START_TIME}) "second(s)"
done
