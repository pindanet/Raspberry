<?php
function checkWall() {
  $fp = fsockopen("udp://rpiwall.local", 22, $errno, $errstr);
  if (!$fp) {
    return false;
  } else {
    fclose($fp);
    return true;
  }
}
function sleepWall() {
  if (checkWall()) {
//    $connection = ssh2_connect("rpiwall.local", 22,  array('hostkey'=>'ssh-rsa'));
//    ssh2_auth_pubkey_file($connection, 'pi',
//                          '.newssh_keys/id_rsa.pub',
//                          '.newssh_keys/id_rsa', '');
//    $stream = ssh2_exec($connection, "sudo shutdown -h now");
//    stream_set_blocking($stream, true);
//    $output = stream_get_contents($stream);
//    fclose($stream);

    $curl = curl_init();
    curl_setopt($curl, CURLOPT_POST, 1);
    curl_setopt($curl, CURLOPT_POSTFIELDS, "command=halt");
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($curl, CURLOPT_URL, 'http://rpiwall/remote.php');
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
    $result = curl_exec($curl);

    sleep(30); // wait 30 seconds
    exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 00 01 25 4A AE 0D 00 00 80\"");
    echo "Wall afgesloten en stroomtoevoer uitgeschakeld.";
  }
}
function wakeupWall() {
  exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 00 01 25 4A AE 0D 01 0F 80\"");
  echo "Stroomtoevoer naar Wall ingeschakeld.";
}

$state = htmlspecialchars($_POST["state"]);

exec("cat /sys/class/backlight/rpi_backlight/bl_power", $output, $return);

$myfile = fopen("/var/www/html/data/debug.txt", "a") or die("Unable to open file!");
fwrite($myfile, date("l d/m/Y H:i:s: ") . $state . ".\n");
fclose($myfile);

if ($output[0] == 0 && $state == "sleep") {
  exec("echo 1 | sudo /usr/bin/tee /sys/class/backlight/rpi_backlight/bl_power");
  sleepWall();
  # IR paneel uitschakelen
#  exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 01 01 41 53 86 02 00 00 80\"");
}
if ($output[0] == 1 && $state == "awake") {
  exec("echo 0 | sudo /usr/bin/tee /sys/class/backlight/rpi_backlight/bl_power");
//  wakeupWall();
  # IR paneel inschakelen
#  exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 00 01 41 53 86 02 01 0F 80\"");
}
?>
