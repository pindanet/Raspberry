<?php 
switch($_POST["command"]):
case "halt": 
  exec("sudo /sbin/shutdown -h now");
  echo "Soft Access Point afgesloten.";
  break;
endswitch ?>
