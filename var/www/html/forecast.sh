#!/bin/bash
echo -e "Content-type: text/html\n"

# sudo apt-get install libxml2-utils
# wget -O forecast.xml "https://www.yr.no/place/Belgium/Flanders/Bruges/forecast.xml"
# wget -O forecast_hour_by_hour.xml "https://www.yr.no/place/Belgium/Flanders/Bruges//forecast_hour_by_hour.xml"
# xmllint --xpath "string(//weatherdata/meta/nextupdate)" data/forecast.xml
# xmllint --xpath "string(//weatherdata/forecast/tabular/time/temperature/@value)" data/forecast.xml
# xmllint --xpath "string(//weatherdata/forecast/tabular/time[@to='2017-08-11T06:00:00']/temperature/@value)" data/forecast.xml
# xmllint --xpath "count(//weatherdata/forecast/tabular/time)" data/forecast.xml

export LANG=nl_BE.UTF-8

forecastXML="/var/www/html/data/forecast.xml"
if [ -f "$forecastXML" ]; then
  nextupdate=$(date -d `xmllint --xpath "string(//weatherdata/meta/nextupdate)" "$forecastXML"` +"%s")
  if [ $(date +"%s") -gt $nextupdate ]; then
    wget -O $forecastXML "https://www.yr.no/place/Belgium/Flanders/Bruges/forecast.xml"
  fi
else
  wget -O $forecastXML "https://www.yr.no/place/Belgium/Flanders/Bruges/forecast.xml"
fi
period=$(xmllint --xpath "string(//weatherdata/forecast/tabular/time[1]/@period)" "$forecastXML")
item=$period
while [ $period -lt 32 ]; do
  periodTemp[$period]=$(xmllint --xpath "string(//weatherdata/forecast/tabular/time[$((period - item + 1))]/temperature/@value)" "$forecastXML")°
  periodWeather[$period]=$(xmllint --xpath "string(//weatherdata/forecast/tabular/time[$((period - item + 1))]/symbol/@var)" "$forecastXML")
#  echo $period ${periodTemp[$period]}
  ((period++))
done

cat <<EOF
  <tr><td colspan="9"><img src="https://www.yr.no/place/Belgium/Flanders/Bruges/avansert_meteogram.svg" alt="Weerbericht Brugge" width="800" onclick="menu();"></td></tr>
  <tr><td colspan="9"><a href="$(xmllint --xpath "string(//weatherdata/credit/link/@url)" "$forecastXML")" target="_blank">$(xmllint --xpath "string(//weatherdata/credit/link/@text)" "$forecastXML")</a></td></tr>
  <tr><td colspan="9">$(/var/www/html/bme280.sh)</td></tr>
  <tr>
    <td></td>
    <td>vandaag</td>
    <td>$(date --date='1 day' +"%a %d/%m")</td>
    <td>$(date --date='2 day' +"%a %d/%m")</td>
    <td>$(date --date='3 day' +"%a %d/%m")</td>
    <td>$(date --date='4 day' +"%a %d/%m")</td>
    <td>$(date --date='5 day' +"%a %d/%m")</td>
    <td>$(date --date='6 day' +"%a %d/%m")</td>
    <td>$(date --date='7 day' +"%a %d/%m")</td>
  </tr>
  <tr>
    <td>3u</td>
    <td>${periodTemp[0]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[0]}" /></svg></td>
    <td>${periodTemp[4]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[4]}" /></svg></td>
    <td>${periodTemp[8]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[8]}" /></svg></td>
    <td>${periodTemp[12]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[12]}" /></svg></td>
    <td>${periodTemp[16]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[16]}" /></svg></td>
    <td>${periodTemp[20]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[20]}" /></svg></td>
    <td>${periodTemp[24]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[24]}" /></svg></td>
    <td>${periodTemp[28]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[28]}" /></svg></td>
  <tr>
  <tr>
    <td>9u</td>
    <td>${periodTemp[1]}</td>
    <td>${periodTemp[5]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[5]}" /></svg></td>
    <td>${periodTemp[9]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[9]}" /></svg></td>
    <td>${periodTemp[13]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[13]}" /></svg></td>
    <td>${periodTemp[17]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[17]}" /></svg></td>
    <td>${periodTemp[21]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[21]}" /></svg></td>
    <td>${periodTemp[25]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[25]}" /></svg></td>
    <td>${periodTemp[29]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[29]}" /></svg></td>
  <tr>
  <tr>
    <td>15u</td>
    <td>${periodTemp[2]}</td>
    <td>${periodTemp[6]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[6]}" /></svg></td>
    <td>${periodTemp[10]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[10]}" /></svg></td>
    <td>${periodTemp[14]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[14]}" /></svg></td>
    <td>${periodTemp[18]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[18]}" /></svg></td>
    <td>${periodTemp[22]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[22]}" /></svg></td>
    <td>${periodTemp[26]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[26]}" /></svg></td>
    <td>${periodTemp[30]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[30]}" /></svg></td>
  <tr>
  <tr>
    <td>21u</td>
    <td>${periodTemp[3]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[3]}" /></svg></td>
    <td>${periodTemp[7]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[7]}" /></svg></td>
    <td>${periodTemp[11]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[11]}" /></svg></td>
    <td>${periodTemp[15]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[15]}" /></svg></td>
    <td>${periodTemp[19]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[19]}" /></svg></td>
    <td>${periodTemp[23]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[23]}" /></svg></td>
    <td>${periodTemp[27]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[27]}" /></svg></td>
    <td>${periodTemp[31]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[31]}" /></svg></td>
  <tr>
EOF
