<?php
$dir = 'background';
$files = glob($dir . '/*.jpg');
shuffle($files);
echo $files[0];
//    $file = array_rand($files);
//    return $files[$file];
?>
