<?php
error_reporting(E_ALL);
/*
 * Tasmota logger
 * Send with Tasmota WebSend
 *   rule3 ON Power1#state do WebSend [pindadomo] /tasmotalog.php?Watt=8&name=Keukenlamp&status=%value% ENDON
 *   rule3 1
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-12-09
 * ToDo
 */
$logfile = __DIR__ . '/data/tasmota.log';
// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/tasmotalog.php Watt=8 name=Keukenlamp status=1
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
}

$status = array("Off", "On");
$data = '{"time":' . time() . ',"Watt":"' . htmlspecialchars($_GET["Watt"]) . '","name":"' . htmlspecialchars($_GET["name"]) . '","status":"' . $status[htmlspecialchars($_GET["status"])] . "\"}\n";
file_put_contents($GLOBALS['logfile'], $data, FILE_APPEND | LOCK_EX);
?>
