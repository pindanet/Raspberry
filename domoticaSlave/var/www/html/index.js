var lightSwitch="tasmota_15dd89-7561";

var startTimer;
var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");

function lightstatus() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "data/light-bulb", true);
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
  xhr.send("dev=" + lightSwitch + "&cmd=Power%20toggle");
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

var roomTemp="20.0 °C";
function getRoomTemp() {
  var xhrthermometer = new XMLHttpRequest();
  xhrthermometer.responseType = 'text';
  xhrthermometer.open('POST', "data/PresHumiTemp", true);
  xhrthermometer.onload = function(e) {
    if (this.status == 200) {
      roomTemp = parseFloat(this.responseText).toFixed(1) + " °C";
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

  document.getElementById("clockdate").innerHTML = today.getDate() + '&nbsp;' + monthNames[today.getMonth()] + '&nbsp;' + today.getFullYear();
  document.getElementById('clockday').innerHTML = dayNames[today.getDay()] + ' ' + roomTemp;
  document.getElementById('clock').innerHTML = h + ":" + m + ":" + s;

  getRoomTemp();
  lightstatus();

  startTimer = setTimeout(startTime, 1000); // elke seconde
}
window.onload = startTime;
