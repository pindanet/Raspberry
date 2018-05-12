<?php
if (file_exists("data/thermostat.json")) {
  $str = file_get_contents("data/thermostat.json");
  $thermostat = json_decode(base64_decode($str));
} else {
  $thermostat = json_decode('[[{"time":"08:00","temp":"20"},{"time":"10:45","temp":"21"},{"time":"21:40","temp":"15"}],[{"time":"07:00","temp":"20"}],[],[{"time":"23:59","temp":"15"}],[{"time":"07:30","temp":"20"}],[],[],{"manual":"Off","heating":"Off","controltemp":"20","roomtemp":"32.72"}]');
}
$temp = 5;
$weekday = date('w');
$currenttime = date('H:i');
$day = 0;

while($day < $weekday) {
  $thermostatTime = $thermostat[$day][0]->{"time"};
  $thermostatTemp = $thermostat[$day][0]->{"temp"};
  foreach ($thermostat[$day] as $timetemp) {
    $temp = $timetemp->{"temp"};
  }
  $day++;
}

$thermostatTime = $thermostat[$weekday][0]->{"time"};
foreach ($thermostat[$weekday] as $timetemp) {
  $thermostatTime = $timetemp->{"time"};
  if ($thermostatTime > $currenttime) {
    break;
  }
  $temp = $timetemp->{"temp"};
}

$thermostat[7]->{"controltemp"} = $temp;

exec("python /var/www/html/bme280.py | tail -3 | head -1 | awk '{ print \$3 }'", $output, $return);
$sensorTemp = $output[0];
$thermostat[7]->{"roomtemp"} = $sensorTemp;

$manual = $thermostat[7]->{"manual"};
if ($manual == "Off") {
  if ($temp < $sensorTemp) {
    exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 01 01 25 4A AE 01 00 00 70\" &");
    $thermostat[7]->{"heating"} = "Off";
//    echo "Verwarming afzetten\n";
  } else {
    exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 00 01 25 4A AE 01 01 0F 70\" &");
    $thermostat[7]->{"heating"} = "On";
  }
} else {
  $heating = $thermostat[7]->{"heating"};
  if ($heating == "Off") {
    exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 01 01 25 4A AE 01 00 00 70\" &");
    $thermostat[7]->{"heating"} = "Off";
  } else {
    exec("cd data; python /home/pi/rfxcmd_gc-master/rfxcmd.py -d /dev/ttyUSB0 -s \"0B 11 00 00 01 25 4A AE 01 01 0F 70\" &");
    $thermostat[7]->{"heating"} = "On";
  }
}

file_put_contents ("data/thermostat.json", base64_encode (json_encode($thermostat)) . "\n");
echo base64_encode (json_encode($thermostat)) . "\n";

//ob_flush();
//ob_start();
//var_dump($thermostat[0][0]->{"time"});
//file_put_contents('data/debug', ob_get_flush());
?>
