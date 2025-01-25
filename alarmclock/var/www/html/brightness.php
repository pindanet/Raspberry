<?php
$brightness = intval(htmlspecialchars($_POST["brightness"]));
file_put_contents("/sys/class/backlight/10-0045/brightness", $brightness);
?>
