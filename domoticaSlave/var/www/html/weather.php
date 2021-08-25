<?php
  // ToDo
  // Sync $Dim with PindaNetMotion.sh
  function getWeather() {
    $silent = true;
    $wttrfile = fopen("/tmp/wttr", "w") or die("Unable to open file!");
    exec("curl -s wttr.in/Brugge?lang=nl | head -7 | tail -5 | aha", $output);
    foreach ($output as $line) {
      if(strpos($line, "<pre>") !== false){
        $silent = false;
      }
      if(strpos($line, "</pre>") !== false){
        $silent = true;
      }
      if($silent === false) {
        fwrite($wttrfile, "$line\n");
      }
    }
    fclose($wttrfile);
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
