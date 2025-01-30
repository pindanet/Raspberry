var startTimer;
var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");
var updateScreen = 10;

function checkTime(i) {
  if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
  return i;
}

const stringToHex = (str) => {
  let hex = '';
  for (let i = 0; i < str.length; i++) {
    const charCode = str.charCodeAt(i);
    const hexValue = charCode.toString(16);

    // Pad with zeros to ensure two-digit representation
    hex += hexValue.padStart(2, '0');
  }
  return hex;
};

function radioStatus() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const output = JSON.parse(this.responseText);
      if (output.length > 0) {
        var fontsize = 10;
        var status = output[0].substring(output[0].indexOf("='") + 2, output[0].indexOf("';"));
        if (status.length > 16) {
          fontsize = 5;
        }
        document.getElementById("radio").innerHTML = "<span style='font-size:" + fontsize + "vw'>" + status + "</span>";
      } else {
        document.getElementById("radio").innerHTML = "Wekkerradio";
      }
    }
  };
  xhr.send("cmd=cat&params="+stringToHex("/var/www/html/data/radio.log | tail -1"));
}

function timeDate (time, dateObject) {
  var hourMin = [];
  if (time.indexOf(":") > -1) {
    hourMin = time.split(':');
  } else {
    if (conf.hasOwnProperty(time)) {
      hourMin = conf[time].split(':');
    } else {
      var varDate = new Date();
      varDate.setTime(window[time].getTime());
      hourMin[0] = varDate.getHours();
      hourMin[1] = varDate.getMinutes();
    }
  }
  dateObject.setHours(hourMin[0], hourMin[1], 0, 0);
  return dateObject;
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
//          begin += 86400000 * conf.event[i].repeat;
          newBeginDate = new Date(begin);
          newBeginDate.setDate(newBeginDate.getDate() + conf.event[i].repeat);
          begin = newBeginDate.getTime();
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

function setBrightness(brightness) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "brightness.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("brightness=" + brightness);
}

function radioStop() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("cmd=touch&params="+stringToHex("/var/www/html/data/radio.stop"));
}

function radioPlay(cmd, volume, channel) {
console.log(cmd, volume, channel);
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("cmd=echo&params="+stringToHex("'" + cmd + ", " + volume + ", " + conf.radio.channel[channel].interval + ", " + conf.radio.channel[channel].URL + "' > /var/www/html/data/radio.cmd"));
}

var nextAlarm;
function nextalarm() {
  var today = new Date();
  setAlarmTime(getEventAlarm(today, today), today); // Get today's alarmtime
  if (today > nextAlarm) { // Alarmtime has expired
    var nextDate = new Date();
    nextDate.setDate(nextAlarm.getDate() + 1);
    nextDate.setHours(0,0,0,0);
    setAlarmTime(getEventAlarm(nextDate, today), nextDate); // Get tomorrow's alarmtime
  }

//var testAlarm = new Date();
//testAlarm.setTime(testAlarm.getTime() + (10*1000));
//console.log(testAlarm);
//setTimeout(radioPlay, testAlarm.getTime() - today.getTime(), "alarm", conf.alarmclock.volume, conf.alarmclock.alarmradio); // Start Alarm

console.log(nextAlarm);
console.log(today);
console.log(((nextAlarm.getTime() - today.getTime()) / 1000) / 60);
  setTimeout(radioPlay, nextAlarm.getTime() - today.getTime(), "alarm", conf.alarmclock.volume, conf.alarmclock.alarmradio); // Start Alarm

  sunTimes = SunCalc.getTimes(new Date(), conf.location.Latitude, conf.location.Longitude, conf.location.Altitude);
  if (today.getTime() > sunTimes.sunset.getTime()) { // night, dim backlight Touchscreen
    setBrightness(20);
  } else { //daylight
    setBrightness(64);
    setTimeout(setBrightness, sunTimes.sunset.getTime() - today.getTime(), 20); // dim backlight Touchscreen at sunset
  }
}

var radioPlaying=false;
function startTime() {
  clearTimeout(startTimer);
  var today = new Date();
  var h = today.getHours();
  var m = today.getMinutes();
  m = checkTime(m);
  var s = today.getSeconds();
  s = checkTime(s);

  document.getElementById('clock').innerHTML = h + ":" + m + ":" + s;

  updateScreen++;
  if (updateScreen > 10) {
    document.getElementById("clockdate").innerHTML = today.getDate() + '&nbsp;' + monthNames[today.getMonth()] + '&nbsp;' + today.getFullYear();
    document.getElementById('clockday').innerHTML = dayNames[today.getDay()] + ' ' + nextAlarm.getHours() + ":" + checkTime(nextAlarm.getMinutes());
    updateScreen = 0;
    radioStatus();
  }
// Check Play Radio button
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      if (this.responseText.includes(" lo ")) { // Play Radio Button pressed
        if (radioPlaying == true) {
          radioStop();
          radioPlaying = false;
        } else {
          radioPlay("play", conf.alarmclock.volume, conf.alarmclock.radio);
          radioPlaying = true;
        }
      }
    }
  };
  xhr.send("cmd=pinctrl&params="+stringToHex("get 5"));

  startTimer = setTimeout(startTime, 1000); // elke seconde
}

function getConf() { // Get configuration
  const xhttp = new XMLHttpRequest();
  xhttp.onload = function(e) {
    if (this.status == 200) {
      if (typeof conf === 'undefined') {
        conf = JSON.parse(this.responseText);
        conf.lastModified = this.getResponseHeader('Last-Modified');
        nextalarm();
        startTime();
      } else if (conf.lastModified !== this.getResponseHeader('Last-Modified')) { // new configuration
//        conf = JSON.parse(this.responseText);
//        conf.lastModified = this.getResponseHeader('Last-Modified');
//        nextalarm();
        location.reload(true);
      }
      setTimeout(getConf, 60000); // Every minute
    }
  }
  xhttp.open("POST", "data/conf.json");
  xhttp.send();
}

function waitForTimeSync() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      if (this.responseText == '["System clock synchronized: yes"]') {
console.log("Time Synced");
        getConf();
      } else {
console.log("Wait for Time Sync");
        setTimeout(waitForTimeSync, 1000); // wait 1 second
      }
    }
  };
  xhr.send("cmd=timedatectl&params="+stringToHex('| grep "System clock synchronized: yes"'));
}
window.onload = waitForTimeSync;
