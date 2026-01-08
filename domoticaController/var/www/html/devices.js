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
function setImgSrc(imgEl, response) {
  if (response == "[]") {
    document.getElementById("connerr").innerHTML += "Connection Error: " + imgEl.parentElement.innerText + "<br>";
    return;
  }
  if (imgEl.src.includes("light-bulb")) {
    svg = "light-bulb";
  } else if (imgEl.src.includes("infrared")) {
    svg = "infrared";
  } else if (imgEl.src.includes("power")) {
    svg = "power";
  }
  const output = JSON.parse(response);
  if (output[0].includes(':"OFF"}')) {
    imgEl.src = "emoji/" + svg + "-off.svg";
  } else if (output[0].includes(':"ON"}')) {
    imgEl.src = "emoji/" + svg + "-on.svg";
  }
}
function toggle(elem, hostname, channel = 1) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', "cli.php", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.elem = elem;
  xhr.onload = function(e) {
    if (this.status == 200) {
     setImgSrc(elem.firstElementChild, this.responseText);
    }
  };
  xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + hostname + "/cm?cmnd=Power" + channel +"%20Toggle"));
}
function getLastNumericalGroup(str) {
  let lastGroupOfNumbers = str.match(/(?:\d+)(?!.*\d)/);
  return (lastGroupOfNumbers ? lastGroupOfNumbers[0] : null);
}
function refresh(event) {
  var buttons = event.parentElement.parentElement.getElementsByTagName('button');
  for(var i = 0; i < buttons.length; i++) {
    var func = buttons[i].getAttribute('onclick');
    var hostname = func.substring(
      func.indexOf("'") + 1,
      func.lastIndexOf("'")
    );
    var channel = getLastNumericalGroup(func);
    var xhr = new XMLHttpRequest();
    xhr.open('POST', "cli.php", true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xhr.button = buttons[i];
    xhr.onload = function(e) {
      if (this.status == 200) {
        var imgEl = this.button.getElementsByTagName('img')[0];
        setImgSrc(imgEl, this.responseText);
      }
    };
    xhr.send("cmd=wget&params="+stringToHex("-qO- http://" + hostname + "/cm?cmnd=Power" + channel));
  }
}
window.onload = function(){
  var imgheadings = document.querySelectorAll("h1 img");
  for(var i = 0; i < imgheadings.length; i++) {
    if (imgheadings[i].src.includes("refresh")) {
      imgheadings[i].click();
    }
  }
};
