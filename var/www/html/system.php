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
  <button onclick="remoteCommand(event,'rpiwall');" <?php
    if (! checkWall()) {
      echo "style=\"color: black;\"";
    }
  ?>>Wall</button>
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
    echo "Wall up";
    $connection = ssh2_connect("rpiwall.local", 22,  array('hostkey'=>'ssh-rsa'));
    ssh2_auth_pubkey_file($connection, 'pi',
                          '/home/pi/.ssh/id_rsa.pub',
                          '/home/pi/.ssh/id_rsa', '');
    $stream = ssh2_exec($connection, 'ls /var/www/html/background/');
//    $stream = ssh2_exec($connection, "sudo shutdown -h now");
    stream_set_blocking($stream, true);
    $output = stream_get_contents($stream);
    echo "<pre>{$output}</pre>";
    fclose($stream);
//    exec("ssh -o StrictHostKeyChecking=no pi@rpiwall.local sudo shutdown -h now");
  } else {
    echo "Wall down";
  }
//  sleep(30); // wait 5 minutes
  break;
case "saveThermostat":
  file_put_contents ("data/thermostat.json", $_POST["json"]);
//  exec("echo " . $_POST["json"] . " > /var/www/html/data/thermostat.json");
  break;

endswitch ?>
<!-- Stroom RPIWall Uitschakelen: python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s "0B 11 00 04 01 25 4A AE 0E 00 00 80" -->
