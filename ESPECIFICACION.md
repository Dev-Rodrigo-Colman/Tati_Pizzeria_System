# Especificación del proyecto: sistema de caja y stock para Tati Pizzas

Documento pensado para pasarle a un asistente de programación (Antigravity) y que construya el proyecto completo.

## 1. Contexto

Tati Pizzas es una pizzería en Paraguay con **dos locales (Itauguá y Capiatá)**. Hoy no tiene ningún sistema informático y **no cuenta con notebook ni PC**: todo se manejará desde el **teléfono**. El local tiene WiFi estable. Por ahora la única usuaria es la **dueña**, pero el sistema debe poder crecer a más usuarios y, en el futuro, usarse también desde una PC.

La moneda es el **guaraní (Gs)**, sin decimales. Los precios se guardan como enteros.

## 2. Objetivo

Controlar principalmente la **caja** y el **stock** de ambos locales, registrando las ventas del día y descontando automáticamente los insumos según la receta de cada producto.

## 3. Stack y arquitectura

- **Backend:** PHP (sin framework pesado, con PDO) y **MySQL**.
- **Frontend:** **PWA** responsive, pensada primero para celular (botones grandes, formularios simples, listas y tarjetas en vez de tablas anchas) y que se adapte a pantallas grandes con CSS responsive.
- **Instalable** desde el navegador (manifest + Service Worker), sin tienda de apps.
- **API JSON** entre la PWA y el servidor.
- Hosting compartido económico (compatible con PHP y MySQL estándar).

## 4. Funcionalidades (módulos)

### 4.1 Ventas

- Registrar una venta eligiendo productos, variante (tamaño y borde, si corresponde) y cantidad.
- Forma de pago: efectivo, transferencia o tarjeta.
- Cada venta queda asociada a un local, a un usuario, a un dispositivo y a la caja abierta.
- Posibilidad de anular una venta (queda registrada, no se borra) y que se revierta el descuento de stock.

### 4.2 Caja diaria (por local)

- Apertura con monto inicial.
- Ingresos y egresos manuales (gastos, retiros) con motivo.
- Cierre: compara el monto esperado (inicial + ventas en efectivo + ingresos - egresos) contra el monto contado y muestra la diferencia.
- Solo un dispositivo es responsable de la caja de cada local por turno.

### 4.3 Stock (por local)

- Insumos con unidad, stock actual y stock mínimo.
- El stock **nunca se edita directamente**: se calcula a partir de movimientos (compra, venta, ajuste, transferencia, anulación).
- Al vender, se descuentan los insumos según la **receta** del producto.
- Alerta de stock bajo cuando un insumo llega al mínimo.
- **Transferencias entre locales:** un movimiento de salida en un local y uno de entrada en el otro.
- Empezar con los insumos clave (masa, muzzarella, salsa, cajas, bebidas) y poder ampliar después.

### 4.4 Reportes

- Ventas del día y de la semana, por local y consolidadas.
- Insumos con stock bajo / qué hay que comprar.
- Resumen de caja por día.
- Diseñados para pantalla chica (tarjetas y listas).

## 5. Multi-local y usuarios

- Tabla **locales**: Itauguá y Capiatá. Caja, stock y ventas se separan por `local_id`.
- Catálogo (productos, variantes y precios) **único y compartido** entre los dos locales.
- **Login con selección de local:** después de autenticarse, el usuario elige el local activo (Itauguá o Capiatá). El nombre del local y un color distinto por local se muestran siempre en el encabezado. Ventas, caja y stock se registran siempre en el local activo.
- **Reportes con selector:** Itauguá, Capiatá o Todos (consolidado con desglose por local). La vista "Todos" es solo de lectura y no permite registrar ventas.
- Tabla **usuarios** con **rol** desde el inicio (por ahora solo `admin` para la dueña, que accede a ambos locales; luego `cajero`, `cocina`). Tabla **usuario\_locales** para asignar cada usuario futuro a sus locales: solo ve los suyos. Permisos por rol y por local validados **en el servidor**, no solo ocultando botones.
- Login con usuario y contraseña (hash con `password_hash`), sesión segura y protección contra fuerza bruta (tabla de intentos de acceso).

