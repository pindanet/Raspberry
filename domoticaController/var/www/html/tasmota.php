<?php

// Use terminal arg as POST en GET arg, example: php tasmota.php dev=e7b609-5641 cmd=Power%20toggle
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$dev = htmlspecialchars($_POST["dev"]);
$cmd = htmlspecialchars($_POST["cmd"]);

exec("wget -qO- \"http://$dev/cm?cmnd=$cmd\"");
