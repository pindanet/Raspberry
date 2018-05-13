<?php
$context = [ 'http' => [ 'method' => 'GET' ], 'ssl' => [ 'verify_peer' => false, 'allow_self_signed'=> true, 'verify_peer_name' => false ] ];
$context = stream_context_create($context);
$resp = file_get_contents('https://rpipindanet.local/luminance.php', false, $context);
echo $resp;
?>
