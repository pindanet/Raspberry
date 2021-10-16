<?php
setlocale(LC_ALL, "nl_BE.UTF8");
$forecastSVG = "data/meteogram.svg";
$date = new DateTime();
$forecastIMG = $forecastSVG . "?time=" . $date->getTimestamp(); 

function getForecast() {
  global $forecastSVG;
  $svg = file_get_contents("https://www.yr.no/en/content/2-2800931/meteogram.svg");
//  $viewbox = str_replace('xmlns="http://www.w3.org/2000/svg"', 'xmlns="http://www.w3.org/2000/svg"' . "\n" . '  viewBox="0 105 500 250"', $svg);
  $needle = 'xmlns="http://www.w3.org/2000/svg"';
  $pos = strpos($svg, $needle);
  if ($pos !== false) {
    $viewbox = substr_replace($svg, 'xmlns="http://www.w3.org/2000/svg"' . "\n" . '  viewBox="0 105 500 250"', $pos, strlen($needle));
    file_put_contents($forecastSVG, $viewbox);
  } else {
    file_put_contents($forecastSVG, $svg);
  }

//  file_put_contents($forecastSVG, file_get_contents("https://www.yr.no/en/content/2-2800931/meteogram.svg"));
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
$filename = "data/PresHumiTemp";
if (file_exists($filename)) {
  $preshumitemp = explode("\n", file_get_contents($filename));
  $room = sprintf("Temperatuur: %.1f °C, Luchtdruk: %d hPa, Vochtigheid: %d %%", $preshumitemp[2], $preshumitemp[0], $preshumitemp[1]);
} else {
  $room = sprintf("Temperatuur: %.1f °C, Luchtdruk: %d hPa, Vochtigheid: %d %%", 20.0, 1013, 60);
}


$html = <<<EOD
<img src="{$forecastIMG}" alt="Weerbericht Brugge"></br>
<span class="bme280">{$room}</span>
EOD;

echo $html;

//var_dump($periodTemp);
//echo $period;

//ob_flush();
//ob_start();
//var_dump($files);
//file_put_contents('data/debug', ob_get_flush());

?>
