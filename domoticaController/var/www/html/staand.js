// Configuration
tempIncrDecr = 0.5;
ChristmasLightDev = "-fb7b27-6951";

function getThermostatVar(varname) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "data/thermostat", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function() {
    var position = this.responseText.search(varname + "=");
    if (position > -1) {
      var thermostatVar = parseFloat(this.responseText.substring(position + varname.length + 1));
      if (varname == "TVVolume") {
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
//console.log(id.substr(0, 6));
    if (id == "kitchentemp") {
        xhr.send("command=" + sshcommand + "&host=pindakeuken");
//      } else if (id == "diningtemp") {
      } else if (id.substr(0, 6) == "dining") {
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
//          console.log("TEMP");
          if (id != "kitchen") {
            document.getElementById(id+"ManualAux").className = "";
          }
          document.getElementById(id+"Manual").className = "highlight";
          document.getElementById(id+"temp").innerHTML = parseFloat(this.responseText).toFixed(1);
        } else {
//          console.log("AUX");
          document.getElementById(id+"Manual").className = "";
          document.getElementById(id+"ManualAux").className = "highlight";
          document.getElementById(id+"aux").innerHTML = parseFloat(this.responseText).toFixed(1);
        }
//console.log(parseFloat(this.responseText).toFixed(1), document.getElementById(id+"temp").innerHTML, document.getElementById(id+"aux").innerHTML);
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

function lights(event) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "ssh.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send('host=pindadining&command=/var/www/html/lightswitch.sh toggle');
  event.stopPropagation();
// ChristmasLight
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "tasmota.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.send('dev=' + ChristmasLightDev + '&cmd=Power%20Toggle');
}

//var yrCodes = {
//	"s01": "clear sky",
//	"s02": "fair",
//	"s03": "partly cloudy",
//	"s04": "cloudy",
//	"s40": "light rain showers",
//	"s05": "rain showers",
//	"s41": "heavy rain showers",
//	"s24": "light rain showers and thunder",
//	"s06": "rain showers and thunder",
//	"s25": "heavy rain showers and thunder",
//	"s42": "light sleet showers",
//	"s07": "sleet showers",
//	"s43": "heavy sleet showers",
//	"s26": "light sleet showers and thunder",
//	"s20": "sleet showers and thunder",
//	"s27": "heavy sleet showers and thunder",
//	"s44": "light snow showers",
//	"s08": "snow showers",
//	"s45": "heavy snow showers",
//	"s28": "light snow showers and thunder",
//	"s21": "snow showers and thunder",
//	"s29": "heavy snow showers and thunder",
//	"s46": "light rain",
//	"s09": "rain",
//	"s10": "heavy rain",
//	"s30": "light rain and thunder",
//	"s22": "rain and thunder",
//	"s11": "heavy rain and thunder",
//	"s47": "light sleet",
//	"s12": "sleet",
//	"s48": "heavy sleet",
//	"s31": "light sleet and thunder",
//	"s23": "sleet and thunder",
//	"s32": "heavy sleet and thunder",
//	"s49": "light snow",
//	"s13": "snow",
//	"s50": "heavy snow",
//	"s33": "light snow and thunder",
//	"s14": "snow and thunder",
//	"s34": "heavy snow and thunder",
//	"s15": "fog"
//}
function weather(event) {
//  document.getElementById("weather").innerHTML = '<pre class="terminalbox">Bezig met het ophalen van het weerbericht...</pre>';
  var xhrforecast = new XMLHttpRequest();
  xhrforecast.open('POST', "weather.php", true);
  xhrforecast.onload = function(e) {
    if (this.status == 200) {
//      var svg = this.responseText;
//      svg.replace('xmlns="http://www.w3.org/2000/svg"','xmlns="http://www.w3.org/2000/svg"'+ "\n" + 'viewBox="0 105 500 250"');
//console.log(svg);
      document.getElementById("weather").innerHTML = this.responseText;
//      var d = new Date();
//      var UTCHour = d.getUTCHours() + ":00";
//      const weatherObj = JSON.parse(this.responseText);
//      for (let x in weatherObj.properties.timeseries) {
//	if (weatherObj.properties.timeseries[x].time.includes(UTCHour)) {
//          for (let col = 1; col < 7; col++) {
//            var ts = parseInt(x) + col - 1;
//            var UTCTime = d;
//            UTCTime.setUTCHours(weatherObj.properties.timeseries[ts].time.substr(11,2));
//            document.getElementById("weatherTime" + col).innerHTML = UTCTime.getHours() + ":00"; 
//            document.getElementById("weatherTemp" + col).innerHTML = weatherObj.properties.timeseries[ts].data.instant.details.air_temperature; 
//            document.getElementById("weatherHumi" + col).innerHTML = weatherObj.properties.timeseries[ts].data.instant.details.relative_humidity; 
//            document.getElementById("weatherWind" + col).innerHTML = '<span style="transform: rotate(' + weatherObj.properties.timeseries[ts].data.instant.details.wind_from_direction + 'deg);display: inline-block;">&darr;</span> ';
//            document.getElementById("weatherWind" + col).innerHTML += weatherObj.properties.timeseries[ts].data.instant.details.wind_speed; 
//            document.getElementById("weatherPrec" + col).innerHTML = weatherObj.properties.timeseries[ts].data.next_1_hours.details.precipitation_amount; 
//            document.getElementById("weatherPres" + col).innerHTML = weatherObj.properties.timeseries[ts].data.instant.details.air_pressure_at_sea_level;
//            var yrSymbol;
//            for (let y in yrCodes) {
//              if (weatherObj.properties.timeseries[ts].data.next_1_hours.summary.symbol_code.includes(yrCodes[y].replace(/\s/g, ''))) {
//                yrSymbol = y;
//                if (weatherObj.properties.timeseries[ts].data.next_1_hours.summary.symbol_code.includes("_day")) {
//                  yrSymbol += "d";
//                } else if (weatherObj.properties.timeseries[ts].data.next_1_hours.summary.symbol_code.includes("_night")) {
//                  yrSymbol += "n";
//                }
//                break;
//              }
//            }
//            document.getElementById("weatherImg" + col).src = "weathericons/" + yrSymbol.substring(1) + ".svg";
//          }
//        }
//      }
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
  document.getElementById('miniclock').innerHTML = h + ":" + m;
  document.getElementById('minitemp').innerHTML = roomTemp;
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
