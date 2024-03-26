var sunTimes;
//console.log(times.sunrise.toString());
//var sunrise = times.sunrise.getHours().toString().padStart(2, '0') + ':' + times.sunrise.getMinutes().toString().padStart(2, '0');
//var sunset = times.sunset.getHours().toString().padStart(2, '0') + ':' + times.sunset.getMinutes().toString().padStart(2, '0');
var nextAlarm;
var breakfast;
var morningLightsOut;
var eveningLightsOn;
function getEventAlarm(nowDate, ref) {
  var nowDateOnly = new Date(nowDate.getTime());
  var refDate = new Date(ref.getTime());
  for (let i = 0; i < conf.event.length; i++) {
    if (conf.event[i].hasOwnProperty('alarm')) {
      nowDateOnly.setHours(0);
      nowDateOnly.setMinutes(0);
      nowDateOnly.setSeconds(0);
      nowDateOnly.setMilliseconds(0);
      var dateOnly = nowDateOnly.getTime();
      var beginDate = new Date(conf.event[i].begindate);
      beginDate.setHours(0);
      var begin = beginDate.getTime();
      if (conf.event[i].repeat > 0) { // repeating event
        while (begin < dateOnly) {
          begin += 86400000 * conf.event[i].repeat;
        }
      }
      if (begin == dateOnly) {
        var expired = begin - beginDate.getTime();
        var endDate = new Date(conf.event[i].enddate);
        var end = endDate.getTime();
        endDate.setTime(end + expired);
        endDate = timeDate(conf.event[i].end, endDate);
//        var endTime = splitTime(conf.event[i].end);
//        endDate.setHours(endTime[0]);
//        endDate.setMinutes(endTime[1]);
//        endDate.setSeconds(0);
console.log(endDate.toString());
        end = endDate.getTime();

        beginDate.setTime(begin);
        beginDate = timeDate(conf.event[i].begin, beginDate);
//        var beginTime = splitTime(conf.event[i].begin);
//        beginDate.setHours(beginTime[0]);
//        beginDate.setMinutes(beginTime[1]);
console.log(beginDate.toString());
        begin = beginDate.getTime();

        var alarmDate = new Date();
        alarmDate.setTime(begin);
        alarmDate = timeDate(conf.event[i].alarm, alarmDate);
//        var alarmTime = splitTime(conf.event[i].alarm);
//        alarmDate.setHours(alarmTime[0]);
//        alarmDate.setMinutes(alarmTime[1]);
//        alarmDate.setSeconds(0);
console.log(alarmDate.toString());
        alarm = alarmDate.getTime();
        if (alarm >= refDate.getTime() && alarm <= end) {
          return alarmDate.getTime();
        }
      }
    }
  }
  return 0;
}
function setAlarmTime(nextAlarmSec, defaultDate) {
  if (nextAlarmSec == 0) { // No alarmtime found, use default alarmtime
    nextAlarm = timeDate (conf.alarmtime, new Date(defaultDate.getTime()));
//    nextAlarm = new Date(defaultDate.getTime());
//    var nextAlarmTime = splitTime(conf.alarmtime);
//    nextAlarm.setHours(nextAlarmTime[0]);
//    nextAlarm.setMinutes(nextAlarmTime[1]);
//    nextAlarm.setSeconds(0);
  } else { // Set found alarmtime
    nextAlarm = new Date(nextAlarmSec);
  }
}
function nextalarm() {
  var today = new Date();
  setAlarmTime(getEventAlarm(today, today), today); // Get today's alarmtime

  if (today > nextAlarm) { // Alarmtime has expired
    var nextDate = new Date();
    nextDate.setDate(nextAlarm.getDate() + 1);
    nextDate.setHours(0,0,0,0);
    setAlarmTime(getEventAlarm(nextDate, today), nextDate); // Get tomorrow's alarmtime
  }

  var sunTimes = SunCalc.getTimes(nextAlarm, 51.2, 5);
  morningTimerLightsOut = new Date(nextAlarm.getTime() + (conf.lights.lightsOut.Offset * 60000)); // 79 min (1 hour 19 min) after wakeup
  breakfast = new Date(nextAlarm.getTime() + (conf.breakfastOffset * 60000)); // 11 min after nextAlarm
  if (morningTimerLightsOut.getTime() > sunTimes.sunrise.getTime()) { // Sun shines
    morningLightsOut = new Date(morningTimerLightsOut.getTime());
  } else { // Still dark
    morningLightsOut = new Date(sunTimes.sunrise.getTime());
  }

  sunTimes = SunCalc.getTimes(new Date(), 51.2, 5);
  var eveningShutterDown = timeDate(conf.lights.eveningShutterDown, eveningShutterDown = new Date());
  if (eveningShutterDown.getTime() > sunTimes.sunset.getTime()) { // Already dark
    eveningLightsOn = new Date(sunTimes.sunset.getTime());
  } else { // Still daylight
    eveningLightsOn = new Date(eveningShutterDown.getTime());
  }

  lights();
}
function lights() {
  var now = new Date().getTime();
  for (let i = 0; i < conf.lights.timer.length; i++) {
    var beginDate = timeDate(conf.lights.timer[i].begin, new Date());
    var begin = beginDate.getTime();
    var endDate = timeDate(conf.lights.timer[i].end, new Date());
    var end = endDate.getTime();
    if (begin <= now && end > now) {
console.log(conf.lights.timer[i]);
console.log(beginDate, endDate);
console.log(conf.switch[conf.lights.timer[i].dev]);
    }
  }
  setTimeout(lights, 60000);
}
setTimeout(nextalarm, 6000);
