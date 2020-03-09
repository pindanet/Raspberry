<?php
function pathPrefix(&$value,$key) {
  $value="motion/fotos/$value";
}
$files = array_diff(scandir("motion/fotos/"), array('..', '.'));
sort($files);
array_walk($files,"pathPrefix");
echo json_encode($files);
?>
