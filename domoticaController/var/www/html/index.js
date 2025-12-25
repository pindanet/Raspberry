// Todo
// Alarm Temperature
// Clean Up
// Clear all buttons in thermostat, before setting
// Done
// Absent-, Sleep temp restore original temp

var tempIncrDecr = 0.5;
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
//function debug(debugText) {
//  var xhr = new XMLHttpRequest();
//  xhr.open('POST', "cli.php", true);
//  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//  xhr.send("cmd=echo&params="+stringToHex("'" + new Date().toString() + ": " + debugText + "' >> data/debug.log"));
//}
//debug("Debug active");

function setTasmotaIP(confArray, tasmotaDev) {
        for (let dev in confArray) {
          if (confArray[dev].Hostname == tasmotaDev[1]) {
            confArray[dev].IP = tasmotaDev[0];
          }
        }
}
function calcConf() { // Calculated Configuration
// Hoe lang duurt dit!!!
const tasmotaScannerTimer = new Date();
  var hostname;
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const output = JSON.parse(this.responseText);
      for (let i in output) {
        var tasmotaDev = output[i].split(" ");
        setTasmotaIP(conf.Dining.heater, tasmotaDev);
        setTasmotaIP(conf.Living.heater, tasmotaDev);
        setTasmotaIP(conf.Kitchen.heater, tasmotaDev);
        setTasmotaIP(conf.switch, tasmotaDev);
      }
console.log("TasmotaScanner in " + ((new Date().getTime() - tasmotaScannerTimer.getTime())/1000) + " seconds");
/*
        setTimeout(() => { // 60 seconds later
          console.log("Delayed for 1 second.");
          lightSwitch('LivingVoor','Toggle');
          lightSwitch('LivingZij','Toggle');
        }, 5000);
*/
    }
  };
  xhr.send("cmd=bash&params="+stringToHex("/var/www/html/tasmotaNetScan.sh"));

  // Set Thermostat UI
  document.getElementById("livingaux").innerHTML = conf.tempAux.toFixed(1);
  document.getElementById("diningaux").innerHTML = conf.tempAux.toFixed(1);
  document.getElementById("livingtemp").innerHTML = conf.tempComfort.toFixed(1);
  document.getElementById("livingtemp").innerHTML = conf.tempComfort.toFixed(1);
  document.getElementById("kitchentemp").innerHTML = conf.tempAux.toFixed(1);
  // Calculated Configuration
  var now = new Date();
  document.getElementById("clockyear").innerHTML = now.getFullYear();
  var hourMin = conf.available[0].sleeptime.split(":");
  // one minute later before temporary freezing the light control
  conf.available[0].sleepdate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hourMin[0], parseInt(hourMin[1]) + 1, 0, 0);
  if (typeof conf.available[0].absenttime !== 'undefined') {
    hourMin = conf.available[0].absenttime.split(":");
    conf.available[0].absentdate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hourMin[0], hourMin[1], 0, 0);
    if (conf.available[0].absentdate - now < 0) {
      conf.available[0].absentdate.setDate(conf.available[0].absentdate.getDate()+1);
    }
  }
  // Set weather URL
  document.getElementById('weather').contentDocument.location.href = "meteogram/meteogram.html?lat=" + conf.location.Latitude + "&lon=" + conf.location.Longitude + "&alt=" + conf.location.Altitude;
}
function saveVariable() {
console.log(variable);
  for (i in conf.rooms) {
    variable[conf.rooms[i]].mode = conf[conf.rooms[i]].mode;
    variable[conf.rooms[i]].tempManual = conf[conf.rooms[i]].tempManual;
  }

  if (typeof conf.thermostatDisabled !== 'undefined') {
    variable.thermostatDisabled = conf.thermostatDisabled;
  }
  variable.clockyear = document.getElementById("clockyear").innerHTML;

console.log(variable);

  var xhr = new XMLHttpRequest();
  xhr.open('POST', "sendVariable.php", true);
  xhr.setRequestHeader("Content-type", "application/json; charset=utf-8");
  xhr.onload = function(e) {
    if (this.status == 200) {
      console.log(this.responseText);
    }
  };
  xhr.send(JSON.stringify(variable, null, 2));
}
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
      var room;
      if (id.indexOf("temp") > -1) {
        room = id.charAt(0).toUpperCase() + id.slice(1).substr(0, id.indexOf("temp") - 1);
      } else {
        room = id.charAt(0).toUpperCase() + id.slice(1).substr(0, id.indexOf("aux") - 1);
      }
      conf[room].mode = command;
      conf[room].tempManual = parseFloat(document.getElementById(id).innerHTML);
      if (command == "Off") {
        conf[room].tempManual = conf.tempOff;
        conf[room].mode = "Manual";
      }
      if (document.getElementById("clockyear").innerHTML == conf.available[0].sleep) { //overrule sleep temp
        conf[room].sleepTemp = conf[room].tempManual;
      }
      setThermostatUI(event);
      variable[room].mode = conf[room].mode;
