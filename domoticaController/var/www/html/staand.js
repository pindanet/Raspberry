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
  conf.available[0].sleepdate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hourMin[0], hourMin[1] + 1, 0, 0);
  if (conf.available[0].sleepdate - now < 0) {
    conf.available[0].sleepdate.setDate(conf.available[0].sleepdate.getDate()+1);
  }
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
  document.getElementById('clock').innerHTML = h + ":" + m;
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
