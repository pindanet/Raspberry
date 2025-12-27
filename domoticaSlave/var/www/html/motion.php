<?php
error_reporting(E_ALL);
/*
 * Motion detector
 * Light switch on Illuminance.
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-12-04
 * ToDo
 */

$logfile = __DIR__ . '/data/php.log';
$motionDir = __DIR__ . '/motion/';
$dataDir = __DIR__ . '/data/';

// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/lights.php message=Cli%20PHP%20Client
// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/lights.php message=$(bash /var/www/html/websocket/urlencode.sh '{"target":"server", "message":"JSON bericht"}')
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}
// Settings
$luxTime= time() - 601; // Initialise lux measurement
$conf = json_decode(file_get_contents(__DIR__ . "/data/conf.php.json"));
date_default_timezone_set($conf->Timezone);
$hostname = trim(file_get_contents("/etc/hostname"));

foreach ($conf->rooms as $room) {
  if ($room->Hostname == $hostname) {
    break;
  }
}
$motionCmd = sprintf("pinctrl get %s", implode(',', $room->Motion->GPIO));

// Initialise
$lux = 0;
file_put_contents("/sys/class/backlight/10-0045/brightness", 0); // Initialise LCD brightness
$room->Motion->timerTime = time() - $room->Motion->timer - 1;  // Initialise lighttimer
$room->Motion->tempTime = time() - 61;  // Initialise temptimer

class WebsocketClient
{
  private $_Socket = null;
  public function __construct($host, $port, $token) {
    $this->_connect($host, $port, $token);
  }
  public function __destruct() {
    $this->_disconnect();
  }
  public function sendData($data) {
    $this->_sendFrame(chr(bindec("10000001")), $data); //Final frame, UTF-8-encoded text
  }
  private function _sendFrame($frame, $data) {
    $length = strlen($data);
    $masks = random_bytes(4);
    if ($length <= 125) {
      $frame .= chr($length | 128); // Masked, Length
      $frame .= $masks[0]; // Masking Key
      $frame .= $masks[1];
      $frame .= $masks[2];
      $frame .= $masks[3];
    }
    // Masked message
    for ($i = 0; $i < $length; ++$i) {
      $frame .= chr(ord($data[$i] ^ $masks[$i % 4]));
    }
    // send frame:
    fwrite($this->_Socket, $frame, strlen($frame)) or die('Error:' . $errno . ':' . $errstr);
  }
  private function _connect($host, $port, $token) {
    $key = base64_encode(($this->_generateRandomString(32)));
    $header = "";
    $header .= "GET /?token={$token} HTTP/1.1\r\n";
    $header .= "Host: {$host}:{$port}\r\n";
    $header .= "Upgrade: websocket\r\n";
    $header .= "Connection: Upgrade\r\n";
    $header .= "Sec-WebSocket-Key: {$key}\r\n";
    $header .= "Sec-WebSocket-Protocol: chat, superchat\r\n";
    $header .= "Sec-WebSocket-Version: 13\r\n";
    $header .= "Origin: http://pindakeuken.home\r\n";
    $header .= "\r\n";
    $this->_Socket = fsockopen($host, $port, $errno, $errstr, 2);
/*
if (!$this->_Socket) { // Start Websocket Server
  echo "Websocket open fout\n";
  // ps -ax | grep websocket.php | grep -v grep| awk '{print $1}'
  shell_exec("/usr/bin/php -e /var/www/html/websocket.php &");
  sleep(1);
  $this->_Socket = fsockopen($host, $port, $errno, $errstr, 2);
}
*/
    fwrite($this->_Socket, $header) or die('Error: ' . $errno . ':' . $errstr);
    $response = fread($this->_Socket, 2000);
    return true;
  }
  private function _disconnect() {
    $data = chr(bindec("00000011")) . chr(bindec("11101001")); //Status code: 1001 	Going away.
    $this->_sendFrame(chr(bindec("10001000")), $data); //Final frame, Close
    fclose($this->_Socket);
  }
  private function _generateRandomString($length = 10, $addSpaces = true, $addNumbers = true) {
    $characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"§$%&/()=[]{}';
    $useChars = array();
    // select some random chars:
    for($i = 0; $i < $length; $i++) {
      $useChars[] = $characters[mt_rand(0, strlen($characters)-1)];
    }
    // add spaces and numbers:
    if($addSpaces === true) {
      array_push($useChars, ' ', ' ', ' ', ' ', ' ', ' ');
    }
    if($addNumbers === true) {
      array_push($useChars, rand(0,9), rand(0,9), rand(0,9));
    }
    shuffle($useChars);
    $randomString = trim(implode('', $useChars));
    $randomString = substr($randomString, 0, $length);
    return $randomString;
  }
}
function sendWebsocket($message) {
  $WebSocketClient = new WebsocketClient("localhost", "9090", bin2hex(random_bytes(7)));
  $WebSocketClient->sendData($message);
  sleep(1); // Let the websocket server process the message
  unset($WebSocketClient);
}

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
    $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel . "%20OFF");
