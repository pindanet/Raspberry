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
$price = 30; // per kWh in centimen

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
        // Output Line Content
        echo $line;
        $powerline = json_decode($line, true);
        var_dump($powerline);
    }
    fclose($file);
}
?>
</body>
</html>
