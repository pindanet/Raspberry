<?php
//ini_set('display_errors', 1);
//ini_set('display_startup_errors', 1);
//error_reporting(E_ALL);
//Post data als argumenten bij php cli

// php ssh.php command="uname -a"
//if (!isset($_SERVER["HTTP_HOST"])) {
//  parse_str($argv[1], $_GET);
//  parse_str($argv[1], $_POST);
//}

$command = htmlspecialchars($_POST["command"]);
$command = str_replace(" &gt; /tmp/"," > /tmp/",$command);
$host = htmlspecialchars($_POST["host"]);
exec("ls /home/", $users);
exec("ssh -v -i data/id_rsa -o StrictHostKeyChecking=no  -o 'UserKnownHostsFile /dev/null' " . $users[0] . "@" . $host . " '" . $command . "'", $output, $return);
//exec("ssh -i data/id_rsa -o StrictHostKeyChecking=no  -o 'UserKnownHostsFile /dev/null' dany@localhost 'echo off > /tmp/thermostatManualTest'", $output, $return);


foreach ($output as $line) {
  echo "$line\n";
}
?>
