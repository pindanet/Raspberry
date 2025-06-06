<?php
$json = file_get_contents('php://input');
$data = json_decode($json, true);
// Check if decoding was successful
if ($data !== null) {
  copy("data/conf.json","data/conf.json.bak");
  sleep(1);
  // Perform further processing or respond to the request
  if (file_put_contents("data/conf.json", $json))
    echo "Configuration is saved.";
  else 
    echo "Oops! Error creating json file...";
} else {
   // JSON decoding failed
   http_response_code(400); // Bad Request
   echo "Invalid JSON data";
}
?>
