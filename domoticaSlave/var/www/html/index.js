// ToDo
// Brandalarm

// Variables
var room = "Kitchen";
var pir1 = 14;
var pir2 = 24

var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");

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
//  var today = new Date("November 15, 2024 03:30:00");
  var today = new Date();
  setAlarmTime(getEventAlarm(today, today), today); // Get today's alarmtime
  if (today > nextAlarm) { // Alarmtime has expired
    var nextDate = new Date();
    nextDate.setDate(nextAlarm.getDate() + 1);
    nextDate.setHours(0,0,0,0);
    setAlarmTime(getEventAlarm(nextDate, today), nextDate); // Get tomorrow's alarmtime
  }
// Waarschijnlijk niet gebruikt
// var alarmtime = timeDate (conf.alarmtime, new Date());
console.log("nextAlarm = " + nextAlarm);

  var sunTimes = SunCalc.getTimes(nextAlarm, conf.location.Latitude, conf.location.Longitude, conf.location.Altitude);
  morningTimerLightsOut = new Date(nextAlarm.getTime() + (conf.lights.lightsOut.Offset * 60000)); // 79 min (1 hour 19 min) after wakeup
  breakfast = new Date(nextAlarm.getTime() + (conf.breakfastOffset * 60000)); // 11 min after nextAlarm
  if (morningTimerLightsOut.getTime() > sunTimes.sunrise.getTime()) { // Sun shines
    morningLightsOut = new Date(morningTimerLightsOut.getTime()).getTime();
  } else { // Still dark
    morningLightsOut = new Date(sunTimes.sunrise.getTime()).getTime();
  }

  sunTimes = SunCalc.getTimes(new Date(), conf.location.Latitude, conf.location.Longitude, conf.location.Altitude);
//  sunTimes = SunCalc.getTimes(new Date("November 15, 2024 03:30:00"), conf.location.Latitude, conf.location.Longitude, conf.location.Altitude);
  var eveningShutterDown = timeDate(conf.lights.eveningShutterDown, eveningShutterDown = new Date());
//  var eveningShutterDown = timeDate(conf.lights.eveningShutterDown, eveningShutterDown = new Date("November 15, 2024 03:30:00"));
  if (eveningShutterDown.getTime() > sunTimes.sunset.getTime()) { // Already dark
    eveningLightsOn = new Date(sunTimes.sunset.getTime()).getTime();
  } else { // Still daylight
    eveningLightsOn = new Date(eveningShutterDown.getTime()).getTime();
  }
  if (eveningLightsOn < morningLightsOut) { // next day
    morningLightsOut -= 86400000;
  }
console.log("eveningLightsOn = " + new Date(eveningLightsOn));
console.log("morningLightsOut = " + new Date(morningLightsOut));
}
function calcConf() {
//  lightOffTime = new Date(new Date().getTime() + conf.lights.lightTimer*1000).getTime();
//console.log("lichtOffTime = " + new Date(lightOffTime));
  nextalarm();
}
function getConf() { // Get configuration
  const xhttp = new XMLHttpRequest();
  xhttp.onload = function(e) {
    if (this.status == 200) {
      if (typeof conf === 'undefined') {
        conf = JSON.parse(this.responseText);
        conf.lastModified = this.getResponseHeader('Last-Modified');
        calcConf();
        startTime();
        if (typeof motionTimer != 'undefined') {
          clearInterval(motionTimer);
        }
        lightOff();
        motionTimer = setInterval(startMotion, 250) // check motion sensor every 0.25s
        setInterval(wgetTemp, 60000, "pindakeuken.local", conf.Kitchen);
//        startTemp();
        setBrightness(0);
        connect(); // Connect to Websocket server
      } else if (conf.lastModified !== this.getResponseHeader('Last-Modified')) { // new configuration
//        conf = JSON.parse(this.responseText);
//        conf.lastModified = this.getResponseHeader('Last-Modified');
//        calcConf();
        location.reload(true);
      }
      setTimeout(getConf, 60000); // Every minute
    }
  }
  xhttp.open("POST", "data/conf.json");
  xhttp.send();
}
window.onload = getConf;

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

