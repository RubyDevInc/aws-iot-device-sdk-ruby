const thingShadow = require('..').thingShadow;
const cmdLineProcess = require('./lib/cmdline');
var sensorLib = require('/home/pi/dht11/node_modules/node-dht-sensor/')


function processMeasure(args) {
    const thingName = ''; // AWS IoTに作成する thing name を指定
    // const thingName = 'RasPi_sendai'; // example

    const RasPiShadow = thingShadow({
	    keyPath: args.privateKey,
	    certPath: args.clientCert,
	    caPath: args.caCert,
	    clientId: args.clientId,
	    region: args.region,
	    baseReconnectTimeMs: args.baseReconnectTimeMs,
	    keepalive: args.keepAlive,
	    protocol: args.Protocol,
	    port: args.Port,
	    host: args.Host,
	    debug: args.Debug
    });

    const operationTimeout = 10000;
    var currentTimeout = null;
    var stack = [];

    function genericOperation(operation, state){

	    var clientToken = RasPiShadow[operation](thingName, state);

	    if (clientToken === null) {
	        if ( currentTimeout !== null ){
		        console.log('waiting for operation to finish before retry...');
		        currentTimeout = setTimeout(
		            function(){
			            genericOperation(operation, state);
		            },
		            operationTimeout * 2);
	        }
	    } else {
	        stack.push(clientToken);
	    }
    }

    function measureTemperature(){
	    var measure = sensorLib.read();
	    return {
	        state: {
		        desired: {
		            temperature: measure.temperature.toFixed(4),
		            humidity: measure.humidity.toFixed(4)
		        },
		        reported: {
		            temperature: measure.temperature.toFixed(4),
		            humidity: measure.humidity.toFixed(4)
		        }
	        }
	    };
    }

    sensorLib.initialize(11, 4);
    var count = 0;
    RasPiShadow.register(thingName);
    genericOperation('update', measureTemperature());

    function handleStatus(thingName, stat, clientToken, stateObject){
	    var expectedClientToken = stack.pop();

	    if(expectedClientToken == clientToken){
	        console.log('got \''+ stat +'\' status on: '+ thingName);
	    } else {
	        console.log('(status) client token mismatch on :' + thingName);
	    }
	    console.log(' updating temperature:  ' + JSON.stringify(stateObject));
	    if(currentTimeout === null) {
	        currentTimeout = setTimeout(function() {
		        currentTimeout = null;
		        genericOperation('update', measureTemperature())
	        }, 60000);
	    }

    }

    function handleDelta(thingName, stateObject) {
        console.log('delta on: ' + thingName + JSON.stringify(stateObject));
    }

    function handleTimeout(thingName, clientToken) {
	    var expectedClientToken = stack.pop();

	    if (expectedClientToken === clientToken) {
            console.log('timeout on: ' + thingName);
	    } else {
            console.log('(timeout) client token mismtach on: ' + thingName);
        }

    }

    RasPiShadow.on('connect', function() {
	    console.log('connect to AwS IoT');
    });
    RasPiShadow.on('close', function() {
	    console.log('close');
	    RasPiShadow.unregister(thingName);
    });

    RasPiShadow.on('reconnect', function() {
	    console.log('reconnect');
    });

    RasPiShadow.on('offline', function() {
        //
	    // If any timeout is currently pending, cancel it.
	    //
	    if (currentTimeout !== null) {
            clearTimeout(currentTimeout);
            currentTimeout = null;
	    }
	    //
        // If any operation is currently underway, cancel it.
        //
        while (stack.length) {
            stack.pop();
        }
	    console.log('offline');
    });

    RasPiShadow.on('error', function(error) {
        console.log('error', error);
    });

    RasPiShadow.on('message', function(topic, payload) {
	    console.log('message', topic, payload.toString());
    });

    RasPiShadow.on('status', function(thingName, stat, clientToken, stateObject) {
        handleStatus(thingName, stat, clientToken, stateObject);
    });

    RasPiShadow.on('delta', function(thingName, stateObject) {
	    handleDelta(thingName, stateObject);
    });

    RasPiShadow.on('timeout', function(thingName, clientToken) {
        handleTimeout(thingName, clientToken);
    });
}

module.exports = cmdLineProcess;

if (require.main === module) {
    cmdLineProcess('connect to the AWS IoT service and update temperature',
		           process.argv.slice(2), processMeasure);
}
