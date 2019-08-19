<?php
$command = htmlspecialchars($_POST["command"]);
file_put_contents('remote/command', $command);
?>
