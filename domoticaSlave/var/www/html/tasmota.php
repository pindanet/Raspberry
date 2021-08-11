<?php

// Use terminal arg as POST en GET arg
// example: php tasmota.php dev=tasmota_e7b609-5641 cmd=Power%20toggle
//          php tasmota.php dev=tasmota_relayGPIO13 cmd=Power%20toggle
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$dev = htmlspecialchars($_POST["dev"]);
$cmd = htmlspecialchars($_POST["cmd"]);
if (strpos("$dev", 'relay') !== false) { // relay heating
  $gpio = substr($dev, strpos($dev, 'relayGPIO') + 9);
  exec("raspi-gpio get $gpio", $output);
  if (strpos("$output[0]", 'level=1') !== false) { // turn on
    exec("raspi-gpio set $gpio op dl", $output);
    file_put_contents("data/$dev", '{"POWER":"ON"}');
  } else { // turn off
    exec("raspi-gpio set $gpio op dh", $output);
    file_put_contents("data/$dev", '{"POWER":"OFF"}');
  }
  echo "$output[0]";
} else { // tasmota lightswitch
  exec("wget -qO- \"http://$dev/cm?cmnd=$cmd\"", $output);
  file_put_contents("data/$dev", "$output[0]");
  echo "$output[0]";
}
?>
