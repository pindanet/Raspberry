<?php

$forecastURL = "https://www.yr.no/place/Belgium/Flanders/Bruges/";
$forecastXML = "data/forecast.xml";
$forecastSVG = "data/avansert_meteogram.svg";

function getForecast() {
  global $forecastURL, $forecastXML, $forecastSVG;
  file_put_contents($forecastXML, file_get_contents($forecastURL . "forecast.xml"));
  file_put_contents($forecastSVG, file_get_contents($forecastURL . "avansert_meteogram.svg"));
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

//var_dump($xml);

//foreach ($xml->weatherdata as $key => $value) {
 // foreach ($value as $key => $value) {
//    echo $key.": ".$value."</br>";
//  }
//}
$period = intval($xml->{'forecast'}->{'tabular'}->{'time'}[0]->attributes()->{'period'});
$item = $period;
while ($period < 32) {
  $periodTemp[$period] = (string) $xml->{'forecast'}->{'tabular'}->{'time'}[$period - $item]->{'temperature'}->attributes()->{'value'};
  $periodWeather[$period] = (string) $xml->{'forecast'}->{'tabular'}->{'time'}[$period - $item]->{'symbol'}->attributes()->{'var'};
  $period++;
}
var_dump($periodTemp);
echo $period;

//ob_flush();
//ob_start();
//var_dump($files);
//file_put_contents('data/debug', ob_get_flush());

?>
