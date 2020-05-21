<?php
// curl -d "url=https://www.google.com/calendar/ical/feestdagenbelgie%40gmail.com/public/basic.ics" -X POST http://pindadomo/upload.php
$filedata=file_get_contents($_POST["url"]);
$target_file = "fullcalendar/" . basename($_POST["url"]);
$imageFileType = strtolower(pathinfo($target_file,PATHINFO_EXTENSION));
// Allow certain file formats
if($imageFileType != "ics") {
  echo "Sorry, this filesformat is not allowed.";
  exit();
}
file_put_contents($target_file, $filedata);
echo basename($_POST["url"]) . " ontvangen."
?>
