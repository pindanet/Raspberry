<?php
/*
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str($argv[1], $_GET);
  parse_str($argv[1], $_POST);
}
*/
$command = htmlspecialchars($_POST["command"]);

//ob_flush();
//ob_start();
//var_dump($command);
//file_put_contents('data/debug', ob_get_flush());

switch ($command) {
  case "Reset":
  case "Default":
    $filename = "data/thermostat" . $command;
    touch($filename);
    while ( file_exists($filename) ) {
      sleep(1);
    }
    break;
  case "Manual":
  case "Auto":
    $temp = htmlspecialchars($_POST["temp"]);
    $room = htmlspecialchars($_POST["room"]);
    if ( $temp == "auto" ) {
      $filename = "data/thermostatManual" . $room;
      unlink($filename);
      while ( file_exists($filename) ) {
        sleep(1);
      }
    } else {
      $myfile = fopen("data/thermostatManual" . $room, "w") or die("Unable to open file!");
//      fwrite($myfile, $room . " " . $temp);
      fwrite($myfile, $temp);
      fclose($myfile);
    }
    break;
}
?>
