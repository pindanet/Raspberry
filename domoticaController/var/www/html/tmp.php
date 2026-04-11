<?php
foreach (glob("/dev/shm/pindatasmotastatus-*") as $filename) {
  $pieces = explode("pindatasmotastatus-", $filename);
  echo $pieces[1] . "\n";
}
?>
