<?php

// Use terminal arg as POST en GET arg, example: php /var/www/html/wtype.php message=t%3D20.0
// wget -qO- --post-data 'message=t%3D20.0' http://localhost/wtype.php
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$message = htmlspecialchars($_POST["message"]);

//file_put_contents("data/debug.txt", $cmd . " " . $params);

// Filter op toegelaten messages

//echo $message;
exec("XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 wtype " . $message . " -k return", $output, $return);
?>
