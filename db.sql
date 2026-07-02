CREATE DATABASE agro_pacayales;
GO

USE agro_pacayales;
GO

-- ============================================================================
-- 1. TABLAS Y RESTRICCIONES (Fáciles de entender)
-- Usamos 5 tipos de restricciones:
--   1. PRIMARY KEY: Identificador único de cada fila.
--   2. FOREIGN KEY: Relación entre dos tablas.
--   3. UNIQUE: No permite valores duplicados.
--   4. CHECK: Valida que los datos cumplan una condición (ej. no precios negativos).
--   5. DEFAULT: Valor automático si no se ingresa nada.
-- ============================================================================

-- Tabla Maestra: Usuarios
CREATE TABLE usuarios (
    id_usuario INT IDENTITY(1,1) CONSTRAINT PK_usuarios PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL CONSTRAINT UQ_usuarios_correo UNIQUE, -- Restricción UNIQUE (correo único)
    password VARCHAR(255) NOT NULL,
    rol VARCHAR(20) CONSTRAINT DF_usuarios_rol DEFAULT 'OPERADOR', -- Restricción DEFAULT
    fecha_nacimiento DATE NOT NULL,
    fecha_contratacion DATE,
    estado BIT CONSTRAINT DF_usuarios_estado DEFAULT 1,
    
    -- Restricción CHECK: El rol solo puede ser uno de estos tres
    CONSTRAINT CK_usuarios_rol CHECK (rol IN ('ADMIN', 'SUPERVISOR', 'OPERADOR'))
);
GO

-- Tabla Maestra: Parcelas (Terrenos de cultivo)
CREATE TABLE parcelas (
    id_parcela INT IDENTITY(1,1) CONSTRAINT PK_parcelas PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL CONSTRAINT UQ_parcelas_nombre UNIQUE, -- Restricción UNIQUE (nombre único)
    ubicacion VARCHAR(200),
    area_hectareas DECIMAL(10,2) NOT NULL,
    tipo_suelo VARCHAR(80),
    responsable VARCHAR(100),
    estado_riego VARCHAR(50),
    fecha_ultima_siembra DATE,
    produccion_estimada VARCHAR(100),
    cultivo_actual VARCHAR(100),
    observaciones VARCHAR(MAX),
    en_uso BIT CONSTRAINT DF_parcelas_en_uso DEFAULT 0,
    estado BIT CONSTRAINT DF_parcelas_estado DEFAULT 1,
    
    -- Restricción CHECK: El área debe ser mayor a cero
    CONSTRAINT CK_parcelas_area CHECK (area_hectareas > 0.0)
);
GO

-- Tabla Maestra: Insumos (Fertilizantes y Químicos)
CREATE TABLE insumos (
    id_insumo INT IDENTITY(1,1) CONSTRAINT PK_insumos PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(MAX),
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL,
    unidad_medida VARCHAR(20),
    tipo_insumo VARCHAR(50),
    proveedor VARCHAR(100),
    presentacion VARCHAR(100),
    estado BIT CONSTRAINT DF_insumos_estado DEFAULT 1,
    
    -- Restricciones CHECK: El precio y el stock no pueden ser negativos
    CONSTRAINT CK_insumos_precio CHECK (precio >= 0.0),
    CONSTRAINT CK_insumos_stock CHECK (stock >= 0)
);
GO

-- Tabla Transaccional: Cultivos (Sembrados en una Parcela)
CREATE TABLE cultivos (
    id_cultivo INT IDENTITY(1,1) CONSTRAINT PK_cultivos PRIMARY KEY,
    id_parcela INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo_cultivo VARCHAR(80) NOT NULL,
    frecuencia_riego_dias INT NOT NULL,
    temperatura_ideal DECIMAL(5,2) NOT NULL,
    fecha_siembra DATE,
    requiere_sombra BIT CONSTRAINT DF_cultivos_sombra DEFAULT 0,
    observaciones VARCHAR(MAX),
    estado BIT CONSTRAINT DF_cultivos_estado DEFAULT 1,
    
    -- Restricción FOREIGN KEY: Conecta con la tabla Parcelas
    CONSTRAINT FK_cultivos_parcelas FOREIGN KEY (id_parcela) 
        REFERENCES parcelas(id_parcela),
        
    -- Restricción CHECK: La frecuencia de riego no puede ser negativa
    CONSTRAINT CK_cultivos_riego CHECK (frecuencia_riego_dias >= 0)
);
GO

-- Tabla Transaccional: Actividades de Cultivo
CREATE TABLE actividad_cultivo (
    id_actividad INT IDENTITY(1,1) CONSTRAINT PK_actividad PRIMARY KEY,
    id_cultivo INT NOT NULL,
    tipo_actividad VARCHAR(50) NOT NULL,
    descripcion VARCHAR(MAX),
    fecha_actividad DATETIME2 NOT NULL,
    costo_total DECIMAL(10,2) NOT NULL,
    estado BIT CONSTRAINT DF_actividad_estado DEFAULT 1,
    
    -- Restricción FOREIGN KEY: Conecta con la tabla Cultivos
    CONSTRAINT FK_actividad_cultivos FOREIGN KEY (id_cultivo) 
        REFERENCES cultivos(id_cultivo),
        
    -- Restricción CHECK: El costo no puede ser negativo
    CONSTRAINT CK_actividad_costo CHECK (costo_total >= 0.0)
);
GO