//      variable[room].sleepTemp = conf[room].sleepTemp;
      variable[room].tempManual = conf[room].tempManual;
      conf[room].tempWanted = conf[room].tempManual;
      saveVariable();
      break;
  }
}
function getThermostatManual (id, host) {
  var room = id.charAt(0).toUpperCase() + id.slice(1);
  document.getElementById(id+"Auto").className = "";
  document.getElementById(id+"Manual").className = "";
  if (id != "kitchen") {
    document.getElementById(id+"ManualAux").className = "";
  }
  document.getElementById(id+"Off").className = "";
  switch(conf[room].mode) {
    case "Auto":
      document.getElementById(id+"Auto").className = "highlight";
      break;
    default: // Manual
      var auxElem =  document.getElementById(id+"aux");
      if (conf[room].tempManual == conf.tempOff) { // Off
        document.getElementById(id+"Off").className = "highlight";
      } else { // Manual
        if (typeof(auxElem) != 'undefined' && auxElem != null) {  // not the kitchen
          if (conf.tempAux.toFixed(1) == conf[room].tempManual.toFixed(1)) { // Aux temp
            document.getElementById(id+"ManualAux").className = "highlight";
          } else {
            document.getElementById(id+"Manual").className = "highlight";
          }
        } else { // kitchen
          document.getElementById(id+"Manual").className = "highlight";
        }
      }
      break;
  }
}
function setThermostatUI (event) {
  getThermostatManual("living", "localhost");
  getThermostatManual("dining", "pindadining");
  getThermostatManual("kitchen", "pindakeuken");

  document.getElementById('livingRoomTemp').innerHTML = conf.Living.temp.toFixed(1) + " °C";
}
function cli(cmd, params) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("cmd=" + cmd + "&params="+stringToHex(params));
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
function radio(event) {
  radioVolume(event, 'getvol');
  radioStatus();
}
function radioStop() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("cmd=touch&params="+stringToHex("/var/www/html/data/radio.stop"));
  toTop();
  radioVolume(event, conf.tvvolume);
}
function radioVolume(event, command) {
  if (typeof event !== 'undefined') {
    event.stopPropagation();
  }
  switch(command) {
    case "getvol":
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "cli.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function(e) {
        if (this.status == 200) {
          const output = JSON.parse(this.responseText);
          document.getElementById("volumeinfo").innerHTML = parseInt(output[0]);
        }
      };
      xhr.send("cmd=amixer&params="+stringToHex("get 'Digital' | awk -F'[][]' '/Left:/ { print $2 }'"));
      break;
    case "volup":
      if ( parseInt(document.getElementById("volumeinfo").innerHTML) == 100 ) { // Maximun Volume
        return;
      }
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "cli.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function(e) {
        if (this.status == 200) {
          const output = JSON.parse(this.responseText);
          document.getElementById("volumeinfo").innerHTML = parseInt(output[0]);
        }
      };
      xhr.send("cmd=amixer&params="+stringToHex("set 'Digital' 5%+ | awk -F'[][]' '/Left:/ { print $2 }'"));
      break;
    case "voldown":
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "cli.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function(e) { 
        if (this.status == 200) {
          const output = JSON.parse(this.responseText);
          document.getElementById("volumeinfo").innerHTML = parseInt(output[0]);
        }
      };
      xhr.send("cmd=amixer&params="+stringToHex("set 'Digital' 5%- | awk -F'[][]' '/Left:/ { print $2 }'"));
      break;
    default:
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "cli.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function(e) { 
        if (this.status == 200) {
          const output = JSON.parse(this.responseText);
          document.getElementById("volumeinfo").innerHTML = parseInt(output[0]);
        }
      };
      xhr.send("cmd=amixer&params="+stringToHex("set 'Digital' " + command + "% | awk -F'[][]' '/Left:/ { print $2 }'"));
  }
}
function radioStatus() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const output = JSON.parse(this.responseText);
      if (output.length > 0) {
        var status = output[0].substring(output[0].indexOf("='") + 2, output[0].indexOf("';"));
        document.getElementById("radioinfo").innerHTML = status;
      }
    }
  };
  xhr.send("cmd=cat&params="+stringToHex("/var/www/html/data/radio.log | grep ICY-META | tail -1"));
}
function playRadio(event, cmd, channel) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("cmd=echo&params="+stringToHex("'" + cmd + ", 12000, " + conf.radio.channel[channel].interval + ", " + conf.radio.channel[channel].URL + "' > /var/www/html/data/radio.cmd"));
  setTimeout(function () { radioStatus(); }, 10000);
}
function radioPlay(event, cmd, channel) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      setTimeout(playRadio, 1000, event, cmd, channel);
    }
  };
  xhr.send("cmd=touch&params="+stringToHex("/var/www/html/data/radio.stop"));
  document.getElementById("radioinfo").innerHTML = "Even geduld, de zenderinformatie wordt opgehaald...";
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
//  xhr.open('POST', "cli.php", true);
  xhr.open('POST', "brightness.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) { //Sleep commands
      thermostatUI(event, 'Auto', 'livingtemp');
      thermostatUI(event, 'Auto', 'diningtemp');
      thermostatUI(event, 'Auto', 'kitchentemp');
      radioStop(event);
      // network leds out
    }
  };
