<?php
$context = [ 'http' => [ 'method' => 'GET' ], 'ssl' => [ 'verify_peer' => false, 'allow_self_signed'=> true, 'verify_peer_name' => false ] ];
$context = stream_context_create($context);
$resp->luminance = intval(file_get_contents('https://rpipindanet.local/motion/luminance.txt', false, $context));

if ($resp->luminance == 0) {
  $resp->luminance = 150;
  $resp->max = 200;
  $resp->min = 100;
  echo json_encode($resp);
  exit();
}

$filename = "data/max.luminance";
if (file_exists($filename)) {
  $resp->max = intval(file_get_contents($filename));
} else {
  $resp->max = $resp->luminance;
  file_put_contents($filename, $resp->max);
}
if ($resp->luminance > $resp->max) {
  file_put_contents($filename, $resp->luminance);
}

$filename = "data/min.luminance";
if (file_exists($filename)) {
  $resp->min = intval(file_get_contents($filename));
} else {
  $resp->min = $resp->luminance;
  file_put_contents($filename, $resp->min);
}
if ($resp->luminance < $resp->min) {
  file_put_contents($filename, $resp->luminance);
}

echo json_encode($resp);
?>