-- Tabla Transaccional: Detalle de Actividades (Insumos que se usaron)
CREATE TABLE detalle_actividad (
    id_detalle INT IDENTITY(1,1) CONSTRAINT PK_detalle PRIMARY KEY,
    id_actividad INT NOT NULL,
    id_insumo INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    
    -- Restricciones FOREIGN KEY: Conectan con Actividades e Insumos
    CONSTRAINT FK_detalle_actividad_cabecera FOREIGN KEY (id_actividad) 
        REFERENCES actividad_cultivo(id_actividad) ON DELETE CASCADE,
    CONSTRAINT FK_detalle_actividad_insumo FOREIGN KEY (id_insumo) 
        REFERENCES insumos(id_insumo),
        
    -- Restricciones CHECK: Cantidades mayores a cero
    CONSTRAINT CK_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_detalle_precio CHECK (precio_unitario >= 0.0)
);
GO

-- Tabla Transaccional: Fichas de Campo (Monitoreo Diario de Cultivos)
CREATE TABLE fichas_campo (
    id_ficha INT IDENTITY(1,1) CONSTRAINT PK_fichas PRIMARY KEY,
    id_cultivo INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_fichas_fecha DEFAULT GETDATE(),
    etapa_fenologica VARCHAR(50) NOT NULL,
    temperatura_amb DECIMAL(5,2),
    humedad_relativa DECIMAL(5,2),
    condicion_clima VARCHAR(30),
    estado_cultivo VARCHAR(20) NOT NULL,
    necesita_riego BIT CONSTRAINT DF_fichas_riego DEFAULT 0,
    necesita_fumigacion BIT CONSTRAINT DF_fichas_fumigacion DEFAULT 0,
    diagnostico VARCHAR(MAX),
    accion_tomada VARCHAR(MAX),
    estado BIT CONSTRAINT DF_fichas_estado DEFAULT 1,
    
    -- Restricciones FOREIGN KEY: Conectan con Cultivos y Usuarios
    CONSTRAINT FK_ficha_cultivo FOREIGN KEY (id_cultivo) REFERENCES cultivos(id_cultivo),
    CONSTRAINT FK_ficha_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);
GO

-- Tabla Transaccional: Movimientos de Insumos (Entradas y Salidas de Almacén)
CREATE TABLE movimiento_insumos (
    id_movimiento INT IDENTITY(1,1) CONSTRAINT PK_movimiento PRIMARY KEY,
    id_insumo INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    motivo VARCHAR(50) NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,
    referencia VARCHAR(100),
    fecha_movimiento DATETIME2 NOT NULL CONSTRAINT DF_mov_fecha DEFAULT GETDATE(),
    
    -- Restricciones FOREIGN KEY y CHECK
    CONSTRAINT FK_mov_insumo FOREIGN KEY (id_insumo) REFERENCES insumos(id_insumo),
    CONSTRAINT FK_mov_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    CONSTRAINT CK_mov_tipo CHECK (tipo_movimiento IN ('ENTRADA', 'SALIDA'))
);
GO

-- Tabla Transaccional: Cosechas - Cabecera (harvest)
CREATE TABLE harvest (
    id_harvest    INT IDENTITY(1,1) CONSTRAINT PK_harvest PRIMARY KEY,
    responsable   VARCHAR(100) NOT NULL,
    fecha_cosecha DATE NOT NULL,
    estado        BIT CONSTRAINT DF_harvest_estado DEFAULT 1,
    created_at    DATETIME2 CONSTRAINT DF_harvest_created DEFAULT GETDATE(),
    updated_at    DATETIME2
);
GO

-- Tabla Transaccional: Detalle de Cosecha por Cultivo (harvest_planting_cycle)
CREATE TABLE harvest_planting_cycle (
    id_harvest_detail INT IDENTITY(1,1) CONSTRAINT PK_harvest_detail PRIMARY KEY,
    id_harvest        INT NOT NULL,
    id_cultivo        INT NOT NULL,
    kilos_optimos     DECIMAL(10,2) NOT NULL,
    kilos_merma       DECIMAL(10,2) NOT NULL,

    -- Restricciones FOREIGN KEY: Conectan con harvest y cultivos
    CONSTRAINT FK_harvest_detail_harvest FOREIGN KEY (id_harvest)
        REFERENCES harvest(id_harvest) ON DELETE CASCADE,
    CONSTRAINT FK_harvest_detail_cultivo FOREIGN KEY (id_cultivo)
        REFERENCES cultivos(id_cultivo),

    -- Restricciones CHECK: Los kilos no pueden ser negativos
    CONSTRAINT CK_harvest_kilos_optimos CHECK (kilos_optimos >= 0.0),
    CONSTRAINT CK_harvest_kilos_merma   CHECK (kilos_merma   >= 0.0)
);
GO

