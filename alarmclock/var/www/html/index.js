//var alarmTime = "07:30";
var startTimer;
var dayNames = new Array("Zondag","Maandag","Dinsdag","Woensdag","Donderdag","Vrijdag","Zaterdag");
var monthNames = new Array("januari","februari","maart","april","mei","juni","juli","augustus","september","oktober","november","december");
var updateScreen = 10;

function checkTime(i) {
  if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
  return i;
}

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

function radioStatus() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const output = JSON.parse(this.responseText);
      if (output.length > 0) {
        if (output[0] > 16) {
          fontsize = 5;
        }
        document.getElementById("radio").innerHTML = "<span style='font-size:" + fontsize + "vw'>" + output[0] + "</span>";
      }
    }
  };
  xhr.send("cmd=cat&params="+stringToHex("/var/www/html/data/radio.log | tail -1 | cut -d \"'\" -f 2"));
}

var nextAlarm = "07:30";
function getNextAlarm() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "data/nextalarm", true);
  xhr.onload = function(e) {
    if (this.status == 200) {
console.log(this.responseText);
      nextAlarm = this.responseText;
    }
  };
  xhr.send();
  startTime();
}

function startTime() {
  clearTimeout(startTimer);
  var today = new Date();
  var h = today.getHours();
  var m = today.getMinutes();
  m = checkTime(m);
  var s = today.getSeconds();
  s = checkTime(s);

  document.getElementById("clockdate").innerHTML = today.getDate() + '&nbsp;' + monthNames[today.getMonth()] + '&nbsp;' + today.getFullYear();
  document.getElementById('clockday').innerHTML = dayNames[today.getDay()] + ' ' + nextAlarm;
  document.getElementById('clock').innerHTML = h + ":" + m + ":" + s;

  updateScreen++;
  if (updateScreen > 10) {
    updateScreen = 0;
    radioStatus();
//    var xhr = new XMLHttpRequest();
//    xhr.open('POST', "data/radio.log", true);
//    xhr.onload = function(e) {
//      if (this.status == 200) {
//        var lines = this.responseText.split("\n");
//        var status = lines[lines.length - 2].split("'")[1];
//        var fontsize = 10;
//        if (status.length > 16) {
//          fontsize = 5;
//        }
//console.log(status);
//        document.getElementById('radio').innerHTML = "<span style='font-size:" + fontsize + "vw'>" + status + "</span>";
//      }
//    };
//    xhr.send();
  }
  startTimer = setTimeout(startTime, 1000); // elke seconde
}
window.onload = getNextAlarm;
