// ToDo
// Fill Initialise Room panels
// lights, switches with icon-colors, background-color of tranparanty level
// See line starting with Test  initialize icons

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
      } else if (id.startsWith("light_")) {
        const idSplit = id.split("_");
        var xhr = new XMLHttpRequest();
        xhr.open('POST', "cli.php", true);
        xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        xhr.onload = function(e) {
          if (this.status == 200) {
            const output = JSON.parse(this.responseText);
            if (output[0].includes(':"OFF"}')) {
              document.getElementById(id).style.backgroundColor = "black";
            } else if (output[0].includes(':"ON"}')) {
              document.getElementById(id).style.backgroundColor = conf.rooms[idSplit[1]].lights[idSplit[2]].BackgroundColorOn;
            }
          }
        };
        if (typeof conf.rooms[idSplit[1]].lights[idSplit[2]].Channel !== 'undefined') {
          xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + conf.rooms[idSplit[1]].lights[idSplit[2]].Hostname + "/cm?cmnd=Power" + conf.rooms[idSplit[1]].lights[idSplit[2]].Channel  + "%20Toggle"));
        } else {
          xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + conf.rooms[idSplit[1]].lights[idSplit[2]].Hostname + "/cm?cmnd=Power%20Toggle"));
        }
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
  xhr.send("cmd=wget&params="+stringToHex("-qO- --post-data 'message=temp' http://" + conf.rooms[room].Hostname + "/wread.php"));
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
    var disabled = false;
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
        if (typeof conf.rooms[room].thermostat.heater !== 'undefined') {
          for (var heater in conf.rooms[room].thermostat.heater) { // Fill Room Heater panel
            HTMLCode += "<img id=\"heater_" + conf.rooms[room].thermostat.heater[heater].Hostname + "\" class=\"menubutton\" onclick=\"elclick(event);\" src=\"emoji/infrared-off.svg\">";
          }
          HTMLCode += "<button style=\"position: relative; bottom: 5vh;\" id=\"" + room + "_Incr\" onclick=\"elclick(event);\">+</button>";
          HTMLCode += "<button style=\"position: relative; bottom: 5vh;\"><span id=\"" + room + "_manual\">20.0</span> °C</button>";
          HTMLCode += "<button style=\"position: relative; bottom: 5vh;\" id=\"" + room + "_Decr\" onclick=\"elclick(event);\">&ndash;</button>";
          HTMLCode += "<button style=\"position: relative; bottom: 5vh;\" id=\"" + room + "_AM\" onclick=\"elclick(event);\">A</button>";
          HTMLCode += "<br>";
        }
        if (typeof conf.rooms[room].lights !== 'undefined') {
          for (var light in conf.rooms[room].lights) { // Fill Room Lights panel
            if (typeof conf.rooms[room].lights[light].disabled === 'undefined') {
              disabled = false;
            } else {
              disabled = conf.rooms[room].lights[light].disabled;
            }
            if (disabled == false) {
              HTMLCode += "<img id=\"light_" + room + "_" + light;
              HTMLCode += "\" class=\"menubutton boxed\" style=\"background-color: dimgray;\" onclick=\"elclick(event);\" src=\"" + conf.rooms[room].lights[light].Icon + "\">";
            }
          }
          HTMLCode += "<br>";
        }
        if (typeof conf.rooms[room].switches !== 'undefined') {
          for (var powerswitch in conf.rooms[room].switches) { // Fill Room switches panel
            if (typeof conf.rooms[room].switches[powerswitch].disabled === 'undefined') {
              disabled = false;
            } else {
              disabled = conf.rooms[room].switches[powerswitch].disabled;
            }
            if (disabled == false) {
              HTMLCode += "<img id=\"switch_" + conf.rooms[room].switches[powerswitch].Hostname;
              if (typeof conf.rooms[room].switches[powerswitch].Channel !== 'undefined') {
                HTMLCode += "_" + conf.rooms[room].switchew[powerswitch].Channel;
              }
              HTMLCode += "\" class=\"menubutton boxed\" style=\"background-color: dimgray;\" onclick=\"elclick(event);\" src=\"" + conf.rooms[room].switches[powerswitch].Icon + "\">";
// Test  initialize icons
            }
          }
          HTMLCode += "<br>";
        }
        HTMLCode += "</div>";
        weatherPlayerEl.insertAdjacentHTML("afterend", HTMLCode);
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
    for (var room in conf.rooms) { // Update Room panels
      if (conf.rooms[room].Hostname != conf.Controller) {
        getTemp(room);
      }
      if (typeof conf.rooms[room].thermostat.temp !== 'undefined') { // Temp received
        document.getElementById("temp_"+conf.rooms[room].Name).innerHTML = conf.rooms[room].thermostat.temp + " °C";
      }
    }

  }
  startTimer = setTimeout(startTime, 1000); // every second
}
window.onload = startTime;