-- ============================================================================
-- TABLA: asignacion_cabecera (CORREGIDA)
-- ============================================================================
CREATE TABLE asignacion_cabecera (
    id_asignacion_cabecera  INT             NOT NULL IDENTITY(1,1), -- Cambiado a INT
    id_actividad            INT             NOT NULL,               -- Cambiado a INT para que coincida con actividad_cultivo
    fecha_asignacion        DATETIME        NOT NULL,
    horas_trabajadas        DECIMAL(5,2)    NOT NULL,
    costo_total_mano_obra   DECIMAL(10,2)   NULL,
    observacion             TEXT            NULL,
    estado                  BIT             NOT NULL DEFAULT 1,
    created_at              DATETIME        NULL DEFAULT GETDATE(),

    CONSTRAINT PK_asignacion_cabecera PRIMARY KEY (id_asignacion_cabecera),
    CONSTRAINT FK_asig_cab_actividad  FOREIGN KEY (id_actividad)
        REFERENCES actividad_cultivo(id_actividad),
    CONSTRAINT CK_asig_horas_positivas CHECK (horas_trabajadas > 0)
);
GO

-- ============================================================================
-- TABLA: asignacion_detalle (CORREGIDA)
-- ============================================================================
CREATE TABLE asignacion_detalle (
    id_asignacion_detalle   INT             NOT NULL IDENTITY(1,1), -- Cambiado a INT
    id_asignacion_cabecera  INT             NOT NULL,               -- Cambiado a INT para que coincida con asignacion_cabecera
    id_usuario              INT             NOT NULL,               -- Cambiado a INT para que coincida con usuarios
    costo_mano_obra         DECIMAL(10,2)   NOT NULL,

    CONSTRAINT PK_asignacion_detalle          PRIMARY KEY (id_asignacion_detalle),
    CONSTRAINT FK_asig_det_cabecera           FOREIGN KEY (id_asignacion_cabecera)
        REFERENCES asignacion_cabecera(id_asignacion_cabecera) ON DELETE CASCADE,
    CONSTRAINT FK_asig_det_usuario            FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),
    CONSTRAINT CK_asig_det_costo_positivo     CHECK (costo_mano_obra > 0)
);
GO


-- ============================================================================
-- 2. INSERCIÓN DE DATOS DE PRUEBA
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLAS MAESTRAS (Exactamente 15 registros por cada tabla)
-- ----------------------------------------------------------------------------

-- USUARIOS (15 registros)
INSERT INTO usuarios (nombre, apellido, correo, password, rol, fecha_nacimiento, fecha_contratacion) VALUES
('Hugo', 'Fernandez', 'hugo.fernandez@agropacayales.com', 'ClaveHugo123', 'ADMIN', '1995-04-12', '2026-01-10'),
('Ana', 'Felix', 'ana.felix@agropacayales.com', 'ClaveAna123', 'SUPERVISOR', '1997-08-25', '2026-02-15'),
('Axel', 'Huapaya', 'axel.huapaya@agropacayales.com', 'ClaveAxel123', 'OPERADOR', '1998-11-03', '2026-03-01'),
('Carlos', 'Mendoza', 'carlos.mendoza@agropacayales.com', 'ClaveCarlos123', 'OPERADOR', '1994-06-15', '2026-04-01'),
('Maria', 'Silva', 'maria.silva@agropacayales.com', 'ClaveMaria123', 'SUPERVISOR', '1990-09-20', '2026-04-10'),
('Jose', 'Delgado', 'jose.delgado@agropacayales.com', 'ClaveJose123', 'OPERADOR', '1993-02-18', '2026-04-15'),
('Laura', 'Rodriguez', 'laura.rodriguez@agropacayales.com', 'ClaveLaura123', 'OPERADOR', '1996-07-22', '2026-05-01'),
('Pedro', 'Gomez', 'pedro.gomez@agropacayales.com', 'ClavePedro123', 'OPERADOR', '1991-12-05', '2026-05-10'),
('Sofia', 'Martinez', 'sofia.martinez@agropacayales.com', 'ClaveSofia123', 'SUPERVISOR', '1992-05-30', '2026-05-12'),
('Luis', 'Hernandez', 'luis.hernandez@agropacayales.com', 'ClaveLuis123', 'OPERADOR', '1989-10-14', '2026-05-15'),
('Elena', 'Diaz', 'elena.diaz@agropacayales.com', 'ClaveElena123', 'OPERADOR', '1995-03-25', '2026-05-20'),
('Miguel', 'Castro', 'miguel.castro@agropacayales.com', 'ClaveMiguel123', 'OPERADOR', '1997-01-08', '2026-06-01'),
('Carmen', 'Ruiz', 'carmen.ruiz@agropacayales.com', 'ClaveCarmen123', 'OPERADOR', '1993-11-12', '2026-06-05'),
('Jorge', 'Morales', 'jorge.morales@agropacayales.com', 'ClaveJorge123', 'OPERADOR', '1990-08-19', '2026-06-10'),
('Lucia', 'Ortiz', 'lucia.ortiz@agropacayales.com', 'ClaveLucia123', 'SUPERVISOR', '1992-04-24', '2026-06-12');

