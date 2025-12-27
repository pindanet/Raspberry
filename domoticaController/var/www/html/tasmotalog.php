<?php
error_reporting(E_ALL);
/*
 * Tasmota logger
 * Send with Tasmota WebSend
 *   rule3 ON Power1#state do WebSend [pindadomo] /tasmotalog.php?Watt=8&name=Keukenlamp&status=%value% ENDON
 *   rule3 1
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-12-27
 * ToDo
 * Get variables from conf.php.json
 */
$websocketServer = "pindadomo.home";
$websocketPort = 8080;

$logfile = __DIR__ . '/data/tasmota.log';
$logstatus = array("Off", "On");

// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/tasmotalog.php Watt=8 name=Keukenlamp status=1
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
}

if (!isset($_GET["Watt"]) || !isset($_GET["name"]) || !isset($_GET["status"])) {
  exit();
}

$watt = htmlspecialchars($_GET["Watt"]);
$name = htmlspecialchars($_GET["name"]);
$status = htmlspecialchars($_GET["status"]);

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
  $WebSocketClient = new WebsocketClient($GLOBALS['websocketServer'], $GLOBALS['websocketPort'], bin2hex(random_bytes(7)));
  $WebSocketClient->sendData($message);
sleep(1);
  unset($WebSocketClient);
}

$data = '{"time":' . time() . ',"Watt":"' . $watt . '","name":"' . $name . '","status":"' . $logstatus[$status] . "\"}\n";
file_put_contents($logfile, $data, FILE_APPEND | LOCK_EX);

$message = array("function"=>"tasmota", "name"=>$name, "state"=>$status);
sendWebsocket(json_encode($message));
?>
