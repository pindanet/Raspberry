<?php
  // ToDo
  // Sync $Dim with PindaNetMotion.sh
  function getWeather() {
    exec("curl -s 'wttr.in/Brugge?lang=nl&format=j1'", $output);
    file_put_contents("/tmp/wttr", $output);
  }
  if (file_exists("/tmp/wttr")) { // first time
    if ((time()-filectime("/tmp/wttr")) >= 3600) { // older than 1 hour or 3600 sec
      exec("cat /sys/class/backlight/rpi_backlight/brightness", $output);
      if ($output[0] > 0) { // screen lit, somebody in the room
        getWeather();
      }
    }
  } else {
    getWeather();
  }
  echo file_get_contents("/tmp/wttr");
?>
