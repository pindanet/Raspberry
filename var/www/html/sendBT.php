<?php
$BTController="B8:27:EB:45:8B:BA";
$value = htmlspecialchars($_POST["value"]);
$file = htmlspecialchars($_POST["file"]);

//ob_flush();
//ob_start();
//var_dump($command);
//file_put_contents('data/debug', ob_get_flush());

if( "$value" != "-1") {
  file_put_contents("/var/www/html/data/" . $file, $value . "\n");
}

exec("/usr/bin/obexftp --bluetooth " . $BTController . " --channel 23 -p /var/www/html/data/" . $file, $output, $return);
//foreach ($output as $line) {
//  echo "$line\n";
//}

?>
