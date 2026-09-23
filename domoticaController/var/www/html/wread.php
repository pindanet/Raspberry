<?php

// Use terminal arg as POST en GET arg, example: php /var/www/html/wread.php message=t%3D20.0
// wget -qO- --post-data 'message=t%3D20.0' http://localhost/wread.php
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$message = htmlspecialchars($_POST["message"]);

//file_put_contents("/dev/shm/debug.txt", print_r($_POST, true) . "\n", FILE_APPEND);

// Filter op toegelaten messages

$varValue = explode("=",$message);

switch ($varValue[0]) {
  case 'temp':
    echo file_get_contents("/dev/shm/" . $varValue[0]);
    break;
}
?>
