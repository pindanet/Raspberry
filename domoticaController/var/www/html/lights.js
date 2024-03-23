var times = SunCalc.getTimes(new Date(), 51.2, 5);
var sunrise = times.sunrise.getHours().toString().padStart(2, '0') + ':' + times.sunrise.getMinutes().toString().padStart(2, '0');
var sunset = times.sunset.getHours().toString().padStart(2, '0') + ':' + times.sunset.getMinutes().toString().padStart(2, '0');
var nextAlarm;
var lightsOut;
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
        var endTime = splitTime(conf.event[i].end);
        endDate.setHours(endTime[0]);
        endDate.setMinutes(endTime[1]);
        endDate.setSeconds(0);
        end = endDate.getTime();

        beginDate.setTime(begin);
        var beginTime = splitTime(conf.event[i].begin);
        beginDate.setHours(beginTime[0]);
        beginDate.setMinutes(beginTime[1]);
        begin = beginDate.getTime();

        var alarmDate = new Date();
        alarmDate.setTime(begin);
        var alarmTime = splitTime(conf.event[i].alarm);
        alarmDate.setHours(alarmTime[0]);
        alarmDate.setMinutes(alarmTime[1]);
        alarmDate.setSeconds(0);
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
    nextAlarm = new Date(defaultDate.getTime());
    var nextAlarmTime = splitTime(conf.alarmtime);
    nextAlarm.setHours(nextAlarmTime[0]);
    nextAlarm.setMinutes(nextAlarmTime[1]);
    nextAlarm.setSeconds(0);
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

  lightsOut = new Date(nextAlarm.getTime() + (conf.lights.lightsOut.Offset * 60000)); // 79 min (1 hour 19 min) after wakeup
  var eveningShutterDownTime = timeDate(conf.lights.eveningShutterDown, eveningShutterDown = new Date());

//console.log(conf.lights.eveningShutterDown);

console.log(nextAlarm.toString());
console.log(eveningShutterDown.toString());

  lights();
}
function lights() {
//  console.log(sunrise, sunset);
//  console.log(conf.alarmtime);
  setTimeout(lights, 60000);
}
setTimeout(nextalarm, 6000);
