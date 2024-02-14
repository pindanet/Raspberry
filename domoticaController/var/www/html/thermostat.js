// ToDo
// Manual temp

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
  Living: {
      id: "living",
      htmlElementId: "clockmonthday",
      heaterColor: "",
      temp: 20.0,
      tempOffset: "0",
      heater: [
        {
          name: "Schilderij",
          color: "Yellow",
          IP: "192.168.129.12",
          Watt: "650"
        },
        {
          name: "Computertafel",
          color: "Orange",
          IP: "192.168.129.0",
          Watt: "300"
        },
        {
          name: "Canyon",
          color: "Red",
          IP: "192.168.129.4",
          Watt: "650"
        }
      ],
      thermostat: [
        {
          begin: "07:30",
          end: "13:30",
          temp: "tempAux"
	},
        {
          begin: "13:30",
          end: "17:00",
          temp: "tempComfort"
	},
        {
          begin: "17:00",
          end: "17:30",
          temp: "tempAux"
	},
        {
          begin: "17:30",
          end: "22:50",
          temp: "tempComfort"
	}
      ]
  },
  Dining: {
      id: "dining",
      htmlElementId: "clockmonth",
      heaterColor: "",
      temp: 20.0,
      tempOffset: "0",
      subtitleColor: "white",
      heater: [
        {
          name: "Zonsondergang",
          color: "Yellow",
          IP: "192.168.129.20",
          Watt: "650"
        },
        {
          name: "Tafel",
          color: "Orange",
          IP: "192.168.129.5",
          Watt: "300"
        },
        {
          name: "Eekhoorn",
          color: "Red",
          IP: "192.168.129.3",
          Watt: "650"
        }
      ],
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
	}
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
      begindate: "2024-02-16",
      begin: "15:30",
      enddate: "2024-02-16",
      end: "bedTime",
      temp: {
        living: "tempAux",
        dining: "tempOff",
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
//var heaterColor = "";
function tempAdjustment(room) {
//room.temp = 16.9;
  if (isNaN(room.temp)) {
    return;
  }
  var today = new Date();
  var now = today.getTime();
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
        begin += 86400000 * conf.event[i].repeat;
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
      begin = beginDate.getTime();
console.log("Event on " + beginDate.toString());
console.log("Until " + endDate.toString());
      if (begin <= now && end > now) {
        tempWanted = conf[conf.event[i].temp[room.id]];
console.log("Temp wanted: " + tempWanted);
        break;
      }
    }
  }

// ToDo
// Manual temp

  if (tempWanted == conf.tempOff) {
    var nightTime = today.getHours().toString().padStart(2, '0') + ":" + today.getMinutes().toString().padStart(2, '0');
    if (conf.tempNightTime > nightTime) {
      tempWanted = conf.tempNight;
    }
  }

  for (let i = 0; i < room.heater.length; i++) {
    var tempHysteresis = tempWanted - conf.hysteresis - conf.hysteresis * (2 * i);
console.log(room.heater[i].name + " switch on at " + tempHysteresis.toFixed(2) + " °C");
    if (room.temp < tempHysteresis) {
//      tasmota room.heater[i]("on");
console.log(room.heater[i].name + " switched on at " + room.temp + " °C");
      room.heaterColor = room.heater[i].color;
    }
  }
  for (let i = room.heater.length - 1; i <= 0; i--) {
    tempHysteresis = tempWanted + conf.hysteresis - conf.hysteresis * (2 * i);
console.log(room.heater[i].name + " switch off at " + tempHysteresis.toFixed(2) + " °C");
    if (room.temp > tempHysteresis) {
//      tasmota room.heater[i]("off");
console.log(room.heater[i].name + " switched off at " + room.temp + " °C");
      if (i == 0) {
        room.heaterColor = "";
      } else {
        room.heaterColor = room.heater[i - 1].color;
      }
    }
  }

console.log(room.temp, tempWanted, room.heaterColor);

  document.getElementById(room.htmlElementId).style.color = room.heaterColor;
}
function thermostat() {
  var thermostatdefault;
  conf.Living.temp = parseFloat(document.getElementById("minitemp").innerHTML);
  tempAdjustment(conf.Living);
//  getLivingTemp();
  conf.Dining.temp = parseFloat(document.getElementById("diningRoomTemp").innerHTML);
  tempAdjustment(conf.Dining);
  getDiningTemp();
//  tempAdjustment(conf.Kitchen, temp);
//  getKitchenTemp();
  setTimeout(thermostat, 60000); // Every minute

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
//  var xhr = new XMLHttpRequest();
//  xhr.open('POST', "ssh.php", true);
//  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
//  xhr.onload = function() {
//    if (this.readyState === 4) {
//      temp = parseFloat(this.responseText).toFixed(2);
//      if (!isNaN(temp)) { // If valid temp
//        tempAdjustment(conf.Dining, temp);
//      }
//    }
//  };
//  xhr.send('host=pindadining&command=cat /home/dany/temp.txt');
// Get temp Kitchen
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
setTimeout(thermostat, 60000);
// Every minute// End of Thermostat
