// Configuration
tempIncrDecr = 0.5;

function getKitchenTemp(command) {
/*
  switch (command) {
    case "on":
      console.log("getKitchenTemp On");
    case "displayTemp":
      console.log("getKitchenTemp Display Temp");
      break;
    case "off":
      console.log("getKitchenTemp Off");
      break;
  }
*/
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "thermostatcommand.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function() {
    if (this.readyState === 4) {
console.log(this.responseText);
      var kitchenTemp = parseFloat(this.responseText).toFixed(1);
      if (!isNaN(kitchenTemp)) {
//        document.getElementById("kitchenRoomTemp").innerHTML = "--.- °C";
//      } else {
        document.getElementById("kitchenRoomTemp").innerHTML = kitchenTemp + " °C";
      }
    }
  };
  xhr.send("command=getKitchenTemp&status=" + command);
}
function thermostatUI (event, command, id) {
  switch (command) {
    case "Incr":
      var temp = parseFloat(document.getElementById(id).innerHTML);
      temp += tempIncrDecr;
      temp = temp.toFixed(2);
      document.getElementById(id).innerHTML = temp;
      break;
    case "Decr":
      var temp = parseFloat(document.getElementById(id).innerHTML);
      temp -= tempIncrDecr;
      temp = temp.toFixed(2);
      document.getElementById(id).innerHTML = temp;
      break;
    case "Manual":
    case "Off":
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "thermostatcommand.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function() {
        if (this.readyState === 4) {
          setThermostatUI(event);
        }
      };
      var temp = document.getElementById(id).innerHTML;
      if (command == "Off") {
        temp = "off";
        command = "Manual";
      }
      if (id == "kitchentemp") {
        xhr.send("command=" + command + "&room=kitchen&temp=" + temp);
      } else {
        xhr.send("command=" + command + "&room=living&temp=" + temp);
      }
      break;
    case "Auto":
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "thermostatcommand.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function() {
        if (this.readyState === 4) {
          setThermostatUI(event);
        }
      };
      if (id == "kitchentemp") {
        xhr.send("command=" + command + "&room=kitchen&temp=auto");
      } else {
        xhr.send("command=" + command + "&room=living&temp=auto");
      }
      break;
  }
}
function setThermostatUI (event) {
  thermostatIfFileExist("data/thermostatManualkitchen", "kitchen");
  thermostatIfFileExist("data/thermostatManualliving", "living");
  document.getElementById('livingRoomTemp').innerHTML = roomTemp;
}
function thermostatIfFileExist(url, id) {
  var xhr = new XMLHttpRequest();
  xhr.responseType = 'text';
  xhr.open('POST', url)
  xhr.onload = function() {
    if (this.readyState === 4) {
      if (this.status === 404) {
        document.getElementById(id+"Auto").style.color = "black";
        document.getElementById(id+"Manual").style.color = "";
        document.getElementById(id+"Off").style.color = "";
      } else {
        document.getElementById(id+"Auto").style.color = "";
        if (this.responseText == "off") {
          document.getElementById(id+"Off").style.color = "black";
          document.getElementById(id+"Manual").style.color = "";
        } else {
          document.getElementById(id+"Off").style.color = "";
          document.getElementById(id+"Manual").style.color = "black";
          document.getElementById("kitchentemp").innerHTML = this.responseText;
        }
      }
    }
  }
  xhr.send("id=" + id);
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
        return "off";
      }
    } else {
      if (!app[id]) {
        app[id]=true;
//console.log(id + " On")
        return "on";
      }
    }
  } else if (app[id]) {
    app[id]=false;
//console.log(id + " Off");
    return "off";
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
  var radioApp = getApp("radio");
  if (radioApp == "on") {
    radio(event);
//  } else if (radioApp == "off") {
  }
  var thermostatUIApp = getApp("thermostatUI");
  if (thermostatUIApp == "on") {
//console.log(thermostatUIApp);
    setThermostatUI(event);
    getKitchenTemp("on");
  } else if (thermostatUIApp == "off") {
//console.log(thermostatUIApp);
    getKitchenTemp("off");
  }
  if (waitMinute++ > 59) {
    waitMinute = 0;
    if (app["radio"]) {
      radio(event);
    }
    if (app["thermostatUI"]) {
      setThermostatUI(event);
      getKitchenTemp("displayTemp");
    }
  }
  startTimer = setTimeout(startTime, 1000); // elke seconde
}
window.onload = startTime;