// Debug
writeLog("Create power for " . $switch->Hostname . ": " . $switch->power);
  }
  if (! str_contains($switch->power, ':"OFF"}') && ! str_contains($switch->power, ':"ON"}')) { // Connection error
    $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel . "%20OFF");
writeLog("Recreate power after error for " . $switch->Hostname . ": " . $switch->power);
    if (! str_contains($switch->power, ':"OFF"}')) { // Persistent Connection error
      $switch->power = '{"POWER":"OFF"}';
writeLog("Recreate power after persistent error for " . $switch->Hostname . ": " . $switch->power);
    }
  }
  if (str_contains($switch->power, ':"OFF"}') && $cmd == "ON") {
writeLog(sprintf("%s aan", $switch->Hostname));
    $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel . "%20ON");
  } elseif (str_contains($switch->power, ':"ON"}') && $cmd == "OFF") {
writeLog(sprintf("%s uit", $switch->Hostname));
    $switch->power = file_get_contents("http://" . $switch->Hostname . "/cm?cmnd=Power" . $channel . "%20OFF");
  }
}

function deleteOldFiles($path) {
  if ($handle = opendir($path)) {
    while (false !== ($file = readdir($handle))) {
      $filelastmodified = filemtime($path . $file);
      if((time() - $filelastmodified) > 24*3600)
      {
        if(is_file($path . $file)) {
          unlink($path . $file);
        }
      }
    }
    closedir($handle);
  }
}

function array_search_partial($arr, $keyword) {
    foreach($arr as $index => $string) {
        if (strpos($string, $keyword) !== FALSE)
            return $index;
    }
}

function thermostat($room) {
//  Get temperature
  exec("cat /sys/bus/w1/devices/28-*/w1_slave", $output, $return);
  if ($return != 0) { // Error > Reset DS18B20
    exec("pinctrl set " . $room->thermostat->ds18b20->powerGPIO . "op dl"); // Power Off
    sleep(3);
    exec("pinctrl set " . $room->thermostat->ds18b20->powerGPIO . "op dh"); // Power On
    sleep(5);
    writeLog("Reset Ds18b20");
    return;
  }
  if (str_contains($output[0], "YES")) {
  if(preg_match_all('/\d+/', $output[1], $numbers))
    $temp = end($numbers[0]);
    if (! isset($room->thermostat->temp)) {
      if ($temp == 0) {
        writeLog("Ds18b20 rejected first 0");
        return;
      }
    }
  } else {
    writeLog("Ds18b20 CRC error");
    return;
  }
  if (! isset($room->thermostat->temp)) {
    writeLog("Ds18b20 rejected first measurement");
    $room->thermostat->temp = 1;
    return;
  }
  file_put_contents($GLOBALS['dataDir'] . "temp", $temp, LOCK_EX);
  $room->thermostat->temp = $temp;
// Minimum maximum temp
  if (! isset($room->thermostat->tempminmax)) {
    $room->thermostat->tempminmaxLog = file($GLOBALS['dataDir'] . "temp.log", FILE_IGNORE_NEW_LINES);
    $room->thermostat->tempminmaxIndex = array_search_partial($room->thermostat->tempminmaxLog, date("m/d"));
    if (! isset($room->thermostat->tempminmaxIndex)) {
      $room->thermostat->tempminmaxLog[] = date("m/d") . ",100000,0";
      $room->thermostat->tempminmaxIndex = array_key_last($room->thermostat->tempminmaxLog);
    }
    $room->thermostat->tempminmax = explode(",", $room->thermostat->tempminmaxLog[$room->thermostat->tempminmaxIndex]);
  }
  if ($temp < $room->thermostat->tempminmax[1]) {
    $writeTemp = true;
    $room->thermostat->tempminmax[1] = $temp;
  }
  if ($temp > $room->thermostat->tempminmax[2]) {
    $writeTemp = true;
    $room->thermostat->tempminmax[2] = $temp;
  }
  if (isset($writeTemp)) {
    $room->thermostat->tempminmaxLog[$room->thermostat->tempminmaxIndex] = implode(",", $room->thermostat->tempminmax);
    sort($room->thermostat->tempminmaxLog);
    file_put_contents($GLOBALS['dataDir'] . "temp.log", implode(PHP_EOL, $room->thermostat->tempminmaxLog), LOCK_EX);
  }
// Heaters
/* lager dan night (10) > altijd aan
   lager dan off (15)
     later dan nighttime > altijd aan
   motion
     lager dan aux (17,5) > altijd aan
     hoger of gelijk aan aux (17,5) > altijd uit
   no motion
     vroeger dan nighttime
       hoger dan night (10) > uit
     hoger dan aux (15) > uit
*/
  $temp += $room->thermostat->tempCorrection * 1000;
  sendWebsocket('{"function":"temp", "value":' . $temp/1000 . '}');
//echo sprintf("%d: Temp after correction %f C.\n", __LINE__, $temp/1000);
  if ($temp < $room->thermostat->tempNight * 1000 - 100) {
    tasmotaSwitch($room->thermostat->heater[0], "ON");
    return;
  } elseif ($temp < $room->thermostat->tempOff * 1000 - 100) {
    if (date("H:i") > $room->thermostat->tempNightTime) {
      tasmotaSwitch($room->thermostat->heater[0], "ON");
      return;
    }
  } elseif (isset($room->Motion->timerTime)) { // Motion
    if ($temp < $room->thermostat->tempAux * 1000 - 100) {
      tasmotaSwitch($room->thermostat->heater[0], "ON");
      return;
    } else { // Motion
      if ($temp > $room->thermostat->tempAux * 1000) { // Temp OK
        tasmotaSwitch($room->thermostat->heater[0], "OFF");
        return;
      }
    }
  } else { // No motion
    if (date("H:i") < $room->thermostat->tempNightTime) {
      if ($temp > $room->thermostat->tempNight * 1000) { // Temp OK
        tasmotaSwitch($room->thermostat->heater[0], "OFF");
        return;
      }
    } else {
      if ($temp > $room->thermostat->tempOff * 1000) { // Temp OK
        tasmotaSwitch($room->thermostat->heater[0], "OFF");
        return;
      }
    }
  }
}

