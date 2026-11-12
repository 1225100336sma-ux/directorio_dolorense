import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'datos/negocios_api.dart';
import 'presentacion/negocios_viewmodel.dart';
import 'presentacion/pantalla_negocios.dart';

const urlApi = 'http://192.168.1.101:3000';

void main() {
  final api = NegociosApi(http.Client(), urlApi);
  runApp(MaterialApp(
    title: 'Directorio Dolores',
    theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
    home: PantallaNegocios(vm: NegociosViewModel(api)),
  ));
}
