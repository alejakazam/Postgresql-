--CREATE DATABASE Alkewallet;--

CREATE TABLE usuario (
    user_id SERIAL PRIMARY KEY,
    numero_cuenta VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    correo_electronico VARCHAR(50) NOT NULL UNIQUE,
    contrasena VARCHAR(50) NOT NULL,
    saldo NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (saldo >= 0)
);

CREATE TABLE moneda (
    currency_id SERIAL PRIMARY KEY,
    currency_name VARCHAR(50) NOT NULL UNIQUE,
    currency_symbol VARCHAR(5) NOT NULL,
    factor_to_clp NUMERIC(10,5) NOT NULL
);

CREATE TABLE transaccion (
    transaction_id SERIAL PRIMARY KEY,
    sender_user_id INT NOT NULL
        REFERENCES usuario(user_id)
        ON DELETE CASCADE,
    receiver_user_id INT NOT NULL
        REFERENCES usuario(user_id)
        ON DELETE CASCADE,
    currency_id INT NOT NULL
        REFERENCES moneda(currency_id)
        ON DELETE CASCADE,
    importe NUMERIC(14,2) NOT NULL
        CHECK (importe > 0),
    factor_to_clp_usado NUMERIC(10,5) NOT NULL
        CHECK (factor_to_clp_usado > 0),
    importe_clp NUMERIC(14,2) NOT NULL
        CHECK (importe_clp > 0),
    transaction_date TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO usuario (numero_cuenta,nombre, correo_electronico, contrasena, saldo) VALUES 
('000123456789','Ana Pérez', 'ana.perez@correo.cl', 'hash123', 500000),
('004578963214','Juan Soto', 'juan.soto@correo.cl', 'hash123', 320000),
('000000987654','María López', 'maria.lopez@correo.cl', 'hash123', 1500000),
('123456789012','Pedro González', 'pedro.gonzalez@correo.cl', 'hash123', 760000),
('456789123456','Lucía Torres', 'lucia.torres@correo.cl', 'hash123', 430000),
('000456789321','Carlos Rojas', 'carlos.rojas@correo.cl', 'hash123', 980000),
('789123456000','Daniela Fuentes','daniela.fuentes@correo.cl','hash123', 210000),
('321654987123','Miguel Díaz', 'miguel.diaz@correo.cl', 'hash123', 670000),
('000001234567','Paula Herrera', 'paula.herrera@correo.cl', 'hash123', 890000),
('654321789456','Jorge Molina', 'jorge.molina@correo.cl', 'hash123', 1200000),
('112233445566','Valentina Cruz', 'valentina.cruz@correo.cl', 'hash123', 450000),
('998877665544','Andrés Silva', 'andres.silva@correo.cl', 'hash123', 380000),
('000999888777','Camila Reyes', 'camila.reyes@correo.cl', 'hash123', 540000),
('555444333222','Sebastián Pino', 'sebastian.pino@correo.cl', 'hash123', 620000),
('101010101010','Fernanda Vega', 'fernanda.vega@correo.cl', 'hash123', 710000),
('909090909090','Rodrigo Muñoz', 'rodrigo.munoz@correo.cl', 'hash123', 860000),
('000314159265','Constanza León', 'constanza.leon@correo.cl', 'hash123', 930000),
('777888999000','Tomás Araya', 'tomas.araya@correo.cl', 'hash123', 470000),
('987654321000','Natalia Campos', 'natalia.campos@correo.cl', 'hash123', 520000),
('010203040506','Felipe Navarro', 'felipe.navarro@correo.cl', 'hash123', 680000);

INSERT INTO moneda (currency_name, currency_symbol, factor_to_clp) VALUES
('CLP', '$', 1),
('USD', '$', 863),
('EUR', '€', 1025),
('CNH', '¥', 124);

INSERT INTO transaccion
(sender_user_id, receiver_user_id, currency_id, importe, factor_to_clp_usado, importe_clp)
VALUES
-- 1) Ana → Juan : 50.000 CLP
(1, 2, 1, 50000, 1, 50000),

-- 2) María → Pedro : 10 USD → 8.630 CLP
(3, 4, 2, 10, 863, 8630),

-- 3) Carlos → Lucía : 5 EUR → 5.125 CLP
(6, 5, 3, 5, 1025, 5125),

-- 4) Paula → Ana : 750 CNH → 93.000 CLP
(9, 1, 4, 750, 124, 93000),

-- 5) Jorge → Paula : 100 USD → 86.300 CLP
(10, 9, 2, 100, 863, 86300),

-- 6) Fernanda → Tomás : 20 EUR → 20.500 CLP
(15, 18, 3, 20, 1025, 20500),

-- 7) Paula → María : 2000 CNH → 248.000 CLP
(9, 3, 4, 2000, 124, 248000);


-- numero de cuenta y sus respectivos titulares
SELECT 
    numero_cuenta AS cuenta,
    nombre AS titular
FROM usuario;

