<?php
$state = htmlspecialchars($_POST["state"]);

//ob_flush();
//ob_start();
//var_dump($state);
//file_put_contents('data/debug', ob_get_flush());

switch ($state) {
  case "awake":
    exec("echo 0 | sudo /usr/bin/tee /sys/class/backlight/rpi_backlight/bl_power");
    exit();
    break;
  case "sleep":
    exec("echo 1 | sudo /usr/bin/tee /sys/class/backlight/rpi_backlight/bl_power");
    exit();
    break;
}
?>
