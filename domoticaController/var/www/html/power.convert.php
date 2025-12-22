<?php
function processLine($powerline) {
  $powerline["time"] = intval($powerline["time"] / 1000);
  file_put_contents("data/power.new.log", json_encode($powerline) . "\n", FILE_APPEND | LOCK_EX);
}

unlink("data/power.new.log");
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
file_put_contents("data/power.new.log", file_get_contents("data/tasmota.log") . "\n", FILE_APPEND | LOCK_EX);

sleep(5);

header("Location: power.new.php");
exit();
?>
