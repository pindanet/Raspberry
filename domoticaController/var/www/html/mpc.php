<?php
$command = htmlspecialchars($_POST["command"]);

//ob_flush();
//ob_start();
//var_dump($command);
//file_put_contents('data/debug', ob_get_flush());

function status($output) {
  $myfile = fopen("/var/www/html/data/mpc.txt", "a") or die("Unable to open file!");
  echo "$output[0]";
  foreach ($output as $line) {
    fwrite($myfile, $line . "\n");
  }
  fclose($myfile);
}

switch ($command) {
  case "play":
    $options = htmlspecialchars($_POST["options"]);
    exec("mpc stop");
    sleep(5);
    exec("mpc play $options", $output, $return);
    status($output);
    exit();
    break;
  case "stop":
    exec("mpc stop", $output, $return);
    foreach ($output as $line) {
      echo "$line\n";
    }
    unlink("/var/www/html/data/mpc.txt");
    exit();
    break;
  case "volup":
    exec("amixer -q -M sset Headphone 5%+", $output, $return);
    exec("mpc status", $output, $return);
    status($output);
    exit();
    break;
  case "voldown":
    exec("amixer -q -M sset Headphone 5%-", $output, $return);
    exec("mpc status", $output, $return);
    status($output);
    exit();
    break;
  case "getvol":
    exec("amixer -M sget Headphone | awk -F\"[][]\" '/dB/ { print $2,$4 }'", $output, $return);
    status($output);
    exit();
    break;
  case "status":
    exec("mpc status", $output, $return);
    status($output);
    exit();
    break;
}
?>