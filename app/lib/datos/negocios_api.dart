import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../dominio/excepciones.dart';
import '../dominio/negocio.dart';

class NegociosApi {
  final http.Client _cliente;
  final String baseUrl;
  final Duration espera;

  NegociosApi(this._cliente, this.baseUrl,
      {this.espera = const Duration(seconds: 5)});

  static const _json = {'Content-Type': 'application/json'};

  Future<List<Negocio>> listar() async {
    final r = await _ejecutar(() => _cliente.get(Uri.parse('$baseUrl/negocios')));
    try {
      final lista = jsonDecode(r.body) as List;
      return lista
          .map((e) => Negocio.desdeJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw RespuestaInvalidaException();
    }
  }

  Future<Negocio> crear(Negocio n) async {
    final r = await _ejecutar(() => _cliente.post(
          Uri.parse('$baseUrl/negocios'),
          headers: _json,
          body: jsonEncode(n.aJson()),
        ));
    return _leerUno(r);
  }

  Future<Negocio> actualizar(Negocio n) async {
    final r = await _ejecutar(() => _cliente.put(
          Uri.parse('$baseUrl/negocios/${n.id}'),
          headers: _json,
          body: jsonEncode(n.aJson()),
        ));
    return _leerUno(r);
  }

  Future<void> eliminar(int id) async {
    await _ejecutar(() => _cliente.delete(Uri.parse('$baseUrl/negocios/$id')));
  }

  Negocio _leerUno(http.Response r) {
    try {
      return Negocio.desdeJson(jsonDecode(r.body) as Map<String, dynamic>);
    } catch (_) {
      throw RespuestaInvalidaException();
    }
  }

  Future<http.Response> _ejecutar(
      Future<http.Response> Function() peticion) async {
    http.Response respuesta;
    try {
      respuesta = await peticion().timeout(espera);
    } on SocketException {
      throw SinConexionException();
    } on TimeoutException {
      throw SinConexionException();
    } on http.ClientException {
      throw SinConexionException();
    }
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw ErrorServidorException(respuesta.statusCode);
    }
    return respuesta;
  }
}