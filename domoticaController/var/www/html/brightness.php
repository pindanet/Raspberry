<?php
if(isset($_POST['power'])){
  $power = intval(htmlspecialchars($_POST["power"]));
  file_put_contents("/sys/class/backlight/10-0045/bl_power", $power);
} elseif (isset($_POST['brightness'])){
  $brightness = intval(htmlspecialchars($_POST["brightness"]));
  file_put_contents("/sys/class/backlight/10-0045/brightness", $brightness);
}
?>