-- PARCELAS (15 registros)
INSERT INTO parcelas (nombre, ubicacion, area_hectareas, tipo_suelo, responsable, estado_riego, fecha_ultima_siembra, produccion_estimada, cultivo_actual, en_uso) VALUES
('Lote A - Valle Norte', 'Sector Norte, Km 5', 4.5, 'Arcilloso', 'Ana Felix', 'Goteo', '2026-03-10', '8000 kg', 'Maíz Híbrido', 1),
('Lote B - La Ladera', 'Sector Sur, Zona Alta', 2.0, 'Arenoso', 'Axel Huapaya', 'Aspersión', '2026-04-01', '3500 kg', 'Papa Yungay', 1),
('Lote C - El Plano', 'Sector Este, Plano Bajo', 3.0, 'Limoso', 'Hugo Fernandez', 'Gravedad', NULL, '0 kg', 'Ninguno', 0),
('Lote D - Invernadero', 'Sector Central, Estructura 1', 0.5, 'Franco', 'Maria Silva', 'Goteo', '2026-05-10', '1500 kg', 'Tomates Cherry', 1),
('Lote E - Zona Alta', 'Límite Norte, Sector Alto', 5.0, 'Pedregoso', 'Carlos Mendoza', 'Secano', NULL, '0 kg', 'Ninguno', 0),
('Lote F - Las Flores', 'Sector Sur, Km 8', 1.5, 'Franco Arenoso', 'Jose Delgado', 'Aspersión', '2026-05-12', '1200 kg', 'Hortalizas', 1),
('Lote G - El Mirador', 'Zona Alta, Mirador Este', 2.5, 'Limoso', 'Laura Rodriguez', 'Goteo', '2026-05-14', '2000 kg', 'Maíz Dulce', 1),
('Lote H - Rio Bajo', 'Cerca al Río, Sector Oeste', 3.5, 'Aluvial', 'Pedro Gomez', 'Gravedad', '2026-05-15', '4500 kg', 'Papa Capiro', 1),
('Lote I - La Colina', 'Colina Alta, Zona Central', 1.8, 'Pedregoso', 'Sofia Martinez', 'Aspersión', '2026-05-16', '1100 kg', 'Tomate Italiano', 1),
('Lote J - El Bosque', 'Límite Este, Cerca Bosque', 2.2, 'Franco Arcilloso', 'Luis Hernandez', 'Goteo', '2026-05-18', '1300 kg', 'Lechuga Orgánica', 1),
('Lote K - Los Olivos', 'Sector Central Oeste', 2.8, 'Franco', 'Elena Diaz', 'Goteo', '2026-05-20', '1800 kg', 'Zanahoria', 1),
('Lote L - El Sol', 'Sector Norte Plano', 3.2, 'Arenoso', 'Miguel Castro', 'Aspersión', '2026-05-22', '2200 kg', 'Cebolla Blanca', 1),
('Lote M - La Cuesta', 'Ladera Norte Cuesta', 1.9, 'Pedregoso', 'Carmen Ruiz', 'Secano', '2026-05-24', '800 kg', 'Alfalfa', 1),
('Lote N - Arenales', 'Sector Oeste Seco', 4.0, 'Arenoso', 'Jorge Morales', 'Goteo', '2026-05-26', '1600 kg', 'Ajo', 1),
('Lote O - El Manantial', 'Cerca Manantial Norte', 2.1, 'Limoso', 'Lucia Ortiz', 'Gravedad', '2026-05-28', '1400 kg', 'Ají Picante', 1);

-- INSUMOS (15 registros)
INSERT INTO insumos (nombre, descripcion, precio, stock, unidad_medida, tipo_insumo, proveedor, presentacion) VALUES
('Fertilizante NPK', 'Fertilizante rico en nutrientes básicos', 45.00, 100, 'kg', 'FERTILIZANTE', 'AgroQuímica S.A.', 'Saco 50kg'),
('Urea Granulada', 'Nitrógeno concentrado para crecimiento rápido', 35.00, 120, 'kg', 'FERTILIZANTE', 'Abonos del Sur', 'Saco 50kg'),
('Herbicida Orgánico', 'Control de maleza sin dañar la tierra', 60.00, 30, 'litro', 'HERBICIDA', 'BioCrops', 'Galón 5L'),
('Semilla de Maíz', 'Semilla seleccionada de alto rendimiento', 110.00, 25, 'saco', 'SEMILLA', 'Semillas Gold', 'Saco 20kg'),
('Fungicida Cúprico', 'Preventivo de hongos en hojas', 55.00, 45, 'litro', 'FUNGICIDA', 'EcoAgro', 'Botella 1L'),
('Semilla de Papa', 'Tubérculo semilla certificado', 85.00, 60, 'saco', 'SEMILLA', 'Paperos del Valle', 'Saco 40kg'),
('Insecticida Neem', 'Extracto natural contra pulgones', 40.00, 50, 'litro', 'INSECTICIDA', 'BioControl', 'Botella 1L'),
('Compost Orgánico', 'Abono orgánico fermentado', 15.00, 300, 'kg', 'FERTILIZANTE', 'TierraSana', 'Bolsa 25kg'),
('Humus de Lombriz', 'Nutrientes de alta asimilación', 25.00, 200, 'kg', 'FERTILIZANTE', 'EcoLombriz', 'Bolsa 25kg'),
('Semilla de Tomate', 'Semillas híbridas certificadas', 120.00, 15, 'saco', 'SEMILLA', 'Semillas Gold', 'Saco 5kg'),
('Semilla de Alfalfa', 'Semilla de alfalfa variedad nacional', 95.00, 40, 'saco', 'SEMILLA', 'Forrajes del Norte', 'Saco 10kg'),
('Sulfato de Cobre', 'Fungicida y desinfectante de suelo', 30.00, 70, 'kg', 'FUNGICIDA', 'EcoAgro', 'Bolsa 10kg'),
('Azufre Mojable', 'Control de ácaros y oídio', 28.00, 80, 'kg', 'FUNGICIDA', 'Química del Agro', 'Saco 25kg'),
('Semilla de Cebolla', 'Semilla de cebolla roja norteña', 105.00, 18, 'saco', 'SEMILLA', 'Semillas Gold', 'Saco 5kg'),
('Fertilizante Foliar', 'Nutrientes líquidos para hojas', 50.00, 60, 'litro', 'FERTILIZANTE', 'EcoAgro', 'Bidón 5L');


