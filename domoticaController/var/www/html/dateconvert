# convert to comparable dates
sunrise=$(date -d "$sunrise" +'%Y%m%d%H%M%S')
sunset=$(date -d "$sunset" +'%Y%m%d%H%M%S')
eveningShutterDown=$(date -d "$eveningShutterDown" +'%Y%m%d%H%M%S')
toprocess=("${lights[@]}")
unset lights
for light in "${toprocess[@]}"; do
  lightProperties=(${light})
  date -d "${lightProperties[1]}" &> /dev/null
  if [ $? == 0 ]; then
    lightProperties[1]=$(date -d "${lightProperties[1]}" +'%Y%m%d%H%M%S')
  fi
  date -d "${lightProperties[2]}" &>/dev/null
  if [ $? == 0 ]; then 
    lightProperties[2]=$(date -d "${lightProperties[2]}" +'%Y%m%d%H%M%S')
  fi
  lights+=("${lightProperties[0]} ${lightProperties[1]} ${lightProperties[2]}")
done
