<?php
$files = array_diff(scandir("motion/day/"), array('..', '.'));
sort($files);
echo json_encode($files);
?>