-- ----------------------------------------------------------------------------
-- TABLAS TRANSACCIONALES (Exactamente 15 registros por cada tabla clave)
-- ----------------------------------------------------------------------------

-- CULTIVOS (15 registros)
INSERT INTO cultivos (id_parcela, nombre, tipo_cultivo, frecuencia_riego_dias, temperatura_ideal, fecha_siembra) VALUES
(1, 'Maíz Primavera', 'Maíz', 4, 25.00, '2026-03-10'),
(2, 'Papa Invierno', 'Papa', 6, 18.00, '2026-04-01'),
(1, 'Hortalizas Orgánicas', 'Hortalizas', 2, 22.00, '2026-05-15'),
(4, 'Tomates Cherry Invernadero', 'Tomate', 1, 24.00, '2026-05-10'),
(3, 'Alfalfa Forrajera', 'Alfalfa', 7, 20.00, '2026-05-11'),
(5, 'Cebolla Roja', 'Cebolla', 5, 21.00, '2026-05-12'),
(6, 'Maíz Dulce Lote F', 'Maíz', 4, 25.00, '2026-05-13'),
(7, 'Papa Capiro Lote G', 'Papa', 6, 19.00, '2026-05-14'),
(8, 'Tomate Italiano Lote H', 'Tomate', 2, 23.00, '2026-05-15'),
(9, 'Lechuga Orgánica Lote I', 'Lechuga', 2, 20.00, '2026-05-16'),
(10, 'Zanahoria Lote J', 'Zanahoria', 3, 21.00, '2026-05-17'),
(11, 'Cebolla Blanca Lote K', 'Cebolla', 5, 22.00, '2026-05-18'),
(12, 'Alfalfa Lote L', 'Alfalfa', 7, 20.00, '2026-05-19'),
(13, 'Ajo Lote M', 'Ajo', 8, 19.00, '2026-05-20'),
(14, 'Ají Picante Lote N', 'Ají', 3, 26.00, '2026-05-21');

-- ACTIVIDADES DE CULTIVO (15 registros)
INSERT INTO actividad_cultivo (id_cultivo, tipo_actividad, descripcion, fecha_actividad, costo_total) VALUES
(1, 'Abonado', 'Primera aplicación de fertilizante NPK', '2026-03-25 08:00:00', 135.00),
(2, 'Fumigación', 'Control preventivo de plagas en papa', '2026-04-15 09:00:00', 60.00),
(1, 'Riego', 'Ajuste del goteo por clima cálido', '2026-05-20 10:00:00', 40.00),
(3, 'Deshierbe', 'Limpieza manual de maleza entre surcos', '2026-05-28 07:00:00', 55.00),
(4, 'Riego Invernadero', 'Control diario de goteo en tomates', '2026-05-11 08:00:00', 15.00),
(5, 'Corte de Alfalfa', 'Primer corte de forraje verde', '2026-06-01 07:30:00', 80.00),
(6, 'Control de Maleza', 'Aplicación de herbicida orgánico', '2026-05-20 09:00:00', 90.00),
(7, 'Abonado de Maíz', 'Dosis de refuerzo de urea granulada', '2026-05-25 08:00:00', 110.00),
(8, 'Deshierbe Papa', 'Limpieza manual de maleza en papas', '2026-05-26 07:00:00', 70.00),
(9, 'Fumigación Tomate', 'Aplicación de fungicida cúprico en hojas', '2026-05-27 09:00:00', 65.00),
(10, 'Riego Lechugas', 'Riego manual matutino en lechugas', '2026-05-28 08:00:00', 20.00),
(11, 'Riego Zanahorias', 'Riego automatizado por aspersión', '2026-05-29 08:00:00', 25.00),
(12, 'Fertilización Cebollas', 'Dosis de NPK diluido en agua de riego', '2026-05-30 08:30:00', 120.00),
(13, 'Corte Alfalfa Lote L', 'Segundo corte periódico de alfalfa', '2026-06-02 07:00:00', 85.00),
(14, 'Abonado Ajos', 'Aplicación superficial de compost orgánico', '2026-06-03 08:00:00', 50.00);

