<?php

// Use terminal arg as POST en GET arg, example: php openssl.php password=12345678 message=Hello
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

// Make password hash in terminal with
// php openssl.php IGTzbhSjRf=12345678
$hash = '$2y$10$oZGzi3P.vmRTVir5U4uRhOw026b6LuTWHg6z/aTyIZHyR0XSZr1K6';
// Encrypt in terminal with
// php openssl.php IGTzbhSjRf=$(echo -n '12345678' | base64) pkxuBCfCDnRnzyWLi=message%20to%20be%20encrypt
$key = base64_decode("jns8lasJOMkQwSjmtCCIGexU/9xQUXQTM56AJJE10q54zu76ukgoCJbN");
$iv = base64_decode("Y4kbzFegGy6YWJyh");
$tag = base64_decode("OIGZWb53/hNOVQGJOYfqhA==");
$ciphertext = base64_decode("QU5kTVN4MVlxWGNGNC9BcTRadVJHcjBRMWhuWTZSS1lCNGZZckhXczFnL1EzMUNzVlExSnVmejNpeUl1ZUUxUmhRU1FxZmt3VDJWbDdwRmhiMFg5c24rZE8rcE1PQjlRQU94S1g2WUVaOG90Nm5GWVJ4K3ZSVWFvMm5odDFFdjlydkxuK2JaSkUycEw1YllmVFg5N3ZGUzBCMWhWaWsxek5VZ0x2VkhrZmU3cm4vMXFrSFVEMnpWT3ZqTE11Ujc1cTdpQW1NL2hEVXB1ZEJTZkEzQitYZEdmVXlhaTl3dVRHSStBNkdYajVHZDNTd3dNNEtoa0NqdHBlRmtOOWRUT3k3cEV0VzkrUm9IdGxEK1ZNb0pTNE5WKzlJdWpjY3B0WXl6aDgybk5QV3FGT3oyYlFneVB0b0FCK3BrS3hoMTNzQUVNR0FSM3NEY2pIRldWU3A5dVNNUEVjc1dSdVo1b2RidWlTaFhVZWoycldZbWRhUy9yb2dpd2dSTmZyV1BJdmc2RUM5TExWdGhQS05tMGdzNitSemdFeTdSR2NOTXplZjQ4UHo5Z1QvSU5WWU1FbHdPeGxEbjVhMXdWaG1QQS93SUJBL0I1V0U3Njh3ZmROL0xKOFZFcU9sSTRhTXdwaHFwaXpqZzl1eXVHenZFK1ZmcjFkN1lvelQ3UTc1SzFSYVNRRGNjNTVNYmNMS3Q5NkJmQ1JWSHVEdW1WRVhWOTRBeXE5UUxkLzliRG9ValZJNVYzWHYxTithTHlsQTRRbUhvVE9uS0duTFRCUktQNVd4ek50R2RPYXd5UFZHZ1NnL1ZJSStoWUNxeDd6Q0xQYWpyYXF1U1RYZjc1UkI1czBJTkhsdjV2MjVMYW5yeDFIVUNVTWhaVkF2em5nVmswNEMxWGprLzUxbUZJdC8vWHJyMnF4MWtPVHNMKy93TklCWUMvSEdoMU8vbkhJWWZyODF3elI3NUY4c1pOMWFxQzVWODA2dkRibEJmSFo2OE1oclE5clRSRi9BZ2UwaXMwTXA2d2FvQ084QUNpazA0aXVkMy9CVlkzaU9LZE45blBjdVBqSGpFS09Bckx0QVc1cEx4WXo4d2VLa29aY0Nxd2hFWExxU2d0eFlkQ3JpZ0daNVJXeGNVUTQ2RTk1a0RhamxKdnZldWlKaytLb2E2a3V3TUI3YkRTTGZjVjJqOXNCdStJbUFEVmNmQTZoZz09");

$password = htmlspecialchars($_POST["IGTzbhSjRf"]);
if (password_verify(base64_decode($password), $hash)) {
  $cipher = "aes-128-gcm";
  if (isset($_POST["pkxuBCfCDnRnzyWLi"])) { //encrypt
    $salt = openssl_random_pseudo_bytes(12);
    $keyLength = 42;
    $iterations = 10000;
    $key = openssl_pbkdf2($password, $salt, $keyLength, $iterations, 'sha256');
    echo "Key: ".base64_encode($key)."\n";
    $plaintext = htmlspecialchars($_POST["pkxuBCfCDnRnzyWLi"]);
//$plaintext = <<<EOT
//<p>HTML code to encrypt.</p>
//EOT;
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
    echo base64_encode($original_plaintext);
  }
} else {
  $hash = password_hash($password, PASSWORD_DEFAULT);;
  echo "Password hash: ".$hash."\n";
}
//print_r(openssl_get_cipher_methods());
?>