//  xhr.send("cmd=echo&params="+stringToHex("1 > /sys/class/backlight/10-0045/bl_power"));
  xhr.send("power=1");
}
function wakeup() {
  if (window.location.hostname === 'localhost') {
    // Backlight inschakelen
    var xhr = new XMLHttpRequest();
//    xhr.open('POST', "cli.php", true);
    xhr.open('POST', "brightness.php", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//    xhr.send("cmd=echo&params="+stringToHex("0 > /sys/class/backlight/10-0045/bl_power"));
  xhr.send("power=0");
  } else {
    console.log('Remote wakeup()');
  }
}
function activateAbsent(room, tempThermostat, mode, id) {
  conf[room].absentRestoreTemp = conf[room].tempWanted;
  conf[room].absentRestoreMode = conf[room].mode;
  conf[room].absentRestoreTempManual = conf[room].tempManual;
  if (conf[room].tempWanted > tempThermostat || conf[room].absentRestoreMode == "Auto") {
console.log(room + " absent temp: " + conf[room].absentRestoreMode + " ("+ conf[room].absentRestoreTemp + ") to " + tempThermostat);
    thermostatUI(event, mode, id);
  }
}
function deactivateAbsent(room) {
  if (conf[room].absentRestoreMode == "Auto") {
console.log(room + " absent restore: " + conf[room].tempWanted + " to Auto");
    thermostatUI(event, 'Auto', room.toLowerCase() + 'temp');
  } else {
    if (conf[room].absentRestoreTemp == conf.tempOff) {
console.log(room + " absent restore: " + conf[room].tempWanted + " to Off");
      thermostatUI(event, 'Off', room.toLowerCase() + 'temp');
    } else {
console.log(room + " absent restore: " + conf[room].tempWanted + " to " + conf[room].absentRestoreTemp);
      thermostatUI(event, 'Manual', room.toLowerCase() + 'aux');
    }
  }
}
function toggleAvailable(event) {
  var elem = document.getElementById("clockyear");
  if(event.target.id == "clockyear") {
    switch(elem.innerHTML) {
      case conf.available[0].sleep:
        var sleepdate = new Date(conf.available[0].sleepdate);
//console.log(sleepdate);
//var testdate = new Date();
//testdate.setTime(testdate.getTime() + (+1*60*60*1000));
//console.log(testdate);
        // Set next Sleepdate
        conf.available[0].sleepdate.setDate(conf.available[0].sleepdate.getDate()+1);
        var timeoutTime = Math.max(30000, timeDate(conf.bedTime, new Date(sleepdate)).getTime() - new Date().getTime() + 30000);
//        var timeoutTime = Math.max(30000, sleepdate.getTime() - new Date().getTime() + 30000);
//console.log(new Date(new Date().getTime() + timeoutTime));
        setTimeout(gotoSleep, timeoutTime);
/*
        setTimeout(() => { // 60 seconds later
          lightSwitch('LivingVoor','Toggle');
          lightSwitch('LivingZij','Toggle');
        }, timeoutTime + 60000);
*/
        var today = new Date();
        elem.innerHTML = today.getFullYear();
        elem.style.fontSize = "";
        deactivateSleep("Living");
        deactivateSleep("Dining");
        deactivateSleep("Kitchen");
        break;
      case conf.available[0].absent:
        var today = new Date();
        elem.innerHTML = today.getFullYear();
        elem.style.fontSize = "";
        deactivateAbsent("Living");
        deactivateAbsent("Dining");
        deactivateAbsent("Kitchen");
//        thermostatUI(event, 'Auto', 'livingtemp');
//        thermostatUI(event, 'Auto', 'diningtemp');
//        thermostatUI(event, 'Auto', 'kitchentemp');
        break;
      default:
        elem.innerHTML = conf.available[0].absent;
        elem.style.fontSize = "64%";
        activateAbsent("Living", conf.tempAux, "Manual", "livingaux");
        activateAbsent("Dining", conf.tempAux, "Manual", "diningaux");
        activateAbsent("Kitchen", conf.tempOff, "Off", "kitchentemp");
    }
  }
  event.stopPropagation();
  event.preventDefault();
  const message = {};
  message.function = "available";
  message.value = elem.innerHTML;
  sendToRoom("pindakeuken", JSON.stringify(message));
//  sendMessage(JSON.stringify(message));
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
//    if (conf.available[0].sleepdate - today < 0) {
//      var elem = document.getElementById("clockyear");
//      if (elem.innerHTML != conf.available[0].sleep) {
//        elem.innerHTML = conf.available[0].sleep;
//        elem.style.fontSize = "70%";
//// see activateAbsent
//console.log(conf.Living.tempWanted, conf.Dining.tempWanted, conf.Kitchen.tempWanted);
//console.log(conf.Living.sleepTemp, conf.Dining.sleepTemp, conf.Kitchen.sleepTemp);
////        thermostatUI(event, 'Manual', 'livingtemp');
//      }
//    } else if (typeof conf.available[0].absentdate !== 'undefined') {
    if (typeof conf.available[0].absentdate !== 'undefined') {
      if (conf.available[0].absentdate - today < 0) {
          conf.available[0].absentdate.setDate(conf.available[0].absentdate.getDate()+1);
          document.getElementById("clockyear").click();
      }
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
function connectWebsocket() {
  var http = new XMLHttpRequest()
  http.open('HEAD', "data/websocket.log", true)
  http.onload = function(e) {
    if (this.status == 200) {
// console.log("websocket.log exist!");
      connect(); // Activate Webconnect
    } else {
// console.log("websocket.log does not exist!");
      setTimeout(connectWebsocket, 1000);
    }
  }
  http.send()
}
function startWebsocket() {
  if (window.location.hostname === 'localhost') {
    // Close Websocket server
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "cli.php", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xhr.onload = function(e) {
      if (this.status == 200 && this.readyState === 4) {
        // Kill Websocket server
        var xhr = new XMLHttpRequest();
        xhr.open('POST', "cli.php", true);
        xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        xhr.onload = function(e) {
          if (this.status == 200 && this.readyState === 4) {
            // Start Websocket server
            var xhr = new XMLHttpRequest();
            xhr.open('POST', "cli.php", true);
            xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            xhr.send("cmd=bash&params="+stringToHex("/var/www/html/websocket.sh"));
          }
        };
        xhr.send("cmd=kill&params="+stringToHex("$(ps -ax | grep websocket | grep -v grep | awk '{print $1}')"));
        setTimeout(connectWebsocket, 1000);
      }
    };
    xhr.send("cmd=touch&params="+stringToHex("/var/www/html/data/websocket.stop"));
  } else {
    connect(); // Connect to Websocket server
  }
}
let domain;
function getVariable() { // Get Variables
  if (window.location.hostname === 'localhost') { // Hide cursor on touchscreen
    document.body.style.cursor = "none";
  }
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      domain = JSON.parse(this.responseText)[0];
console.log("getVariable: startWebsocket");
      startWebsocket();
    }
  };
  xhr.send("cmd=cat&params="+stringToHex("/etc/resolv.conf | grep search | awk '{print $2}'"));

  const xhttp = new XMLHttpRequest();
  xhttp.onload = function(e) {
    if (this.status == 200) {
      variable = JSON.parse(this.responseText);
console.log("getVariable: getConf");
      getConf();
    }
  }
  xhttp.open("POST", "data/variable.json");
  xhttp.send();
console.log("getVariable");
}
function variableToConf(obj, dest) {
  for (let key in obj) {
    if (typeof obj[key] === 'object') {
      if (Array.isArray(obj[key])) {
        // loop through array
        for (let i = 0; i < obj[key].length; i++) {
          variableToConf(obj[key][i], dest[key]);
        }
      } else {
        // call function recursively for object
        variableToConf(obj[key], dest[key]);
      }
    } else {
      // do something with value
      dest[key] = obj[key];
    }
  }
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
//        conf = JSON.parse(this.responseText);
//        conf.lastModified = this.getResponseHeader('Last-Modified');
//        calcConf();
        location.reload(true);
      }
      variableToConf(variable, conf);
      if (conf.hasOwnProperty('thermostatDisabled')) {
        document.getElementById("clockday").style.color = "deepskyblue";
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
window.onload = getVariable;
// Thermostat
function activeHeaters(room) {
  var activeHeaters = -1;
  for (let i = 0; i < room.heater.length; i++) {
    if (room.heater[i].status == "on") {
      activeHeaters++;
    }
  }
  const message = {};
  message.function = "activeHeaters";
  message.id = room.htmlElementId;
  if (activeHeaters > -1) {
    document.getElementById(room.htmlElementId).style.color = room.heater[activeHeaters].color;
    message.color = room.heater[activeHeaters].color;
    sendToRoom("pindakeuken", JSON.stringify(message));
//    sendMessage(JSON.stringify(message));
  } else {
    document.getElementById(room.htmlElementId).style.color = "";
    message.color = "";
    sendToRoom("pindakeuken", JSON.stringify(message));
//    sendMessage(JSON.stringify(message));
  }
}
function tasmotaHeater (dev, cmd, room, heater) {
  if (! Object.keys(room.heater[heater]).includes("manual")) {
    if (window.location.hostname === 'localhost') {
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
    } else {
      console.log('Remote tasmotaHeater()');
    }
  }
}
//function getTemp(host, cmd, room) {
//  var xhr = new XMLHttpRequest();
//  xhr.open('POST', "cli.php", true);
//  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//  xhr.onload = function(e) {
//    if (this.status == 200 && this.readyState === 4) {
//      const output = JSON.parse(this.responseText);
//      room.temp = parseFloat(output[0]) / 1000 + room.tempCorrection;
//      document.getElementById(room.id + "RoomTemp").innerHTML = room.temp.toFixed(1) + " °C";
//      if (room.id == "living") {
//        roomTemp = room.temp.toFixed(1) + " °C";
//      }
//    }
//  };
//  xhr.send("cmd=ssh&params="+stringToHex("-v -i data/id_rsa -o StrictHostKeyChecking=no -o 'UserKnownHostsFile /dev/null' $(ls /home)@" +  host +" '" + cmd + "'"));
//}
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
console.log("Event: " + beginDate.toString() + " tot " + endDate.toString());
      if (begin <= now && end > now) {
        tempWanted = conf[conf.event[i].temp[room.id]];
        conf.eventDots = true;
        break;
      }
    }
  }

