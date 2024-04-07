// Todo
// Radio interval
// cli.php
// Clean Up
// power.html
// config.html

// define a function that converts a string to hex
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

var tempIncrDecr = 0.5;
var ChristmasLightDev = "192.168.129.44";
var TVlampDev = "192.168.129.11";
var HaardlampDev = "192.168.129.18";
var KitchenLightDev = "192.168.129.14"
var PharmacyLightDev = "192.168.129.19"
var LivingVoorDev = "192.168.129.41:2"
var LivingZijDev = "192.168.129.41"

function calcConf() {// Calculated Configuration
  var now = new Date();
  var hourMin = conf.available[0].sleeptime.split(":");
  // one minute later before temporary freezing the light control
  conf.available[0].sleepdate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hourMin[0], parseInt(hourMin[1]) + 1, 0, 0);
  hourMin = conf.available[0].absenttime.split(":");
  conf.available[0].absentdate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hourMin[0], hourMin[1], 0, 0);
  if (conf.available[0].absentdate - now < 0) {
    conf.available[0].absentdate.setDate(conf.available[0].absentdate.getDate()+1);
  }
}
function getThermostatVar(varname) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "data/thermostat", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function () {
    var position = this.responseText.search(varname + "=");
    if (position > -1) {
      var thermostatVar = parseFloat(this.responseText.substring(position + varname.length + 1));
      if (varname == "TVVolume") {
        radioCommand(event, 'setvol', thermostatVar);
      } else if (varname == "RadioVolume") {
        radioCommand(event, 'setvol', thermostatVar);
      }
    }
  };
  xhr.send();
}
function photoframe(event) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "system.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function() {
    if (this.readyState === 4) {
      var img = new Image();
      img.src = this.responseText;
      document.getElementById("photoframe").src = this.responseText;
    }
  };
  xhr.send("command=photoframe");
  event.stopPropagation();
}
function os(event, command) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "system.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("command=" + command);
  event.stopPropagation();
}
// PinPad
function addNumber(event, element){
  document.getElementById('PINbox').value = document.getElementById('PINbox').value+element.value;
  event.stopPropagation();
}
function clearForm(event){
  document.getElementById('PINbox').value = "";
  event.stopPropagation();
}
function submitForm(event) {
  if (document.getElementById('PINbox').value != "") {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "openssl.php", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xhr.onload = function(e) {
      if (this.status == 200) {
        if (! this.responseText.includes("Password hash:")) {
          document.getElementById("hiddenmenu").style.display = "";
          document.getElementById("pinpadmenubutton").style.display = "none";
          location.href = "#menu";
        } else {
          document.getElementById("hiddenmenu").style.display = "none";
          document.getElementById("pinpadmenubutton").style.display = "";
          location.href = "#menu";
        }
        event.stopPropagation();
      }
    };
    xhr.send("IGTzbhSjRf=" + btoa(document.getElementById('PINbox').value));
  } else {
    document.getElementById("hiddenmenu").style.display = "none";
    document.getElementById("pinpadmenubutton").style.display = "";
    location.href = "#menu";
  }
  event.stopPropagation();
}
// End PinPad

