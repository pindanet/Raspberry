var lightSwitch="tasmota_15dd89-7561";
var irSwitch = [];
irSwitch["ir1"] = "tasmota_relayGPIO13";
irSwitch["ir2"] = "tasmota_relayGPIO19";

var startTimer;
var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");

function weather(event) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "weather.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const weatherObj = JSON.parse(this.responseText);
      var HTMLCode = "<pre>"
      HTMLCode += weatherObj.current_condition[0].lang_nl[0].value + "<br>";
      HTMLCode += weatherObj.current_condition[0].temp_C + " °C<br>";
      HTMLCode += weatherObj.current_condition[0].winddir16Point + " " + weatherObj.current_condition[0].windspeedKmph + " km/h<br>";
      HTMLCode += weatherObj.current_condition[0].precipMM + " mm<br>";
      HTMLCode += weatherObj.current_condition[0].pressure + " hPa<br>";

//      var d = new Date();
//      for (let period in weatherObj.weather[0].hourly) {
//        if (weatherObj.weather[0].hourly[period].time / 100 >= d.getHours()) {
//          var currentTime = weatherObj.current_condition[0].localObsDateTime;
//          var currentTemp = weatherObj.current_condition[0].temp_C;
//          var forecastTime = weatherObj.weather[0].hourly[period].time / 100;
//          var forecastTemp = weatherObj.weather[0].hourly[period].tempC;
//          console.log("Temp (" + currentTime + ") " + currentTemp + " > " + forecastTemp + " (" + forecastTime + "u)");
//          break;
//        }
//      }
//console.log(this.responseText);
      HTMLCode += "</pre>"
      document.getElementById("weather").innerHTML = HTMLCode;
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
      if (this.responseText.includes("ON")) {
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

//  irstatus(irSwitch["ir1"], "ir1");
//  irstatus(irSwitch["ir2"], "ir2");

  startTimer = setTimeout(startTime, 1000); // elke seconde
}
window.onload = startTime;
