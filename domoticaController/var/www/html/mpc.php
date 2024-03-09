<?php
$command = htmlspecialchars($_POST["command"]);
$options = htmlspecialchars($_POST["options"]);

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
//    $options = htmlspecialchars($_POST["options"]);
//    exec("mpc stop");
//    sleep(5);
//    exec("mpc play $options", $output, $return);
//    status($output);
    exec("killall mpg123 curl");
    exec("sudo killall roc-recv");
//    sleep(1);
    exec("/var/www/html/playRadio.sh $options 2> /var/www/html/data/radio.log &");
    exit();
    break;
  case "stop":
//    exec("mpc stop", $output, $return);
//    foreach ($output as $line) {
//      echo "$line\n";
//    }
//    unlink("/var/www/html/data/mpc.txt");
    unlink("/var/www/html/data/radio.log");
    exec("killall mpg123 curl");
    echo "Kies een zender";
    exit();
    break;
  case "volup":
// Headphone
//    exec("amixer -q -M sset PCM 5%+", $output, $return);
// USB Soundcard
//    exec("mpc volume +5", $output, $return);
//    exec("mpc status", $output, $return);
//    status($output);
    exec("amixer set \"Digital\" 5%+| awk -F\"[][]\" '/Left:/ { print $2 }'", $output, $return);
    echo "Volume: " . $output[0];
//    status(str_replace('%', '', $output));
    exit();
    break;
  case "voldown":
//    exec("amixer -q -M sset PCM 5%-", $output, $return);
// USB Soundcard
//    exec("mpc volume -5", $output, $return);
//    exec("mpc status", $output, $return);
//    status($output);
    exec("amixer set \"Digital\" 5%- | awk -F\"[][]\" '/Left:/ { print $2 }'", $output, $return);
    echo "Volume: " . $output[0];
//    status($output);
//    status(str_replace('%', '', $output));
    exit();
    break;
  case "getvol":
// headphone
//    exec("amixer -M sget PCM | awk -F\"[][]\" '/dB/ { print $2,$4 }'", $output, $return);
// USB Soundcard
//    exec("mpc volume | awk -F \":\" '{print $2}'", $output, $return);
//    status($output);
    exec("amixer get \"Digital\" | awk -F\"[][]\" '/Left:/ { print $2 }'", $output, $return);
//    status($output);
    status(str_replace('%', '', $output));
    exit();
    break;
  case "setvol":
//    $volume = htmlspecialchars($_POST["volume"]);
// mpc	amixer
// 30	70% (145)  TV
// 20   60% (124)  Radio
//    exec("mpc volume " . $options, $output, $return);
//    status($output);
    exec("amixer set \"Digital\" $options% | awk -F\"[][]\" '/Left:/ { print $2 }'", $output, $return);
    echo "Volume: " . $output[0];
    exit();
    break;
   case "status":
//    exec("mpc status", $output, $return);
//    status($output);
//    exec("cat /var/www/html/data/radio.log | tail -1 | sed 's\/.*: \/\/; s\/;.*\/\/'", $output, $return);
    exec("cat /var/www/html/data/radio.log | tail -1 | cut -d \"'\" -f 2", $output, $return);
    status($output);
    exit();
    break;
}
?>
