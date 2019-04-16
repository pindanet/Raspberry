<?php
exec("cat /sys/class/backlight/rpi_backlight/bl_power", $output, $return);
echo $output[0];
?>