// Manual temp
  if (room.mode == "Manual") {
    tempWanted = room.tempManual;
  } else if (room.mode == "Off") {
    tempWanted = conf.tempOff;
  }
// Thermostat disabled
  if (conf.hasOwnProperty('thermostatDisabled')) {
    tempWanted = 10;
  }
// Night temp
  if (tempWanted == conf.tempOff) {
    var nightTime = today.getHours().toString().padStart(2, '0') + ":" + today.getMinutes().toString().padStart(2, '0');
    if (conf.tempNightTime > nightTime) {
      tempWanted = conf.tempNight;
    }
  }
  if (document.getElementById("clockyear").innerHTML == conf.available[0].sleep) { // Sleeptime: keep temp
    if (typeof room.sleepTemp !== 'undefined') {
      tempWanted = room.sleepTemp;
    } else {
      room.sleepTemp = tempWanted;
    }
  } else { // Store Sleeptime temp
    room.sleepTemp = tempWanted;
  }
  room.tempWanted = tempWanted;
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
function fireAlarm(room) {
//      if (room.tempPrev != 20 && room.temp != 20 && room.temp > 5) { // Fire alarm
        if (room.tempPrev < room.temp) {
          if (typeof room.tempDiv !== 'undefined') {
            if (room.temp - room.tempPrev > room.tempDiv * 3) {
              var xhr = new XMLHttpRequest();
              xhr.open('POST', "cli.php", true);
              xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
              var firealarm = "Fire alarm in " + room.id  + " on " + new Date().toString() + "at " + room.temp + " °C and rising with " + (room.temp - room.tempPrev) + " °C (Allowed rising: " + (room.tempDiv * 2) + " °C)";
console.log(firealarm);
              xhr.send("cmd=echo&params="+stringToHex("\"" + firealarm + "\" >> data/firealarm.log"));
            } else {
              if (room.temp - room.tempPrev > room.tempDiv) {
                room.tempDiv = room.temp - room.tempPrev;
              }
            }
          } else {
            room.tempDiv = room.temp - room.tempPrev;
          }
        }
//      } else {
//console.log("Initialise Temp");
//      }
}

