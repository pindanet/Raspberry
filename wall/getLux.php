<?php
$context = [ 'http' => [ 'method' => 'GET' ], 'ssl' => [ 'verify_peer' => false, 'allow_self_signed'=> true, 'verify_peer_name' => false ] ];
$context = stream_context_create($context);
$resp = file_get_contents('https://rpipindanet/data/lux', false, $context);
echo $resp;
$resp = file_get_contents('https://rpipindanet/data/luxmin', false, $context);
echo $resp;
$resp = file_get_contents('https://rpipindanet/data/luxmax', false, $context);
echo $resp;
?>
