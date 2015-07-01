if [ -f "../SMile.ipa" ]
then
  echo "Uploading ipa"
  scp ../SMile.ipa mad:/var/www/hockey/public/de.fau.cs.mad.SMile.ios/SMile.ipa
else
  echo "Ipa file not found! :-("
fi

