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
$datetime = explode(" ", date("j W n Y"));
$processDay = $datetime[0];
$processMonth = $datetime[2];
$processYear = $datetime[3];
$firstWeek = 0;
$firstMonth = 0;
$firstYear = 0;

date_default_timezone_set('Europe/Brussels');
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

$days = array(
    'Zondag',
    'Maandag',
    'Dinsdag',
    'Woensdag',
    'Donderdag',
    'Vrijdag',
    'Zaterdag'
);

$powerLog = [];

function processLine($powerline) {
  $datetime = explode(" ", date("j W n Y G i s l F w", $powerline["time"] / 1000));
  if(strtolower($powerline["status"]) == "off") {
    $GLOBALS[$powerline["name"]] = $powerline["time"];
  } else if (isset($GLOBALS[$powerline["name"]])) {
    $minutes = round(($GLOBALS[$powerline["name"]] - $powerline["time"]) / 60000);
    if ($minutes < 60 * 19) { // filter communication errors duration longer than  19 hours
      $kWh = ($powerline["Watt"] / 1000) * ($minutes / 60);
      if (!isset($GLOBALS['powerLog'][$datetime[3]])) {
        $GLOBALS['powerLog'][$datetime[3]] = [];
      }
      if (!isset($GLOBALS['powerLog'][$datetime[3]][$datetime[2]])) {
        $GLOBALS['powerLog'][$datetime[3]][$datetime[2]] = [];
      }
      if (!isset($GLOBALS['powerLog'][$datetime[3]][$datetime[2]][$datetime[0]])) {
        $GLOBALS['powerLog'][$datetime[3]][$datetime[2]][$datetime[0]] = [];
      }
      $GLOBALS['powerLog'][$datetime[3]][$datetime[2]][$datetime[0]]['kWh'] += $kWh;
      $GLOBALS['powerLog'][$datetime[3]][$datetime[2]][$datetime[0]]['week'] = $datetime[1];
      $GLOBALS['powerLog'][$datetime[3]][$datetime[2]][$datetime[0]]['date'] = $datetime[0];
      $GLOBALS['powerLog'][$datetime[3]][$datetime[2]][$datetime[0]]['month'] = $GLOBALS['months'][$datetime[2] - 1];
      $GLOBALS['powerLog'][$datetime[3]][$datetime[2]][$datetime[0]]['weekday'] = $GLOBALS['days'][$datetime[9]];

      if ($GLOBALS['processDay'] != $datetime[0] OR $GLOBALS['processMonth'] != $datetime[2] OR $GLOBALS['processYear'] != $datetime[3]) {
        if($GLOBALS['firstWeek'] < 8) { // next 7 days details
          echo "<hr>";
        }
        $targetArray = $GLOBALS['powerLog'][$GLOBALS['processYear']][$GLOBALS['processMonth']][$GLOBALS['processDay']];
        if ($GLOBALS['processDay'] != $datetime[0]) {
          if($GLOBALS['firstMonth'] < 1 OR $GLOBALS['firstWeek'] < 8) { // First month daily totals
            printf("<strong>%-10s %'02u/%'02u/%u: %.2f kWh, %.2f €</strong><br>", $targetArray['weekday'], $GLOBALS['processDay'], $GLOBALS['processMonth'], $GLOBALS['processYear'], $targetArray['kWh'], $targetArray['kWh'] * $GLOBALS['price'] / 100);
          }
          $GLOBALS['processDay'] = $datetime[0];
          $GLOBALS['firstWeek'] += 1;
        }
        if ($GLOBALS['processMonth'] != $datetime[2]) {
          $targetMonth = $GLOBALS['powerLog'][$GLOBALS['processYear']][$GLOBALS['processMonth']];
          $total = 0;
          foreach($targetMonth as $day) {
            $total += $day['kWh'];
          }
          $GLOBALS['powerLog'][$GLOBALS['processYear']][$GLOBALS['processMonth']]['total'] = $total;
          $GLOBALS['firstMonth'] += 1;
          if($GLOBALS['firstMonth'] == 1) {
            echo "<hr>";
          }
          printf("<strong>%-9s %u: %6.2f kWh, %6.2f €</strong><br>", $targetArray['month'], $GLOBALS['processYear'], $total, $total * $GLOBALS['price'] / 100);
          $GLOBALS['processMonth'] = $datetime[2];
        }
        if ($GLOBALS['processYear'] != $datetime[3]) {
          $targetYear = $GLOBALS['powerLog'][$GLOBALS['processYear']];
          $total = 0;
          foreach($targetYear as $month) {
            $total += $month['total'];
          }
          $GLOBALS['powerLog'][$GLOBALS['processYear']]['total'] = $total;
          $GLOBALS['firstYear'] += 1;
          if($GLOBALS['firstYear'] == 1) {
            echo "<hr>";
          }
          printf("<strong>%u: %6.2f kWh, %6.2f €</strong><br>", $GLOBALS['processYear'], $total, $total * $GLOBALS['price'] / 100);
          $GLOBALS['processYear'] = $datetime[3];
        }
        if($GLOBALS['firstWeek'] < 8) { // next 7 days details
          echo "<hr>";
        }
      }
      if($GLOBALS['firstWeek'] < 8) { // next 7 days details
        if($datetime[4] < "7") {  // Highlight night time: 00h00 - 06h59
          echo "<b style='color: red;'>";
        }
        printf("%s to %s %15s %4u Watt %4u min %6.3f kWh<br>", date("d/m/Y H:i:s", $powerline["time"] / 1000), date("d/m/Y H:i:s", $GLOBALS[$powerline["name"]] / 1000), $powerline["name"], $powerline["Watt"], $minutes, $kWh);
        if($datetime[4] < "7") {  // Highlight night time: 00h00 - 06h59
          echo "</b>";
        }
      }
    } else {
      echo "<b style='color: red;'>";
      printf("%s to %s %15s %4u Watt %4u uur %u min genegeerd.<br>", date("d/m/Y H:i:s", $powerline["time"] / 1000), date("d/m/Y H:i:s", $GLOBALS[$powerline["name"]] / 1000), $powerline["name"], $powerline["Watt"], $minutes/60, $minutes % 60);
      echo "</b>";
    }
    unset($GLOBALS[$powerline["name"]]);
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