## 6. Modo sin internet y sincronización

- **Service Worker** para que la app abra sin conexión.
- Datos locales en **IndexedDB**. Ventas y movimientos se guardan con estado `pendiente`.
- Al volver la conexión, se envían automáticamente al servidor.
- Cada registro se crea con un **UUID generado en el dispositivo** (no autoincremental) para evitar choques.
- El servidor debe ser **idempotente**: si recibe un registro que ya tiene, lo ignora (no duplica).
- Como stock y caja se calculan por movimientos, unir datos de varios dispositivos es seguro (solo se suman movimientos).
- Indicador visible: "N registros sin sincronizar".
- Cada registro lleva `local_id`, `usuario_id`, `dispositivo_id` y fecha/hora del dispositivo.

## 7. Modelo de datos sugerido

- **locales**: id, nombre, activo.
- **usuarios**: id, nombre, usuario, password\_hash, rol, activo.
- **log\_intentos**: id, usuario, ip, fecha, exito.
- **categorias**: id, nombre.
- **productos**: id, categoria\_id, nombre, descripcion, activo.
- **producto\_variantes**: id, producto\_id, tamano\_porciones (nullable), con\_borde (nullable), precio.
- **insumos**: id, nombre, unidad, stock\_minimo.
- **recetas**: producto\_id, variante\_id (nullable), insumo\_id, cantidad.
- **ventas**: uuid, local\_id, usuario\_id, dispositivo\_id, caja\_uuid, fecha, total, forma\_pago, estado (activa o anulada).
- **venta\_detalle**: venta\_uuid, variante\_id, cantidad, precio\_unitario.
- **cajas**: uuid, local\_id, usuario\_id, fecha, monto\_inicial, monto\_contado, estado (abierta o cerrada).
- **movimientos\_caja**: uuid, caja\_uuid, tipo (ingreso o egreso), monto, motivo, fecha.
- **movimientos\_stock**: uuid, local\_id, insumo\_id, tipo (compra, venta, ajuste, transferencia\_entrada, transferencia\_salida, anulacion), cantidad, referencia, fecha.

* **usuario\_locales**: usuario\_id, local\_id.

El stock actual de un insumo en un local es la suma de sus movimientos.

## 8. Menú de Tati Pizzas (datos para cargar)

### Pizzas (precio según categoría, tamaño y borde)

| Categoría | 8 porciones sin borde | 12 porciones sin borde | 8 porciones con borde | 12 porciones con borde |
| --- | --- | --- | --- | --- |
| Tradicionales | 30.000 | 45.000 | 40.000 | 50.000 |
| Especiales | 35.000 | 45.000 | 40.000 | 50.000 |
| Premium | 35.000 | 45.000 (por confirmar) | 45.000 | 55.000 |

**Excepción:** la **Muzzarella** (tradicional) tiene **precio único de 25.000 Gs**, sin variantes de tamaño ni borde.

Nota: los precios de Premium se leyeron de una foto borrosa; confirmar con la dueña antes de producción.

**Tradicionales**

- Muzzarella: salsa, muzzarella, aceitunas, orégano
- Katupiry: salsa, muzzarella, pollo, katupiry, aceituna, orégano
- Pepperoni: salsa, muzzarella, pepperoni, aceitunas, orégano
- Margarita: salsa, muzzarella, cebolla salteada, tomate en cubos, orégano
- Choclo: salsa, muzzarella, choclo, orégano
- Jamón: salsa, muzzarella, jamón, orégano
- Palmito: salsa, muzzarella, palmito, orégano
- Mexicana: salsa picante, chorizo picante, muzzarella, tomate en rodajas, locote en tiras, aceituna, orégano
- Napolitana: salsa, jamón, muzzarella, tomate en rodajas, pincelada de salsa de ajo, aceitunas, orégano

