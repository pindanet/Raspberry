<?php
// php openssl.php password=secret message=Hello
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

// Make password hash in terminal with
// php openssl.php IGTzbhSjRf=12345678
$hash = '$2y$10$Gn21BCxn6ZJxX7Azg/XBsOUsarlsWY26KJJEUV2z6LMGhkTZ7Ijxe';
// Encrypt in terminal with
// php openssl.php IGTzbhSjRf=1234 pkxuBCfCDnRnzyWLi=message%20to%20be%20encrypt
$key = base64_decode("OvW/rWBI0+HWUmC7ypTataUi6h/ucrb0YiH8aFcFtZaRDd5+O+DPtIqE");
$iv = base64_decode("QUUZkc9oHt6RSrqM");
$tag = base64_decode("fCoCo+MOHIfqkuz0hokRdw==");
$ciphertext = base64_decode("NzFublJUdXl3WnREOGFCQ2t0M0o2TkNmaUVycA==");

$password = htmlspecialchars($_POST["IGTzbhSjRf"]);
if (password_verify($password, $hash)) {
  $cipher = "aes-128-gcm";
  if (isset($_POST["pkxuBCfCDnRnzyWLi"])) { //encrypt
    $salt = openssl_random_pseudo_bytes(12);
    $keyLength = 42;
    $iterations = 10000;
    $key = openssl_pbkdf2($password, $salt, $keyLength, $iterations, 'sha256');
    echo "Key: ".base64_encode($key)."\n";
    $plaintext = htmlspecialchars($_POST["pkxuBCfCDnRnzyWLi"]);
    if (in_array($cipher, openssl_get_cipher_methods())) {
      $ivlen = openssl_cipher_iv_length($cipher);
      $iv = openssl_random_pseudo_bytes($ivlen);
      echo "Iv: ".base64_encode($iv)."\n";
      $ciphertext = openssl_encrypt($plaintext, $cipher, $key, $options=0, $iv, $tag);
      echo "Tag: ".base64_encode($tag)."\n";
      echo "Ciphertext: ".base64_encode($ciphertext)."\n";
    }
  } else {
    $original_plaintext = openssl_decrypt($ciphertext, $cipher, $key, $options=0, $iv, $tag);
    echo $original_plaintext."\n";
  }
} else {
  $hash = password_hash($password, PASSWORD_DEFAULT);;
  echo "Password hash: ".$hash."\n";
}
//print_r(openssl_get_cipher_methods());
?>
