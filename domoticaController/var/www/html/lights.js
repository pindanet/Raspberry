var sunTimes;
var nextAlarm;
var breakfast;
var morningLightsOut;
var eveningLightsOn;
var bedTime;
function lightSwitch(name, cmd) {
  var tasmotaSwitch = conf.switch[name];
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      if (this.responseText != "[]") { // no response
        const output = JSON.parse(this.responseText);
        if (output[0].includes(':"OFF"}')) {
          tasmotaSwitch.status = "Off";
        } else if (output[0].includes(':"ON"}')) {
          tasmotaSwitch.status = "On";
        }
        powerLog(tasmotaSwitch, name);
        if (cmd == "Toggle") {
          if (Object.keys(tasmotaSwitch).includes("manual")) {
            delete tasmotaSwitch.manual;
          } else {
            tasmotaSwitch.manual = tasmotaSwitch.status;
          }
        }
      }
    }
  };
  if (typeof tasmotaSwitch.Channel !== 'undefined') {
    xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + tasmotaSwitch.IP + "/cm?cmnd=Power"+ tasmotaSwitch.Channel + "%20" + cmd));
  } else {
    xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + tasmotaSwitch.IP + "/cm?cmnd=Power%20" + cmd));
  }
}
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
        end = endDate.getTime();

        beginDate.setTime(begin);
        beginDate = timeDate(conf.event[i].begin, beginDate);
        begin = beginDate.getTime();

        var alarmDate = new Date();
        alarmDate.setTime(begin);
        alarmDate = timeDate(conf.event[i].alarm, alarmDate);
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
  var alarmtime = timeDate (conf.alarmtime, new Date());
  if (today.getTime() < alarmtime.getTime()) { // still night, disable backlight Touchscreen
    gotoSleep();
  }
  setTimeout(wakeup, nextAlarm.getTime() - today.getTime()); // activate backlight Touchscreen at nextAlarm

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
}
function lights() {
  var now = new Date().getTime();
  for (const [key, value] of Object.entries(conf.switch)) { // reset switch commands
   conf.switch[key].cmd = "Off";
  }
  for (let i = 0; i < conf.lights.timer.length; i++) {
    var beginDate = timeDate(conf.lights.timer[i].begin, new Date());
    var begin = beginDate.getTime();
    var endDate = timeDate(conf.lights.timer[i].end, new Date());
    var end = endDate.getTime();
    if (begin <= now && end > now) {
      conf.switch[conf.lights.timer[i].dev].cmd = "On";
    }
  }
  for (const [key, value] of Object.entries(conf.switch)) {
    if (! Object.keys(conf.switch[key]).includes("status")) {
      lightSwitch(key, conf.switch[key].cmd);
    } else {
      if (! Object.keys(conf.switch[key]).includes("manual")) {
        if (conf.switch[key].cmd != conf.switch[key].status) {
          lightSwitch(key, conf.switch[key].cmd);
        }
      }
    }
  }
}
