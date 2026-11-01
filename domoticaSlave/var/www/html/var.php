<?php
// Use terminal arg as POST en GET arg, example: php /var/www/html/var.php var=pindatasmotastatus-Tandenborstel
// wget -qO- --post-data 'var=pindatasmotastatus-Tandenborstel' http://localhost/var.php
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$var = "/dev/shm/" . htmlspecialchars($_POST["var"]);

//file_put_contents("/dev/shm/debug.txt", print_r($_POST, true) . "\n", FILE_APPEND);

if (!file_exists($var)) {
  exit("false");
} else {
  if (filesize($var) == 0) {
    exit("exist");
  } else {
    echo file_get_contents($var);
  }
}
?>
