<?php

error_reporting(E_ALL);

/**
 * Light switch on brightness.
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-11-18
 */

$logfile = '/var/www/html/data/php.log';

// Use terminal arg as POST en GET arg, example: php -e /var/www/html/websocket/client.php message=Cli%20PHP%20Client
// Use terminal arg as POST en GET arg, example: php -e /var/www/html/websocket/client.php message=$(bash /var/www/html/websocket/urlencode.sh '{"target":"server", "message":"JSON bericht"}')
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$switchingPoint = 30;
$hysteresis = 1;

$power = file_get_contents("http://192.168.129.41/cm?cmnd=Power1");

while (true) {
  $lux = file_get_contents(__DIR__ . "/data/lux");
  echo $lux;
  if ($lux < $switchingPoint - $hysteresis) {
    if (str_contains($power, ':"OFF"}')) {
      $handle = fopen($logfile, 'a');
      $data = date("Y-m-d H:i:s") . ": Licht aan bij " . $lux . "\n";
      fwrite($handle, $data);
      fclose($handle);
      $power = file_get_contents('http://192.168.129.41/cm?cmnd=Power1%20ON');
    }
  } elseif ($lux > $switchingPoint + $hysteresis) {
    if (str_contains($power, ':"ON"}')) {
      $handle = fopen($logfile, 'a');
      $data = date("Y-m-d H:i:s") . ": Licht uit bij " . $lux . "\n";
      fwrite($handle, $data);
      fclose($handle);
      $power = file_get_contents('http://192.168.129.41/cm?cmnd=Power1%20OFF');
    }
  }
  sleep(60);
}
?>
