<?php
setlocale(LC_ALL, "nl_BE.UTF8");
$forecastURL = "https://www.yr.no/place/Belgium/Flanders/Bruges/";
$forecastXML = "data/forecast.xml";
$forecastSVG = "data/avansert_meteogram.svg";
$forecastPNG = "data/avansert_meteogram.png";
$date = new DateTime();
$forecastIMG = $forecastPNG . "?time=" . $date->getTimestamp(); 

function getForecast() {
  global $forecastURL, $forecastXML, $forecastSVG, $forecastPNG;
  file_put_contents($forecastXML, file_get_contents($forecastURL . "forecast.xml"));
  file_put_contents($forecastSVG, file_get_contents($forecastURL . "avansert_meteogram.svg"));
  exec("inkscape -z -e $forecastPNG -w 800 $forecastSVG");
}

if (file_exists($forecastSVG)) {
    $filemtime = filemtime($forecastSVG);
    $currtime = time();
    if (($currtime - $filemtime) > 3600) { // weerbericht is één uur geldig
      getForecast();
    }
} else {
    getForecast();
}
$xml = simplexml_load_file($forecastXML);

$period = intval($xml->{'forecast'}->{'tabular'}->{'time'}[0]->attributes()->{'period'});
$item = $period;
while ($period < 32) {
  $periodTemp[$period] = (string) $xml->{'forecast'}->{'tabular'}->{'time'}[$period - $item]->{'temperature'}->attributes()->{'value'} . "°";
  $periodWeather[$period] = (string) $xml->{'forecast'}->{'tabular'}->{'time'}[$period - $item]->{'symbol'}->attributes()->{'var'};
  $period++;
}

$creditURL = (string) $xml->{'credit'}->{'link'}->attributes()->{'url'};
$credit = (string) $xml->{'credit'}->{'link'}->attributes()->{'text'};
for ($i = 1; $i < 8; $i++) {
  $day[$i] = strftime("%a %d/%m", mktime(0, 0, 0, date("m")  , date("d") + $i, date("Y")));
  echo $day[$i];
}

$filename = "data/PresHumiTemp";
if (file_exists($filename)) {
  $preshumitemp = explode("\n", file_get_contents($filename));
  $room = sprintf("Temperatuur: %.1f °C, Luchtdruk: %d hPa, Vochtigheid: %d %%", $preshumitemp[2], $preshumitemp[0], $preshumitemp[1]);
} else {
  $room = sprintf("Temperatuur: %.1f °C, Luchtdruk: %d hPa, Vochtigheid: %d %%", 20.0, 1013, 60);
}


$html = <<<EOD
<table id="forecast">
  <tr><th colspan="9"><a href="{$creditURL}" target="_blank">{$credit}</a></td></th>
  <tr><td colspan="9"><img src="{$forecastIMG}" alt="Weerbericht Brugge" width="800"></td></tr>
  <tr>
    <td></td>
    <td>vandaag</td>
    <td>{$day[1]}</td>
    <td>{$day[2]}</td>
    <td>{$day[3]}</td>
    <td>{$day[4]}</td>
    <td>{$day[5]}</td>
    <td>{$day[6]}</td>
    <td>{$day[7]}</td>
  </tr>
  <tr>
    <td>3u</td>
    <td>{$periodTemp[0]} <svg viewbox="0 0 100 100"><use xlink:href="#s{$periodWeather[0]}" /></svg></td>
    <td>{$periodTemp[4]} <svg viewbox="0 0 100 100"><use xlink:href="#s{$periodWeather[4]}" /></svg></td>
    <td>{$periodTemp[8]} <svg viewbox="0 0 100 100"><use xlink:href="#s{$periodWeather[8]}" /></svg></td>
    <td>{$periodTemp[12]} <svg viewbox="0 0 100 100"><use xlink:href="#s{$periodWeather[12]}" /></svg></td>
    <td>{$periodTemp[16]} <svg viewbox="0 0 100 100"><use xlink:href="#s{$periodWeather[16]}" /></svg></td>
    <td>{$periodTemp[20]} <svg viewbox="0 0 100 100"><use xlink:href="#s{$periodWeather[20]}" /></svg></td>
    <td>{$periodTemp[24]} <svg viewbox="0 0 100 100"><use xlink:href="#s{$periodWeather[24]}" /></svg></td>
    <td>{$periodTemp[28]} <svg viewbox="0 0 100 100"><use xlink:href="#s{$periodWeather[28]}" /></svg></td>
  <tr>
  <tr>
    <td>9u</td>
    <td>${periodTemp[1]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[1]}" /></svg></td>
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
    <td>${periodTemp[2]} <svg viewbox="0 0 100 100"><use xlink:href="#s${periodWeather[2]}" /></svg></td>
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
  <tr><th class="bme280" colspan="9">{$room}</th></tr>
</table>
EOD;

echo $html;

//var_dump($periodTemp);
//echo $period;

//ob_flush();
//ob_start();
//var_dump($files);
//file_put_contents('data/debug', ob_get_flush());

?>
