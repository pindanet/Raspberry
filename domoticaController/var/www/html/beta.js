const tempCorrection = 0;
const Controller = "pindadomo";
const tmpDir = "/data/";
var activePanel = "content";

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
  if (panel != "content") {
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
      activatePanel("menu");
      break;
    case "miniclock":
    case "minitemp":
      activatePanel("content");
      break;
//    case "Kitchen_Auto":
//      const idSplit = id.split("_");
//      var room = idSplit[0];
//console.log(room); //, id.slice(room.length));
//      break;
    default:
      console.log(id, event);
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
function getTemp(host) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      const output = JSON.parse(this.responseText);
      const clocktempEl = document.getElementById("clocktemp");
      const minitempEl = document.getElementById("minitemp");
      if (!isNaN(output[0])) {
        var roomTemp = (parseFloat(output[0]) / 1000 + tempCorrection).toFixed(1);
        clocktempEl.style.opacity="";
        clocktempEl.innerHTML = roomTemp;
        minitempEl.style.opacity="";
        minitempEl.innerHTML = roomTemp + " °C";
      } else { // Fetching temp error
        clocktempEl.style.opacity=".5";
        minitempEl.style.opacity="";
      }
    }
  };
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + host + tmpDir + "temp"));
}
function checkTime(i) {
  if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
  return i;
}
function startTime() {
  var today = new Date();
  var h = today.getHours();
  var m = today.getMinutes();
  m = checkTime(m);
  if ( m != document.getElementById('clockminutes').innerHTML) { // every minute
    document.getElementById("clockmonthday").innerHTML = today.getDate();
    document.getElementById("clockmonth").innerHTML = monthNames[today.getMonth()];

    document.getElementById('clockday').innerHTML = dayNames[today.getDay()];
    document.getElementById('clockhours').innerHTML = h;
    document.getElementById('clockminutes').innerHTML = m;
    document.getElementById('miniclock').innerHTML = h + ":" + m;

    getTemp(Controller);
  }
  startTimer = setTimeout(startTime, 1000); // every second
}
window.onload = startTime;
