videos+=("aquarium.mp4")
videos+=("haardvuur.mp4")
videos+=("lente.mp4")
video=${videos[$(( $RANDOM % ${#videos[@]} ))]}
rm /home/dany/video.mp4
ln -s /home/dany/$video /home/dany/video.mp4
if [ $video == "aquarium.mp4" ]; then
  sed -i 's/\(^subtitleColor=\).*/\1"black"/' /var/www/html/data/thermostat
else
  sed -i 's/\(^subtitleColor=\).*/\1"white"/' /var/www/html/data/thermostat
fi
