window.KSBench = function(){
  var benchMessage = "";
  var benchStart = null;
  this.reportAsAlert = false;

  function startBench(message){
    benchStart = (new Date()).getTime();
    benchMessage = "KSBench: " + message + " : Start";
  }

  function benchmark(message) {
    var elapsedTime = (new Date()).getTime() - benchStart;
    benchMessage += "\n" + "KSBench: " + message + " : " + parseInt(elapsedTime, 10) + "ms";
  }

  function endBench(message) {
    var elapsedTime = (new Date()).getTime() - benchStart;
    benchMessage += "\n" + "KSBench: " + message + " : " + parseInt(elapsedTime, 10) + "ms";
    if (this.reportAsAlert) {
      alert(benchMessage);    
    }
    console.log(benchMessage);
  }

  return {
    startBench: startBench,
    benchmark: benchmark,
    endBench: endBench
  }
}();
