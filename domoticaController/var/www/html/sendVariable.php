<?php
$json = file_get_contents('php://input');
$data = json_decode($json, true);
// Check if decoding was successful
if ($data !== null) {
  copy("data/variable.json","data/variable.json.bak");
  // Perform further processing or respond to the request
  if (file_put_contents("data/variable.json", $json))
    echo "Variable is saved.";
  else
    echo "Oops! Error creating json file...";
} else {
   // JSON decoding failed
   http_response_code(400); // Bad Request
   echo "Invalid JSON data";
}
?>
