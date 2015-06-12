if [ -f "../FixMyMail.ipa" ]
then
  echo "Uploading ipa"
  scp ../FixMyMail.ipa mad:/var/www/hockey/public/de.fau.cs.mad.fixmymail.ios/fixmymail.ipa
else
  echo "Ipa file not found! :-("
fi

