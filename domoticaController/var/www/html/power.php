<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>PindaDomo Power log</title>
</head>
<body style="font-family: monospace;">
<div id="errors"  style="font-weight: bold; color: red"></div>
<div id="log">Bezig met het inlezen van het logboek...</div>
<?php
// ToDo
// reverse power.log > power.rev

$price = 32; // per kWh in centimen
$processDay = 0;
$processToday = 0;

function processLine($powerline) {
  $datetime = explode(" ", date("d m Y H m s", $powerline["time"] / 1000));
//  echo $GLOBALS['processDay'] . " " . $datetime[0] . "<br>";
  if($GLOBALS['processDay'] <> $datetime[0]) {
    if($GLOBALS['processDay'] <> 0) {
      $GLOBALS['processToday'] = 1;
    }
    $GLOBALS['processDay'] = $datetime[0];
    echo "New day: " . $GLOBALS['processDay'] . "<br>";
  }
  if($GLOBALS['processToday'] == 0) {
//  var_dump($powerline);
    echo date("d/m/Y H:m:s", $powerline["time"] / 1000) . "<br>";
  }
}

$file = fopen("data/power.log", "r");
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