function thermostatUI (event, command, id) {
  switch (command) {
    case "Incr":
      var temp = parseFloat(document.getElementById(id).innerHTML);
      temp += tempIncrDecr;
      temp = temp.toFixed(1);
      document.getElementById(id).innerHTML = temp;
      break;
    case "Decr":
      var temp = parseFloat(document.getElementById(id).innerHTML);
      temp -= tempIncrDecr;
      temp = temp.toFixed(1);
      document.getElementById(id).innerHTML = temp;
      break;
    case "Manual":
    case "Auto":
    case "Off":
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "ssh.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function() {
        if (this.readyState === 4) {
          setThermostatUI(event);
        }
      };
      var temp = document.getElementById(id).innerHTML;
      if (command == "Off") {
        temp = "off";
      }
      sshcommand = 'echo ' + temp + ' > /tmp/thermostatManual';
      if (command == "Auto") {
        sshcommand = 'rm /tmp/thermostatManual';
      }
    if (id == "kitchentemp") {
      xhr.send("command=" + sshcommand + "&host=pindakeuken");
      conf.Kitchen.mode = command;
      conf.Kitchen.ManualId = id;
    } else if (id.substr(0, 6) == "dining") {
      xhr.send("command=" + sshcommand + "&host=pindadining");
      conf.Dining.mode = command;
      conf.Dining.ManualId = id;
    } else {
      xhr.send("command=" + sshcommand + "&host=localhost");
      conf.Living.mode = command;
      conf.Living.ManualId = id;
    }
    break;
  }
}
function getThermostatManual (id, host) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "ssh.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function() {
    if (this.readyState === 4) {
      if (this.responseText.length == 0) {
        document.getElementById(id+"Auto").className = "highlight";
        document.getElementById(id+"Manual").className = "";
        if (id != "kitchen") {
          document.getElementById(id+"ManualAux").className = "";
        }
        document.getElementById(id+"Off").className = "";
      } else if (this.responseText == "off\n") {
        document.getElementById(id+"Auto").className = "";
        document.getElementById(id+"Manual").className = "";
        if (id != "kitchen") {
          document.getElementById(id+"ManualAux").className = "";
        }
        document.getElementById(id+"Off").className = "highlight";
      } else {
        document.getElementById(id+"Auto").className = "";
        document.getElementById(id+"Off").className = "";
        if (parseFloat(this.responseText).toFixed(1) == document.getElementById(id+"temp").innerHTML) {
          if (id != "kitchen") {
            document.getElementById(id+"ManualAux").className = "";
          }
          document.getElementById(id+"Manual").className = "highlight";
          document.getElementById(id+"temp").innerHTML = parseFloat(this.responseText).toFixed(1);
        } else {
          document.getElementById(id+"Manual").className = "";
          document.getElementById(id+"ManualAux").className = "highlight";
          document.getElementById(id+"aux").innerHTML = parseFloat(this.responseText).toFixed(1);
        }
      }
    }
  };
  xhr.send('host=' + host + '&command=cat /tmp/thermostatManual');
}

function setThermostatUI (event) {
  getThermostatManual("living", "localhost");
  getThermostatManual("dining", "pindadining");
  getThermostatManual("kitchen", "pindakeuken");

  document.getElementById('livingRoomTemp').innerHTML = conf.Living.temp.toFixed(1) + " °C";
}
function powerLog(dev, name) {
  const d = new Date();
  const logLine = {time: d.getTime(),
    Watt: dev.Watt,
    name: name,
    status: dev.status};
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("cmd=echo&params="+stringToHex("'" + JSON.stringify(logLine) + "' >> data/power.log"));
}
function weather(event) {
  var xhrforecast = new XMLHttpRequest();
  xhrforecast.open('POST', "weather.php", true);
  xhrforecast.onload = function(e) {
    if (this.status == 200) {
      document.getElementById("weather").innerHTML = this.responseText;
    }
  };
  xhrforecast.send();
  event.stopPropagation();
}

var radioStatusInterval;
function radio(event) {
  radioCommand(event, 'getvol', 1);
  radioCommand(event, 'status', 1);
  radioStatusInterval = setInterval(function () { radioCommand(event, 'status', 1); }, 60000); // Elke minuut
}
function radioCommand(event, command, options) {
  if ( command == "volup" ) {
    if ( parseInt(document.getElementById("volumeinfo").innerHTML) == 100 ) { // Maximun Volume
      if (typeof event !== 'undefined') {
        event.stopPropagation();
      }
      return;
    }
  }
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "mpc.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      if (command == "getvol") {
        document.getElementById("volumeinfo").innerHTML = this.responseText;
      } else {
        var element = document.getElementById("radioinfo")
        if (element == null || typeof(element) == 'undefinedd') {
          clearInterval(radioStatusInterval);
        } else {
          document.getElementById("radioinfo").innerHTML = this.responseText;
          if (command == "volup" || command == "voldown") {
            radioCommand(event, 'getvol', 1);
          }
        }
      }
    }
  };
  xhr.send("command=" + command + "&options=" + options);
  if (command == "play") {
    document.getElementById("radioinfo").innerHTML = "Even geduld, de zender wordt opgehaald...";
  } else if (command == "stop") {
    window.scrollTo(0, 0);
    document.getElementById('miniclock').style.display = 'none';
    document.getElementById('minitemp').style.display = 'none';
    getThermostatVar("TVVolume");
  }
  if (typeof event !== 'undefined') {
    event.stopPropagation();
  }
}