while (true) { // Main loop
  unset($output);
  exec($motionCmd, $output, $return);

  foreach($output as $line) {
    if (str_contains($line, ' hi ') === true) { // Motion detected
//echo sprintf("%d: %s Motion High \n", __LINE__, date("Y-m-d_H:i:s"));
      if (isset($room->Motion->light) && $lux < $room->Motion->lowerThreshold) {
        tasmotaSwitch($room->tasmota->{$room->Motion->light}, "ON");
      }
      $room->Motion->timerTime = time();  // (Re)Activate timer
      if (!isset($room->Motion->photo)) { // Thermostat and take photo
        if (date("H:i") > $room->thermostat->tempNightTime) { // Thermostat only add daytime
          $room->Motion->tempTime = time();
          thermostat($room);
        }
        if (isset($lux) && isset($luxmax)) { //Calculate backlight
          $rellux = $lux / $luxmax;
          $backlight = (int)($room->minBacklight + $rellux * $room->maxBacklight);
          file_put_contents("/sys/class/backlight/10-0045/brightness", $backlight); // LCD brightness
        }
        deleteOldFiles($motionDir);
        sendWebsocket('{"target":"pindakeuken", "message":"weather"}');
        $room->Motion->photo = date('Y-m-d_H:i:s');
        exec('/usr/bin/rpicam-still -v 0 -o ' . $motionDir . $room->Motion->photo . '.jpg --rotation 180 --nopreview');
        exec('/usr/bin/convert ' . $motionDir . $room->Motion->photo . '.jpg -resize 1920 ' . $motionDir . $room->Motion->photo . '.jpg');
      }
      break;
    }
  }
  if (isset($room->Motion->timerTime)) { // Lighttimer
    if (time() - $room->Motion->timerTime > $room->Motion->timer) { // Light out
//echo sprintf("%d: %s Motion off after 3 minutes \n", __LINE__, date("Y-m-d_H:i:s"));
      unset($room->Motion->timerTime);
      tasmotaSwitch($room->tasmota->{$room->Motion->light}, "OFF");
      file_put_contents("/sys/class/backlight/10-0045/brightness", 0); // LCD brightness
      unset($room->Motion->photo);
      $luxTime= time() - 601; // Reset lux measurement
    }
  } else { // If no motion: Calculate lux and adjust temperature
    if (time() - $luxTime > 600) { // Calculate lux every 10 minutes
      unset($rpicam);
      exec('/usr/bin/rpicam-still --nopreview --immediate --metadata - -o /dev/zero 2>&1', $rpicam, $return);
      foreach($rpicam as $property) {
        if (str_contains($property, '"Lux": ') === true) {
          $lux = intval(substr($property, 11));
          if (!isset($luxmax)) {
            if(is_file(__DIR__ . "/data/luxmax")) {
              $luxmax = intval(file_get_contents(__DIR__ . "/data/luxmax"));
            } else {
              $luxmax = $lux - 1;
            }
          }
          if ($lux > $luxmax) {
            $luxmax = $lux;
            file_put_contents(__DIR__ . "/data/luxmax", $luxmax);
          }
          break;
        }
      }
      $luxTime = time();
    }
  }
  if (time() - $room->Motion->tempTime > 60) { // Thermostat every minute
    $room->Motion->tempTime = time();
    thermostat($room);
  }
  usleep(250000); //every 0.25 s
}
?>
