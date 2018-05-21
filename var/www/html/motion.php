<?php
$files = array_diff(scandir("motion/fotos/"), array('..', '.'));
rsort($files);
echo json_encode($files);
//ob_flush();
//ob_start();
//var_dump($files);
//file_put_contents('data/debug', ob_get_flush());
?>
