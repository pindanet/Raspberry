<?php
// https://www.mjhall.org/php-cross-origin-resource-sharing/
$req = array('device' => 'wall');
$data = json_encode($req);

$curl = curl_init();
curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
curl_setopt($curl, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/json',
    'Content-Length: ' . strlen($data))
);
curl_setopt($curl, CURLOPT_URL, 'https://slimhuis.pindanet.be/remote.php');
$result = curl_exec($curl);
$json  = json_decode($result);
curl_close($curl);
if (! empty($json->command)) {
  switch($json->command) {
  case "Reboot":
    exec("sudo /sbin/shutdown -r now");
    break;
  }
}
echo $result;
?>