-- DETALLE DE ACTIVIDADES (15 registros)
INSERT INTO detalle_actividad (id_actividad, id_insumo, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 3, 45.00, 135.00), (2, 3, 1, 60.00, 60.00), (3, 2, 2, 35.00, 70.00), (4, 5, 1, 55.00, 55.00),
(5, 1, 1, 45.00, 45.00), (6, 7, 2, 40.00, 80.00), (7, 3, 1, 60.00, 60.00), (8, 2, 3, 35.00, 105.00),
(9, 5, 1, 55.00, 55.00), (10, 8, 2, 15.00, 30.00), (11, 1, 2, 45.00, 90.00), (12, 1, 2, 45.00, 90.00),
(13, 9, 3, 25.00, 75.00), (14, 8, 3, 15.00, 45.00), (15, 12, 2, 30.00, 60.00);

-- FICHAS DE CAMPO (15 registros)
INSERT INTO fichas_campo (id_cultivo, id_usuario, etapa_fenologica, temperatura_amb, humedad_relativa, condicion_clima, estado_cultivo, necesita_riego, necesita_fumigacion, diagnostico, accion_tomada) VALUES
(1, 3, 'Crecimiento', 26.0, 60.0, 'Despejado', 'Bueno', 0, 0, 'Plantas creciendo sanas', 'Monitoreo visual'),
(2, 3, 'Floración', 18.0, 70.0, 'Nublado', 'Regular', 1, 0, 'Suelo seco', 'Se programó riego'),
(3, 4, 'Brote inicial', 22.0, 65.0, 'Soleado', 'Excelente', 0, 0, 'Buena germinación general', 'Ninguna'),
(4, 5, 'Fructificación', 24.0, 55.0, 'Soleado', 'Bueno', 1, 0, 'Fruto en desarrollo', 'Control de humedad'),
(5, 3, 'Crecimiento', 20.0, 60.0, 'Nublado', 'Bueno', 0, 0, 'Buen follaje', 'Ninguna'),
(6, 4, 'Brote', 21.0, 65.0, 'Soleado', 'Excelente', 0, 0, 'Sin plagas', 'Monitoreo'),
(7, 3, 'Crecimiento', 25.0, 58.0, 'Despejado', 'Bueno', 1, 0, 'Necesita riego', 'Programado'),
(8, 4, 'Floración', 19.0, 72.0, 'Nublado', 'Regular', 0, 1, 'Presencia de hongos', 'Aplicar fungicida'),
(9, 5, 'Fructificación', 23.0, 55.0, 'Soleado', 'Excelente', 0, 0, 'Fruto sano', 'Monitoreo'),
(10, 4, 'Crecimiento', 20.0, 65.0, 'Soleado', 'Bueno', 1, 0, 'Suelo suelto', 'Riego manual'),
(11, 3, 'Raíz', 21.0, 60.0, 'Despejado', 'Excelente', 1, 0, 'Crecimiento óptimo', 'Riego'),
(12, 5, 'Crecimiento', 22.0, 65.0, 'Nublado', 'Bueno', 0, 0, 'Sin novedad', 'Ninguna'),
(13, 3, 'Crecimiento', 20.0, 60.0, 'Soleado', 'Bueno', 1, 0, 'Suelo seco', 'Riego'),
(14, 3, 'Crecimiento', 19.0, 68.0, 'Nublado', 'Bueno', 0, 0, 'Buen desarrollo', 'Ninguna'),
(15, 5, 'Floración', 26.0, 50.0, 'Soleado', 'Excelente', 0, 0, 'Floración masiva', 'Ninguna');

-- MOVIMIENTOS DE INSUMOS (15 registros)
INSERT INTO movimiento_insumos (id_insumo, id_usuario, tipo_movimiento, motivo, cantidad, precio_unitario, subtotal, stock_anterior, stock_nuevo, referencia) VALUES
(1, 1, 'ENTRADA', 'Compra inicial', 50, 45.00, 2250.00, 50, 100, 'FAC-1001'),
(3, 2, 'SALIDA', 'Uso en fumigación', 1, 60.00, 60.00, 31, 30, 'REQ-001'),
(6, 1, 'ENTRADA', 'Compra semilla', 20, 85.00, 1700.00, 40, 60, 'FAC-1002'),
(2, 3, 'SALIDA', 'Uso abonado', 2, 35.00, 70.00, 120, 118, 'REQ-002'),
(5, 4, 'SALIDA', 'Uso fungicida', 1, 55.00, 55.00, 45, 44, 'REQ-003'),
(7, 3, 'SALIDA', 'Uso insecticida', 2, 40.00, 80.00, 50, 48, 'REQ-004'),
(8, 5, 'SALIDA', 'Abono compost', 2, 15.00, 30.00, 300, 298, 'REQ-005'),
(1, 4, 'SALIDA', 'NPK foliar', 2, 45.00, 90.00, 100, 98, 'REQ-006'),
(1, 3, 'SALIDA', 'NPK refuerzo', 2, 45.00, 90.00, 98, 96, 'REQ-007'),
(9, 4, 'SALIDA', 'Humus', 3, 25.00, 75.00, 200, 197, 'REQ-008'),
(8, 3, 'SALIDA', 'Compost', 3, 15.00, 45.00, 298, 295, 'REQ-009'),
(12, 5, 'SALIDA', 'Sulfato', 2, 30.00, 60.00, 70, 68, 'REQ-010'),
(4, 1, 'ENTRADA', 'Compra semillas', 10, 110.00, 1100.00, 25, 35, 'FAC-1003'),
(10, 1, 'ENTRADA', 'Compra semillas', 5, 120.00, 600.00, 15, 20, 'FAC-1004'),
(13, 1, 'ENTRADA', 'Compra azufre', 20, 28.00, 560.00, 80, 100, 'FAC-1005');
GO

