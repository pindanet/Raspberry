function activeHeaters(room) {
  var activeHeaters = -1;
  for (let i = 0; i < room.heater.length; i++) {
    if (room.heater[i].status == "on") {
      activeHeaters++;
    }
  }
  if (activeHeaters > -1) {
    document.getElementById(room.htmlElementId).style.color = room.heater[activeHeaters].color;
  } else {
    document.getElementById(room.htmlElementId).style.color = "";
  }
}
function tasmotaHeater (dev, cmd, room, heater) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const output = JSON.parse(this.responseText);
      if (output[0] == '{"POWER":"OFF"}') {
        room.heater[heater].status = "off";
        activeHeaters(room);
        powerLog(room.heater[heater], room.heater[heater].name);
      } else if (output[0] == '{"POWER":"ON"}') {
        room.heater[heater].status = "on";
        activeHeaters(room);
        powerLog(room.heater[heater], room.heater[heater].name);
      }
    }
  };
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + dev + "/cm?cmnd=" + cmd));
}
function getTemp(host, cmd, room) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "ssh.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      room.temp = parseFloat(this.responseText) / 1000 + room.tempCorrection;
      document.getElementById(room.id + "RoomTemp").innerHTML = room.temp.toFixed(1) + " °C";
      if (room.id == "living") {
        roomTemp = room.temp.toFixed(1) + " °C";
      }
    }
  };
  xhr.send('host=' + host + '&command=' + cmd);
}
function getLivingTemp() {
  getTemp("pindadomo", "cat /sys/bus/iio/devices/iio\:device0/in_temp_input", conf.Living);
}
function getDiningTemp() {
  getTemp("pindadining", "cat /sys/bus/w1/devices/28-*/temperature", conf.Dining);
}
function getKitchenTemp() {
  getTemp("pindakeuken", '/var/www/html/mcp9808.sh', conf.Kitchen);
}
function timeDate (time, dateObject) {
  var hourMin;
  if (time.indexOf(":") > -1) {
    hourMin = time.split(':');
  } else {
    if (conf.hasOwnProperty(time)) {
      hourMin = conf[time].split(':');
    } else {
      dateObject.setTime(window[time].getTime());
      return dateObject;
    }
  }
  dateObject.setHours(hourMin[0], hourMin[1], 0, 0);
  return dateObject;
}
function tempAdjustment(room) {
  if (isNaN(room.temp)) {
    return;
  }
  var today = new Date();
  var now = today.getTime();
  var tempWanted = conf.tempOff;
  for (let i = 0; i < room.thermostat.length; i++) {
    var beginDate = timeDate(room.thermostat[i].begin, new Date());
    var begin = beginDate.getTime();
    var endDate = timeDate(room.thermostat[i].end, new Date());
    var end = endDate.getTime();
    if (begin <= now && end > now) {
      tempWanted = conf[room.thermostat[i].temp];
      break;
    }
  }
  for (let i = 0; i < conf.event.length; i++) {
    delete conf.eventDots;
    var nowDateOnly = new Date(now);
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
        begin = new Date(begin).setHours(0); // Compensate Daylight Saving
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
      if (begin <= now && end > now) {
        tempWanted = conf[conf.event[i].temp[room.id]];
        conf.eventDots = true;
//console.log(conf.event[i].temp[room.id]);
        break;
      }
    }
  }

// Manual temp
  if (room.mode == "Manual") {
    tempWanted = parseFloat(document.getElementById(room.ManualId).innerHTML);
  } else if (room.mode == "Off") {
    tempWanted = conf.tempOff;
  }
// Night temp
  if (tempWanted == conf.tempOff) {
    var nightTime = today.getHours().toString().padStart(2, '0') + ":" + today.getMinutes().toString().padStart(2, '0');
    if (conf.tempNightTime > nightTime) {
      tempWanted = conf.tempNight;
    }
  }
// Heaters On/Off
  for (let i = 0; i < room.heater.length; i++) {
    if (room.heater[i].status != "off" && room.heater[i].status != "on") { // Initialise heater status
      tasmotaHeater (room.heater[i].IP, "Power", room, i);
    } else {
      var tempOn = (tempWanted - conf.hysteresis - conf.hysteresis * (2 * i)).toFixed(2);
      var tempOff = (tempWanted + conf.hysteresis - conf.hysteresis * (2 * i)).toFixed(2);
      if (room.temp > tempOff) { // Heater Off
        if (room.heater[i].status != "off") {
          tasmotaHeater (room.heater[i].IP, "Power%20Off", room, i);
        }
      } else if (room.temp < tempOn) { //Heater On
        if (room.heater[i].status != "on") {
          tasmotaHeater (room.heater[i].IP, "Power%20On", room, i);
        }
      }
    }
  }
}
function sendConf(obj) {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "sendConf.php", true);
    xhr.setRequestHeader("Content-type", "application/json; charset=utf-8");
    xhr.onload = function(e) {
      if (this.status == 200) {
        conf = JSON.parse(this.responseText);
      }
    };
    xhr.send(JSON.stringify(obj, null, 2));
}
function thermostat() {
  tempAdjustment(conf.Living);
  getLivingTemp();
  tempAdjustment(conf.Dining);
  getDiningTemp();
  tempAdjustment(conf.Kitchen);
  getKitchenTemp();
}
