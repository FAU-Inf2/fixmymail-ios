if [ -f "../$LOG" ]
then
  echo "Uploading log file $LOG"
  scp ../$LOG mad:/var/www/smile/log
fi