-- HARVEST - COSECHAS CABECERA (15 registros)
INSERT INTO harvest (responsable, fecha_cosecha) VALUES
('Ana Felix',      '2026-06-01'),
('Hugo Fernandez', '2026-06-03'),
('Maria Silva',    '2026-06-05'),
('Sofia Martinez', '2026-06-07'),
('Ana Felix',      '2026-06-08'),
('Hugo Fernandez', '2026-06-10'),
('Lucia Ortiz',    '2026-06-11'),
('Maria Silva',    '2026-06-12'),
('Sofia Martinez', '2026-06-13'),
('Ana Felix',      '2026-06-14'),
('Hugo Fernandez', '2026-06-15'),
('Lucia Ortiz',    '2026-06-16'),
('Maria Silva',    '2026-06-17'),
('Sofia Martinez', '2026-06-18'),
('Ana Felix',      '2026-06-20');
GO

-- HARVEST_PLANTING_CYCLE - DETALLE DE COSECHAS (15 registros)
INSERT INTO harvest_planting_cycle (id_harvest, id_cultivo, kilos_optimos, kilos_merma) VALUES
(1,  1,  3500.00, 320.00),
(2,  2,  1800.00, 210.00),
(3,  4,   950.00,  80.00),
(4,  3,   600.00,  55.00),
(5,  5,  2200.00, 190.00),
(6,  6,  1100.00, 130.00),
(7,  7,  2800.00, 250.00),
(8,  8,  1650.00, 160.00),
(9,  9,   870.00,  70.00),
(10, 10,  980.00,  95.00),
(11, 11, 1750.00, 145.00),
(12, 12, 2100.00, 200.00),
(13, 13,  720.00,  60.00),
(14, 14, 1400.00, 120.00),
(15, 15,  530.00,  45.00);
GO

-- ASIGNACION_CABECERA - CABECERAS DE ASIGNACIÓN DE MANO DE OBRA (15 registros)
-- Referencia: id_actividad del 1 al 14 existentes; el 15 reutiliza actividad 1
INSERT INTO asignacion_cabecera (id_actividad, fecha_asignacion, horas_trabajadas, costo_total_mano_obra, observacion) VALUES
(1,  '2026-03-25 08:00:00', 4.00,  120.00, 'Aplicación de fertilizante NPK, turno mañana'),
(2,  '2026-04-15 09:00:00', 3.50,   85.00, 'Control preventivo de plagas en papa'),
(3,  '2026-05-20 10:00:00', 2.00,   50.00, 'Ajuste del sistema de goteo'),
(4,  '2026-05-28 07:00:00', 5.00,  130.00, 'Deshierbe manual entre surcos, dos operadores'),
(5,  '2026-05-11 08:00:00', 1.50,   40.00, 'Control diario de humedad en invernadero'),
(6,  '2026-06-01 07:30:00', 6.00,  160.00, 'Primer corte de forraje verde, equipo completo'),
(7,  '2026-05-20 09:00:00', 3.00,   75.00, 'Aplicación de herbicida orgánico'),
(8,  '2026-05-25 08:00:00', 4.00,  110.00, 'Dosis de refuerzo de urea granulada'),
(9,  '2026-05-26 07:00:00', 4.50,  120.00, 'Limpieza manual de maleza en papas'),
(10, '2026-05-27 09:00:00', 2.50,   65.00, 'Fumigación con fungicida cúprico'),
(11, '2026-05-28 08:00:00', 1.50,   35.00, 'Riego manual matutino en lechugas'),
(12, '2026-05-29 08:00:00', 2.00,   50.00, 'Riego por aspersión en zanahorias'),
(13, '2026-05-30 08:30:00', 3.50,   95.00, 'Fertilización cebollas con NPK diluido'),
(14, '2026-06-02 07:00:00', 5.50,  150.00, 'Segundo corte periódico de alfalfa, Lote L'),
(1,  '2026-06-05 08:00:00', 3.00,   80.00, 'Refuerzo de abonado en maíz, turno especial');
GO

-- ASIGNACION_DETALLE - OPERADORES ASIGNADOS POR CABECERA (15 registros)
-- Referencia: id_asignacion_cabecera 1-15; id_usuario operadores IDs 3-14
INSERT INTO asignacion_detalle (id_asignacion_cabecera, id_usuario, costo_mano_obra) VALUES
(1,  3,  60.00),
(2,  4,  42.50),
(3,  6,  50.00),
(4,  7,  65.00),
(5,  8,  40.00),
(6,  3,  80.00),
(7,  4,  75.00),
(8,  6,  55.00),
(9,  7,  60.00),
(10, 8,  65.00),
(11, 10, 35.00),
(12, 11, 50.00),
(13, 12, 47.50),
(14, 3,  75.00),
(15, 6,  80.00);
GO

