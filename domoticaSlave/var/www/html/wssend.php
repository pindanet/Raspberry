<?php
error_reporting(E_ALL);

// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/wssend.php message=Cli%20PHP%20Client
// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/wssend.php message=$(bash /var/www/html/websocket/urlencode.sh '{"function":"activeHeaters", "id":"clockyear", "color":"red"}')
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

function isJson($string) {
   json_decode($string);
   return json_last_error() === JSON_ERROR_NONE;
}

if (isJson($_GET["message"])) {
  $message = $_GET["message"];
} else {
  $message = htmlspecialchars($_GET["message"]);
}

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
//function sendWebsocket($message) {
$WebSocketClient = new WebsocketClient('localhost', 9090, bin2hex(random_bytes(7)));
//$WebSocketClient->sendData('{"function":"available","value":"Afwezig"}');
$WebSocketClient->sendData($message);
//$WebSocketClient->sendData($message);
sleep(1);
unset($WebSocketClient);
//}

?>
