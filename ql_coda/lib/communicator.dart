import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

const String BROKER = '192.168.1.253'; //'localhost';
const String RPC_TOPIC = 'mqinvoke/rpc';

typedef Parser = void Function(String msg);
typedef SubscribeProcessor = void Function(String msg);
//Map<String, List<SubscribeProcessor>> subscribeProcessors = {};
Logger _logger = getLogger('Communicator', Level.warning);

enum TransportState {
  closed,
  opening,
  open,
}

class Communicator {
  static final Communicator _communicator = Communicator._internal();
  Isolate? mqttIsolate;
  ReceivePort? requestorReceivePort;
  ReceivePort? onErrorPort;
  SendPort? transportSendPort; // will become the port for messages to the transport isolate
  // Map<String, List<Parser>> _listener = {};
  Map<String, List<SubscribeProcessor>> subscribeProcessors = {};
  static List< void Function()> actWhenTransportReady = [];
  //bool startupComplete = false;
  TransportState transportState = TransportState.closed;

  List <List> doRemoteQueue = [];


  factory Communicator() {
    return _communicator;
  }

  Communicator._internal() {
    //_logger.d('constructor');
    reset();
    //communicateViaMqtt();
    /*communicateViaMqtt().then<bool>((FutureOr s) {
      // hang on until ready to communicate
      return s;
    });*/
  }

  bool mqttTransportIsOperating() {
    return transportSendPort != null;
  }

  // do an action - wait if transport isn't available yet
  void onReady(void Function() action) {
    if (mqttTransportIsOperating()) {
      action();
    }
    else {actWhenTransportReady.add(action);}
  }

  void reset() async {
    //_logger.i('reset $transportState');
    if (transportState == TransportState.open) {
      //_logger.d('killing');
      requestorReceivePort?.close();
      if (onErrorPort != null) {
        mqttIsolate?.removeErrorListener(onErrorPort!.sendPort);
        onErrorPort?.close();
      }
      mqttIsolate?.kill();
      transportState = TransportState.closed;
    }
    if (transportState == TransportState.closed) {
      transportState = TransportState.opening;
      communicateViaMqtt().then((value) {
        transportState = TransportState.open;
        /*for (var action in actWhenTransportReady) {action();} // TODO throws exception using Pixel 2 XL emulator
        actWhenTransportReady.clear();*/
      });
    }
  }

  Future<bool> communicateViaMqtt() async {

    requestorReceivePort = ReceivePort();
    mqttIsolate = await Isolate.spawn(mqttTransport, requestorReceivePort!.sendPort);

    onErrorPort = ReceivePort();
    mqttIsolate?.addErrorListener(onErrorPort!.sendPort);
    mqttIsolate?.setErrorsFatal(false);

    requestorReceivePort?.listen((data)
    {
      // print(data);
      if (data is SendPort) {  // mqttTransport isolate provides its sendPort as its first message
        transportSendPort = data;
        doRemoteQueue.forEach((msg) {
          // _logger.d('_sendQueue ${msg[0]}, ${msg[1]}');
          transportSendPort?.send([msg[0], msg[1]]);
        }) ;
        doRemoteQueue = [];
        for (var action in actWhenTransportReady) {action();}
        actWhenTransportReady.clear();
      }
      else {
        String topic = data[0];
        String msg = data[1];
        //_logger.d('ql: $topic: $msg');
        List<SubscribeProcessor>? subscriptions = subscribeProcessors[topic];
        if (subscriptions != null) {
          //_logger.d('$topic subscriber count: ${subscriptions.length}');
          subscriptions.forEach( (_) {_(msg);});
        }
      }
    },
    onDone: () {
      //_logger.i('requestorReceivePort.listen - onDone');
      transportSendPort = null;
    });

    onErrorPort?.listen((err) {
      //_logger.e("communicator.. mqtt transport error: $err");
      //throw Exception(["communicator.. mqtt transport error"]);
    },
    onDone: () {
      //_logger.i('onErrorPort.listen - onDone');
    });

    return true;
  }

  Future sendReceive(SendPort port, msg) {
    ReceivePort response = new ReceivePort();
    port.send([msg, response.sendPort]);
    return response.first;
  }

  /*List<dynamic> onMqttTransportIsOperating = [];

  Future<String> request(String op, [List<String> args = const []]) async {
    // if the transport isn't ready, queue the requast for later
    if (!mqttTransportIsOperating()) {
      onMqttTransportIsOperating.add(
          (String op, [List<String> args = const []])
          {
          __request(op, args);
          }
      );
      return '';
    }
    else return __request(op, args);
  }*/

  Future<String> request(String op, [List<String> args = const []]) async {
    //print('request op: ${op['op']}, args: ${op['args']}');
    args = args.map((String arg){
      return '"${arg.replaceAll('"', '\\"')}"';
    }).toList();
    try {
      _logger.d('request op: $op, args: $args');
      String response = await sendReceive(transportSendPort!, {'op': op, 'args': args});
      //print('response: $response');
      return response;
    }
    catch (e) {
      _logger.e('request error: $e');
      throw e;
    }
  }

  void subscribe(topic, callBack) {
    // TODO signal isolate to subscribe
    if (subscribeProcessors[topic] == null) {subscribeProcessors[topic] = [];}
    //_logger.d('subscribe handler for $topic is ${callBack.toString()}');
    if (!subscribeProcessors[topic]!.contains(callBack)) {
      //_logger.d('additional subscribe handler for $topic is ${callBack.toString()}');
      subscribeProcessors[topic]?.add(callBack);
    }
  }