**Especiales**

- Italiana: salsa, jamón, muzzarella, tomate en cubos, orégano
- Brasilera: salsa, muzzarella, choclo, panceta, orégano
- Primavera: salsa, muzzarella, cebolla, tomate, choclo, albahaca, orégano
- Salchicha: salsa, muzzarella, abundante salchicha, orégano
- Salchicha con vegetales: salsa, muzzarella, cebolla, tomate, locote, salchicha, orégano
- Española: salsa, jamón, chorizo viena, tomate, locote, muzzarella, pepperoni, orégano

**Premium**

- Pizza 4 quesos: salsa, muzzarella, katupiry, roquefort, queso rallado, orégano
- Sabor de la casa: salsa, muzzarella, tomate en cubos, cebolla morada en rodajas, lomo de res en tiras, aceituna, orégano
- Carnívora: salsa, jamón, chorizo viena, muzzarella, pepperoni, panceta, orégano
- Pizza de sardinas: salsa, muzzarella, filetes de sardina, tomate en rodajas, cebolla blanca, orégano

### Papas

- Papas clásicas: 15.000 Gs
- Papas con cheddar: 18.000 Gs
- Papas con katupiry: 18.000 Gs
- Salchipapas con cheddar: 20.000 Gs
- Papas premium (papas fritas con queso cheddar y trocitos de panceta): 20.000 Gs

### Hamburguesas

- Pequeña (pan, carne, cheddar): 10.000 Gs
- Completa (pan, carne, cheddar, huevo, lechuga, tomate, cebolla morada): 15.000 Gs
- Parrillera (pan, parrillera, cheddar, huevo, lechuga, tomate, cebolla morada): 18.000 Gs

### Bebidas

- Agua 500 ml: 5.000 Gs
- Gaseosa personal: 5.000 Gs
- Gaseosa 500 ml: 8.000 Gs
- Gaseosa 1 L: 10.000 Gs
- Gaseosa 1,5 L: 13.000 Gs
- Gaseosa 2 L: 15.000 Gs
- Bud lata: 7.000 Gs
- Bud botella: 17.000 Gs
- Miller botella: 15.000 Gs
- Fernet cola: 15.000 Gs
- Whiscola: 15.000 Gs
- Caipiriña: 15.000 Gs
- Mojito: 18.000 Gs
- Jarra de caipiriña: 45.000 Gs

Las bebidas envasadas se descuentan 1 a 1 (el producto es a la vez el insumo, sin receta).

## 9. Recetas (cantidades)

Las cantidades exactas de cada insumo por pizza y por tamaño (por ejemplo, cuánta muzzarella lleva una de 8 y una de 12 porciones) **no están definidas**: deben cargarse con la dueña. El sistema debe permitir editar recetas desde la app y funcionar aunque una receta aún esté vacía.

## 10. Seguridad

- Consultas con PDO y parámetros (sin concatenar SQL).
- Contraseñas con `password_hash`.
- Sesiones seguras, CSRF en formularios y API autenticada.
- Validación de permisos por rol en el servidor.
- HTTPS obligatorio en producción.

## 11. Entregables esperados

1. Script SQL con todas las tablas y el menú cargado (categorías, productos, variantes y precios).
2. Backend PHP con la API.
3. PWA con manifest y Service Worker, funcionando offline con sincronización.
4. Pantallas: login, selector de local, nueva venta, caja, stock, recetas, reportes.
5. Instrucciones de instalación y despliegue en hosting compartido.
6. Usuario admin inicial para la dueña.

## 12. Puntos por confirmar con la dueña

- Precios exactos de las pizzas Premium (la foto del menú estaba borrosa).
- Cantidades de insumos por receta y por tamaño.
- Lista inicial de insumos y su stock mínimo.
- Confirmar que ambos locales usan el mismo menú y precios (se asumió que sí).
