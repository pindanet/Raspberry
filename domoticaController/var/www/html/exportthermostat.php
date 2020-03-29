<?php
header("Content-Type: text/plain");
header("Content-Transfer-Encoding: base64"); 
header("Content-disposition: attachment; filename=\"thermostat\""); 
readfile("/var/www/html/data/thermostat"); 
?>
