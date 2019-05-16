<?php
$state = htmlspecialchars($_POST["state"]);

exec("cat /sys/class/backlight/rpi_backlight/bl_power", $output, $return);

$myfile = fopen("/var/www/html/data/debug.txt", "a") or die("Unable to open file!");
fwrite($myfile, date("l d/m/Y H:i:s: ") . $state . ".\n");
fclose($myfile);

if ($output[0] == 0 && $state == "sleep") {
  exec("echo 1 | sudo /usr/bin/tee /sys/class/backlight/rpi_backlight/bl_power");
}
if ($output[0] == 1 && $state == "awake") {
  exec("echo 0 | sudo /usr/bin/tee /sys/class/backlight/rpi_backlight/bl_power");
}
?>
