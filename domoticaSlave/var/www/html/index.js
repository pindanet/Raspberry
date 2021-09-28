var lightSwitch="tasmota_15dd89-7561";
var irSwitch = [];
irSwitch["ir1"] = "tasmota_4fd8ee-6382.log";
irSwitch["ir2"] = "tasmota_a943fa-1018.log";

var startTimer;
var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");
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
//var WWO_CODE = {
//    "113": "clear-day",
//    "116": "partly-cloudy-day",
//    "119": "cloudy",
//    "122": "overcast",
//    "143": "mist",
//    "176": "drizzle",
//    "179": "sleet",
//    "182": "sleet",
//    "185": "sleet",
//    "200": "thunderstorms-rain",
//    "227": "snow",
//    "230": "snow",
//    "248": "mist",
//    "260": "mist",
//    "263": "drizzle",
//    "266": "drizzle",
//    "281": "sleet",
//    "284": "sleet",
//    "293": "drizzle",
//    "296": "drizzle",
//    "299": "rain",
//    "302": "rain",
//    "305": "rain",
//    "308": "rain",
//    "311": "sleet",
//    "314": "sleet",
//    "317": "sleet",
//    "320": "snow",
//    "323": "snow",
//    "326": "snow",
//    "329": "snow",
//    "332": "snow",
//    "335": "snow",
//    "338": "snow",
//    "350": "sleet",
//    "353": "drizzle",
//    "356": "rain",
//    "359": "rain",
//    "362": "sleet",
//    "365": "sleet",
//    "368": "snow",
//    "371": "snow",
//    "374": "sleet",
//    "377": "sleet",
//    "386": "thunderstorms-rain",
//    "389": "thunderstorms-rain",
//    "392": "thunderstorms-snow",
//    "395": "snow"
//}
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
        for (let col = 1; col < 4; col++) {
          var ts = parseInt(x) + col - 1;
          var UTCTime = d;
          UTCTime.setUTCHours(weatherObj.properties.timeseries[ts].time.substr(11,2));
          document.getElementById("weatherTime" + col).innerHTML = UTCTime.getHours() + ":00"; 
          document.getElementById("weatherTemp" + col).innerHTML = weatherObj.properties.timeseries[ts].data.instant.details.air_temperature; 
          document.getElementById("weatherHumi" + col).innerHTML = weatherObj.properties.timeseries[ts].data.instant.details.relative_humidity; 
          document.getElementById("weatherWind" + col).innerHTML = '<span style="transform: rotate(' + weatherObj.properties.timeseries[ts].data.instant.details.wind_from_direction + 'deg);display: inline-block;">&darr;</span> ';
          document.getElementById("weatherWind" + col).innerHTML += weatherObj.properties.timeseries[ts].data.instant.details.wind_speed; 
          document.getElementById("weatherPrec" + col).innerHTML = weatherObj.properties.timeseries[ts].data.next_1_hours.details.precipitation_amount; 
          document.getElementById("weatherPres" + col).innerHTML = weatherObj.properties.timeseries[ts].data.instant.details.air_pressure_at_sea_level;
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
/*
          var HTMLCode = "<pre>";
          var yrSymbol;
          for (let y in yrCodes) {
            if (weatherObj.properties.timeseries[x].data.next_1_hours.summary.symbol_code.includes(yrCodes[y].replace(/\s/g, ''))) {
              yrSymbol = y;
              if (weatherObj.properties.timeseries[x].data.next_1_hours.summary.symbol_code.includes("_day")) {
                yrSymbol += "d";
              } else if (weatherObj.properties.timeseries[x].data.next_1_hours.summary.symbol_code.includes("_night")) {
                yrSymbol += "n";
              }
//              console.log(yrSymbol, yrCodes[y]);
              break;
            }
          }
          HTMLCode += weatherObj.properties.timeseries[x].data.next_1_hours.summary.symbol_code + "<br>";
          HTMLCode += weatherObj.properties.timeseries[x].data.instant.details.air_temperature + " °C<br>";
          HTMLCode += weatherObj.properties.timeseries[x].data.instant.details.relative_humidity + " %<br>";
          HTMLCode += '<span style="transform: rotate(' + weatherObj.properties.timeseries[x].data.instant.details.wind_from_direction + 'deg);display: inline-block;">&darr;</span> '
          HTMLCode += weatherObj.properties.timeseries[x].data.instant.details.wind_speed + " m/s<br>";
//          HTMLCode += weatherObj.properties.timeseries[x].data.instant.details.wind_from_direction + " ° " + weatherObj.properties.timeseries[x].data.instant.details.wind_speed + " m/s<br>";
          HTMLCode += weatherObj.properties.timeseries[x].data.next_1_hours.details.precipitation_amount + " mm<br>";
          HTMLCode += weatherObj.properties.timeseries[x].data.instant.details.air_pressure_at_sea_level + " hPa<br>";
          HTMLCode += "</pre>"
//          document.getElementById("weather").innerHTML = HTMLCode;
//          document.getElementById("weathericon").src = "weathericons/" + yrSymbol.substring(1) + ".svg";
*/
          break;
        }
      }
//      const weatherObj = JSON.parse(this.responseText);
//      var HTMLCode = "<pre>"
//      HTMLCode += weatherObj.current_condition[0].localObsDateTime + "<br>";
//      HTMLCode += weatherObj.current_condition[0].lang_nl[0].value + "<br>";
//      HTMLCode += weatherObj.current_condition[0].temp_C + " (" + weatherObj.current_condition[0].FeelsLikeC + ") °C<br>";
//      HTMLCode += weatherObj.current_condition[0].humidity + " %<br>";
//      HTMLCode += weatherObj.current_condition[0].winddir16Point + " " + weatherObj.current_condition[0].windspeedKmph + " km/h<br>";
//      HTMLCode += weatherObj.current_condition[0].precipMM + " mm<br>";
//      HTMLCode += weatherObj.current_condition[0].pressure + " hPa<br>";
//      HTMLCode += "</pre>"
//      document.getElementById("weather").innerHTML = HTMLCode;
//      if (! document.getElementById("weathericon").src.includes(WWO_CODE[weatherObj.current_condition[0].weatherCode])) {
//        document.getElementById("weathericon").src = "weathericons/" + WWO_CODE[weatherObj.current_condition[0].weatherCode] + ".svg";
//      }
    }
  };
  xhr.send();
  if (typeof event !== 'undefined') {
    event.stopPropagation();
  }
}

function executeIfFileExist(src, callback) {
  var xhrfe = new XMLHttpRequest()
  xhrfe.responseType = 'text';
  xhrfe.open('POST', src, true);
  xhrfe.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhrfe.onload = function(e) {
    if (this.status == 200) {
      callback();
    }
  }
  xhrfe.send();
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
        document.getElementById(id).src = "emoji/infrared-auto.svg";
        executeIfFileExist("data/thermostatManual", function () {
          document.getElementById(id).src = "emoji/infrared-off.svg";
        });
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
