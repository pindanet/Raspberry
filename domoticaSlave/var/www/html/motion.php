<?php
error_reporting(E_ALL);
/*
 * Motion detector
 * Light switch on Illuminance.
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-11-22
 * ToDo
 * Take picture
 * maxlux
 * conf / room
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

// Initialise
$lux = 0;
$luxTimer = time() - 61; // initialise lux measurement
file_put_contents("/sys/class/backlight/10-0045/brightness", 0); // Initialise LCD brightness
$room->Motion->timerTime = time();  // Initialise lighttimer

function writeLog($text) {
  $handle = fopen($GLOBALS['logfile'], 'a');
  $data = date("Y-m-d H:i:s") . ": " . $text . "\n";
  fwrite($handle, $data);
  fclose($handle);
}

function tasmotaSwitch(&$switch, $cmd) {
  if (isset ($switch->Channel)) {
    $channel = $switch->Channel;
  } else {
    $channel = "";
  }
  if (! isset($switch->power)) { // Initialize Power Off
    $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel . "%20OFF");
writeLog("Create power for " . $switch->Hostname . ": " . $switch->power);
    sleep(1);
  }
  if (! str_contains($switch->power, ':"OFF"}') && ! str_contains($switch->power, ':"ON"}')) { // Connection error
    $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel . "%20OFF");
writeLog("Recreate power after error for " . $switch->Hostname . ": " . $switch->power);
    sleep(1);
    if (! str_contains($switch->power, ':"OFF"}')) { // Persistent Connection error
      $switch->power = '{"POWER":"OFF"}';
writeLog("Recreate power after persistent error for " . $switch->Hostname . ": " . $switch->power);
    }
  }
//echo sprintf("%d: tasmotaSwitch Power: %s.\n", __LINE__, $switch->power);
  if (str_contains($switch->power, ':"OFF"}') && $cmd == "ON") {
    writeLog(sprintf("%s aan", $switch->Hostname));
    $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel . "%20ON");
  } elseif (str_contains($switch->power, ':"ON"}') && $cmd == "OFF") {
    writeLog(sprintf("%s uit", $switch->Hostname));
    $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel . "%20OFF");
  }
}

function backlight($lux) {
  $maxHelderheid = 128;
  $minHelderheid = 33;
  $rellux = $lux / max(2000, $lux); // luxmax;
  $backlight = (int)($minHelderheid + $rellux * $maxHelderheid);
  return $backlight;
}

function deleteOldFiles($path) {
  if ($handle = opendir($path)) {
    while (false !== ($file = readdir($handle))) {
      $filelastmodified = filemtime($path . $file);
      if((time() - $filelastmodified) > 24*3600)
      {
        if(is_file($path . $file)) {
echo sprintf("%d: Verwijder %s.\n", __LINE__, $path . $file);
//          unlink($path . $file);
        }
      }
    }
    closedir($handle);
  }
}

while (true) { // Main loop
  unset($output);
  exec($motionCmd, $output, $return);

  foreach($output as $line) {
    if (str_contains($line, ' hi ') === true) { // Motion detected
      if (isset($room->Motion->light) && $lux < $room->Motion->lowerThreshold) {
        tasmotaSwitch($conf->switch->{$room->Motion->light}, "ON");
      }
//      if (isset($conf->switch->{$room->Motion->light}->power)) {
//        if (str_contains($conf->switch->{$room->Motion->light}->power, ':"ON"}')) {

//      deleteOldFiles("/var/www/html/motion/");

//echo sprintf("%d: Filename: %s.\n", __LINE__, date('Y-m-d_H:i:s') . '.jpg');

      $room->Motion->timerTime = time();  // (Re)Activate timer
//        }
//      }
      file_put_contents("/sys/class/backlight/10-0045/brightness", backlight($lux)); // LCD brightness
      sleep(5); // Debounce
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
  }
  if (isset($room->Motion->timerTime)) { // Lighttimer
    if (time() - $room->Motion->timerTime > $room->Motion->timer) { // Light out
      unset($room->Motion->timerTime);
      tasmotaSwitch($conf->switch->{$room->Motion->light}, "OFF");
      file_put_contents("/sys/class/backlight/10-0045/brightness", 0); // LCD brightness
    }
  }
  usleep(250000); //every 0.25 s
}
exit("Afgebroken\n");
?>
