<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>PindaDomo Power log</title>
</head>
<body style="font-family: monospace;white-space: pre;">
<div id="errors"  style="font-weight: bold; color: red"></div>
<div id="log">Bezig met het inlezen van het logboek...</div>
<?php
// ToDo
// 

$price = 32; // per kWh in centimen
$processDay = 0;
$processToday = 0;

function processLine($powerline) {
  $datetime = explode(" ", date("d m Y G i s l", $powerline["time"] / 1000));
  if($GLOBALS['processDay'] <> $datetime[0]) {
    if($GLOBALS['processDay'] <> 0) {
      $GLOBALS['processToday'] = 1;
      echo "Dag: " . $datetime[6] . " " . $datetime[0] . "<br>";
    } else {
      echo "Vandaag: " . $datetime[0] . "<br>";
    }
    $GLOBALS['processDay'] = $datetime[0];
  }
  if(strtolower($powerline["status"]) == "off") {
    $GLOBALS[$powerline["name"]] = $powerline["time"];
  } else if (isset($GLOBALS[$powerline["name"]])) {
// https://www.tutorialspoint.com/how-to-calculate-the-difference-between-two-dates-in-php
    $minutes = round(($GLOBALS[$powerline["name"]] - $powerline["time"]) / 60000);
    if($datetime[3] < "7") {  // Highlight night time: 00h00 - 06h59
      echo "<b style='color: red;'>";
    }
echo date("d/m/Y H:i:s", $powerline["time"] / 1000) . " to " . date("d/m/Y H:i:s", $GLOBALS[$powerline["name"]] / 1000) . " " . str_pad($powerline["name"], 15, " ", STR_PAD_LEFT) . " " . $minutes . " minutes<br>";
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
