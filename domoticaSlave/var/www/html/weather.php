<?php
  $silent = true;
  exec("curl -s wttr.in/Brugge?lang=nl | head -7 | tail -5 | aha", $output);
  foreach ($output as $line) {
    if(strpos($line, "<pre>") !== false){
      $silent = false;
    }
    if(strpos($line, "</pre>") !== false){
      $silent = true;
    }
    if($silent === false) {
      echo "$line\n";
    }
  }
?>
