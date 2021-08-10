<?php

// Use terminal arg as POST en GET arg, example: php tasmota.php dev=tasmota_e7b609-5641 cmd=Power%20toggle
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$dev = htmlspecialchars($_POST["dev"]);
$cmd = htmlspecialchars($_POST["cmd"]);
if (strpos("$dev", 'relay') !== false) {
  $gpio = substr($dev, strpos($dev, 'relayGPIO') + 9);
//  echo substr($dev, strpos($dev, 'relayGPIO') + 9);
  exec("raspi-gpio get $gpio", $output);
  echo "$output[0]";

} else {
  exec("wget -qO- \"http://$dev/cm?cmnd=$cmd\"", $output);
  file_put_contents("data/light-bulb", "$output[0]");
  echo "$output[0]";
}
?>
