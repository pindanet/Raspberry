<?php
// wget -qO- --header='Content-Type: application/json' --post-data '["Computertafel","Zonsondergang","Tropen"]' http://localhost/countstatus.php
$json = json_decode(file_get_contents("php://input"), true);
if ($json === null){
  exit("Illegal input");
}
$count = 0;
foreach ($json as $check) {
  if (file_exists("/dev/shm/pindatasmotastatus-" . $check)) {
    $count += 1;
  }
}
echo $count;
?>
