<?php
$context = [ 'http' => [ 'method' => 'GET' ], 'ssl' => [ 'verify_peer' => false, 'allow_self_signed'=> true, 'verify_peer_name' => false ] ];
$context = stream_context_create($context);

$luminance = json_decode(file_get_contents('https://rpipindanet.local/motion/luminance.json', false, $context));
if ($luminance == NULL) {
  $luminance->luminance = 150;
  $luminance->max = 200;
  $luminance->min = 100;
}
echo json_encode($luminance);
?>