var startTimer;
var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");
function checkTime(i) {
  if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
  return i;
}
var app = {radio:false, thermostatUI:false};

function getApp(id) {
  var el = document.getElementById(id);
  var top = el.offsetTop;
  var height = el.offsetHeight;
  if (window.pageYOffset + window.innerHeight > top) {
    if (window.pageYOffset > top + height) {
      if (app[id]) {
        app[id] = false;
        return "off";
      }
    } else {
      if (!app[id]) {
        app[id]=true;
        return "on";
      }
    }
  } else if (app[id]) {
    app[id]=false;
    return "off";
  }
}
waitMinute=0;
function gotoSleep() {
      // Backlight uitschakelen
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "cli.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function(e) {
        if (this.status == 200) { //Sleep commands
          thermostatUI(event, 'Auto', 'livingtemp');
          thermostatUI(event, 'Auto', 'diningtemp');
          thermostatUI(event, 'Auto', 'kitchentemp');
          radioCommand(event, 'stop', 1);
          // network leds out
        }
      };
      xhr.send("cmd=echo&params="+stringToHex("1 > /sys/class/backlight/rpi_backlight/bl_power"));
}
function wakeup() {
  // Backlight inschakelen
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("cmd=echo&params="+stringToHex("0 > /sys/class/backlight/rpi_backlight/bl_power"));
}
function toggleAvailable(event) {
  var elem = document.getElementById("clockyear");
  switch(elem.innerHTML) {
    case conf.available[0].sleep:
      // Get next Sleepdate
      conf.available[0].sleepdate.setDate(conf.available[0].sleepdate.getDate()+1);
      var timeoutTime = Math.max(30000, timeDate(conf.bedTime, new Date()).getTime() - new Date().getTime());
      setTimeout(gotoSleep, timeoutTime);
    case conf.available[0].absent:
      var today = new Date();
      elem.innerHTML = today.getFullYear();
      elem.style.fontSize = "";
      thermostatUI(event, 'Auto', 'livingtemp');
      thermostatUI(event, 'Auto', 'diningtemp');
      thermostatUI(event, 'Auto', 'kitchentemp');
      break;
    default:
      elem.innerHTML = conf.available[0].absent;
      elem.style.fontSize = "64%";
      thermostatUI(event, 'Manual', 'livingaux');
      thermostatUI(event, 'Manual', 'diningaux');
      thermostatUI(event, 'Off', 'kitchentemp');
  }
  event.stopPropagation();
  event.preventDefault();
}
function startTime() {
  clearTimeout(startTimer);
  var today = new Date();
  var h = today.getHours();
  var m = today.getMinutes();
  m = checkTime(m);

  document.getElementById("clockmonthday").innerHTML = today.getDate();
  document.getElementById("clockmonth").innerHTML = monthNames[today.getMonth()];
  if (document.getElementById("clockyear").innerHTML != conf.available[0].absent) {
    if (conf.available[0].sleepdate - today < 0) {
      var elem = document.getElementById("clockyear");
      if (elem.innerHTML != conf.available[0].sleep) {
        elem.innerHTML = conf.available[0].sleep;
        elem.style.fontSize = "70%";
        thermostatUI(event, 'Manual', 'livingtemp');
      }
    } else if (conf.available[0].absentdate - today < 0) {
        conf.available[0].absentdate.setDate(conf.available[0].absentdate.getDate()+1);
        document.getElementById("clockyear").click();
    } else {
      document.getElementById("clockyear").innerHTML = today.getFullYear();
    }
  }
  document.getElementById('clockday').innerHTML = dayNames[today.getDay()] + ' ' + conf.Living.temp.toFixed(1) + " °C";;
  var eventDots = ":" ;
  if (Object.keys(conf).includes("eventDots")) {
    if (today.getSeconds() % 2 == 0) {
      eventDots = '<span style="visibility:hidden">:</span>';
    }
  }
  document.getElementById('clock').innerHTML = h + eventDots + m;
  document.getElementById('miniclock').innerHTML = h + ":" + m;
  document.getElementById('minitemp').innerHTML = conf.Living.temp.toFixed(1) + " °C";;
  var radioApp = getApp("radio");
  if (radioApp == "on") {
    radio(event);
  }
  var thermostatUIApp = getApp("thermostatUI");
  if (thermostatUIApp == "on") {
    setThermostatUI(event);
  }
  if (waitMinute++ > 59) {
    waitMinute = 0;
    if (app["radio"]) {
      radio(event);
    }
    if (app["thermostatUI"]) {
      setThermostatUI(event);
    }
  }
  startTimer = setTimeout(startTime, 1000); // elke seconde
}
function getConf() { // Get configuration
  const xhttp = new XMLHttpRequest();
  xhttp.onload = function(e) {
    if (this.status == 200) {
      if (typeof conf === 'undefined') {
        conf = JSON.parse(this.responseText);
        conf.lastModified = this.getResponseHeader('Last-Modified');
        calcConf();
        nextalarm();
        startTime();
      } else if (conf.lastModified !== this.getResponseHeader('Last-Modified')) { // new configuration
        conf = JSON.parse(this.responseText);
        conf.lastModified = this.getResponseHeader('Last-Modified');
        calcConf();
      }
      thermostat();
      if (document.getElementById("clockyear").innerHTML != conf.available[0].sleep) {
        // process lights only when not waiting for sleep
        lights();
      }
      brightness();
      setTimeout(getConf, 60000); // Every minute
    }
  }
  xhttp.open("POST", "data/conf.json");
  xhttp.send();
}
window.onload = getConf;
// Thermostat
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
// Lights
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

  var sunTimes = SunCalc.getTimes(nextAlarm, conf.location.Latitude, conf.location.Longitude, conf.location.Altitude);
  morningTimerLightsOut = new Date(nextAlarm.getTime() + (conf.lights.lightsOut.Offset * 60000)); // 79 min (1 hour 19 min) after wakeup
  breakfast = new Date(nextAlarm.getTime() + (conf.breakfastOffset * 60000)); // 11 min after nextAlarm
  if (morningTimerLightsOut.getTime() > sunTimes.sunrise.getTime()) { // Sun shines
    morningLightsOut = new Date(morningTimerLightsOut.getTime());
  } else { // Still dark
    morningLightsOut = new Date(sunTimes.sunrise.getTime());
  }

  sunTimes = SunCalc.getTimes(new Date(), conf.location.Latitude, conf.location.Longitude, conf.location.Altitude);
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
// Brightness
var lux;
var luxmax;
var luxmin;
function brightness() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    const output = JSON.parse(this.responseText);
    lux = parseFloat(output[0]);