-- ============================================================================
-- 3. EXPLICACIÓN DE ÍNDICES Y SCRIPTS DE PRUEBA (2 por estudiante)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ESTUDIANTE 1: HUGO FERNANDEZ
-- ----------------------------------------------------------------------------

-- ÍNDICE 1: Búsqueda de usuarios por correo electrónico.
-- Explicación simple: Funciona como el índice alfabético de un libro de contactos. 
-- En lugar de buscar página por página (Table Scan), el sistema va directo a la letra 
-- del correo para iniciar sesión en milisegundos.
CREATE NONCLUSTERED INDEX IX_usuarios_correo
ON usuarios(correo);
GO

-- SCRIPT DE PRUEBA:
-- Esta consulta utiliza el índice 'IX_usuarios_correo' para buscar el usuario directamente por su email.
SELECT * FROM usuarios 
WHERE correo = 'hugo.fernandez@agropacayales.com';
GO


-- ÍNDICE 2: Ordenar actividades por fecha.
-- Explicación simple: Ordena las actividades cronológicamente. Cuando la app pide 
-- "ver las actividades de esta semana", la base de datos ya las tiene ordenadas y las 
-- entrega de inmediato, sin tener que ordenarlas en el momento.
CREATE NONCLUSTERED INDEX IX_actividad_cultivo_fecha
ON actividad_cultivo(fecha_actividad);
GO

-- SCRIPT DE PRUEBA:
-- Esta consulta filtra las actividades en un rango de fechas, beneficiándose de tener el índice ya ordenado.
SELECT * FROM actividad_cultivo 
WHERE fecha_actividad BETWEEN '2026-03-01' AND '2026-05-31';
GO


-- ----------------------------------------------------------------------------
-- ESTUDIANTE 2: ANA FELIX
-- ----------------------------------------------------------------------------

-- ÍNDICE 3: Relación entre cultivos y parcelas. NONCLUSTERED.
-- Explicación simple: Une los cultivos con sus parcelas rápidamente. Al cargar la pantalla 
-- del mapa de parcelas, el sistema junta las dos tablas al instante gracias a que sabe 
-- exactamente qué cultivo pertenece a cada parcela sin buscar en todo el disco duro.
CREATE NONCLUSTERED INDEX IX_cultivos_id_parcela
ON cultivos(id_parcela);
GO

-- SCRIPT DE PRUEBA:
-- Esta consulta realiza un JOIN de las tablas usando la clave foránea id_parcela, la cual está indexada.
SELECT p.nombre AS Parcela, c.nombre AS Cultivo
FROM parcelas p
INNER JOIN cultivos c ON p.id_parcela = c.id_parcela
WHERE c.id_parcela = 1;
GO


-- ÍNDICE 4: Filtrar insumos por tipo (ej. Fertilizantes).
-- Explicación simple: Funciona como las pestañas de categorías en un catálogo. Si buscas 
-- solo "FERTILIZANTES", el índice ignora las semillas y pesticidas, mostrando solo lo 
-- que el bodeguero necesita ver.
CREATE NONCLUSTERED INDEX IX_insumos_tipo
ON insumos(tipo_insumo);
GO

-- SCRIPT DE PRUEBA:
-- Esta consulta busca insumos específicos filtrando por su categoría, reduciendo el área de búsqueda.
SELECT * FROM insumos 
WHERE tipo_insumo = 'FERTILIZANTE';
GO


-- ----------------------------------------------------------------------------
-- ESTUDIANTE 3: AXEL HUAPAYA
-- ----------------------------------------------------------------------------

-- ÍNDICE 5: Ver el historial de salud por cultivo.
-- Explicación simple: Agrupa las fichas de campo de cada cultivo. Cuando el supervisor 
-- entra a ver el historial de salud del "Maíz Primavera", este índice le trae todas 
-- sus visitas diarias en orden sin leer las fichas de los demás cultivos.
CREATE NONCLUSTERED INDEX IX_fichas_campo_id_cultivo
ON fichas_campo(id_cultivo);
GO

-- SCRIPT DE PRUEBA:
-- Esta consulta obtiene todas las fichas clínicas de un cultivo específico de forma instantánea.
SELECT * FROM fichas_campo 
WHERE id_cultivo = 1;
GO


-- ÍNDICE 6: Filtrar movimientos de bodega por tipo (Entradas / Salidas).
-- Explicación simple: Separa las facturas de compras (entradas) de los consumos (salidas). 
-- Hace que el balance del inventario de insumos se calcule al instante al no tener que 
-- mezclar y filtrar todas las transacciones juntas.
CREATE NONCLUSTERED INDEX IX_movimiento_insumos_tipo
ON movimiento_insumos(tipo_movimiento, fecha_movimiento);
GO

-- SCRIPT DE PRUEBA:
-- Esta consulta compuesta filtra las salidas de bodega posteriores a una fecha, usando el índice compuesto.
SELECT * FROM movimiento_insumos 
WHERE tipo_movimiento = 'SALIDA' 
  AND fecha_movimiento >= '2026-05-01';
GO

