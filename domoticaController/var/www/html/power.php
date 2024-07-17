<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>PindaDomo Power log</title>
</head>
<body style="font-family: monospace;white-space: pre;">
<?php
// ToDo
// 

$price = 32; // per kWh in centimen
$processDay = 0;
$processToday = 0;
$processDaykWh = 0;

$processWeek = 0;
//$processThisWeek = 0;
$processWeekkWh = 0;

function processLine($powerline) {
  $datetime = explode(" ", date("j W m Y G i s l F", $powerline["time"] / 1000));
  if($GLOBALS['processDay'] <> $datetime[0]) {
    if($GLOBALS['processDay'] <> 0) {
      echo "Dagtotaal: " . round($GLOBALS['processDaykWh'], 3) . " kWh, " . round($GLOBALS['processDaykWh'] * $GLOBALS['price'] / 100 , 2) . " €<br>";
      $GLOBALS['processDaykWh'] = 0;
      $GLOBALS['processToday'] = 1;
      echo $datetime[7] . " " . $datetime[0] . " " . $datetime[8] . "<br>";
    } else {
      echo $datetime[7] . " " . $datetime[0] . " " . $datetime[8] . ", Week: " . $datetime[1] . "<br>";
    }
    $GLOBALS['processDay'] = $datetime[0];
  if($GLOBALS['processWeek'] <> $datetime[1]) {
//    if($GLOBALS['processWeek'] <> 0) {
      echo "Week: " . $processWeekkWh . " kWh" . "<br>";
//    }
  }
  }
  if(strtolower($powerline["status"]) == "off") {
    $GLOBALS[$powerline["name"]] = $powerline["time"];
  } else if (isset($GLOBALS[$powerline["name"]])) {
// https://www.tutorialspoint.com/how-to-calculate-the-difference-between-two-dates-in-php
    $minutes = round(($GLOBALS[$powerline["name"]] - $powerline["time"]) / 60000);
    $kWh = ($powerline["Watt"] / 1000) * ($minutes / 60);
    $GLOBALS['processDaykWh'] += $kWh;
    $GLOBALS['processWeekkWh'] += $kWh;
    if($datetime[3] < "7") {  // Highlight night time: 00h00 - 06h59
      echo "<b style='color: red;'>";
    }
    echo date("d/m/Y H:i:s", $powerline["time"] / 1000) . " to " . date("d/m/Y H:i:s", $GLOBALS[$powerline["name"]] / 1000) . " " . str_pad($powerline["name"], 15, " ", STR_PAD_LEFT) . " " . str_pad($minutes, 4, " ", STR_PAD_LEFT) . " min. " . str_pad(round($kWh, 3), 4, " ", STR_PAD_LEFT) . " kWh<br>";
    if($datetime[3] < "7") {  // Highlight night time: 00h00 - 06h59
      echo "</b>";
    }
    unset($GLOBALS[$powerline["name"]]);
  }
  if($GLOBALS['processToday'] == 0) {
    echo date("d/m/Y H:i:s", $powerline["time"] / 1000) . " " . $powerline["Watt"] . " " . $powerline["name"] . " " . $powerline["status"] . " " . $GLOBALS[$powerline["name"]] . "<br>";
// var_dump($powerline);
  }
}
// Reverse power.log
exec("tac data/power.log > data/power.rev ", $output, $return);

$file = fopen("data/power.rev", "r");
// Iterator Number
$i = 0;
if($file){
    // If file is open
    while(($line=fgets($file)) !== false){
        // Skipping the empty line and Comment line
        if((empty(trim($line))) || (preg_match('/^#/', $line) > 0))
            continue;
        $i++;
        // Process Line Content
        $powerline = json_decode($line, true);
        processLine($powerline);
    }
    fclose($file);
}
?>
</body>
</html>