console.log("Omgevingslicht: " + lux);
    setTimeout(() => {
      var xhr = new XMLHttpRequest(); // write lux
      xhr.open('POST', "cli.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.send("cmd=echo&params="+stringToHex(lux + " > /var/www/html/data/luxtls"));
    }, "1000");
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "cli.php", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xhr.onload = function(e) {
      if (this.status == 200) {
        const output = JSON.parse(this.responseText);
        luxmax = parseFloat(output[0]);
        if (isNaN(luxmax) || (luxmax < lux)) {
          luxmax = lux;
          var xhr = new XMLHttpRequest(); // write luxmax
          xhr.open('POST', "cli.php", true);
          xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
          xhr.send("cmd=echo&params="+stringToHex(luxmax + " > /var/www/html/data/luxmaxtls"));
        }
        luxmin = 0;
console.log("Maximaal gemeten omgevingslicht: " + luxmax);
console.log("Minimaal gemeten omgevingslicht: " + luxmin);
        var rangelux = luxmax - luxmin;
        var rellux = (lux - luxmin) / rangelux;
        var correction = [65535, 65508, 65479, 65451, 65422, 65394, 65365, 65337,
        65308, 65280, 65251, 65223, 65195, 65166, 65138, 65109,
        65081, 65052, 65024, 64995, 64967, 64938, 64909, 64878,
        64847, 64815, 64781, 64747, 64711, 64675, 64637, 64599,
        64559, 64518, 64476, 64433, 64389, 64344, 64297, 64249,
        64200, 64150, 64099, 64046, 63992, 63937, 63880, 63822,
        63763, 63702, 63640, 63577, 63512, 63446, 63379, 63310,
        63239, 63167, 63094, 63019, 62943, 62865, 62785, 62704,
        62621, 62537, 62451, 62364, 62275, 62184, 62092, 61998,
        61902, 61804, 61705, 61604, 61501, 61397, 61290, 61182,
        61072, 60961, 60847, 60732, 60614, 60495, 60374, 60251,
        60126, 59999, 59870, 59739, 59606, 59471, 59334, 59195,
        59053, 58910, 58765, 58618, 58468, 58316, 58163, 58007,
        57848, 57688, 57525, 57361, 57194, 57024, 56853, 56679,
        56503, 56324, 56143, 55960, 55774, 55586, 55396, 55203,
        55008, 54810, 54610, 54408, 54203, 53995, 53785, 53572,
        53357, 53140, 52919, 52696, 52471, 52243, 52012, 51778,
        51542, 51304, 51062, 50818, 50571, 50321, 50069, 49813,
        49555, 49295, 49031, 48764, 48495, 48223, 47948, 47670,
        47389, 47105, 46818, 46529, 46236, 45940, 45641, 45340,
        45035, 44727, 44416, 44102, 43785, 43465, 43142, 42815,
        42486, 42153, 41817, 41478, 41135, 40790, 40441, 40089,
        39733, 39375, 39013, 38647, 38279, 37907, 37531, 37153,
        36770, 36385, 35996, 35603, 35207, 34808, 34405, 33999,
        33589, 33175, 32758, 32338, 31913, 31486, 31054, 30619,
        30181, 29738, 29292, 28843, 28389, 27932, 27471, 27007,
        26539, 26066, 25590, 25111, 24627, 24140, 23649, 23153,
        22654, 22152, 21645, 21134, 20619, 20101, 19578, 19051,
        18521, 17986, 17447, 16905, 16358, 15807, 15252, 14693,
        14129, 13562, 12990, 12415, 11835, 11251, 10662, 10070,
        9473, 8872, 8266, 7657, 7043, 6424, 5802, 5175,
        4543, 3908, 3267, 2623, 1974, 1320, 662, 0];
        var correctionTableIndex = parseInt(255 - (rellux * 255));
        var correctionTableValue = correction[correctionTableIndex];
        var correctionTableBrightness = correctionTableValue / correction[0];
console.log("CorrectionTable Relatief omgevingslicht: " + correctionTableBrightness);
        var backlight = parseInt(conf.minBacklight + correctionTableBrightness * conf.maxBacklight); // 15, 110
        var xhr = new XMLHttpRequest();
        xhr.open('POST', "cli.php", true);
        xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        xhr.onload = function(e) {
          if (this.status == 200) {
            const output = JSON.parse(this.responseText);
            current = output[0];
console.log("Brightness from " + current + " to " + backlight);
            var xhr = new XMLHttpRequest();
            xhr.open('POST', "cli.php", true);
            xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            xhr.send("cmd=echo&params="+stringToHex(backlight + " > /sys/class/backlight/rpi_backlight/brightness"));
          }
        };
        xhr.send("cmd=cat&params="+stringToHex("/sys/class/backlight/rpi_backlight/brightness"));
      }
    };
    xhr.send("cmd=cat&params="+stringToHex("data/luxmaxtls"));
  };
  xhr.send("cmd=python3&params="+stringToHex("/var/www/html/tls2591.py"));
}

