<?php
error_reporting(E_ALL);
/*
 * Motion detector
 * Light switch on Illuminance.
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-11-22
 * ToDo
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
/*
if (!is_dir('/var/www/html/motion')) {
    mkdir('/var/www/html/motion', 0755, true);
}
*/

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
  $WebSocketClient = new WebsocketClient($GLOBALS['conf']->websocket->server, $GLOBALS['conf']->websocket->port, bin2hex(random_bytes(7)));
  $WebSocketClient->sendData($message);
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
    $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel . "%20OFF");
writeLog("Create power for " . $switch->Hostname . ": " . $switch->power);
  }
  if (! str_contains($switch->power, ':"OFF"}') && ! str_contains($switch->power, ':"ON"}')) { // Connection error
    $switch->power = file_get_contents("http://" . $switch->IP . "/cm?cmnd=Power" . $channel . "%20OFF");
writeLog("Recreate power after error for " . $switch->Hostname . ": " . $switch->power);
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
          unlink($path . $file);
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

      file_put_contents("/sys/class/backlight/10-0045/brightness", backlight($lux)); // LCD brightness

      $room->Motion->timerTime = time();  // (Re)Activate timer

      deleteOldFiles("/var/www/html/motion/");
      if (!isset($room->Motion->photo)) { // take photo
        sendWebsocket('{"target":"pindakeuken", "message":"weather"}');
//echo sprintf("%d: Filename: %s.\n", __LINE__, "/var/www/html/motion/" . date('Y-m-d_H:i:s') . '.jpg');
        $room->Motion->photo = date('Y-m-d_H:i:s');
        exec('/usr/bin/rpicam-still -v 0 -o /var/www/html/motion/' . $room->Motion->photo . '.jpg --rotation 180 --nopreview');
        exec('/usr/bin/convert /var/www/html/motion/' . $room->Motion->photo . '.jpg -resize 1920 /var/www/html/motion/' . $room->Motion->photo . '.jpg');
      }
//      sleep(5); // Debounce
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
      unset($room->Motion->photo);
    }
  }
  usleep(250000); //every 0.25 s
}
exit("Afgebroken\n");
?>