  void doRemote(String cmd, [args='']) async {
    //_logger.d('doRemote mqinvoke/control $cmd${args != ''? ' ' + args : ''}');
    String _topic = 'mqinvoke/control';
    String _content = "$cmd${args != null? '\ '+args : ''}";
    //
    // if necessary, queue the request to be sent when the mqttTransport is ready
    if (mqttTransportIsOperating()) {
      transportSendPort?.send([_topic, _content]);
    }
    else {
      doRemoteQueue.add([_topic, _content]);
    }
  }
}

mqttTransport(SendPort requestorReceivePort) async {
  final mqttClientID = 'Coda-' + Uuid().v1();
  final MqttServerClient mqttClient = MqttServerClient(BROKER, mqttClientID);
  final pendingMqttResponses = {};
  StreamSubscription? updatesListener;

  Logger _iLogger = getLogger('mqttTransport');

  mqttClient.keepAlivePeriod = 20;
  mqttClient.autoReconnect = true;

  mqttClient.onDisconnected = () {
    if (updatesListener != null) {
      updatesListener?.cancel();
      updatesListener = null;
    }
    if (mqttClient.connectionStatus?.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      _iLogger.d('disconnected from broker as solicited');
    } else {
      _iLogger.d('disconnection from broker was unsolicited');
    }
  };

  ConnectCallback subscribeAndListen = () {

    //_logger.d('subscribe & listen');
    // TODO subscriptions should be made from subscribe()
    for (String topic in ['quodlibet/now-playing',
      'mqinvoke/response',
      'mqinvoke/cover-image']) {
      if (mqttClient.getSubscriptionsStatus(topic) ==
          MqttSubscriptionStatus.doesNotExist) {
        mqttClient.subscribe(topic, MqttQos.exactlyOnce);
      }
    }

    // handle incoming mqtt messages
    if (updatesListener == null) {
      updatesListener = mqttClient.updates?.listen((List<MqttReceivedMessage<MqttMessage>> event) {
      final MqttPublishMessage recMess = event[0].payload as MqttPublishMessage;
      final String message = utf8.decode(recMess.payload.message);
      final topic = event[0].topic;

      _logger.d('topic received ia $topic');

      // might be an RPC response
      if (pendingMqttResponses.containsKey(topic)) {
        // respond to the requestor
        pendingMqttResponses[topic].send(message);

        // clean up completed requestor
        pendingMqttResponses.remove(topic);
        mqttClient.unsubscribe(topic);
      }
      // might be listeners for the topic
      else {
        requestorReceivePort.send([topic, message]);
      }
    });}
  };

  mqttClient.onAutoReconnect = () {
    _iLogger.w('autoReconnected');
    subscribeAndListen();
  };

  mqttClient.onSubscribed = (String topic) {
    //print('Subscription confirmed for topic $topic');
  };
  mqttClient.onUnsubscribed = (String? topic) {
    //print('Unsubscription confirmed for topic $topic');
  };

  mqttClient.onConnected = subscribeAndListen;

  //_iLogger.d('attempt reconnectMqttClient');
  await reconnectMqttClient(mqttClientID, mqttClient, _iLogger);

  // Notify any other isolates what port this isolate listens to.
  var port = new ReceivePort();
  requestorReceivePort.send(port.sendPort);

  // & listen for incoming request messages.
  port.listen((requestMsg) {

    if (mqttClient.connectionStatus?.state != MqttConnectionState.connected) {
      _iLogger.d('not MqttConnectionState.connected');
      // can only send the request once reconnected
      reconnectMqttClient(mqttClientID, mqttClient, _iLogger)
          .then<void>((FutureOr s) {
        sendViaMqtt(mqttClient, pendingMqttResponses, requestMsg);
      });
    }
    else {
      sendViaMqtt(mqttClient, pendingMqttResponses, requestMsg);
    }

  });
}

sendViaMqtt(mqttClient, pendingMqttResponses, requestMsg) {
  final MqttClientPayloadBuilder mqttClientPayloadBuilder = MqttClientPayloadBuilder();
  String topic = RPC_TOPIC;
  String _payload;

  if (requestMsg[0] is Map) {
    // rpc?
    Map op = requestMsg[0];

    // prepare the request details so it can be linked to the Mqtt response when it arrives
    // ...identify each request with a uuid
    // ...use the uuid as key to map response port of requestor
    SendPort respondToPort = requestMsg[1];
    String uuid = Uuid().v1();
    pendingMqttResponses[uuid] = respondToPort;

    // ... also use the uuid as an mqtt topic, and attach it to message for the RPC server to use for responses
    op['replyTopic'] = uuid;
    mqttClient.subscribe(uuid, MqttQos.atMostOnce);

    _payload = jsonEncode(op);
    topic = RPC_TOPIC;
  }
  else {                                // simple send
    _payload = requestMsg[1];
    topic = requestMsg[0];

  }

  //print('publish $topic $_payload');
  mqttClientPayloadBuilder.addUTF8String(_payload);

  mqttClient.publishMessage(
    topic,
    MqttQos.values[0],
    mqttClientPayloadBuilder.payload,
    retain: false,
  );
}

reconnectMqttClient(mqttClientID, mqttClient, _iLogger) async {
  final MqttConnectMessage connMess = MqttConnectMessage()
      .withClientIdentifier(mqttClientID)
      .keepAliveFor(20) // Must agree with the keep alive set above or not set
      .startClean();
  //_iLogger.d('connecting to broker');
  mqttClient.connectionMessage = connMess;

  try {
    await mqttClient.connect();
  } on Exception catch (e) {
    mqttClient.disconnect();
    throw e;                   // TODO crashes here after device resumes from pause app lifecycle state
  }

  if (mqttClient.connectionStatus.state == MqttConnectionState.connected) {
    _iLogger.i('connected to broker');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    _iLogger.e(
        'connection to broker failed - disconnecting, status is ${mqttClient.connectionStatus}');
    mqttClient.disconnect();
  }
}