var yrCodes = {
	"s01": "clear sky",
	"s02": "fair",
	"s03": "partly cloudy",
	"s04": "cloudy",
	"s40": "light rain showers",
	"s05": "rain showers",
	"s41": "heavy rain showers",
	"s24": "light rain showers and thunder",
	"s06": "rain showers and thunder",
	"s25": "heavy rain showers and thunder",
	"s42": "light sleet showers",
	"s07": "sleet showers",
	"s43": "heavy sleet showers",
	"s26": "light sleet showers and thunder",
	"s20": "sleet showers and thunder",
	"s27": "heavy sleet showers and thunder",
	"s44": "light snow showers",
	"s08": "snow showers",
	"s45": "heavy snow showers",
	"s28": "light snow showers and thunder",
	"s21": "snow showers and thunder",
	"s29": "heavy snow showers and thunder",
	"s46": "light rain",
	"s09": "rain",
	"s10": "heavy rain",
	"s30": "light rain and thunder",
	"s22": "rain and thunder",
	"s11": "heavy rain and thunder",
	"s47": "light sleet",
	"s12": "sleet",
	"s48": "heavy sleet",
	"s31": "light sleet and thunder",
	"s23": "sleet and thunder",
	"s32": "heavy sleet and thunder",
	"s49": "light snow",
	"s13": "snow",
	"s50": "heavy snow",
	"s33": "light snow and thunder",
	"s14": "snow and thunder",
	"s34": "heavy snow and thunder",
	"s15": "fog"
}
function weather(event) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "weather.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      var d = new Date();
      var UTCHour = d.getUTCHours() + ":00";
      const weatherObj = JSON.parse(this.responseText);
      for (let x in weatherObj.properties.timeseries) {
	if (weatherObj.properties.timeseries[x].time.includes(UTCHour)) {
        for (let col = 1; col < 5; col++) {
          var ts = parseInt(x) + col - 1;
          var UTCTime = d;
          UTCTime.setUTCHours(weatherObj.properties.timeseries[ts].time.substr(11,2));
          document.getElementById("weatherTime" + col).innerHTML = UTCTime.getHours() + ":00"; 
          document.getElementById("weatherTemp" + col).innerHTML = weatherObj.properties.timeseries[ts].data.instant.details.air_temperature; 
          document.getElementById("weatherHumi" + col).innerHTML = weatherObj.properties.timeseries[ts].data.instant.details.relative_humidity; 
          document.getElementById("weatherWind" + col).innerHTML = '<span style="transform: rotate(' + weatherObj.properties.timeseries[ts].data.instant.details.wind_from_direction + 'deg);display: inline-block;">&darr;</span> ';
          document.getElementById("weatherWind" + col).innerHTML += Math.round(weatherObj.properties.timeseries[ts].data.instant.details.wind_speed * 3.6); 
          document.getElementById("weatherPrec" + col).innerHTML = weatherObj.properties.timeseries[ts].data.next_1_hours.details.precipitation_amount; 
          document.getElementById("weatherPres" + col).innerHTML = Math.round(weatherObj.properties.timeseries[ts].data.instant.details.air_pressure_at_sea_level);
          var yrSymbol;
          for (let y in yrCodes) {
            if (weatherObj.properties.timeseries[ts].data.next_1_hours.summary.symbol_code.includes(yrCodes[y].replace(/\s/g, ''))) {
              yrSymbol = y;
              if (weatherObj.properties.timeseries[ts].data.next_1_hours.summary.symbol_code.includes("_day")) {
                yrSymbol += "d";
              } else if (weatherObj.properties.timeseries[ts].data.next_1_hours.summary.symbol_code.includes("_night")) {
                yrSymbol += "n";
              }
              break;
            }
          }
          document.getElementById("weatherImg" + col).src = "weathericons/" + yrSymbol.substring(1) + ".svg";
        }
          break;
        }
      }
    }
  };
  xhr.send("lat=" + conf.location.Latitude + "&lon=" + conf.location.Longitude + "&alt=" + conf.location.Altitude);
  if (typeof event !== 'undefined') {
    event.stopPropagation();
  }
}

function checkTime(i) {
  if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
  return i;
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
//        fireAlarm(room);
      }
      document.getElementById(room.id + "RoomTemp").innerHTML = room.temp.toFixed(1);
    }
  };
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + host + "/data/temp"));
}

//function startTemp() {
//  var xhr = new XMLHttpRequest();
//  xhr.open('POST', "cli.php", true);
//  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//  xhr.onload = function(e) {
//    if (this.status == 200 && this.readyState === 4) {
//      const output = JSON.parse(this.responseText);
//      if (isNaN(output[0])) {
//        console.log(output[0]);
//      } else {
//        conf[room].temp = parseFloat(output[0]) / 1000 + conf[room].tempCorrection;
//        document.getElementById(conf[room].id + "RoomTemp").innerHTML = conf[room].temp.toFixed(1);
//      }
//    }
//  };
//  xhr.send("cmd=bash&params="+stringToHex("/var/www/html/ds18b20.sh"));
//
//  setTimeout(startTemp, 60000); // elke minuut
//}

function powerLog(dev, name) {
  const d = new Date();
  const logLine = {time: d.getTime(),
    Watt: dev.Watt,
    name: name,
    status: dev.status};
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  var wgetcmd = "wget -qO- --post-data='" + "cmd=echo&params="+stringToHex("'" + JSON.stringify(logLine) + "' >> data/power.log") + "' http://" + conf.Living.host + "/cli.php";
  xhr.send("cmd=wget&params="+stringToHex(wgetcmd));
}

