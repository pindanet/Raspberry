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
//  wakeupTime: "07:30",
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
      temp: 20.0,
      tempCorrection : -2.5,
      mode: "Auto",
      ManualId : "",
      heater: [
        {
          name: "Schilderij",
          color: "Yellow",
          status: "undefined",
          IP: "192.168.129.12",
          Watt: "650"
        },
        {
          name: "Computertafel",
          color: "Orange",
          status: "undefined",
          IP: "192.168.129.0",
          Watt: "300"
        },
        {
          name: "Canyon",
          color: "Red",
          status: "undefined",
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
      status: "undefined",
      temp: 20.00,
      tempCorrection : 0.5,
      mode: "Auto",
      ManualId : "",
      tempOffset: "0",
      subtitleColor: "white",
      heater: [
        {
          name: "Zonsondergang",
          color: "Yellow",
          status: "undefined",
          IP: "192.168.129.20",
          Watt: "650"
        },
        {
          name: "Tafel",
          color: "Orange",
          status: "undefined",
          IP: "192.168.129.5",
          Watt: "300"
        },
        {
          name: "Eekhoorn",
          color: "Red",
          status: "undefined",
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
  Kitchen: {
      id: "kitchen",
      htmlElementId: "clockyear",
      status: "undefined",
      temp: 20.00,
      tempCorrection : 0,
      mode: "Auto",
      ManualId : "",
      tempOffset: "0",
      heater: [
        {
          name: "Tropen",
          color: "Red",
          status: "undefined",
          IP: "192.168.129.8",
          Watt: "650"
        }
      ],
      thermostat: [
        {
          begin: "07:30",
          end: "11:00",
          temp: "tempAux"
	},
        {
          begin: "12:15",
          end: "13:00",
          temp: "tempAux"
	},
        {
          begin: "16:55",
          end: "17:45",
          temp: "tempAux"
	},
        {
          begin: "22:25",
          end: "22:50",
          temp: "tempAux"
	}
      ]
  },
  event: [
    {
      repeat: 0,
      begindate: "2024-02-20",
//      begin: "wakeupTime",
      begin: "11:45",
      enddate: "2024-02-20",
      end: "14:00",
      temp: {
        living: "tempAux",
        dining: "tempAux",
        kitchen: "tempOff"
      },
      comment: "Kapper"
    },
//    {
//      repeat: 1,
//      begindate: "2024-02-16",
//      begin: "15:30",
//      enddate: "2024-02-16",
//      end: "bedTime",
//      temp: {
//        living: "tempAux",
//        dining: "tempOff",
//        kitchen: "tempOff"
//      },
//      comment: "Test"
//    },
    {
      repeat: 14,
      begindate: "2024-02-26",
      begin: "16:00",
      enddate: "2024-02-26",
      end: "17:00",
      temp: {
        living: "tempAux",
        dining: "tempAux",
        kitchen: "tempOff"
      },
      comment: "Bad Maandag"
    },
     {
      repeat: 14,
      begindate: "2024-02-02",
      begin: "16:00",
      enddate: "2024-02-02",
      end: "17:00",
      temp: {
        living: "tempAux",
        dining: "tempAux",
        kitchen: "tempOff"
      },
      comment: "Bad Vrijdag"
    },
     {
      repeat: 14,
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
      repeat: 14,
      begindate: "2024-02-07",
      begin: "16:00",
      enddate: "2024-02-07",
      end: "17:00",
      temp: {
        living: "tempAux",
        dining: "tempAux",
        kitchen: "tempOff"
      },
      comment: "Bad Woensdag"
    },
     {
      repeat: 14,
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
//console.log(conf.Dining.event[0]);
//console.log(JSON.stringify(conf));
sendConf(conf);
function activeHeaters(room) {
  var activeHeaters = -1;
  for (let i = 0; i < room.heater.length; i++) {
    if (room.heater[i].status == "on") {
      activeHeaters++;
    }
  }
  if (activeHeaters > -1) {
    document.getElementById(room.htmlElementId).style.color = room.heater[activeHeaters].color;
  } else {
    document.getElementById(room.htmlElementId).style.color = "";
  }
}

function tasmotaHeater (dev, cmd, room, heater) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      const output = JSON.parse(this.responseText);
      if (output[0] == '{"POWER":"OFF"}') {
        room.heater[heater].status = "off";
        activeHeaters(room);
      } else if (output[0] == '{"POWER":"ON"}') {
        room.heater[heater].status = "on";
        activeHeaters(room);
      }
    }
  };
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + dev + "/cm?cmnd=" + cmd));
}
function getTemp(host, cmd, room) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "ssh.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200 && this.readyState === 4) {
      room.temp = parseFloat(this.responseText) / 1000 + room.tempCorrection;
      document.getElementById(room.id + "RoomTemp").innerHTML = room.temp.toFixed(1) + " °C";
      if (room.id == "living") {
        roomTemp = room.temp.toFixed(1) + " °C";
      }
console.log(room.id, room.temp, roomTemp, room.tempCorrection, parseFloat(this.responseText) / 1000 + room.tempCorrection);
    }
  };
  xhr.send('host=' + host + '&command=' + cmd);
}
function getLivingTemp() {
  getTemp("pindadomo", "cat /sys/bus/iio/devices/iio\:device0/in_temp_input", conf.Living);
}
//var testTemp = 17.81;
function getDiningTemp() {
  getTemp("pindadining", "cat /sys/bus/w1/devices/28-*/temperature", conf.Dining);
}
function getKitchenTemp() {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "ssh.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function() {
    if (this.readyState === 4) {
      conf.Kitchen.temp = parseFloat(this.responseText);
      var kitchenTemp = parseFloat(this.responseText).toFixed(1);
      if (!isNaN(kitchenTemp)) { // change with valid temp
        document.getElementById("kitchenRoomTemp").innerHTML = kitchenTemp + " °C";
      }
    }
  };
  xhr.send('host=pindakeuken&command=cat /var/www/html/data/PresHumiTemp');
}
function splitTime (time) { // convert time variable to time and split hours and minutes
  if (time.indexOf(":") > -1) {
    return time.split(':');
  } else {
    return conf[time].split(':');
  }
}
function tempAdjustment(room) {
  if (isNaN(room.temp)) {
    return;
  }
  var today = new Date();
  var now = today.getTime();
  var tempWanted = conf.tempOff;
  for (let i = 0; i < room.thermostat.length; i++) {
//    var beginTime = room.thermostat[i].begin.split(':');
    var beginTime = splitTime(room.thermostat[i].begin);
    var beginDate = new Date();
    beginDate.setHours(beginTime[0]);
    beginDate.setMinutes(beginTime[1]);
    beginDate.setSeconds(0);
    var begin = beginDate.getTime();
//    var endTime = room.thermostat[i].end.split(':');
    var endTime = splitTime(room.thermostat[i].end);
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
      var endTime = splitTime(conf.event[i].end);
      endDate.setHours(endTime[0]);
      endDate.setMinutes(endTime[1]);
      endDate.setSeconds(0);
      end = endDate.getTime();

      beginDate.setTime(begin);
      var beginTime = splitTime(conf.event[i].begin);
      beginDate.setHours(beginTime[0]);
      beginDate.setMinutes(beginTime[1]);
      begin = beginDate.getTime();
console.log("Event on " + beginDate.toString());
console.log("Until " + endDate.toString());
      if (begin <= now && end > now) {
        tempWanted = conf[conf.event[i].temp[room.id]];
console.log("Event Temp wanted: " + tempWanted);
        break;
      }
    }
  }

