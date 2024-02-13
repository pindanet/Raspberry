// Configuration
var conf = {
  available: [
    {
      absent: "Afwezig",
      sleep: "Slapen",
      sleeptime: "22:24"
    }
  ],
  tempIncrDecr: 0.5,
  tempComfort: 20.00,
  tempAux: 17.50,
  tempOff: 15.00,
  tempNight: 10.00,
  tempNightTime: "06:30",
  bedTime: "22:50",
  hysteresis: 0.1,
  switch: [
    {
      name: "Haardlamp",
      IP: "192.168.129.18",
      Watt: "20",
      Cmnd: "Power"
    },
    {
      name: "Tandenborstel",
      IP: "192.168.129.7",
      Watt: "10",
      Cmnd: "Power"
    },
    {
      name: "Apotheek",
      IP: "192.168.129.19",
      Watt: "20",
      Cmnd: "Power"
    },
    {
      name: "TVlamp",
      IP: "92.168.129.11",
      Watt: "20",
      Cmnd: "Power"
    },
    {
      name: "SwitchBacklight",
      IP: "192.168.129.41",
      Watt: "1",
      Cmnd: "Power3"
    },
    {
      name: "Kerst",
      IP: "192.168.129.44",
      Watt: "15",
      Cmnd: "Power"
    },
    {
      name: "LivingVoor",
      IP: "192.168.129.41",
      Watt: "16",
      Cmnd: "Power2"
    }
  ],
  Dining: {
      id: "dining",
      tempOffset: "0",
      subtitleColor: "white",
      thermostat: [
        {
          begin: "07:30",
          end: "08:50",
          temp: "tempComfort"
	},
        {
          begin: "08:50",
          end: "10:55",
          temp: "tempAux"
	},
        {
          begin: "10:55",
          end: "12:20",
          temp: "tempComfort"
	},
        {
          begin: "12:20",
          end: "12:55",
          temp: "tempAux"
	},
        {
          begin: "12:55",
          end: "13:30",
          temp: "tempComfort"
	},
        {
          begin: "13:30",
          end: "16:55",
          temp: "tempAux"
	},
        {
          begin: "16:55",
          end: "17:30",
          temp: "tempComfort"
	},
        {
          begin: "17:30",
          end: "22:30",
          temp: "tempAux"
	},
      ]
  },
  event: [
    {
      repeat: 0,
      begindate: "2024-02-02",
      begin: "19:45",
      enddate: "2024-02-02",
      end: "bedTime",
      temp: {
        living: "tempAux",
        dining: "tempAux",
        kitchen: "tempOff"
      },
      comment: "MCCB"
    },
    {
      repeat: 1,
      begindate: "2024-02-13",
      begin: "14:45",
      enddate: "2024-02-13",
      end: "bedTime",
      temp: {
        living: "tempAux",
        dining: "tempComfort",
        kitchen: "tempOff"
      },
      comment: "Test"
    },
    {
      repeat: 0,
      begindate: "2024-02-07",
      begin: "19:45",
      enddate: "2024-02-07",
      end: "bedTime",
      temp: {
        living: "tempAux",
        dining: "tempAux",
        kitchen: "tempOff"
      },
      comment: "ACCB"
    }
  ]
};
//          "temp": conf["tempComfort"]

