<?php
//ini_set('display_errors', 1);
//ini_set('display_startup_errors', 1);
//error_reporting(E_ALL);
//Post data als argumenten bij php cli
/*
// php system.php command=update
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str($argv[1], $_GET);
  parse_str($argv[1], $_POST);
}
*/
function checkWall() {
  $fp = fsockopen("udp://rpiwall.local", 22, $errno, $errstr);
  if (!$fp) {
    return false;
  } else {
    fclose($fp);
    return true;
  }
}
switch($_POST["command"]):
case "system": ?>
  <button onclick="location.reload();">Vernieuwen</button>
  <button onclick="remoteCommand(event,'softap');">WiFi AP</button>
  <button onclick="remoteCommand(event,'reboot');">Herstart</button>
  <button onclick="remoteCommand(event,'halt');">Uitschakelen</button>
  <button onclick="remoteCommand(event,'rpiwall');">Wall</button>
<?php break;
case "softap": 
  exec("/bin/systemctl is-active hostapd.service", $output, $return);
  if ($output[0] == "inactive") {
    exec("sudo /bin/systemctl start hostapd.service");
    echo "WiFi AP actief";
  } else {
    exec("sudo /bin/systemctl stop hostapd.service");
    echo "WiFi AP uitgeschakeld";
  }
  break;
case "reboot": 
  echo "Domoticacontroller herstart.\n";
  exec("sudo /sbin/shutdown -r now");
  break;
case "halt": 
  exec("sudo /sbin/shutdown -h now");
  break;
case "rsync": 
  exec("sudo /bin/bash remote.sh rsync");
  break;
case "update": 
  exec("sudo /bin/bash remote.sh update");
  break;
case "clean": 
  exec("sudo /bin/bash remote.sh clean");
  break;
case "rpiwall": 
  if (checkWall()) {
//    $connection = ssh2_connect("rpiwall.local", 22,  array('hostkey'=>'ssh-rsa'));
//    ssh2_auth_pubkey_file($connection, 'dany',
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

    sleep(60); // wait 1 minute
#    $webData = file_get_contents('http://tasmota_4fdd94-7572/cm?cmnd=Power%20Off');
#    exec("cd data; python ../rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 00 01 25 4A AE 0D 00 00 80\"");
    echo "Wall afgesloten en stroomtoevoer uitgeschakeld.";
  } else {
#    exec("cd data; python ../rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 00 01 25 4A AE 0D 01 0F 80\"");
#    $webData = file_get_contents('http://tasmota_4fdd94-7572/cm?cmnd=Power%20On');
    echo "Stroomtoevoer naar Wall ingeschakeld.";
  }
  break;
case "saveThermostat":
//  file_put_contents ("data/thermostat.json", $_POST["json"] . "\n");
  file_put_contents ("data/thermostat", base64_decode($_POST["json"]));
  break;
case "saveHeating":
  file_put_contents ("data/heating", base64_decode($_POST["heating"]));
  break;
endswitch ?>
