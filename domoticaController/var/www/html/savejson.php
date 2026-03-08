<?php
// Test: wget -q -O- --post-data "save=$(echo -n '/tmp/save.json' | xxd -p -c 256)&json=$(echo -n '{"target":"server", "message":"JSON bericht"}' | xxd -p -c 256)" -H "http://pindadomo/savejson.php"
// Use terminal arg as POST en GET arg, example: sudo -u www-data php /var/www/html/savejson.php save=$(echo -n '/tmp/save.json' | xxd -p -c 256) json=$(echo -n '{"target":"server", "message":"JSON bericht"}' | xxd -p -c 256)
if (!isset($_SERVER["HTTP_HOST"])) {
  parse_str(implode('&', array_slice($argv, 1)), $_GET);
  parse_str(implode('&', array_slice($argv, 1)), $_POST);
}

$save = htmlspecialchars($_POST["save"]);
$json = htmlspecialchars($_POST["json"]);

//file_put_contents("data/debug.txt", $save . " " . $json);

$data = json_decode($json, true);
  echo $save." ".$json;
// Check if decoding was successful
if ($data !== null) {

  echo $save." ".$json;

/*
  if (file_exists($save)) {
    rename($save, $save . ".bak");
  }
*/
//  sleep(1);

  // Perform further processing or respond to the request
/*
  if (file_put_contents($save, $json))
    echo "Configuration is saved.";
  else
    echo "Oops! Error creating json file...";
*/
} else {
   // JSON decoding failed
//   http_response_code(400); // Bad Request
   echo "Invalid JSON data";
   echo $json;
}
?>