function tasmotaSwitch (switchName, cmd) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const output = JSON.parse(this.responseText);
      if (output[0] == '{"POWER":"OFF"}') {
        conf.switch[switchName].status = "off";
        powerLog(conf.switch[switchName], switchName);
      } else if (output[0] == '{"POWER":"ON"}') {
        conf.switch[switchName].status = "on";
        powerLog(conf.switch[switchName], switchName);
      }
    }
  };
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + conf.switch[switchName].IP + "/cm?cmnd=" + cmd));
}

function setBrightness(brightness) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "brightness.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send("brightness=" + brightness);
}

//function motionPicture() {
//  var xhr = new XMLHttpRequest();  // Take picture
//  xhr.open('POST', "cli.php", true);
//  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//  xhr.send("cmd=bash&params="+stringToHex("./motion.sh"));
//}

function lightOff() {
  document.getElementById("lightoff").style.display = "";
  document.getElementById("lighton").style.display = "none";
  if (conf.switch[conf[room].light].status != "off") { // if light is on > light off
    tasmotaSwitch (conf[room].light, "Power%20Off");
  }
}

//var pirStatus;
//var pir = pir1;
var pictureTaken = false;
// var lightOffTime;
function startMotion() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
//      const output = JSON.parse(this.responseText);
      if (this.responseText.includes(" hi ")) { // Motion detected
//console.log(new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}), this.responseText);
        if (typeof screenTimer != 'undefined') {
          clearTimeout(screenTimer);
        }
        screenTimer = setTimeout(setBrightness, conf.lights.lightTimer*1000, 0); // Reset Timeoff
        var now = new Date().getTime();
        if (now > eveningLightsOn || now < morningLightsOut) { // dark
          setBrightness(conf.minBacklight * 2); // activate dimmed screen
          if (typeof lightTimer != 'undefined') {
            clearTimeout(lightTimer);
          }
          document.getElementById("lightoff").style.display = "none";
          document.getElementById("lighton").style.display = "";
          if (conf.switch[conf[room].light].status != "on") { // if light is out > light on
            tasmotaSwitch (conf[room].light, "Power%20On");
          }
          lightTimer = setTimeout(lightOff, conf.lights.lightTimer*1000); // Reset Timeoff
        } else {
          setBrightness(conf.maxBacklight + conf.minBacklight); // activate bright screen
        }
//        if (pictureTaken == false) {
//          pictureTaken = true;
//          motionPicture(); // take a photo
//        }
        weather();  // refresh weather
//      } else { // no motion
//        pictureTaken = false;
      }
//      if (pir == pir1) {
//        pir = pir2;
//      } else {
//        pir = pir1;
//      }
    }
  };
  xhr.send("cmd=pinctrl&params="+stringToHex("get " + pir1 + "," + pir2));
}

function startTime() {
//  clearTimeout(startTimer);
  var today = new Date();
  var h = today.getHours();
  var m = today.getMinutes();
  m = checkTime(m);
  var s = today.getSeconds();
  s = checkTime(s);

  document.getElementById('day').innerHTML = dayNames[today.getDay()];
  document.getElementById('clock').innerHTML = h + ":" + m;
  var elem = document.getElementById("clockdate");
  if (elem.innerHTML !== conf.available[0].sleep && elem.innerHTML !== conf.available[0].absent) {
    document.getElementById("clockdate").innerHTML = today.getDate() + '&nbsp;' + monthNames[today.getMonth()];
  }

  setTimeout(startTime, 1000); // elke seconde
}
function connect() {
  socket = new WebSocket("ws://pindadomo.local:8080");
//  socket = new WebSocket("ws://192.168.129.2:8080");
  socket.onopen = function(event) {
    console.log("Connected to server");
//    if (window.location.hostname !== 'localhost') {
//      const message = {};
//      message.function = "heaterColors";
//      sendMessage(JSON.stringify(message));
//    }
  };
  socket.onmessage = function(event) {
    console.log("Message received: " + event.data);
    if (event.data[0] == "["  || event.data[0] == "{") {
      var message = JSON.parse(event.data);
      switch (message.function) {
        case "thermostatClockday":
          document.getElementById("day").style.color = message.value;
          break;
        case "available":
          if (message.value == conf.available[0].sleep || message.value == conf.available[0].absent) {
            document.getElementById("clockdate").innerHTML = message.value;
          } else {
              var today = new Date();
              document.getElementById("clockdate").innerHTML = today.getDate() + '&nbsp;' + monthNames[today.getMonth()];
          }
          break;
      }
//    } else {
//       document.getElementById(event.data).click();
    }
  };
  socket.onclose = function(event) {
    console.log("WebSocket connection has been closed successfully.");
    setTimeout(connect, 1000);
  };
  socket.onerror = function(event) {
    console.log("WebSocket error: ", event);
  };
}
function sendMessage(message) {
  if (typeof socket !== 'undefined') {
    if (socket.readyState) {
      socket.send(message);
      console.log("Message sent: " + message);
    }
  } else {
console.log("Websocket not ready yet!");
  }
}