//console.log(conf.Dining.event[0]);
//console.log(JSON.stringify(conf));
sendConf(conf);
function tempAdjustment(room, temp) {
  var today = new Date();
  var now = today.getTime();
  var heatingRoom = "off";
  var tempWanted = conf.tempOff;
  for (let i = 0; i < room.thermostat.length; i++) {
    var beginTime = room.thermostat[i].begin.split(':');
    var beginDate = new Date();
    beginDate.setHours(beginTime[0]);
    beginDate.setMinutes(beginTime[1]);
    beginDate.setSeconds(0);
    var begin = beginDate.getTime();
    var endTime = room.thermostat[i].end.split(':');
    var endDate = new Date();
    endDate.setHours(endTime[0]);
    endDate.setMinutes(endTime[1]);
    endDate.setSeconds(0);
    var end = endDate.getTime();
    if (begin <= now && end > now) {
      heatingRoom = "on";
      tempWanted = conf[room.thermostat[i].temp];
      break;
    }
  }
  for (let i = 0; i < conf.event.length; i++) {
    var nowDateOnly = new Date(now);
    nowDateOnly.setHours(0);
    nowDateOnly.setMinutes(0);
    nowDateOnly.setSeconds(0);
    nowDateOnly.setMilliseconds(0);
    var dateOnly = nowDateOnly.getTime();
    var beginDate = new Date(conf.event[i].begindate);
    beginDate.setHours(0);
    var begin = beginDate.getTime();
    if (conf.event[i].repeat > 0) { // repeating event
      while (begin < dateOnly) {
        begin += 86400000;
      }
    }
    if (begin == dateOnly) {
      var expired = begin - beginDate.getTime();
      var endDate = new Date(conf.event[i].enddate);
      var end = endDate.getTime();
      endDate.setTime(end + expired);
      if (conf.event[i].end.indexOf(":")) {
        var endTime = conf[conf.event[i].end].split(':');
      } else {
        var endTime = conf.event[i].end.split(':');
      }
      endDate.setHours(endTime[0]);
      endDate.setMinutes(endTime[1]);
      endDate.setSeconds(0);
      end = endDate.getTime();

      beginDate.setTime(begin);
      var beginTime = conf.event[i].begin.split(':');
      beginDate.setHours(beginTime[0]);
      beginDate.setMinutes(beginTime[1]);
console.log("Event on " + beginDate.toString());
console.log("Until " + endDate.toString());
      if (begin <= now && end > now) {
        heatingRoom = "on";
        tempWanted = conf[conf.event[i].temp[room.id]];
console.log("Temp wanted: " + tempWanted);
        break;
      }
    }
  }

console.log(beginDate.toString(), endDate.toString(), tempWanted);

  switch (tempWanted) {
    case conf.tempOff:
      document.getElementById("clockmonth").style.color = "blue";
      break;
    case conf.tempAux:
      document.getElementById("clockmonth").style.color = "orange";
      break;
    case conf.tempComfort:
      document.getElementById("clockmonth").style.color = "red";
      break;
    default:
      document.getElementById("clockmonth").style.color = "";
      break;
  }
}
function thermostat() {
  var temp;
  var thermostatdefault;
// Get temp Living
//  var xhr = new XMLHttpRequest();
//  xhr.open('POST', "data/PresHumiTemp", true);
//  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//  xhr.onload = function () {
//    if (this.status == 200) {
//      var PresHumiTemp = this.responseText.split('\n');
//      temp = parseFloat(PresHumiTemp[2]).toFixed(2);
//      tempAdjustment(conf.Living, temp);
//    }
//  };
//  xhr.send();
// Get temp Dining
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "ssh.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function() {
    if (this.readyState === 4) {
      temp = parseFloat(this.responseText).toFixed(2);
      if (!isNaN(temp)) { // If valid temp
        tempAdjustment(conf.Dining, temp);
      }
    }
  };
  xhr.send('host=pindadining&command=cat /home/dany/temp.txt');
// Get temp Kitchen
  setTimeout(thermostat, 60000); // Every minute
}
function sendConf(obj) {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "sendConf.php", true);
    xhr.setRequestHeader("Content-type", "application/json; charset=utf-8");
    xhr.onload = function(e) {
      if (this.status == 200) {
        conf = JSON.parse(this.responseText);
//console.log(this.responseText);
      }
    };
    xhr.send(JSON.stringify(obj));
}
setTimeout(thermostat, 6000);
// Every minute// End of Thermostat


