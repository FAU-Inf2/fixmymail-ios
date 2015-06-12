if [ -f "../$LOG" ]
then
  echo "Uploading log file $LOG"
  scp ../$LOG mad:/var/www/hockey/public/de.fau.cs.mad.fixmymail.ios
fi
