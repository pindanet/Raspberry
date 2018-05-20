<?php
$command = htmlspecialchars($_POST["command"]);

//ob_flush();
//ob_start();
//var_dump($command);
//file_put_contents('data/debug', ob_get_flush());

switch ($command) {
  case "play":
    $options = htmlspecialchars($_POST["options"]);
    exec("mpc stop");
    sleep(5);
    exec("mpc play $options", $output, $return);
    foreach ($output as $line) {
      echo "$line\n";
    }
    exit();
    break;
  case "stop":
    exec("mpc stop", $output, $return);
    foreach ($output as $line) {
      echo "$line\n";
    }
    exit();
    break;
  case "status":
    exec("mpc status", $output, $return);
    foreach ($output as $line) {
      echo "$line\n";
    }
    exit();
    break;
}
?>
