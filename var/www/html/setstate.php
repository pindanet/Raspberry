<?php
$state = htmlspecialchars($_POST["state"]);

exec("cat /sys/class/backlight/rpi_backlight/bl_power", $output, $return);
echo $output[0];

$myfile = fopen("/var/www/html/data/debug.txt", "a") or die("Unable to open file!");
fwrite($myfile, date("l d/m/Y H:i:s: ") . $state . ".\n");
fclose($myfile);
?>
