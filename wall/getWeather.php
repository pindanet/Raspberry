<?php
$curl = curl_init();
curl_setopt($curl, CURLOPT_HTTPHEADER, array(
    'Accept-Language: nl')
);
curl_setopt($curl, CURLOPT_URL, 'wttr.in/brugge?0Q');
$result = curl_exec($curl)
?>
