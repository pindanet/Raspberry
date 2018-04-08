<?php
$context = [ 'http' => [ 'method' => 'GET' ], 'ssl' => [ 'verify_peer' => false, 'allow_self_signed'=> true, 'verify_peer_name' => false ] ];
$context = stream_context_create($context);
$resp = file_get_contents('https://rpipindanet.local/data/thermostat.json', false, $context);
//$json = base64_decode ($resp);
echo $resp;
?>
