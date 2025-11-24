<?php
error_reporting(E_ALL);
/**
 * Motion detector
 * Light switch on Illuminance.
 * @author Dany Pinoy https://github.com/pindanet/Raspberry/
 * @version 2025-11-22
 */

$logfile = '/var/www/html/data/php.log';

// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/lights.php message=Cli%20PHP%20Client
// Use terminal arg as POST en GET arg, example: sudo -u www-data php -e /var/www/html/lights.php message=$(bash /var/www/html/websocket/urlencode.sh '{"target":"server", "message":"JSON bericht"}')
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}
// Settings
$conf = json_decode(file_get_contents(__DIR__ . "/data/conf.php.json"));
date_default_timezone_set($conf->Timezone);
$hostname = trim(file_get_contents("/etc/hostname"));
foreach ($conf->rooms as $room) {
  if ($room->Hostname == $hostname) {
    break;
  }
}


$motionCmd=sprintf("pinctrl get %s", implode(',', $room->Motion->GPIO));
exec($motionCmd, $output, $return);

var_dump($output);
foreach($output as $line) {
  if ( str_contains($line, ' lo ') === true)

echo sprintf("%d: Motion detected: %s.\n", __LINE__, $line);

}
exit("Afgebroken\n");
?>
