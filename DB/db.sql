-- ================================
--  BD Paquexpress
-- ================================

-- 1. Crear base de datos
CREATE DATABASE IF NOT EXISTS paquexpress_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE paquexpress_db;

-- 2. Tabla de usuarios (agentes)
DROP TABLE IF EXISTS entregas;
DROP TABLE IF EXISTS asignaciones;
DROP TABLE IF EXISTS paquetes;
DROP TABLE IF EXISTS usuarios;

CREATE TABLE usuarios (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol VARCHAR(50) NOT NULL DEFAULT 'agente',
  activo TINYINT(1) NOT NULL DEFAULT 1,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de paquetes
CREATE TABLE paquetes (
  id_paquete INT AUTO_INCREMENT PRIMARY KEY,
  codigo_rastreo VARCHAR(50) NOT NULL UNIQUE,
  direccion_destino VARCHAR(255) NOT NULL,
  lat_destino DECIMAL(10,8) NULL,
  lng_destino DECIMAL(11,8) NULL,
  estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',  -- pendiente | entregado
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla de asignaciones
CREATE TABLE asignaciones (
  id_asignacion INT AUTO_INCREMENT PRIMARY KEY,
  id_paquete INT NOT NULL,
  id_usuario INT NOT NULL,
  fecha_asignacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_asig_paquete
    FOREIGN KEY (id_paquete) REFERENCES paquetes(id_paquete)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_asig_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- 5. Tabla de entregas
CREATE TABLE entregas (
  id_entrega INT AUTO_INCREMENT PRIMARY KEY,
  id_paquete INT NOT NULL,
  id_usuario INT NOT NULL,
  fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lat_entrega DECIMAL(10,8) NOT NULL,
  lng_entrega DECIMAL(11,8) NOT NULL,
  foto_url VARCHAR(255) NOT NULL,
  observaciones TEXT NULL,
  CONSTRAINT fk_entrega_paquete
    FOREIGN KEY (id_paquete) REFERENCES paquetes(id_paquete)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_entrega_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- ======================================================
-- 6. Datos de ejemplo (usuarios, paquetes, asignaciones)
-- ======================================================

-- Hash SHA-256 para la contraseña 123456:
-- 8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92

-- 6.1 Usuario Agente de prueba
INSERT INTO usuarios (nombre, email, password_hash, rol, activo)
VALUES
('Agente Prueba', 'agente@paquexpress.com',
 '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
 'agente', 1);

-- 6.2 Usuario Brandon
INSERT INTO usuarios (nombre, email, password_hash, rol, activo)
VALUES
('Brandon Zúñiga', 'brandon@gmail.com',
 '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
 'agente', 1);

-- 6.3 Variables de IDs de usuarios
SET @id_agente := (
  SELECT id_usuario FROM usuarios
  WHERE email = 'agente@paquexpress.com' LIMIT 1
);

SET @id_brandon := (
  SELECT id_usuario FROM usuarios
  WHERE email = 'brandon@gmail.com' LIMIT 1
);

-- 6.4 Paquetes de ejemplo del agente de prueba
INSERT INTO paquetes (codigo_rastreo, direccion_destino)
VALUES
('PKG-001', 'Av. Principal #123, Ciudad de Prueba'),
('PKG-002', 'Calle Secundaria #456, Colonia Centro'),
('PKG-003', 'Privada de los Pinos #789, Zona Norte');

-- 6.5 Asignar PKG-001..003 al agente de prueba
INSERT INTO asignaciones (id_paquete, id_usuario)
SELECT p.id_paquete, @id_agente
FROM paquetes p
WHERE p.codigo_rastreo IN ('PKG-001', 'PKG-002', 'PKG-003');

-- ======================================================
-- 7. Paquetes y entregas de prueba para Brandon
-- ======================================================

-- 7.1 Paquetes BR-001..BR-005 para Brandon
INSERT INTO paquetes (codigo_rastreo, direccion_destino, lat_destino, lng_destino, estado)
VALUES
('BR-001', 'Av. Universidad #1001, Col. Centro, Querétaro, Qro.',  20.593100, -100.389500, 'pendiente'),
('BR-002', 'Blvd. Bernardo Quintana #2500, Querétaro, Qro.',       20.603500, -100.392800, 'pendiente'),
('BR-003', 'Col. El Mirador, Calle Vista Real #45, Querétaro',     20.569800, -100.334200, 'pendiente'),
('BR-004', 'Col. Juriquilla, Calle Lago de Chapala #12, Qro.',     20.704500, -100.447300, 'pendiente'),
('BR-005', 'Col. Satélite, Calle Andrómeda #321, Querétaro, Qro.', 20.604800, -100.400700, 'pendiente');

-- 7.2 Variables con IDs de paquetes BR-00X
SET @pkg1 := (SELECT id_paquete FROM paquetes WHERE codigo_rastreo = 'BR-001' LIMIT 1);
SET @pkg2 := (SELECT id_paquete FROM paquetes WHERE codigo_rastreo = 'BR-002' LIMIT 1);
SET @pkg3 := (SELECT id_paquete FROM paquetes WHERE codigo_rastreo = 'BR-003' LIMIT 1);
SET @pkg4 := (SELECT id_paquete FROM paquetes WHERE codigo_rastreo = 'BR-004' LIMIT 1);
SET @pkg5 := (SELECT id_paquete FROM paquetes WHERE codigo_rastreo = 'BR-005' LIMIT 1);

-- 7.3 Asignar todos los paquetes BR-00X a Brandon
INSERT INTO asignaciones (id_paquete, id_usuario)
VALUES
(@pkg1, @id_brandon),
(@pkg2, @id_brandon),
(@pkg3, @id_brandon),
(@pkg4, @id_brandon),
(@pkg5, @id_brandon);

-- 7.4 Entregas simuladas para BR-001 y BR-002

INSERT INTO entregas (
  id_paquete,
  id_usuario,
  fecha_hora,
  lat_entrega,
  lng_entrega,
  foto_url,
  observaciones
)
VALUES
(
  @pkg1,
  @id_brandon,
  NOW() - INTERVAL 1 DAY,
  20.593200,
  -100.389600,
  'fotos/demo_br_001.jpg',
  'Entrega simulada de prueba. Cliente recibió el paquete en puerta principal.'
),
(
  @pkg2,
  @id_brandon,
  NOW() - INTERVAL 2 HOUR,
  20.603600,
  -100.392900,
  'fotos/demo_br_002.jpg',
  'Entrega simulada de prueba. Paquete entregado en recepción.'
);

-- 7.5 Actualizar estado de paquetes de Brandon
UPDATE paquetes
SET estado = 'entregado'
WHERE codigo_rastreo IN ('BR-001', 'BR-002');

UPDATE paquetes
SET estado = 'pendiente'
WHERE codigo_rastreo IN ('BR-003', 'BR-004', 'BR-005');

-- ======================================================
-- RESULTADO ESPERADO:
-- Usuario 1 (probable): agente@paquexpress.com / 123456
-- Usuario 2 (probable): brandon@gmail.com / 123456
--
-- Agente Prueba:
--   - Tiene asignados PKG-001, PKG-002, PKG-003.
--
-- Brandon:
--   - Tiene asignados BR-001..BR-005.
--   - BR-001 y BR-002 aparecen como entregados (tienen registros en ENTREGAS).
--   - BR-003, BR-004 y BR-005 aparecen como "pendiente" para probar en la app.
-- ======================================================
