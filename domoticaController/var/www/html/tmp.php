<?php
foreach (glob("/tmp/pindatasmotastatus-*") as $filename) {
  $pos = strrpos($filename, '-');
  echo substr($filename, $pos + 1) . "\n";
}
?>
