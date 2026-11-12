const http = require('http');

let siguienteId = 6;
const negocios = [
  { id: 1, nombre: 'Nieves de la Plaza', categoria: 'Nevería', telefono: '418-100-0001', favorito: true },
  { id: 2, nombre: 'Talavera La Esperanza', categoria: 'Artesanías', telefono: '418-100-0002', favorito: false },
  { id: 3, nombre: 'Tacos Don Chema', categoria: 'Comida', telefono: '418-100-0003', favorito: false },
  { id: 4, nombre: 'Dulces Cajeta Real', categoria: 'Dulcería', telefono: '418-100-0004', favorito: true },
  { id: 5, nombre: 'Papelería El Cura', categoria: 'Papelería', telefono: '418-100-0005', favorito: false },
];

function responder(res, codigo, datos) {
  res.writeHead(codigo, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(datos === undefined ? '' : JSON.stringify(datos));
}

function leerCuerpo(req) {
  return new Promise((resolver, rechazar) => {
    let texto = '';
    req.on('data', (pedazo) => (texto += pedazo));
    req.on('end', () => {
      try {
        resolver(texto ? JSON.parse(texto) : {});
      } catch (e) {
        rechazar(e);
      }
    });
  });
}

const servidor = http.createServer(async (req, res) => {
  console.log(req.method, req.url);

  const partes = req.url.split('/').filter(Boolean);
  if (partes[0] !== 'negocios') {
    return responder(res, 404, { error: 'Ruta no encontrada' });
  }
  const id = partes[1] ? Number(partes[1]) : null;

  try {
    // GET /negocios
    if (req.method === 'GET' && id === null) {
      return responder(res, 200, negocios);
    }

    // GET /negocios/2
    if (req.method === 'GET') {
      const negocio = negocios.find((n) => n.id === id);
      if (!negocio) return responder(res, 404, { error: 'No existe ese negocio' });
      return responder(res, 200, negocio);
    }

    // POST /negocios
    if (req.method === 'POST') {
      const datos = await leerCuerpo(req);
      if (!datos.nombre || !datos.categoria) {
        return responder(res, 400, { error: 'nombre y categoria son obligatorios' });
      }
      const nuevo = {
        id: siguienteId++,
        nombre: datos.nombre,
        categoria: datos.categoria,
        telefono: datos.telefono || '',
        favorito: !!datos.favorito,
      };
      negocios.push(nuevo);
      return responder(res, 201, nuevo);
    }

    // PUT /negocios/3
    if (req.method === 'PUT') {
      const posicion = negocios.findIndex((n) => n.id === id);
      if (posicion < 0) return responder(res, 404, { error: 'No existe ese negocio' });
      const datos = await leerCuerpo(req);
      negocios[posicion] = { ...negocios[posicion], ...datos, id };
      return responder(res, 200, negocios[posicion]);
    }

    // DELETE /negocios/3
    if (req.method === 'DELETE') {
      const posicion = negocios.findIndex((n) => n.id === id);
      if (posicion < 0) return responder(res, 404, { error: 'No existe ese negocio' });
      negocios.splice(posicion, 1);
      return responder(res, 204);
    }

    responder(res, 405, { error: 'Método no permitido' });
  } catch (e) {
    responder(res, 400, { error: 'JSON inválido' });
  }
});

servidor.listen(3000, () => {
  console.log('API lista en http://localhost:3000/negocios');
});