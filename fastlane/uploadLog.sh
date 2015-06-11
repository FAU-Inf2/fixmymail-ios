if [ -f "../log.txt" ]
then
  echo "Uploading log file..."
  scp ../log.txt mad:/var/www/hockey/public/de.fau.cs.mad.fixmymail.ios
fi
