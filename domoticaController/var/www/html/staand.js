// Configuration
tempIncrDecr = 0.5;

function getDiningTemp() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "ssh.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function() {
    if (this.readyState === 4) {
      var diningTemp = parseFloat(this.responseText).toFixed(1);
      if (!isNaN(diningTemp)) { // change with valid temp
        document.getElementById("diningRoomTemp").innerHTML = diningTemp + " °C";
      }
    }
  };
  xhr.send('host=pindadining&command=cat /home/dany/temp.txt');
}
function getKitchenTemp() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "ssh.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function() {
    if (this.readyState === 4) {
      var kitchenTemp = parseFloat(this.responseText).toFixed(1);
      if (!isNaN(kitchenTemp)) { // change with valid temp
        document.getElementById("kitchenRoomTemp").innerHTML = kitchenTemp + " °C";
      }
    }
  };
  xhr.send('host=pindakeuken&command=cat /var/www/html/data/PresHumiTemp');
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
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "ssh.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function() {
        if (this.readyState === 4) {
          setThermostatUI(event);
//console.log("thermostatUI", this.responseText);
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
//console.log(command);
    if (id == "kitchentemp") {
        xhr.send("command=" + sshcommand + "&host=pindakeuken");
      } else if (id == "diningtemp") {
        xhr.send("command=" + sshcommand + "&host=pindadining");
      } else {
        xhr.send("command=" + sshcommand + "&host=localhost");
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
//console.log("setThermostatUI 2 ", this.responseText.length, "." + this.responseText + ".");
//var id = "living";
      if (this.responseText.length == 0) {
        document.getElementById(id+"Auto").style.color = "lime";
        document.getElementById(id+"Manual").style.color = "";
        document.getElementById(id+"Off").style.color = "";
      } else if (this.responseText == "off\n") {
        document.getElementById(id+"Auto").style.color = "";
        document.getElementById(id+"Manual").style.color = "";
        document.getElementById(id+"Off").style.color = "lime";
      } else {
        document.getElementById(id+"Auto").style.color = "";
        document.getElementById(id+"Manual").style.color = "lime";
        document.getElementById(id+"Off").style.color = "";
        document.getElementById(id+"temp").innerHTML = parseFloat(this.responseText).toFixed(1);
      }
    }
  };
  xhr.send('host=' + host + '&command=cat /tmp/thermostatManual');
}

function setThermostatUI (event) {
  getThermostatManual("living", "localhost");
  getThermostatManual("dining", "pindadining");
  getThermostatManual("kitchen", "pindakeuken");

//  thermostatIfFileExist("data/thermostatManualkitchen", "kitchen");
//  thermostatIfFileExist("data/thermostatManualliving", "living");
  document.getElementById('livingRoomTemp').innerHTML = roomTemp;
}
/*
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
*/
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
  }
  var thermostatUIApp = getApp("thermostatUI");
  if (thermostatUIApp == "on") {
    setThermostatUI(event);
    getKitchenTemp();
    getDiningTemp();
console.log("thermostatUIApp == on");
//  } else if (thermostatUIApp == "off") {
//    getKitchenTemp("off");
  }
  if (waitMinute++ > 59) {
    waitMinute = 0;
    if (app["radio"]) {
      radio(event);
    }
    if (app["thermostatUI"]) {
console.log("ThermostatUI / min");
      setThermostatUI(event);
      getKitchenTemp();
      getDiningTemp();
    }
  }
  startTimer = setTimeout(startTime, 1000); // elke seconde
}
window.onload = startTime;
