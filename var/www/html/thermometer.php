<?php
exec("python /var/www/html/bme280.py", $output, $return);
$temp = explode(" ", $output[2]);
$pres = explode(" ", $output[3]);
$humi = explode(" ", $output[4]);
printf("<span id=\"temp\">%.1f °C</span><br><span id=\"date\">Luchtdruk: %d hPa Vochtigheid: %d %%</span>", $temp[3], $pres[3], $humi[3]);

//ob_flush();
//ob_start();
//var_dump($output);
//file_put_contents('data/debug', ob_get_flush());
?>
