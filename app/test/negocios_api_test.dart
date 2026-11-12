import 'dart:convert';
import 'dart:io';

import 'package:directorio_dolores/datos/negocios_api.dart';
import 'package:directorio_dolores/dominio/excepciones.dart';
import 'package:directorio_dolores/dominio/negocio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

NegociosApi apiCon(MockClient cliente) => NegociosApi(cliente, 'http://prueba');

void main() {
  test('listar convierte el JSON en objetos Negocio', () async {
    final api = apiCon(MockClient((req) async {
      expect(req.method, 'GET');
      expect(req.url.path, '/negocios');
      return http.Response(
        jsonEncode([
          {'id': 1, 'nombre': 'A', 'categoria': 'X'},
          {'id': 2, 'nombre': 'B', 'categoria': 'Y'},
        ]),
        200,
      );
    }));
    final lista = await api.listar();
    expect(lista.length, 2);
    expect(lista.first.nombre, 'A');
  });

  test('un error 500 lanza ErrorServidorException con el código', () async {
    final api = apiCon(MockClient((_) async => http.Response('boom', 500)));
    await expectLater(
      api.listar(),
      throwsA(isA<ErrorServidorException>()
          .having((e) => e.codigo, 'codigo', 500)),
    );
  });

  test('sin red lanza SinConexionException', () async {
    final api =
        apiCon(MockClient((_) async => throw const SocketException('x')));
    await expectLater(api.listar(), throwsA(isA<SinConexionException>()));
  });

  test('si la API tarda demasiado se trata como sin conexión', () async {
    final api = NegociosApi(
      MockClient((_) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return http.Response('[]', 200);
      }),
      'http://prueba',
      espera: const Duration(milliseconds: 20),
    );
    await expectLater(api.listar(), throwsA(isA<SinConexionException>()));
  });

  test('una respuesta que no es JSON lanza RespuestaInvalidaException',
      () async {
    final api = apiCon(MockClient((_) async => http.Response('<html>', 200)));
    await expectLater(
        api.listar(), throwsA(isA<RespuestaInvalidaException>()));
  });

  test('crear envía un POST con JSON', () async {
    final api = apiCon(MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.headers['Content-Type'], contains('application/json'));
      final cuerpo = jsonDecode(req.body) as Map<String, dynamic>;
      expect(cuerpo['nombre'], 'Nuevo');
      return http.Response(jsonEncode({...cuerpo, 'id': 9}), 201);
    }));
    final creado =
        await api.crear(const Negocio(nombre: 'Nuevo', categoria: 'Z'));
    expect(creado.id, 9);
  });

  test('actualizar envía un PUT a /negocios/ID', () async {
    final api = apiCon(MockClient((req) async {
      expect(req.method, 'PUT');
      expect(req.url.path, '/negocios/3');
      final cuerpo = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode(cuerpo), 200);
    }));
    final r = await api.actualizar(
      const Negocio(id: 3, nombre: 'X', categoria: 'Y', favorito: true),
    );
    expect(r.favorito, true);
  });

  test('eliminar envía un DELETE al id correcto', () async {
    final api = apiCon(MockClient((req) async {
      expect(req.method, 'DELETE');
      expect(req.url.path, '/negocios/4');
      return http.Response('', 204);
    }));
    await api.eliminar(4);
  });
}