function wgetTemp(host, room) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      const output = JSON.parse(this.responseText);
      if (!isNaN(output[0])) {
        room.tempPrev = room.temp;
        room.temp = parseFloat(output[0]) / 1000 + room.tempCorrection;
        fireAlarm(room);
        document.getElementById(room.htmlElementId).style.opacity="";
      } else { // Fetching temp error
        document.getElementById(room.htmlElementId).style.opacity=".5";
      }
      document.getElementById(room.id + "RoomTemp").innerHTML = room.temp.toFixed(1) + " °C";
    }
  };
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + host + "/data/temp"));
}
function toggleThermostat(event) {
  if (document.getElementById("clockday").style.color != "deepskyblue") {
    document.getElementById("clockday").style.color="deepskyblue";
    variable.thermostatDisabled = true;
    conf.thermostatDisabled = true;
  } else {
    document.getElementById("clockday").style.color="";
    delete variable.thermostatDisabled;
    delete conf.thermostatDisabled;
  }
  saveVariable();

  const message = {};
  message.function = "thermostatClockday";
  message.value = document.getElementById("clockday").style.color;
  sendToRoom("pindakeuken", JSON.stringify(message));
//  sendMessage(JSON.stringify(message));

  event.stopPropagation();
  event.preventDefault();
}
function activateSleep(room) {
//function activateSleep(room, tempThermostat, mode, id) {
  conf[room].sleepRestoreTemp = conf[room].tempWanted;
  conf[room].sleepRestoreMode = conf[room].mode;
  conf[room].sleepRestoreTempManual = conf[room].tempManual;
console.log(room, conf[room].sleepRestoreTemp, conf[room].sleepRestoreMode, conf[room].sleepRestoreTempManual);
//  if (conf[room].tempWanted > tempThermostat || conf[room].absentRestoreMode == "Auto") {
//console.log(room + " absent temp: " + conf[room].absentRestoreMode + " ("+ conf[room].absentRestoreTemp + ") to " + tempThermostat);
//    thermostatUI(event, mode, id);
//  }
}
function deactivateSleep(room) {
  if (conf[room].sleepRestoreMode == "Auto") {
console.log(room + " sleep restore: " + conf[room].tempWanted + " to Auto");
    thermostatUI(event, 'Auto', room.toLowerCase() + 'temp');
  } else {
    if (conf[room].sleepRestoreTemp == conf.tempOff) {
console.log(room + " sleep restore: " + conf[room].tempWanted + " to Off");
      thermostatUI(event, 'Off', room.toLowerCase() + 'temp');
    } else {
console.log(room + " sleep restore: " + conf[room].tempWanted + " to " + conf[room].sleepRestoreTemp);
      thermostatUI(event, 'Manual', room.toLowerCase() + 'aux');
    }
  }
}
function thermostat() {
  tempAdjustment(conf.Living);
  wgetTemp("pindadomo", conf.Living);
//  var xhr = new XMLHttpRequest();
//  xhr.open('POST', "cli.php", true);
//  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//  xhr.onload = function(e) {
//    if (this.status == 200 && this.readyState === 4) {
//      const output = JSON.parse(this.responseText);
//      if (isNaN(output[0])) {
//        console.log(output[0]);
//      } else {
//        conf.Living.temp = parseFloat(output[0]) / 1000 + conf.Living.tempCorrection;
//        fireAlarm(conf.Living);
//      }
//    }
//  };
//  xhr.send("cmd=bash&params="+stringToHex("/var/www/html/ds18b20.sh"));

  tempAdjustment(conf.Dining);
  wgetTemp("pindadining", conf.Dining);
//  tempAdjustment(conf.Kitchen);
  wgetTemp("pindakeuken", conf.Kitchen);
  if (!conf.hasOwnProperty('thermostatDisabled')) {
    if ((conf.Living.temp > conf.tempComfort) && (conf.Dining.temp > conf.tempComfort) && (conf.Kitchen.temp > conf.tempComfort) && (document.getElementById("clockday").style.color !== "lime")) {
      document.getElementById("clockday").style.color="lime";

      const message = {};
      message.function = "thermostatClockday";
      message.value = document.getElementById("clockday").style.color;
      sendToRoom("pindakeuken", JSON.stringify(message));
//      sendMessage(JSON.stringify(message));
//    } else if (document.getElementById("clockday").style.color == "lime") {
    } else if (((conf.Living.temp < conf.tempComfort) || (conf.Dining.temp < conf.tempComfort) || (conf.Kitchen.temp < conf.tempComfort)) && (document.getElementById("clockday").style.color == "lime")) {

      document.getElementById("clockday").style.color="";

      const message = {};
      message.function = "thermostatClockday";
      message.value = document.getElementById("clockday").style.color;
      sendToRoom("pindakeuken", JSON.stringify(message));
//      sendMessage(JSON.stringify(message));
    }
  }
  if (document.getElementById("clockyear").innerHTML != conf.available[0].absent) {
    if (conf.available[0].sleepdate - new Date() < 0) {
      var elem = document.getElementById("clockyear");
      if (elem.innerHTML != conf.available[0].sleep) {
        elem.innerHTML = conf.available[0].sleep;
        elem.style.fontSize = "70%";
        activateSleep("Living");
        activateSleep("Dining");
        activateSleep("Kitchen");

        const message = {};
        message.function = "available";
        message.value = elem.innerHTML;
        sendToRoom("pindakeuken", JSON.stringify(message));
//        sendMessage(JSON.stringify(message));
      }
    }
  }
}
// Lights
var sunTimes;
var nextAlarm;
var breakfast;
var morningLightsOut;
var eveningLightsOn;
//var bedTime;
function lightSwitch(name, cmd) {
  if (window.location.hostname === 'localhost') {
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
  } else {
    console.log('Remote lichtSwitch()');
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
    if (typeof conf.lights.timer[i].disabled !== 'undefined') {
      if(conf.lights.timer[i].disabled) {
        continue;
      }
    }

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
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "cli.php", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xhr.onload = function(e) {
      const output = JSON.parse(this.responseText);
      luxmax = parseFloat(output[0]);
      var rellux = lux / luxmax;
//      var correction = [65535, 65508, 65479, 65451, 65422, 65394, 65365, 65337,
//      65308, 65280, 65251, 65223, 65195, 65166, 65138, 65109,
//      65081, 65052, 65024, 64995, 64967, 64938, 64909, 64878,
//      64847, 64815, 64781, 64747, 64711, 64675, 64637, 64599,
//      64559, 64518, 64476, 64433, 64389, 64344, 64297, 64249,
//      64200, 64150, 64099, 64046, 63992, 63937, 63880, 63822,
//      63763, 63702, 63640, 63577, 63512, 63446, 63379, 63310,
//      63239, 63167, 63094, 63019, 62943, 62865, 62785, 62704,
//      62621, 62537, 62451, 62364, 62275, 62184, 62092, 61998,
//      61902, 61804, 61705, 61604, 61501, 61397, 61290, 61182,
//      61072, 60961, 60847, 60732, 60614, 60495, 60374, 60251,
//      60126, 59999, 59870, 59739, 59606, 59471, 59334, 59195,
//      59053, 58910, 58765, 58618, 58468, 58316, 58163, 58007,
//      57848, 57688, 57525, 57361, 57194, 57024, 56853, 56679,
//      56503, 56324, 56143, 55960, 55774, 55586, 55396, 55203,
//      55008, 54810, 54610, 54408, 54203, 53995, 53785, 53572,
//      53357, 53140, 52919, 52696, 52471, 52243, 52012, 51778,
//      51542, 51304, 51062, 50818, 50571, 50321, 50069, 49813,
//      49555, 49295, 49031, 48764, 48495, 48223, 47948, 47670,
//      47389, 47105, 46818, 46529, 46236, 45940, 45641, 45340,
//      45035, 44727, 44416, 44102, 43785, 43465, 43142, 42815,
//      42486, 42153, 41817, 41478, 41135, 40790, 40441, 40089,
//      39733, 39375, 39013, 38647, 38279, 37907, 37531, 37153,
//      36770, 36385, 35996, 35603, 35207, 34808, 34405, 33999,
//      33589, 33175, 32758, 32338, 31913, 31486, 31054, 30619,
//      30181, 29738, 29292, 28843, 28389, 27932, 27471, 27007,
//      26539, 26066, 25590, 25111, 24627, 24140, 23649, 23153,
//      22654, 22152, 21645, 21134, 20619, 20101, 19578, 19051,
//      18521, 17986, 17447, 16905, 16358, 15807, 15252, 14693,
//      14129, 13562, 12990, 12415, 11835, 11251, 10662, 10070,
//      9473, 8872, 8266, 7657, 7043, 6424, 5802, 5175,
//      4543, 3908, 3267, 2623, 1974, 1320, 662, 0];
//      var correctionTableIndex = parseInt(255 - (rellux * 255));
//      var correctionTableValue = correction[correctionTableIndex];
//      var correctionTableBrightness = correctionTableValue / correction[0];
//      var backlight = parseInt(conf.minBacklight + correctionTableBrightness * conf.maxBacklight); // 15, 110
      var backlight = parseInt(conf.minBacklight + rellux * conf.maxBacklight); // 15, 110
//console.log(backlight, backlightold);
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "brightness.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.send("brightness=" + backlight);
    };
    xhr.send("cmd=cat&params="+stringToHex("data/luxmax"));
  };
  xhr.send("cmd=cat&params="+stringToHex("data/lux"));
}

