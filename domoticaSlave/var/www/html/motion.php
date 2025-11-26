<?php
error_reporting(E_ALL);
/**
 * Motion detector
 * Light switch on Illuminance.
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-11-22
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
$motionCmd = sprintf("pinctrl get %s", implode(',', $room->Motion->GPIO));

//var_dump($conf->switch->{$room->Motion->light}->IP);

$lux = 0;
$luxTimer = time() - 61; // initialise lux measurement

function writeLog($text) {
  $handle = fopen($GLOBALS['logfile'], 'a');
  $data = date("Y-m-d H:i:s") . ": " . $text . "\n";
  fwrite($handle, $data);
  fclose($handle);
}

function tasmotaSwitch(&$switch, $cmd) { // ToDo
  if (isset ($switch->Channel)) {
    $channel = $switch->Channel;
  } else {
    $channel = "";
  }

// Errors opvangen

  if (! isset($switch->power)) { // Initialize
    $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel);
writeLog("Create power for " . $switch->Hostname . ": " . $switch->power);
  } elseif (! str_contains($switch->power, ':"OFF"}') && ! str_contains($switch->power, ':"ON"}')) { // Connection error
    $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel);
writeLog("Recreate power after error for " . $switch->Hostname . ": " . $switch->power);
  } else {
    if (str_contains($switch->power, ':"OFF"}') && $cmd == "ON") {
      writeLog(sprintf("%s aan", $switch->Hostname));
      $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel . "%20ON");
    } elseif (str_contains($switch->power, ':"ON"}') && $cmd == "OFF") {
      writeLog(sprintf("%s uit", $switch->Hostname));
      $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel . "%20OFF");
    }
  }
//echo sprintf("%d: Licht %s %s.\n", __LINE__, $switch->Hostname, $cmd);
}

function backlight($lux) {
  $maxHelderheid = 128;
  $minHelderheid = 33;
  $rellux = $lux / max(2000, $lux); // luxmax;
  $backlight = (int)($minHelderheid + $rellux * $maxHelderheid);
//echo sprintf("%d: Lichtintensiteit: %d, Backlight: %d.\n", __LINE__, $lux, $backlight);
  return $backlight;
}

while (true) { // Main loop
  unset($output);
  exec($motionCmd, $output, $return);

  foreach($output as $line) {
    if (str_contains($line, ' hi ') === true) { // Motion detected
      if (isset($room->Motion->light) && $lux < $room->Motion->lowerThreshold) {

//        $room->Motion->timerTime = time();
        tasmotaSwitch($conf->switch->{$room->Motion->light}, "ON");
      }
      if (str_contains($conf->switch->{$room->Motion->light}->power, ':"ON"}')) {
        $room->Motion->timerTime = time();  // (Re)Activate timer
//echo sprintf("%d: Lichttimer voor Licht %s %d s (her)activeren bij %d Lux (inschakelen bij %d lux).\n", __LINE__, $room->Motion->light, $room->Motion->timer , $lux, $room->Motion->lowerThreshold);
      }
      file_put_contents("/sys/class/backlight/10-0045/brightness", backlight($lux)); // LCD brightness
      break;
    }
  }
  if (time() - $luxTimer > 60) { // Measure every minute the light intensity
    unset($rpicam);
    exec('/usr/bin/rpicam-still --nopreview --immediate --metadata - -o /dev/zero 2>&1', $rpicam, $return);

    foreach($rpicam as $property) {
      if (str_contains($property, '"Lux": ') === true) {
        $lux = intval(substr($property, 11));
        $luxTimer = time();
        break;
      }
    }
    if (isset($room->Motion->timerTime)) { // Lighttimer
      if (time() - $room->Motion->timerTime > $room->Motion->timer) { // Light out
        unset($room->Motion->timerTime);

echo sprintf("%d: Licht uit na %d s.\n", __LINE__, $room->Motion->timer);

        tasmotaSwitch($conf->switch->{$room->Motion->light}, "OFF");
        file_put_contents("/sys/class/backlight/10-0045/brightness", 0); // LCD brightness
      }
    }
  }
  usleep(250000); //every 0.25 s
}
exit("Afgebroken\n");
?>
