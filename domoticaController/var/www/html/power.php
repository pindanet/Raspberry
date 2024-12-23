<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>PindaDomo Power log</title>
</head>
<body style="font-family: monospace;white-space: pre;">
<?php
// ToDo

$price = 32; // per kWh in centimen
$processDay = 0;
$processToday = 0;
$processDaykWh = 0;
$firstWeek = 0;

$processWeek = 0;
$processWeekkWh = 0;
$firstMonth = 0;

$processMonth = 0;
$processMonthkWh = 0;

$months = array(
    'Januari',
    'Februari',
    'Maart',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Augustus',
    'September',
    'October',
    'November',
    'December'
);

function processLine($powerline) {
  $datetime = explode(" ", date("j W n Y G i s l F", $powerline["time"] / 1000));
  if($GLOBALS['processMonth'] <> $datetime[2]) { // New month
    if($GLOBALS['processMonth'] <> 0) {
      echo str_pad($GLOBALS['months'][$datetime[2]] . " " . $datetime[3], 15, " ", STR_PAD_RIGHT) . str_pad(round($GLOBALS['processMonthkWh'], 0),3," ", STR_PAD_LEFT) . " kWh " . str_pad(round($GLOBALS['processMonthkWh'] * $GLOBALS['price'] / 100 , 0),3," ", STR_PAD_LEFT) . " €<br>";
      $GLOBALS['firstMonth'] += 1;
    }
    $GLOBALS['processMonthkWh'] = 0;
    $GLOBALS['processMonth'] = $datetime[2];
  }
  if($GLOBALS['firstMonth'] == 0) { // first month
    if($GLOBALS['processWeek'] <> $datetime[1]) {
      if($GLOBALS['processWeek'] <> 0) {
        $weekTotal = "Week " . str_pad($GLOBALS['processWeek'],3," ",STR_PAD_RIGHT) . number_format(round($GLOBALS['processWeekkWh'], 1),1,","," ") . " kWh, " . number_format(round($GLOBALS['processWeekkWh'] * $GLOBALS['price'] / 100 , 2),2,',',' ') . " €<br>";
      }
      $GLOBALS['processWeekkWh'] = 0;
      $GLOBALS['processWeek'] = $datetime[1];
    }
  }
  if($GLOBALS['firstWeek'] < 8) { // first week
    if($GLOBALS['processDay'] <> $datetime[0]) {
      if($GLOBALS['processDay'] <> 0) {
        echo "Dagtotaal: " . round($GLOBALS['processDaykWh'], 2) . " kWh, " . round($GLOBALS['processDaykWh'] * $GLOBALS['price'] / 100 , 2) . " €<br>";
        if (isset($weekTotal)) {
          echo $weekTotal;
        }
        $GLOBALS['processDaykWh'] = 0;
        $GLOBALS['processToday'] = 1;
        $GLOBALS['firstWeek'] += 1;
        if($GLOBALS['firstWeek'] < 8) {
          echo $datetime[7] . " " . $datetime[0] . " " . $datetime[8] . "<br>";
        }
      } else {
        echo $datetime[7] . " " . $datetime[0] . " " . $datetime[8] . ", Week: " . $datetime[1] . "<br>";
      }
      $GLOBALS['processDay'] = $datetime[0];
    }
  } elseif (isset($weekTotal)) {
    echo $weekTotal;
  }
  if(strtolower($powerline["status"]) == "off") {
    $GLOBALS[$powerline["name"]] = $powerline["time"];
  } else if (isset($GLOBALS[$powerline["name"]])) {
    $minutes = round(($GLOBALS[$powerline["name"]] - $powerline["time"]) / 60000);
    if ($minutes < 60 * 8) { // filter communication errors duration longer than  8 hours
      $kWh = ($powerline["Watt"] / 1000) * ($minutes / 60);
      $GLOBALS['processDaykWh'] += $kWh;
      $GLOBALS['processWeekkWh'] += $kWh;
      $GLOBALS['processMonthkWh'] += $kWh;

      if($GLOBALS['firstWeek'] < 8) { // next 7 days details
        if($datetime[4] < "7") {  // Highlight night time: 00h00 - 06h59
          echo "<b style='color: red;'>";
        }
        echo date("d/m/Y H:i:s", $powerline["time"] / 1000) . " to " . date("d/m/Y H:i:s", $GLOBALS[$powerline["name"]] / 1000) . " " . str_pad($powerline["name"], 15, " ", STR_PAD_LEFT) . " " . str_pad($minutes, 4, " ", STR_PAD_LEFT) . " min. " . number_format(round($kWh, 3), 3,',', " ") . " kWh<br>";
        if($datetime[4] < "7") {  // Highlight night time: 00h00 - 06h59
          echo "</b>";
        }
      }
    } else {
      echo "<b style='color: red;'>";
      echo date("d/m/Y H:i:s", $powerline["time"] / 1000) . " to " . date("d/m/Y H:i:s", $GLOBALS[$powerline["name"]] / 1000) . " " . str_pad($powerline["name"], 15, " ", STR_PAD_LEFT) . " " . str_pad($minutes, 4, " ", STR_PAD_LEFT) . " min. " . number_format(round($kWh, 3), 3,',', " ") . " kWh  Genegeerde meting<br>";
      echo json_encode($powerline) . "<br>";
      echo "</b>";
    }
    unset($GLOBALS[$powerline["name"]]);
  }
  if($GLOBALS['processToday'] == 0) {
    echo date("d/m/Y H:i:s", $powerline["time"] / 1000) . " " . $powerline["Watt"] . " " . $powerline["name"] . " " . $powerline["status"] . " " . $GLOBALS[$powerline["name"]] . "<br>";
  }
}

// Reverse sorted power.log
exec("sort data/power.log | tac > data/power.rev ", $output, $return);

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
