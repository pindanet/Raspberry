<?php
# Random background
$dir = 'background';
$files = glob($dir . '/*.jpg');
shuffle($files);
echo $files[0];

# Dynamic background
/*
$prefix = 'background/dynamic/Achtergrond-';
$suffix = (int)date("G");
$suffix = $suffix * 2;
if (date("i") > "30") {
  $suffix++;
}
echo $prefix . $suffix . ".jpg";
*/

//    $file = array_rand($files);
//    return $files[$file];
?>
