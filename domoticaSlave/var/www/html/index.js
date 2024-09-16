//var lightSwitch="tasmota-15dd89-7561";
//var irSwitch = [];
//irSwitch["ir1"] = "tasmota-4fd8ee-6382.log";
//irSwitch["ir2"] = "tasmota-a943fa-1018.log";

var startTimer;
var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");

function getConf() { // Get configuration
  const xhttp = new XMLHttpRequest();
  xhttp.onload = function(e) {
    if (this.status == 200) {
      if (typeof conf === 'undefined') {
        conf = JSON.parse(this.responseText);
        conf.lastModified = this.getResponseHeader('Last-Modified');
//        calcConf();
//        nextalarm();
        startTime();
      } else if (conf.lastModified !== this.getResponseHeader('Last-Modified')) { // new configuration
        conf = JSON.parse(this.responseText);
        conf.lastModified = this.getResponseHeader('Last-Modified');
//        calcConf();
      }
//      brightness();
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

function getTemp(host, cmd, room) {
}

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
  xhr.send();
  if (typeof event !== 'undefined') {
    event.stopPropagation();
  }
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
//  document.getElementById('temp').innerHTML = roomTemp;

  getTemp("localhost", "/var/www/html/ds18b20.sh", conf.Dining);
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      const output = JSON.parse(this.responseText);
      conf.Dining.temp = parseFloat(output[0]) / 1000 + conf.Dining.tempCorrection;
      document.getElementById(conf.Dining.id + "RoomTemp").innerHTML = conf.Dining.temp.toFixed(1) + " °C";
    }
  };
//  xhr.send("cmd=ssh&params="+stringToHex("-v -i data/id_rsa -o StrictHostKeyChecking=no -o 'UserKnownHostsFile /dev/null' $(ls /home)@" +  host +" '" + cmd + "'"));
  xhr.send("cmd=/var/www/html/ds18b20.sh&params="+stringToHex(""));

//  lightstatus();
  weather();

//  setTimeout(irstatus, 2500, irSwitch["ir1"], "ir1");
//  irstatus(irSwitch["ir1"], "ir1");
//  irstatus(irSwitch["ir2"], "ir2");

  startTimer = setTimeout(startTime, 5000); // elke 5 seconden
}
