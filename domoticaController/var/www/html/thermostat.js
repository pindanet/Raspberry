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
//console.log(room.id, room.temp, roomTemp, room.tempCorrection, parseFloat(this.responseText) / 1000 + room.tempCorrection);
    }
  };
  xhr.send('host=' + host + '&command=' + cmd);
}
function getLivingTemp() {
  getTemp("pindadomo", "cat /sys/bus/iio/devices/iio\:device0/in_temp_input", conf.Living);
}
//var testTemp = 17.81;
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
//  var hourMin = splitTime (time);
  dateObject.setHours(hourMin[0], hourMin[1], 0, 0);
//  dateObject.setMinutes(hourMin[1]);
//  dateObject.setSeconds(0);
  return dateObject;
}
//function splitTime (time) { // convert time variable to time and split hours and minutes
//  if (time.indexOf(":") > -1) {
//    return time.split(':');
//  } else {
//    return conf[time].split(':');
//  }
//}
function tempAdjustment(room) {
  if (isNaN(room.temp)) {
    return;
  }
  var today = new Date();
  var now = today.getTime();
  var tempWanted = conf.tempOff;
  for (let i = 0; i < room.thermostat.length; i++) {
    var beginDate = timeDate(room.thermostat[i].begin, new Date());
//    var beginTime = splitTime(room.thermostat[i].begin);
//    var beginDate = new Date();
//    beginDate.setHours(beginTime[0]);
//    beginDate.setMinutes(beginTime[1]);
//    beginDate.setSeconds(0);
    var begin = beginDate.getTime();
//    var endTime = room.thermostat[i].end.split(':');
    var endDate = timeDate(room.thermostat[i].end, new Date());
//    var endTime = splitTime(room.thermostat[i].end);
//    var endDate = new Date();
//    endDate.setHours(endTime[0]);
//    endDate.setMinutes(endTime[1]);
//    endDate.setSeconds(0);
    var end = endDate.getTime();
    if (begin <= now && end > now) {
      tempWanted = conf[room.thermostat[i].temp];
      break;
    }
  }
  for (let i = 0; i < conf.event.length; i++) {
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
      }
    }
    if (begin == dateOnly) {
      var expired = begin - beginDate.getTime();
      var endDate = new Date(conf.event[i].enddate);
      var end = endDate.getTime();
      endDate.setTime(end + expired);
      endDate = timeDate(conf.event[i].end, endDate);
//      var endTime = splitTime(conf.event[i].end);
//      endDate.setHours(endTime[0]);
//      endDate.setMinutes(endTime[1]);
//      endDate.setSeconds(0);
//console.log(endDate.toString());
      end = endDate.getTime();

      beginDate.setTime(begin);
      beginDate = timeDate(conf.event[i].begin, beginDate);
//      var beginTime = splitTime(conf.event[i].begin);
//      beginDate.setHours(beginTime[0]);
//      beginDate.setMinutes(beginTime[1]);
//console.log(beginDate.toString());
      begin = beginDate.getTime();
//console.log("Event on " + beginDate.toString());
//console.log("Until " + endDate.toString());
      if (begin <= now && end > now) {
        tempWanted = conf[conf.event[i].temp[room.id]];
//console.log("Event Temp wanted: " + tempWanted);
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
//console.log("On: " + tempOn, "Off: " + tempOff, "Room.temp: " + room.temp, room.heater[i].name + ": " + room.heater[i].status);
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
  setTimeout(getConf, 60000); // Every minute
}
function getConf() { // Get configuration
  const xhttp = new XMLHttpRequest();
  xhttp.onload = function(e) {
    if (this.status == 200) {
      if (typeof conf === 'undefined') {
        conf = JSON.parse(this.responseText);
        conf.lastModified = this.getResponseHeader('Last-Modified');
console.log("Init " + conf.lastModified);
      } else if (conf.lastModified !== this.getResponseHeader('Last-Modified')) { // new configuration
        conf = JSON.parse(this.responseText);
        conf.lastModified = this.getResponseHeader('Last-Modified');
console.log("Modified " + conf.lastModified);
      }
      thermostat();
    }
  }
  xhttp.open("POST", "data/conf.json");
  xhttp.send();
}
getConf();
