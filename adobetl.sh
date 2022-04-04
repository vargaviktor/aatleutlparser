#!/bin/bash

url1="https://trustlist.adobe.com/eutl12.acrobatsecuritysettings"
url2="https://trustlist.adobe.com/tl12.acrobatsecuritysettings"
url3="https://trustlist.adobe.com/tl.beta/tl12.acrobatsecuritysettings"

echo "(i) Downloading EUTL and AATL PDF and AATL Beta (new candidates) and extracting the XML settings attachment"
curl ${url1} --output eutl.pdf
pdfdetach -savefile SecuritySettings.xml eutl.pdf
mv SecuritySettings.xml sseutl.xml
curl ${url2} --output aatl.pdf
pdfdetach -savefile SecuritySettings.xml aatl.pdf
mv SecuritySettings.xml ssaatl.xml

curl ${url3} --output aatlbeta.pdf
pdfdetach -savefile SecuritySettings.xml aatlbeta.pdf
mv SecuritySettings.xml ssaatlbeta.xml


echo "(i) Grepping date from PDFs"
aatldate="$(grep --text 'PPKLite' aatl.pdf | sed 's/.*M(D://; s/)\/Name.*//')"
aatlbetadate="$(grep --text 'PPKLite' aatlbeta.pdf | sed 's/.*M(D://; s/)\/Name.*//')"
eutldate="$(grep --text 'PPKLite' eutl.pdf | sed 's/.*M(D://; s/)\/Name.*//')"

echo "(i) AATL signature date:" $aatldate
echo "(i) EUTL signature date:" $eutldate
echo "(i) AATL Beta signature date:" $aatlbetadate


echo "Signature time:" $aatldate > aatl.xml
echo "Signature time:" $aatlbetadate > aatlbeta.xml
echo "Signature time:" $eutldate > eutl.xml

echo "(i) Parsing certificate data from EUTL"
input="sseutl.xml"
while IFS= read line
do
    if [[ $line = *"<Certificate>"* ]]; then
	subject='"'
	subject+=`echo $line | sed 's/<\/Certificate>//; s/<Certificate>//' | base64 -d | openssl x509 -subject -noout -inform DER`
	subject+='",'
	echo $subject >> eutl.xml
    else 
	echo $line >> eutl.xml
    fi
done < "$input"

echo "(i) Parsing certificate data for AATL"
input="ssaatl.xml"
while IFS= read line
do
    if [[ $line = *"<Certificate>"* ]]; then
	subject='"'
	subject+=`echo $line | sed 's/<\/Certificate>//; s/<Certificate>//' | base64 -d | openssl x509 -subject -noout -inform DER`
	subject+=','
	echo $subject >> aatl.xml
    else 
	echo $line >> aatl.xml
    fi
done < "$input"

echo "(i) Parsing certificate data for AATL Beta"
input="ssaatlbeta.xml"
while IFS= read line
do
    if [[ $line = *"<Certificate>"* ]]; then
	subject='"'
	subject+=`echo $line | sed 's/<\/Certificate>//; s/<Certificate>//' | base64 -d | openssl x509 -subject -noout -inform DER`
	subject+=','
	echo $subject >> aatlbeta.xml
    else 
	echo $line >> aatlbeta.xml
    fi
done < "$input"


cp -i aatl.xml aatl-$aatldate.xml
cp -i aatlbeta.xml aatlbeta-$aatlbetadate.xml
cp -i eutl.xml eutl-$eutldate.xml
