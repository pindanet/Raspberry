var lightSwitch="tasmota_15dd89-7561";
var irSwitch = [];
irSwitch["ir1"] = "tasmota_4fd8ee-6382.log";
irSwitch["ir2"] = "tasmota_a943fa-1018.log";

var startTimer;
var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");
var WWO_CODE = {
    "113": "clear-day",
    "116": "partly-cloudy-day",
    "119": "cloudy",
    "122": "overcast",
    "143": "mist",
    "176": "drizzle",
    "179": "sleet",
    "182": "sleet",
    "185": "sleet",
    "200": "thunderstorms-rain",
    "227": "snow",
    "230": "snow",
    "248": "mist",
    "260": "mist",
    "263": "drizzle",
    "266": "drizzle",
    "281": "sleet",
    "284": "sleet",
    "293": "drizzle",
    "296": "drizzle",
    "299": "rain",
    "302": "rain",
    "305": "rain",
    "308": "rain",
    "311": "sleet",
    "314": "sleet",
    "317": "sleet",
    "320": "snow",
    "323": "snow",
    "326": "snow",
    "329": "snow",
    "332": "snow",
    "335": "snow",
    "338": "snow",
    "350": "sleet",
    "353": "drizzle",
    "356": "rain",
    "359": "rain",
    "362": "sleet",
    "365": "sleet",
    "368": "snow",
    "371": "snow",
    "374": "sleet",
    "377": "sleet",
    "386": "thunderstorms-rain",
    "389": "thunderstorms-rain",
    "392": "thunderstorms-snow",
    "395": "snow"
}
function weather(event) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "weather.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const weatherObj = JSON.parse(this.responseText);
      var HTMLCode = "<pre>"
      HTMLCode += weatherObj.current_condition[0].localObsDateTime + "<br>";
      HTMLCode += weatherObj.current_condition[0].lang_nl[0].value + "<br>";
      HTMLCode += weatherObj.current_condition[0].temp_C + " (" + weatherObj.current_condition[0].FeelsLikeC + ") °C<br>";
      HTMLCode += weatherObj.current_condition[0].humidity + " %<br>";
      HTMLCode += weatherObj.current_condition[0].winddir16Point + " " + weatherObj.current_condition[0].windspeedKmph + " km/h<br>";
      HTMLCode += weatherObj.current_condition[0].precipMM + " mm<br>";
      HTMLCode += weatherObj.current_condition[0].pressure + " hPa<br>";
      HTMLCode += "</pre>"
      document.getElementById("weather").innerHTML = HTMLCode;
      if (! document.getElementById("weathericon").src.includes(weatherObj.current_condition[0].weatherCode)) {
        document.getElementById("weathericon").src = "weathericons/" + WWO_CODE[weatherObj.current_condition[0].weatherCode] + ".svg";
      }
    }
  };
  xhr.send();
  if (typeof event !== 'undefined') {
    event.stopPropagation();
  }
}

function irstatus(irswitch, id) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "data/" + irswitch, true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      var lines = this.responseText.split('\n');
      if (lines[lines.length - 2].includes("on")) {
        document.getElementById(id).src = "emoji/infrared-on.svg";
      } else {
        document.getElementById(id).src = "emoji/infrared-off.svg";
      }
    }
  };
  xhr.send();
}

function ir(event, el) {
  var id = el.id;
  if (document.getElementById(id).src.includes("infrared-off.svg")) {
    document.getElementById(id).src = "emoji/infrared-on.svg";
  } else if (document.getElementById(id).src.includes("infrared-on.svg")) {
    document.getElementById(id).src = "emoji/infrared-auto.svg";
  } else {
    document.getElementById(id).src = "emoji/infrared-off.svg";
  }
//  var xhr = new XMLHttpRequest();
//  xhr.open('POST', "tasmota.php", true);
//  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//  xhr.onload = function(e) {
//    if (this.status == 200) {
//      irstatus(irSwitch[el.id], el.id);
//    }
//  };
//  xhr.send("dev=" + irSwitch[el.id] + "&cmd=Power%20toggle");

  event.stopPropagation();
}

function lightstatus() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "data/" + lightSwitch, true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      if (this.responseText.includes("ON")) {
        document.getElementById("light").src = "emoji/light-bulb-on.svg";
      } else {
        document.getElementById("light").src = "emoji/light-bulb-off.svg";
      }
    }
  };
  xhr.send();
}

function lights(event) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "tasmota.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      lightstatus();
    }
  };
  xhr.send("dev=" + lightSwitch + "&cmd=Power%20toggle");

  event.stopPropagation();
}

var roomTemp="20.0";
function getRoomTemp() {
  var xhrthermometer = new XMLHttpRequest();
  xhrthermometer.responseType = 'text';
  xhrthermometer.open('POST', "data/PresHumiTemp", true);
  xhrthermometer.onload = function(e) {
    if (this.status == 200) {
      roomTemp = parseFloat(this.responseText).toFixed(1);
    }
  };
  xhrthermometer.send();
}

function checkTime(i) {
  if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
  return i;
}

function startTime() {
  clearTimeout(startTimer);
  var today = new Date();
  var h = today.getHours();
  var m = today.getMinutes();
  m = checkTime(m);
  var s = today.getSeconds();
  s = checkTime(s);

  document.getElementById('day').innerHTML = dayNames[today.getDay()];
  document.getElementById('clock').innerHTML = h + ":" + m;
  document.getElementById("clockdate").innerHTML = today.getDate() + '&nbsp;' + monthNames[today.getMonth()];
  document.getElementById('temp').innerHTML = roomTemp;

  getRoomTemp();
  lightstatus();
  weather();

  irstatus(irSwitch["ir1"], "ir1");
  irstatus(irSwitch["ir2"], "ir2");

  startTimer = setTimeout(startTime, 5000); // elke 5 seconden
}
window.onload = startTime;