function toTop() {
  window.scrollTo(0, 0);
  document.getElementById('miniclock').style.display = 'none';
  document.getElementById('minitemp').style.display = 'none';
}

let socket;
function connect() {
  socket = new WebSocket("ws://pindadomo." + domain + ":8080");
//  socket = new WebSocket("ws://192.168.129.2:8080");
  socket.onopen = function(event) {
    console.log("Connected to server");
    if (window.location.hostname !== 'localhost') {
      const message = {};
      message.function = "heaterColors";
      sendToRoom("pindakeuken", JSON.stringify(message));
//      sendMessage(JSON.stringify(message));
    }
  };
  socket.onmessage = function(event) {
    console.log("Message received: " + event.data);
    if (event.data[0] == "["  || event.data[0] == "{") {
      var message = JSON.parse(event.data);
      switch (message.function) {
        case "activeHeaters":
          document.getElementById(message.id).style.color = message.color;
          break;
        case "heaterColors":
          const answer = {};
          answer.function = "activeHeaters";
          for (i in conf.rooms) {
            answer.id = conf[conf.rooms[i]].htmlElementId;
            answer.color = document.getElementById(answer.id).style.color;
            sendToRoom("pindakeuken", JSON.stringify(message));
//            sendMessage(JSON.stringify(answer));
          }
          break;
      }
    } else {
       document.getElementById(event.data).click();
    }
  };
  socket.onclose = function(event) {
    console.log("WebSocket connection has been closed successfully.");
    startWebsocket();
  };
  socket.onerror = function(event) {
    console.log("WebSocket error: ", event);
  };
}

