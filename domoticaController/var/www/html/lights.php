<?php

error_reporting(E_ALL);

/**
 * Light switch on Illuminance.
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-11-19
 */

$logfile = '/var/www/html/data/php.log';

// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/lights.php message=Cli%20PHP%20Client
// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/lights.php message=$(bash /var/www/html/websocket/urlencode.sh '{"target":"server", "message":"JSON bericht"}')
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}
// Settings
$conf = json_decode(file_get_contents(__DIR__ . "/data/conf.php.json"));
date_default_timezone_set($conf->Timezone);
$hostname = trim(file_get_contents("/etc/hostname"));

foreach ($conf->rooms as $room) {
  if ($room->Hostname == $hostname) {
    break;
  }
}

function writeLog($text) {
  $handle = fopen($GLOBALS['logfile'], 'a');
  $data = date("Y-m-d H:i:s") . ": " . $text . "\n";
  fwrite($handle, $data);
  fclose($handle);
}

function lightSwitch(&$switch, $lux, $event) {
  if (isset ($switch->Channel)) {
    $channel = $switch->Channel;
  } else {
    $channel = "";
  }
  if (! isset($switch->power)) { // Initialize
    $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel);
writeLog("Create power for " . $switch->Hostname . ": " . $switch->power);
  } elseif (! str_contains($switch->power, ':"OFF"}') && ! str_contains($switch->power, ':"ON"}')) { // Connection error
    $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel);
writeLog("Recreate power after error for " . $switch->Hostname . ": " . $switch->power);
  } else {
    if ($lux < $event->lowerThreshold) {
      if (str_contains($switch->power, ':"OFF"}')) {
        writeLog(sprintf("%s aan bij %s lux", $switch->Hostname, $lux));
        $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel . "%20ON");
      }
    } elseif ($lux > $event->upperThreshold) {
      if (str_contains($switch->power, ':"ON"}')) {
        writeLog(sprintf("%s uit bij %s lux", $switch->Hostname, $lux));
        $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel . "%20OFF");
      }
    }
  }
}

while (true) {
  $lux = intval(file_get_contents(__DIR__ . "/data/lux"));
  $now = date("H:i");
  foreach ($room->tasmota as $switch) {
    if (!isset($switch->disabled)) {
      $switch->disabled = false;
    }
//echo sprintf("%d: Switch %s disabled: %d.\n", __LINE__, $switch->Hostname, $switch->disabled);
    if (isset($switch->type) && $switch->disabled == false) {
      if ($switch->type == "light" && isset($switch->events)) {
        foreach ($switch->events as $event) {
          if ($event->startTime > $event->stopTime) { // stopTime on next day
            if (($now > $event->startTime && $now > $event->stopTime) || ($now < $event->startTime && $now < $event->stopTime)) {
              lightSwitch($switch, $lux, $event);
            }
          } else { // startTime and stopTime on same day
            if ($now > $event->startTime && $now < $event->stopTime) {
              lightSwitch($switch, $lux, $event);
            } elseif (isset($switch->power)) { // add also to stopTime on next day
              if (isset ($switch->Channel)) {
                $channel = $switch->Channel;
              } else {
                $channel = "";
              }
              if ($now >= $event->stopTime && str_contains($switch->power, ':"ON"}')) {
                writeLog(sprintf("%s uit bij %s lux", $switch->Hostname, $lux));
                $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel . "%20OFF");
              }
            }
          }
//var_dump($event->switchingIlluminance);
        }
      }
    }
  }
  sleep(60); //every minute
}
?>
