<?php
$command = htmlspecialchars($_POST["command"]);

//ob_flush();
//ob_start();
//var_dump($command);
//file_put_contents('data/debug', ob_get_flush());

switch ($command) {
  case "Reset":
  case "Default":
    touch("data/thermostat" . $command);
    break;
  case "Manual":
  case "Auto":
    $temp = htmlspecialchars($_POST["temp"]);
    $room = htmlspecialchars($_POST["room"]);
    if ( $temp == "auto" ) {
      unlink("data/thermostatManual" . $room);
    } else {
      $myfile = fopen("data/thermostatManual" . $room, "w") or die("Unable to open file!");
//      fwrite($myfile, $room . " " . $temp);
      fwrite($myfile, $temp);
      fclose($myfile);
    }
    break;
}
?>