function sendToRoom(room, message) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + room + "/wssend.php?message=" + encodeURI(message)));
}

/*
function sendMessage(message) {
  if (typeof socket !== 'undefined') {
    if (socket.readyState) {
      socket.send(message);
//      console.log("Message sent: " + message);
    }
  } else {
console.log("Websocket not ready yet!");
  }
}
*/
function remote(event) {
  switch(event.target.id) {
    case "clock":
      wakeup();
      document.getElementById('miniclock').style.display = '';
      document.getElementById('minitemp').style.display = '';
      location.href = "#menu";
      break;
    case "miniclock":
      window.scrollTo(0,0);
      event.target.style.display = 'none';
      document.getElementById('minitemp').style.display = 'none';
      break;
    case "clockday":
      toggleThermostat(event);
      break;
    case "clockyear":
      toggleAvailable(event);
      break;
    case "menuradio":
      radioVolume(event,conf.radio.volume);
      location.href = "#radio";
      break;
    case "menuweather":
      document.getElementById('weather').contentDocument.location.reload(true);
      location.href = "#weather";
      break;
    case "menuthermostatUI":
      location.href = "#thermostatUI";
      break;
    case "menuheaters":
      location.href = "#heaters";
      break;
    case "menulights":
      location.href = "#lights";
      break;
    case "radioStop":
      if (window.location.hostname !== 'localhost') {
        toTop();
      } else {
        radioStop(event);
      }
      break;
    case "radioVolumeDown":
      if (window.location.hostname !== 'localhost') {
        setTimeout(function () { radioVolume(event, "getvol"); }, 1000);
      } else {
        radioVolume(event, "voldown");
      }
      break;
    case "radioVolumeUp":
      if (window.location.hostname !== 'localhost') {
        setTimeout(function () { radioVolume(event, "getvol"); }, 1000);
      } else {
        radioVolume(event, "volup");
      }
      break;
    case "Haardlamp":
    case "TVlamp":
    case "Keukenlamp":
    case "Apotheek":
    case "Kerst":
    case "LivingVoor":
    case "LivingZij":
      lightSwitch(event.target.id,'Toggle');
      break;
    case "Schilderij":
    case "Computertafel":
    case "Canyon":
    case "Zonsondergang":
    case "Eettafel":
    case "Tropen":
    case "Eekhoorn":
      var heaterIP;
      for (let room in conf.rooms) {
        looproom:
        for (let heater in conf[conf.rooms[room]].heater) {
          if (conf[conf.rooms[room]].heater[heater].name == event.target.id) {
            if (window.location.hostname === 'localhost') {
              var tasmotaHeater = conf[conf.rooms[room]].heater[heater];
              var xhr = new XMLHttpRequest();
              xhr.open('POST', "cli.php", true);
              xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
              xhr.onload = function(e) {
                if (this.status == 200) {
                  if (this.responseText != "[]") { // no response
                    const output = JSON.parse(this.responseText);
                    if (output[0].includes(':"OFF"}')) {
                      tasmotaHeater.status = "off";
                    } else if (output[0].includes(':"ON"}')) {
                      tasmotaHeater.status = "on";
                    }
                    powerLog(tasmotaHeater, tasmotaHeater.name);
                    if (Object.keys(tasmotaHeater).includes("manual")) {
                      delete tasmotaHeater.manual;
                    } else {
                      tasmotaHeater.manual = tasmotaHeater.status;
                    }
                    activeHeaters(conf[conf.rooms[room]]);
                  }
                }
              };
              xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + tasmotaHeater.IP + "/cm?cmnd=Power%20Toggle"));
            }
            break looproom;
          }
        }
      }
      break;
    default:
      console.log(event.target.id);
  }
  if (window.location.hostname !== 'localhost') {
    sendToRoom("localhost", event.target.id);
//    sendMessage(event.target.id);
  }
}
