<?php
//$user = 'gebruiker';
//$password = 'wachtwoord';
$user = 'gebruiker';
$password = 'wachtwoord';
$passphrase = 'Geheime schatkamer vol met gouden sleutels';
// https://www.mjhall.org/php-cross-origin-resource-sharing/
function decrypt(string $text, string $key): string {
  $hmac       = mb_substr($text, 0, 64, '8bit');
  $iv         = mb_substr($text, 64, 16, '8bit');
  $ciphertext = mb_substr($text, 80, null, '8bit');

  $keys    = hash_pbkdf2('sha256', $key, $iv, 80000, 64, true);
  $encKey  = mb_substr($keys, 0, 32, '8bit');
  $hmacKey = mb_substr($keys, 32, null, '8bit');
  $hmacNow = hash_hmac('sha256', $iv . $ciphertext, $hmacKey);
  if (! hash_equals($hmac, $hmacNow)) {
    throw new Exception('Authentication error!');
  }
  return openssl_decrypt($ciphertext, 'aes-256-cbc', $encKey,
    OPENSSL_RAW_DATA, $iv
  );
}

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
curl_setopt($curl, CURLOPT_USERPWD, "$user:$password");
curl_setopt($curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
$result = curl_exec($curl);
$ciphertext = base64_decode($result);
/*
// Decryption
$PrivKey = file_get_contents('data/private.key');
$encKey     = mb_substr($ciphertext, 0, 512, '8bit');
$ciphertext = mb_substr($ciphertext, 512, null, '8bit');
$privateKey = openssl_pkey_get_private($PrivKey,$passphrase);
openssl_private_decrypt($encKey, $key, $privateKey);
$result = decrypt($ciphertext, $key);
$json  = json_decode($result);
*/
$json  = json_decode($ciphertext);
curl_close($curl);
if (! empty($json->command)) {
  switch($json->command) {
  case "Reboot":
    exec("sudo /sbin/shutdown -r now");
    break;
  }
}
//echo $result;
echo $ciphertext;
?>
