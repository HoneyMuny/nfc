import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  ValueNotifier<dynamic> result = ValueNotifier(null);
  late String myString;
  final _controladorn=TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Conectividad NFC'),
          backgroundColor: Colors.amber,
        ),
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: NfcManager.instance.isAvailable(),
            builder: (context, ss) {
              return ss.data != true
                ? Center(
                  child: Text('NfcManager.isAvailable(): ${ss.data}')
              )
                  : Flex(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              direction: Axis.vertical,
              children: [
                Flexible(
                  flex: 2,
                  child: Container(
                    margin: EdgeInsets.all(4),
                    constraints: BoxConstraints.expand(),
                    decoration: BoxDecoration(border: Border.all()),
                    child: SingleChildScrollView(
                      child: ValueListenableBuilder<dynamic>(
                        valueListenable: result,
                        builder: (context, value, _) {
                          switch(result.value.toString()) {
                            case 'sw': {
                              myString ='Mensaje Guardado';
                            }
                            break;
                            case 'nw': {
                              myString ='No se puede escribir en TAG';
                            }
                            break;
                            default: {
                              Map<String, dynamic>? myMap = result.value is Map<String, dynamic> ? result.value as Map<String, dynamic> : null;
                              List<dynamic> myList = myMap?['ndef']['cachedMessage']['records'][0]['payload']!= null ? List.from(myMap?['ndef']['cachedMessage']['records'][0]['payload'] ) : [];
                              print("---*****------------***");
                              print(myList.toString());
                              myString = String.fromCharCodes(myList.map((e) {
                                return e as int;
                              }));
                            }
                            break;
                          }
                          return Text('${myString ?? ''!}');
                        },
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(10.00)),
                TextField(
                  controller: _controladorn,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Texto a guardar en Tag"
                  ),
                ),
                Padding(padding: EdgeInsets.all(10.00)),
                Flexible(
                  flex: 3,
                  child: GridView.count(
                    padding: EdgeInsets.all(4),
                    crossAxisCount: 2,
                    childAspectRatio: 4,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber, // Background color
                          ),
                           child: Text('Leer TAG'),
                            onPressed: _leerTag
                      ),

                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber, // Background color
                          ),
                          child: Text('Escribir en TAG'),
                          onPressed: _escribirTag
                      ),
                    ],
                  ),
                ),
              ],
            );
            },
          ),
        ),
      ),
    );
  }

  void _leerTag() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      result.value = tag.data;
      print(result.value.toString());
      NfcManager.instance.stopSession();
    });
  }

  void _escribirTag() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'nw';//'Tag is not ndef writable';
        print('///////////////'+result.value.toString());
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }
      NdefMessage message = NdefMessage([
      // NdefRecord.createText('INSTITUTO TECNOLOGICO DE DURANGO')
        NdefRecord.createText(_controladorn.text)
      ]);

      try {
        await ndef.write(message);
        result.value = 'sw';
        print('///////////////'+result.value.toString());
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
  }
}