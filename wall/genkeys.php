<?php
// https://www.zimuel.it/slides/zendcon2016/encrypt#/21
// Generate public and private keys
$keys = openssl_pkey_new(array(
  "private_key_bits" => 4096,
  "private_key_type" => OPENSSL_KEYTYPE_RSA,
));

// Store the private key in a file
$passphrase = 'Geheime schatkamer vol met gouden sleutels';
openssl_pkey_export_to_file($keys, 'data/private.key', $passphrase);

// Store the public key in a file
$details   = openssl_pkey_get_details($keys);
$publicKey = $details['key'];
file_put_contents('data/public.key', $publicKey);
?>
