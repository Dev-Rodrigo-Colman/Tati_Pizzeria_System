SET NAMES utf8mb4;

CREATE TABLE locales (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    color_hex CHAR(7) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_locales_nombre (nombre),
    CONSTRAINT chk_locales_color CHECK (color_hex REGEXP '^#[0-9A-Fa-f]{6}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE usuarios (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(150) NOT NULL,
    usuario VARCHAR(80) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('admin', 'cajero', 'cocina') NOT NULL,
    debe_cambiar_password TINYINT(1) NOT NULL DEFAULT 1,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_usuarios_usuario (usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE usuario_locales (
    usuario_id BIGINT UNSIGNED NOT NULL,
    local_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (usuario_id, local_id),
    CONSTRAINT fk_usuario_locales_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
    CONSTRAINT fk_usuario_locales_local
        FOREIGN KEY (local_id) REFERENCES locales (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE log_intentos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id BIGINT UNSIGNED NULL,
    usuario_ingresado VARCHAR(80) NOT NULL,
    ip VARBINARY(16) NULL,
    fecha TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    exito TINYINT(1) NOT NULL,
    PRIMARY KEY (id),
    KEY idx_log_intentos_usuario_fecha (usuario_id, fecha),
    KEY idx_log_intentos_ip_fecha (ip, fecha),
    CONSTRAINT fk_log_intentos_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categorias (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_categorias_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE productos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    categoria_id BIGINT UNSIGNED NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_productos_categoria_nombre (categoria_id, nombre),
    KEY idx_productos_activo_categoria (activo, categoria_id),
    CONSTRAINT fk_productos_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE producto_variantes (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    producto_id BIGINT UNSIGNED NOT NULL,
    tamano_porciones SMALLINT UNSIGNED NULL,
    con_borde TINYINT(1) NULL,
    tamano_unico SMALLINT UNSIGNED
        GENERATED ALWAYS AS (COALESCE(tamano_porciones, 0)) STORED,
    borde_unico TINYINT UNSIGNED
        GENERATED ALWAYS AS (COALESCE(con_borde, 2)) STORED,
    precio BIGINT UNSIGNED NOT NULL,
    precio_confirmado TINYINT(1) NOT NULL DEFAULT 1,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_variantes_producto (id, producto_id),
    UNIQUE KEY uq_variantes_opcion (producto_id, tamano_unico, borde_unico),
    KEY idx_variantes_producto_activo (producto_id, activo),
    CONSTRAINT chk_variantes_tamano CHECK (tamano_porciones IS NULL OR tamano_porciones > 0),
    CONSTRAINT chk_variantes_borde CHECK (con_borde IS NULL OR con_borde IN (0, 1)),
    CONSTRAINT chk_variantes_precio CHECK (precio > 0),
    CONSTRAINT fk_variantes_producto
        FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE insumos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(150) NOT NULL,
    unidad VARCHAR(30) NOT NULL,
    stock_minimo DECIMAL(14,3) NOT NULL DEFAULT 0,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_insumos_nombre (nombre),
    CONSTRAINT chk_insumos_stock_minimo CHECK (stock_minimo >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE recetas (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    producto_id BIGINT UNSIGNED NOT NULL,
    variante_id BIGINT UNSIGNED NULL,
    variante_unica BIGINT UNSIGNED
        GENERATED ALWAYS AS (COALESCE(variante_id, 0)) STORED,
    insumo_id BIGINT UNSIGNED NOT NULL,
    cantidad DECIMAL(14,3) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_recetas_producto_variante_insumo
        (producto_id, variante_unica, insumo_id),
    KEY idx_recetas_variante (variante_id),
    KEY idx_recetas_insumo (insumo_id),
    CONSTRAINT chk_recetas_cantidad CHECK (cantidad > 0),
    CONSTRAINT fk_recetas_producto
        FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE RESTRICT,
    CONSTRAINT fk_recetas_variante_producto
        FOREIGN KEY (variante_id, producto_id)
        REFERENCES producto_variantes (id, producto_id) ON DELETE RESTRICT,
    CONSTRAINT fk_recetas_insumo
        FOREIGN KEY (insumo_id) REFERENCES insumos (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cajas (
    uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    local_id BIGINT UNSIGNED NOT NULL,
    usuario_id BIGINT UNSIGNED NOT NULL,
    dispositivo_id CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    fecha DATE NOT NULL,
    monto_inicial BIGINT UNSIGNED NOT NULL,
    monto_contado BIGINT UNSIGNED NULL,
    estado ENUM('abierta', 'cerrada') NOT NULL DEFAULT 'abierta',
    abierta_en DATETIME(3) NOT NULL,
    cerrada_en DATETIME(3) NULL,
    local_abierto_id BIGINT UNSIGNED
        GENERATED ALWAYS AS (CASE WHEN estado = 'abierta' THEN local_id ELSE NULL END) STORED,
    PRIMARY KEY (uuid),
    UNIQUE KEY uq_cajas_uuid_local (uuid, local_id),
    UNIQUE KEY uq_cajas_una_abierta_por_local (local_abierto_id),
    KEY idx_cajas_local_fecha (local_id, fecha),
    CONSTRAINT chk_cajas_cierre CHECK (
        (estado = 'abierta' AND monto_contado IS NULL AND cerrada_en IS NULL)
        OR (estado = 'cerrada' AND monto_contado IS NOT NULL AND cerrada_en IS NOT NULL)
    ),
    CONSTRAINT fk_cajas_local
        FOREIGN KEY (local_id) REFERENCES locales (id) ON DELETE RESTRICT,
    CONSTRAINT fk_cajas_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ventas (
    uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    local_id BIGINT UNSIGNED NOT NULL,
    usuario_id BIGINT UNSIGNED NOT NULL,
    dispositivo_id CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    caja_uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    fecha DATETIME(3) NOT NULL,
    recibido_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    total BIGINT UNSIGNED NOT NULL,
    forma_pago ENUM('efectivo', 'transferencia', 'tarjeta') NOT NULL,
    estado ENUM('activa', 'anulada') NOT NULL DEFAULT 'activa',
    anulada_en DATETIME(3) NULL,
    anulada_por BIGINT UNSIGNED NULL,
    PRIMARY KEY (uuid),
    UNIQUE KEY uq_ventas_uuid_local (uuid, local_id),
    KEY idx_ventas_local_fecha_estado (local_id, fecha, estado),
    KEY idx_ventas_caja_pago_estado (caja_uuid, forma_pago, estado),
    KEY idx_ventas_usuario (usuario_id),
    CONSTRAINT chk_ventas_total CHECK (total >= 0),
    CONSTRAINT chk_ventas_anulacion CHECK (
        (estado = 'activa' AND anulada_en IS NULL AND anulada_por IS NULL)
        OR (estado = 'anulada' AND anulada_en IS NOT NULL AND anulada_por IS NOT NULL)
    ),
    CONSTRAINT fk_ventas_caja_local
        FOREIGN KEY (caja_uuid, local_id) REFERENCES cajas (uuid, local_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_anulada_por
        FOREIGN KEY (anulada_por) REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE venta_detalle (
    venta_uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    linea SMALLINT UNSIGNED NOT NULL,
    variante_id BIGINT UNSIGNED NOT NULL,
    cantidad INT UNSIGNED NOT NULL,
    precio_unitario BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (venta_uuid, linea),
    KEY idx_venta_detalle_variante (variante_id),
    CONSTRAINT chk_venta_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_venta_detalle_precio CHECK (precio_unitario > 0),
    CONSTRAINT fk_venta_detalle_venta
        FOREIGN KEY (venta_uuid) REFERENCES ventas (uuid) ON DELETE RESTRICT,
    CONSTRAINT fk_venta_detalle_variante
        FOREIGN KEY (variante_id) REFERENCES producto_variantes (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE movimientos_caja (
    uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    caja_uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    usuario_id BIGINT UNSIGNED NOT NULL,
    dispositivo_id CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    tipo ENUM('ingreso', 'egreso') NOT NULL,
    monto BIGINT UNSIGNED NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    fecha DATETIME(3) NOT NULL,
    recibido_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (uuid),
    KEY idx_movimientos_caja_caja_fecha (caja_uuid, fecha),
    CONSTRAINT chk_movimientos_caja_monto CHECK (monto > 0),
    CONSTRAINT fk_movimientos_caja_caja
        FOREIGN KEY (caja_uuid) REFERENCES cajas (uuid) ON DELETE RESTRICT,
    CONSTRAINT fk_movimientos_caja_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE transferencias (
    uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    local_origen_id BIGINT UNSIGNED NOT NULL,
    local_destino_id BIGINT UNSIGNED NOT NULL,
    usuario_id BIGINT UNSIGNED NOT NULL,
    dispositivo_id CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    fecha DATETIME(3) NOT NULL,
    recibido_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (uuid),
    KEY idx_transferencias_origen_fecha (local_origen_id, fecha),
    KEY idx_transferencias_destino_fecha (local_destino_id, fecha),
    CONSTRAINT chk_transferencias_locales CHECK (local_origen_id <> local_destino_id),
    CONSTRAINT fk_transferencias_origen
        FOREIGN KEY (local_origen_id) REFERENCES locales (id) ON DELETE RESTRICT,
    CONSTRAINT fk_transferencias_destino
        FOREIGN KEY (local_destino_id) REFERENCES locales (id) ON DELETE RESTRICT,
    CONSTRAINT fk_transferencias_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE movimientos_stock (
    uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    local_id BIGINT UNSIGNED NOT NULL,
    insumo_id BIGINT UNSIGNED NOT NULL,
    usuario_id BIGINT UNSIGNED NOT NULL,
    dispositivo_id CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    tipo ENUM(
        'compra',
        'venta',
        'ajuste',
        'transferencia_entrada',
        'transferencia_salida',
        'anulacion'
    ) NOT NULL,
    cantidad DECIMAL(14,3) NOT NULL,
    referencia VARCHAR(255) NULL,
    venta_uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NULL,
    transferencia_uuid CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NULL,
    fecha DATETIME(3) NOT NULL,
    recibido_en TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (uuid),
    KEY idx_movimientos_stock_local_insumo_fecha (local_id, insumo_id, fecha),
    KEY idx_movimientos_stock_venta_local (venta_uuid, local_id),
    UNIQUE KEY uq_movimientos_stock_transferencia_insumo
        (transferencia_uuid, insumo_id, tipo),
    UNIQUE KEY uq_movimientos_stock_venta_insumo_tipo
        (venta_uuid, insumo_id, tipo),
    CONSTRAINT chk_movimientos_stock_cantidad CHECK (cantidad <> 0),
    CONSTRAINT chk_movimientos_stock_sentido CHECK (
        (tipo IN ('compra', 'transferencia_entrada') AND cantidad > 0)
        OR (tipo = 'venta' AND cantidad < 0)
        OR (tipo = 'ajuste')
        OR (tipo = 'anulacion' AND cantidad > 0)
        OR (tipo = 'transferencia_salida' AND cantidad < 0)
    ),
    CONSTRAINT chk_movimientos_stock_referencia CHECK (
        (
            tipo IN ('venta', 'anulacion')
            AND venta_uuid IS NOT NULL
            AND transferencia_uuid IS NULL
        )
        OR (
            tipo IN ('transferencia_entrada', 'transferencia_salida')
            AND venta_uuid IS NULL
            AND transferencia_uuid IS NOT NULL
        )
        OR (
            tipo IN ('compra', 'ajuste')
            AND venta_uuid IS NULL
            AND transferencia_uuid IS NULL
        )
    ),
    CONSTRAINT fk_movimientos_stock_local
        FOREIGN KEY (local_id) REFERENCES locales (id) ON DELETE RESTRICT,
    CONSTRAINT fk_movimientos_stock_insumo
        FOREIGN KEY (insumo_id) REFERENCES insumos (id) ON DELETE RESTRICT,
    CONSTRAINT fk_movimientos_stock_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
    CONSTRAINT fk_movimientos_stock_venta_local
        FOREIGN KEY (venta_uuid, local_id) REFERENCES ventas (uuid, local_id) ON DELETE RESTRICT,
    CONSTRAINT fk_movimientos_stock_transferencia
        FOREIGN KEY (transferencia_uuid) REFERENCES transferencias (uuid) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE VIEW vista_stock_actual AS
SELECT
    l.id AS local_id,
    i.id AS insumo_id,
    i.nombre AS insumo,
    i.unidad,
    i.stock_minimo,
    COALESCE(SUM(ms.cantidad), 0) AS stock_actual,
    (COALESCE(SUM(ms.cantidad), 0) <= i.stock_minimo) AS stock_bajo
FROM locales AS l
CROSS JOIN insumos AS i
LEFT JOIN movimientos_stock AS ms
    ON ms.local_id = l.id
    AND ms.insumo_id = i.id
WHERE l.activo = 1
    AND i.activo = 1
GROUP BY l.id, i.id, i.nombre, i.unidad, i.stock_minimo;
