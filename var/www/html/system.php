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
  exec("sudo /sbin/shutdown -r now");
  break;
case "halt": 
  exec("sudo /sbin/shutdown -h now");
  break;
case "rpiwall": 
  if (checkWall()) {
    $connection = ssh2_connect("rpiwall.local", 22,  array('hostkey'=>'ssh-rsa'));
    ssh2_auth_pubkey_file($connection, 'pi',
                          '.newssh_keys/id_rsa.pub',
                          '.newssh_keys/id_rsa', '');
//    $stream = ssh2_exec($connection, 'ls /var/www/html/background/');
    $stream = ssh2_exec($connection, "sudo shutdown -h now");
    stream_set_blocking($stream, true);
    $output = stream_get_contents($stream);
//    echo "<pre>{$output}</pre>";
    fclose($stream);
    sleep(60); // wait 1 minute
    exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 04 01 25 4A AE 0E 00 00 80\"");
    echo "Wall afgesloten en stroomtoevoer uitgeschakeld.";
  } else {
    exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 02 01 25 4A AE 0E 01 0F 80\"");
    echo "Stroomtoevoer naar Wall ingeschakeld.";
  }
  break;
case "saveThermostat":
//  file_put_contents ("data/thermostat.json", $_POST["json"] . "\n");
  file_put_contents ("data/thermostat", base64_decode($_POST["json"]));
  break;

endswitch ?>
