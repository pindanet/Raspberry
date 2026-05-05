// ToDo
// Fill Room panels

const confName = "data/conf.php.json";

var activePanel = "dashboard";

var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");

function miniPanel(display) {
  document.getElementById("miniclock").style.display = display;
  document.getElementById("minitemp").style.display = display;
}
function activatePanel(panel) {
  document.getElementById(activePanel).style.display = "none";
  activePanel = panel;
  document.getElementById(activePanel).style.display = "";
  if (panel != "dashboard") {
    miniPanel("");
  } else {
    miniPanel("none");
  }
}
function elclick(event) {
  var id = event.target.id;
  switch(id) {
    case "clock":
    case "clockhours":
    case "dots":
    case "clockminutes":
    case "clockdaytemp":
    case "clockdate":
      activatePanel("menu");
      break;
    case "menuradio":
      activatePanel("radio");
      radioPlay("getvol");
      break;
    case "miniclock":
    case "minitemp":
      activatePanel("dashboard");
      break;
    case "menuweather":
      activatePanel("weather");
      // Set weather URL
      document.getElementById('weather').contentDocument.location.href = "meteogram/meteogram.html?lat=" + conf.location.Latitude + "&lon=" + conf.location.Longitude + "&alt=" + conf.location.Altitude;
//      document.getElementById('weather').contentDocument.location.reload(true);
      break;

//    case "Kitchen_Auto":
//      const idSplit = id.split("_");
//      var room = idSplit[0];
//console.log(room); //, id.slice(room.length));
//      break;
    default:
      if (id.startsWith("menu")) {
        activatePanel(id.slice(4));
      } else {
        console.log(id, event);
      }
  }
}
function radioPlay(cmd, channel = "none") {
  radioElem = document.getElementById("radioPlayer");
  volumeElem = document.getElementById("volumeinfo");
  switch(cmd) {
    case "play":
      radioElem.src = conf.radio.channel[channel].URL;
      volumeElem.innerHTML = conf.radio.channel[channel].volume;
      radioElem.volume = conf.radio.channel[channel].volume / 100;
      radioElem.play();
      break;
    case "stop":
      radioElem.pause();
      activatePanel("dashboard");
      break;
    case "getvol":
      volumeElem.innerHTML = radioElem.volume * 100;
      break;
    case "volume":
      radioElem.volume = channel / 100;
      volumeElem.innerHTML = channel;
      break;
    case "voldown":
      volume = parseInt(volumeElem.innerHTML);
      if ( volume == 0 ) { // Minimum Volume
        return;
      }
      volume -= 5;
      radioElem.volume = volume / 100;
      volumeElem.innerHTML = volume;
      break;
    case "volup":
      volume = parseInt(volumeElem.innerHTML);
      if ( volume == 100 ) { // Maximum Volume
        return;
      }
      volume += 5;
      radioElem.volume = volume / 100;
      volumeElem.innerHTML = volume;
      break;
  }
}
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
function getTemp(room) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      const output = JSON.parse(this.responseText);
      if (!isNaN(output[0])) {
        conf.rooms[room].thermostat.temp = (parseFloat(output[0]) / 1000 + conf.rooms[room].thermostat.tempCorrection).toFixed(1);
        document.getElementById(conf.rooms[room].thermostat.sensorStatus).style.opacity="";
      } else { // Fetching temp error
        document.getElementById(conf.rooms[room].thermostat.sensorStatus).style.opacity=".5";
      }
    }
  };
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + conf.rooms[room].Hostname + conf.rooms[room].thermostat.tempPath));
}
function checkTime(i) {
  if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
  return i;
}
async function startTime() {
  var today = new Date();
  var h = today.getHours();
  var m = today.getMinutes();
  m = checkTime(m);
  if ( m != document.getElementById('clockminutes').innerHTML) { // every minute

//const start = Date.now();
    let response = await fetch(confName);
    if (typeof conf === 'undefined') { // Get configuration
      conf = await response.json();
      conf.lastModified = response.headers.get('Last-Modified');

      var HTMLCode = "";
      const weatherMenuEl = document.getElementById("menuweather");
      for (var room in conf.rooms) { // search Controller Room Name
        if (conf.rooms[room].Hostname == conf.Controller) {
          conf.ControllerRoom = conf.rooms[room].Name;
        }
        HTMLCode += "<img id=\"menu" + conf.rooms[room].Name  + "\" class=\"menubutton\" onclick=\"elclick(event);\" src=\""+ conf.rooms[room].Icon + "\">";
      }
      weatherMenuEl.insertAdjacentHTML("afterend", HTMLCode);

      // Fill Radio panel with channels
      const radioPlayerEl = document.getElementById("radioPlayer");
      HTMLCode = "";
      for (var channel in conf.radio.channel) {
        HTMLCode += "<img class=\"menubutton\" onclick=\"radioPlay('play', '" + channel + "');\" src=\"" + conf.radio.channel[channel].logo  + "\">";
      }
      radioPlayerEl.insertAdjacentHTML("afterend", HTMLCode);

      const weatherPlayerEl = document.getElementById("weather");
      for (var room in conf.rooms) { // Fill Room panels
        HTMLCode = "<div id=\"" + conf.rooms[room].Name + "\" class=\"panel\" style=\"display:none;\">";
        HTMLCode += "  <h1><img class=\"menubutton\" src=\"" + conf.rooms[room].Icon + "\"> " + conf.rooms[room].Name + " <span id=\"temp_" + conf.rooms[room].Name + "\">--.- °C</span></h1>";
        HTMLCode += "<br>";
        for (var heater in conf.rooms[room].thermostat.heater) { // Fill Room Heater panel
console.log(conf.rooms[room].thermostat.heater[heater]);
          HTMLCode += "<img id=\"heater_" + conf.rooms[room].thermostat.heater[heater].Hostname + "\" class=\"menubutton\" onclick=\"elclick(event);\" src=\"emoji/infrared-off.svg\">";
        }
        HTMLCode += "<button style=\"position: relative; bottom: 5vh;\" id=\"Living_Incr\" onclick=\"elclick(event);\">+</button>";
        HTMLCode += "<button style=\"position: relative; bottom: 5vh;\"><span id=\"Lining_manual\">20.0</span> °C</button>";
        HTMLCode += "<button style=\"position: relative; bottom: 5vh;\" id=\"Living_Decr\" onclick=\"elclick(event);\">&ndash;</button>";
        HTMLCode += "<button style=\"position: relative; bottom: 5vh;\" id=\"Living_AM\" onclick=\"elclick(event);\">A</button>";
        HTMLCode += "<br>";

        HTMLCode += "</div>";
        weatherPlayerEl.insertAdjacentHTML("afterend", HTMLCode);

//<div id="Kamer" class="panel">
//<h1><img class="menubutton" src="emoji/kitchen.svg"> Kamer <span id="Kamer_temp">--.- °C</span></h1>
//<br>
//<img id="heater_Computertafel" class="menubutton" onclick="elclick(event);" src="emoji/infrared-off.svg">
//<img id="heater_Computertafel" class="menubutton" onclick="elclick(event);" src="emoji/infrared-off.svg">
//<img id="heater_Computertafel" class="menubutton" onclick="elclick(event);" src="emoji/infrared-off.svg">

//<button style="position: relative; bottom: 5vh;" id="Living_Incr" onclick="elclick(event);">+</button>
//<button style="position: relative; bottom: 5vh;"><span id="Lining_manual">20.0</span> °C</button>  
//<button style="position: relative; bottom: 5vh;" id="Living_Decr" onclick="elclick(event);">&ndash;</button>
//<button style="position: relative; bottom: 5vh;" id="Living_AM" onclick="elclick(event);">A</button>
//<br>
//<img id="light_LivingZij" class="menubutton" onclick="elclick(event);" src="emoji/light-bulb-off.svg">
//<br>
//<img id="switch_Tandenborstel" class="menubutton" onclick="elclick(event);" src="emoji/power-off.svg">
//</div>

      }

    } else if (conf.lastModified !== response.headers.get('Last-Modified')) { // New configuration
      location.reload(true);
    }
//const ms = Date.now() - start;
//console.log('miliseconds elapsed: ' +  ms);

    document.getElementById("clockmonthday").innerHTML = today.getDate();
    document.getElementById("clockmonth").innerHTML = monthNames[today.getMonth()];

    document.getElementById('clockday').innerHTML = dayNames[today.getDay()];
    document.getElementById('clockhours').innerHTML = h;
    document.getElementById('clockminutes').innerHTML = m;
    document.getElementById('miniclock').innerHTML = h + ":" + m;

    getTemp(conf.ControllerRoom);

    if (typeof conf.rooms[conf.ControllerRoom].thermostat.temp !== 'undefined') { // Temp received
      document.getElementById("clocktemp").innerHTML = conf.rooms[conf.ControllerRoom].thermostat.temp;
      document.getElementById("minitemp").innerHTML = conf.rooms[conf.ControllerRoom].thermostat.temp;
    }
  }
  startTimer = setTimeout(startTime, 1000); // every second
}
window.onload = startTime;