// Manual temp
  if (room.mode == "Manual") {
    tempWanted = parseFloat(document.getElementById(room.ManualId).innerHTML);
  } else if (room.mode == "Off") {
    tempWanted = conf.tempOff;
  }
// Night temp
  if (tempWanted == conf.tempOff) {
    var nightTime = today.getHours().toString().padStart(2, '0') + ":" + today.getMinutes().toString().padStart(2, '0');
    if (conf.tempNightTime > nightTime) {
      tempWanted = conf.tempNight;
    }
  }
// Heaters On/Off
  for (let i = 0; i < room.heater.length; i++) {
    if (room.heater[i].status != "off" && room.heater[i].status != "on") { // Initialise heater status
      tasmotaHeater (room.heater[i].IP, "Power", room, i);
    } else {
      var tempOn = (tempWanted - conf.hysteresis - conf.hysteresis * (2 * i)).toFixed(2);
      var tempOff = (tempWanted + conf.hysteresis - conf.hysteresis * (2 * i)).toFixed(2);
      if (room.temp > tempOff) { // Heater Off
        if (room.heater[i].status != "off") {
          tasmotaHeater (room.heater[i].IP, "Power%20Off", room, i);
        }
      } else if (room.temp < tempOn) { //Heater On
        if (room.heater[i].status != "on") {
          tasmotaHeater (room.heater[i].IP, "Power%20On", room, i);
        }
      }
    }
//console.log("On: " + tempOn, "Off: " + tempOff, "Room.temp: " + room.temp, room.heater[i].name + ": " + room.heater[i].status);
  }
}
function thermostat() {
  var thermostatdefault;
  tempAdjustment(conf.Living);
  getLivingTemp();
  tempAdjustment(conf.Dining);
  getDiningTemp();
  tempAdjustment(conf.Kitchen);
  getKitchenTemp();
  setTimeout(thermostat, 60000); // Every minute
}
function sendConf(obj) {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "sendConf.php", true);
    xhr.setRequestHeader("Content-type", "application/json; charset=utf-8");
    xhr.onload = function(e) {
      if (this.status == 200) {
        conf = JSON.parse(this.responseText);
      }
    };
    xhr.send(JSON.stringify(obj));
}
//function getConf() {
//  const requestURL = "data/conf.json";
//  const request = new Request(requestURL);
//
//  const response = await fetch(request);
//  const confText = await response.text();
//
//  conf = JSON.parse(confText);
//}
setTimeout(thermostat, 60000); // Every minute
