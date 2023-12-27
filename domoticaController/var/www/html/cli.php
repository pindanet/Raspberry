<?php

// Use terminal arg as POST en GET arg, example: php /var/www/html/cli.php cmd=wget params=$(echo -n '-qO- http://192.168.129.41/cm?cmnd=Power3%20Off' | xxd -p -c 256)
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$params = hex2bin(htmlspecialchars($_POST["params"]));
$cmd = htmlspecialchars($_POST["cmd"]);

// Filter op toegelaten opdrachten

//echo $cmd." ".$params;
exec($cmd." ".$params, $output, $return);
echo json_encode($output);
