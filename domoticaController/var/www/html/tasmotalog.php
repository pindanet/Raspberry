<?php
error_reporting(E_ALL);
/*
 * Tasmota logger
 * Send with Tasmota WebSend
 *   rule3 ON Power1#state do WebSend [pindadomo] /tasmotalog.php?Watt=8&name=Keukenlamp&status=%value% ENDON
 *   rule3 1
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2026-03-16
 * ToDo
 * Get variables from conf.php.json
 */
$logfile = __DIR__ . '/data/tasmota.log';
$logstatus = array("Off", "On");

// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/tasmotalog.php Watt=8 name=Keukenlamp status=1
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
}

if (!isset($_GET["Watt"]) || !isset($_GET["name"]) || !isset($_GET["status"])) {
  exit();
}

$watt = htmlspecialchars($_GET["Watt"]);
$name = htmlspecialchars($_GET["name"]);
$status = htmlspecialchars($_GET["status"]);

$data = '{"time":' . time() . ',"Watt":"' . $watt . '","name":"' . $name . '","status":"' . $logstatus[$status] . "\"}\n";
file_put_contents($logfile, $data, FILE_APPEND | LOCK_EX);

if($status == 1) { // On
  file_put_contents('/dev/shm/pindatasmotastatus-'.$name, '');
} else { // Off
  unlink('/dev/shm/pindatasmotastatus-'.$name);
}
?>
