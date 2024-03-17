var times = SunCalc.getTimes(new Date(), 51.2, 5);
var sunrise = times.sunrise.getHours().toString().padStart(2, '0') + ':' + times.sunrise.getMinutes().toString().padStart(2, '0');
var sunset = times.sunset.getHours().toString().padStart(2, '0') + ':' + times.sunset.getMinutes().toString().padStart(2, '0');
function lights() {
  console.log(sunrise, sunset);
  console.log(conf.alarmtime);
  setTimeout(lights, 60000);
}
setTimeout(lights, 6000);
