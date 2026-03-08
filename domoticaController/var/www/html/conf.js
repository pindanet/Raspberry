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
var editor;
const xhttp = new XMLHttpRequest();
xhttp.onload = function(e) {
  if (this.status == 200) {
    // create the editor
    const container = document.getElementById("jsoneditor")
    const options = {
      modes: ['tree', 'text']
    }
    editor = new JSONEditor(container, options)
    // set json
    const initialJson = JSON.parse(this.responseText);
    editor.set(initialJson)
    // get json
    const updatedJson = editor.get()
  }
}
xhttp.open("POST", confFileName);
xhttp.send();
// Download JSON configuration
document.getElementById('saveDocument').onclick = function () {
  // Save Dialog
  let fname = window.prompt("Save as...", "conf.json")
  // Check json extension in file name
  if (fname.indexOf(".") === -1) {
    fname = fname + ".json"
  } else {
    if (fname.split('.').pop().toLowerCase() === "json") {
      // Nothing to do
    } else {
      fname = fname.split('.')[0] + ".json"
    }
  }
  const blob = new Blob([JSON.stringify(editor.get(), null, 2)], {type: 'application/json;charset=utf-8'})
  saveAs(blob, fname)
}
// Upload JSON configuration
document.getElementById('loadDocument').onclick = function () {
  // Load a JSON document
  FileReaderJS.setupInput(document.getElementById('loadDocument'), {
    readAsDefault: 'Text',
    on: {
      load: function (event, file) {
        editor.setText(event.target.result)
      }
    }
  })
}
// Activate JSON configuration
document.getElementById('sendDocument').onclick = function () {
  // Send JSON configuration to Pindadomo, Pindakeuken, PindaAlarmclock
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "savejson.php", true);
  xhr.setRequestHeader("Content-type", "application/json; charset=utf-8");
  xhr.onload = function(e) {
    if (this.status == 200) {
      console.log(this.responseText);
/*
      // Send to pindakeuken.local
      var xhr = new XMLHttpRequest();
      xhr.open('POST', "cli.php", true);
      xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      xhr.onload = function(e) {
        if (this.status == 200) {
          console.log("PindaKeuken: ", this.responseText);
          // Send to pindaalarmclock.local
          var xhr = new XMLHttpRequest();
          xhr.open('POST', "cli.php", true);
          xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
          xhr.onload = function(e) {
            if (this.status == 200) {
              console.log("PindaAlarmclock: ", this.responseText);
              window.location.href = "/";
              alert("Configuratie verzonden naar alle apparaten.");
            }
          };
          xhr.send("cmd=wget&params="+stringToHex("-q -O- --post-file data/conf.json -H 'http://pindaalarmclock.local/sendconf.php' --header 'content-type: application/json'"));
        }
      };
      xhr.send("cmd=wget&params="+stringToHex("-q -O- --post-file data/conf.json -H 'http://pindakeuken.local/sendconf.php' --header 'content-type: application/json'"));
*/
    }
  };
//  console.log(JSON.stringify(editor.get()));
//  xhr.send("save="+stringToHex('/tmp/conf.php.json')+"&json="+stringToHex(JSON.stringify(editor.get())));
//  console.log(stringToHex('{"target":"server", "message":"JSON bericht"}'));
console.log("save="+stringToHex('/tmp/conf.php.json')+"&json="+stringToHex('{"target":"server", "message":"JSON bericht"}'));
  xhr.send("save="+stringToHex('/tmp/conf.php.json')+"&json="+stringToHex('{"target":"server", "message":"JSON bericht"}'));
}

// https://reqbin.com/code/javascript/wzp2hxwh/javascript-post-request-example

  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php");
  xhr.setRequestHeader("Content-type", "Content-type", "application/x-www-form-urlencoded");
  xhr.onload = function(e) {
    if (this.status == 200) {
      console.log(this.responseText);
    }
  };
//  console.log(JSON.stringify(editor.get()));
//  xhr.send("save="+stringToHex('/tmp/conf.php.json')+"&json="+stringToHex(JSON.stringify(editor.get())));

//console.log("save="+stringToHex('/tmp/conf.php.json')+"&json="+stringToHex('{"target":"server", "message":"JSON bericht"}'));
// wget -q -O- --post-data "save=$(echo -n '/tmp/save.json' | xxd -p -c 256)&json=$(echo -n '{"target":"server", "message":"JSON bericht"}' | xxd -p -c 256)" -H "http://pindadomo/savejson.php"
params=''
xhr.send("cmd=wget" + cmd + "&params="+stringToHex(params));