-- alter table para añadir fecha de creación de usuario 
ALTER TABLE usuario
ADD COLUMN fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE;
SELECT * FROM usuario

-- transferencia paula a pedro de 200 CNH usando cuenta
SELECT numero_cuenta,nombre, saldo from usuario
WHERE user_id in (9,4)
FOR UPDATE;

SELECT factor_to_clp, 200*factor_to_clp as importe_clp
FROM moneda WHERE currency_id = 4;

INSERT INTO transaccion(
	sender_user_id,
	receiver_user_id,
	currency_id,
	importe,
	factor_to_clp_usado,
	importe_clp
)values(
9,
4,
4,
200,
124,
24800
);
-- update y commit del cambio de saldo por transacción
UPDATE usuario 
SET saldo = saldo - 24800
WHERE user_id = 9;

UPDATE usuario 
SET saldo = saldo + 24800
WHERE user_id = 4;

COMMIT

-- Monedas utilizadas en las transferencias de un usuario concreto (Paula)
SELECT numero_cuenta, nombre, currency_name, currency_symbol FROM 
usuario u
JOIN
transaccion t
ON u.user_id = t.sender_user_id
JOIN
moneda m
ON m.currency_id = t.currency_id
WHERE t.sender_user_id = 9;
-- total de la sumatoria de las transferencias del usuario top (SUM)
SELECT
    u.numero_cuenta,
    u.nombre,
    SUM(t.importe_clp) AS total_transferido_clp
FROM transaccion t
INNER JOIN usuario u
    ON u.user_id = t.sender_user_id
WHERE t.sender_user_id = 9
GROUP BY u.user_id, u.nombre;
-- top receptores de transferencias (Pedro) con COUNT
SELECT
    u_receiver.numero_cuenta,
    u_receiver.nombre,
    COUNT(*) AS total_transacciones_recibidas
FROM transaccion t
INNER JOIN usuario u_receiver
    ON u_receiver.user_id = t.receiver_user_id
INNER JOIN moneda m
    ON m.currency_id = t.currency_id
GROUP BY u_receiver.user_id, u_receiver.nombre
ORDER BY total_transacciones_recibidas DESC;

-- top transferencias realizadas (Paula) con COUNT
SELECT
    u_sender.numero_cuenta,
    u_sender.nombre,
    COUNT(*) AS total_transacciones_enviadas
FROM transaccion t
INNER JOIN usuario u_sender
    ON u_sender.user_id = t.sender_user_id
INNER JOIN moneda m
    ON m.currency_id = t.currency_id
GROUP BY u_sender.user_id, u_sender.nombre
ORDER BY total_transacciones_enviadas DESC;

-- vista de top de saldos con límite 5 desc
CREATE VIEW vw_top_money as
SELECT numero_cuenta, nombre, saldo
FROM usuario
ORDER BY saldo DESC 
LIMIT 5;
SELECT * FROM vw_top_money;


-- historial transacciones (ordenado por ID asc por preferencia personal)
SELECT
    t.transaction_id,
    u_sender.numero_cuenta   AS cuenta_emisor,
    u_sender.nombre          AS nombre_emisor,
    u_receiver.numero_cuenta AS cuenta_receptor,
    u_receiver.nombre        AS nombre_receptor,
    t.importe                AS importe_original,
    t.factor_to_clp_usado    AS factor_usado,
    t.transaction_date       AS fecha_transaccion
FROM transaccion t
INNER JOIN usuario u_sender
    ON u_sender.user_id = t.sender_user_id
INNER JOIN usuario u_receiver
    ON u_receiver.user_id = t.receiver_user_id
INNER JOIN moneda m
    ON m.currency_id = t.currency_id
ORDER BY t.transaction_id ASC;

-- modificación correo con update
SELECT nombre, correo_electronico FROM usuario WHERE user_id = 3;
UPDATE usuario SET correo_electronico = 'correocambiado@gmail.com' WHERE user_id = 3;
SELECT nombre, correo_electronico FROM usuario WHERE user_id = 3;

-- cambiar tipo de typestamp con alter table
ALTER TABLE transaccion
ALTER COLUMN transaction_date
TYPE TIMESTAMPTZ
USING transaction_date AT TIME ZONE 'UTC';

-- alterar tabla para añadir una constrain que checkea un like para filtrar formatos no válidos de email (puede ser más estricto con un regex)
ALTER TABLE usuario
ADD CONSTRAINT chk_email_formato
CHECK (correo_electronico LIKE '%_@_%._%');

-- borrado de usuario y rollback
BEGIN;
DELETE FROM usuario WHERE user_id = 10;
-- probar si existe usuario
SELECT * FROM usuario WHERE user_id = 10;
SELECT * FROM transaccion WHERE sender_user_id = 10;
-- si campos están vacíos se eliminó
-- revertir 
ROLLBACK;
-- comprobar que usuario vuelve a estar disponible
SELECT * FROM usuario WHERE user_id = 10;
SELECT * FROM transaccion WHERE sender_user_id = 10;
