var radioStatusInterval;
function radio(event) {
  radioCommand(event, 'getvol', 1);
  radioCommand(event, 'status', 1);
  radioStatusInterval = setInterval(function () { radioCommand(event, 'status', 1); }, 60000); // Elke minuut
console.log("Radio");
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
  }
  if (typeof event !== 'undefined') {
    event.stopPropagation();
  }
}

var roomTemp="20.0 °C";
function getRoomTemp() {
  var xhrthermometer = new XMLHttpRequest();
  xhrthermometer.responseType = 'text';
  xhrthermometer.open('POST', "data/PresHumiTemp", true);
  xhrthermometer.onload = function(e) {
    if (this.status == 200) {
      var PresHumiTemp = this.responseText.split('\n');
      roomTemp = parseFloat(PresHumiTemp[2]).toFixed(1) + " °C";
    }
  };
  xhrthermometer.send();
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
//console.log(id + " Off");
      }
    } else {
      if (!app[id]) {
        app[id]=true;
//console.log(id + " On")
        return true;
      }
    }
  } else if (app[id]) {
    app[id]=false;
//console.log(id + " Off");
  }
}
waitMinute=0;
function startTime() {
  clearTimeout(startTimer);
  var today = new Date();
  var h = today.getHours();
  var m = today.getMinutes();
  m = checkTime(m);

  document.getElementById("clockdate").innerHTML = today.getDate() + '&nbsp;' + monthNames[today.getMonth()] + '&nbsp;' + today.getFullYear();
  document.getElementById('clockday').innerHTML = dayNames[today.getDay()] + ' ' + roomTemp;
  document.getElementById('clock').innerHTML = h + ":" + m;
  getRoomTemp();
  if (getApp("radio")) {
    radio(event);
  }
  getApp("thermostatUI");
  if (waitMinute++ > 59) {
    waitMinute = 0;
    if (app["radio"]) {
      radio(event);
    }
  }
  startTimer = setTimeout(startTime, 1000); // elke seconde
}
window.onload = startTime;
