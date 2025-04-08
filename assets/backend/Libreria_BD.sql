CREATE DATABASE LibreriaBD;
USE LibreriaBD;

CREATE TABLE Usuario (
    ID_User INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100),
    Apellido VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Contraseña VARCHAR(50)
);

CREATE TABLE Pedido (
    ID_Pedido INT AUTO_INCREMENT PRIMARY KEY,
    Fecha_pedido DATE,
    Estado BOOLEAN,
    FK_User INT NOT NULL
);

ALTER TABLE Pedido  
ADD FOREIGN KEY (FK_User) 
REFERENCES Usuario (ID_User);

CREATE TABLE Pago (
    ID_Pago INT AUTO_INCREMENT PRIMARY KEY,
    FechaPago DATE,
    Metodo VARCHAR(50),
    Monto BIGINT,
    FK_Pedido_ID INT NOT NULL
);

ALTER TABLE Pago 
ADD FOREIGN KEY (FK_Pedido_ID)
REFERENCES Pedido (ID_Pedido);

CREATE TABLE Detalle_pedido(
	ID_detalle_pedido INT AUTO_INCREMENT PRIMARY KEY,
    ISBN_Libro BIGINT NOT NULL,
    ID_Libro INT NOT NULL,
    Cantidad INT,
    FK_pedido INT NOT NULL
);

ALTER TABLE Detalle_pedido
ADD FOREIGN KEY  (FK_pedido)
REFERENCES Pedido (ID_Pedido);

CREATE TABLE Direccion_Envio (
    ID_Direccion INT AUTO_INCREMENT PRIMARY KEY,
    Pais VARCHAR(100),
    Ciudad VARCHAR(100),
    Direccion VARCHAR(100) NOT NULL,
    Codigo_postal VARCHAR(50),
    FK_User_DIR INT
);

ALTER TABLE Direccion_Envio
ADD FOREIGN KEY (FK_User_DIR)
REFERENCES Usuario (ID_User);

CREATE TABLE Carrito_compras (
    ID_Carrito INT AUTO_INCREMENT PRIMARY KEY,
    Fecha_creacion DATE,
    Precio_Total BIGINT,
    FK_User_Car INT NOT NULL
);

ALTER TABLE Carrito_compras
ADD FOREIGN KEY (FK_User_car)
REFERENCES Usuario(ID_User);

CREATE TABLE Detalle_carrito (
    ID_Detalle_carro INT AUTO_INCREMENT PRIMARY KEY,
    ID_Libro VARCHAR(150),
    cantidad INT,
    FK_Carro_ID INT NOT NULL
);

ALTER TABLE Detalle_carrito
ADD FOREIGN KEY (FK_Carro_ID)
REFERENCES Carrito_compras (ID_Carrito);

CREATE TABLE Editorial (
    ID_Editorial INT AUTO_INCREMENT PRIMARY KEY,
    Nombre_Editorial VARCHAR(100)
);

CREATE TABLE Categoria_Libro (
    ID_Categoria INT AUTO_INCREMENT PRIMARY KEY,
    Nombre_Categoria VARCHAR(100)
);

CREATE TABLE Autor (
    ID_Autor INT AUTO_INCREMENT PRIMARY KEY,
    Nombre_Autor VARCHAR(100),
    Apellido_Autor VARCHAR(100)
);

CREATE TABLE Libro (
    ID_Libro INT AUTO_INCREMENT PRIMARY KEY,
    Titulo VARCHAR(200),
    ISBN BIGINT NOT NULL,
    Precio INT,
    FK_Detalle_pedido INT,
    FK_Detalle_carrito INT,
    FK_Editorial INT,
    FK_Categoria INT,
    FK_Autor INT
);

ALTER TABLE Libro
ADD FOREIGN KEY (FK_Detalle_pedido)
REFERENCES Detalle_pedido (ID_detalle_pedido);

ALTER TABLE Libro
ADD FOREIGN KEY (FK_Detalle_carrito)
REFERENCES Detalle_carrito (ID_Detalle_carro);

ALTER TABLE Libro
ADD FOREIGN KEY (FK_Editorial)
REFERENCES Editorial (ID_Editorial);

ALTER TABLE Libro
ADD FOREIGN KEY (FK_Categoria) 
REFERENCES Categoria_Libro(ID_Categoria);

ALTER TABLE Libro
ADD FOREIGN KEY (FK_Autor) 
REFERENCES Autor(ID_Autor);


DELIMITER $$

CREATE TRIGGER trg_actualizar_estado_pedido
AFTER INSERT ON Pago
FOR EACH ROW
BEGIN
    UPDATE Pedido 
    SET Estado = TRUE 
    WHERE ID_Pedido = NEW.FK_Pedido_ID;
END $$

DELIMITER ;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

DELIMITER $$

CREATE TRIGGER trg_validar_pedido
BEFORE INSERT ON Pedido
FOR EACH ROW
BEGIN
    DECLARE cantidad_items INT;

    -- Verificar cuántos artículos tiene el usuario en su carrito
    SELECT COUNT(*) INTO cantidad_items 
    FROM Detalle_carrito dc
    JOIN Carrito_compras cc ON dc.FK_Carro_ID = cc.ID_Carrito
    WHERE cc.FK_User_Car = NEW.FK_User;

    -- Si el usuario no tiene artículos en el carrito, se lanza un error
    IF cantidad_items = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No se puede crear un pedido sin artículos en el carrito';
    END IF;
END $$

DELIMITER ;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

DELIMITER $$

CREATE TRIGGER trg_eliminar_carrito
AFTER INSERT ON Pedido
FOR EACH ROW
BEGIN
    DECLARE carrito_id INT;

    -- Obtener el ID del carrito del usuario
    SELECT ID_Carrito INTO carrito_id 
    FROM Carrito_compras 
    WHERE FK_User_Car = NEW.FK_User;

    -- Si el usuario tiene un carrito, eliminarlo junto con sus detalles
    IF carrito_id IS NOT NULL THEN
        DELETE FROM Detalle_carrito WHERE FK_Carro_ID = carrito_id;
        DELETE FROM Carrito_compras WHERE ID_Carrito = carrito_id;
    END IF;
END $$

DELIMITER ;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

DELIMITER $$

CREATE TRIGGER trg_actualizar_stock
AFTER INSERT ON Detalle_carrito
FOR EACH ROW
BEGIN
    DECLARE stock_actual INT;

    -- Obtener el stock actual del libro
    SELECT Precio INTO stock_actual 
    FROM Libro 
    WHERE ID_Libro = NEW.ID_Libro;

    -- Verificar si hay suficiente stock
    IF stock_actual < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Stock insuficiente para el libro';
    ELSE
        -- Reducir el stock del libro
        UPDATE Libro 
        SET Precio = Precio - NEW.cantidad 
        WHERE ID_Libro = NEW.ID_Libro;
    END IF;
END $$

DELIMITER ;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

DELIMITER $$

CREATE TRIGGER trg_validar_email
BEFORE INSERT ON Usuario
FOR EACH ROW
BEGIN
    DECLARE existe INT;

    -- Verificar si el email ya existe
    SELECT COUNT(*) INTO existe 
    FROM Usuario 
    WHERE Email = NEW.Email;

    -- Si ya existe, lanzar un error
    IF existe > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El correo ya está registrado';
    END IF;
END $$

DELIMITER ;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

INSERT INTO Editorial (Nombre_Editorial) VALUES
('Diana'), ('Penguin Random House'), ('Literatura Random House'), ('Debolsillo'), ('Planeta'),
('Anagrama'), ('Tusquets Editores'), ('Alfaguara'), ('HarperCollins'), ('Vintage Books');

INSERT INTO Categoria_Libro (Nombre_Categoria) VALUES
('Autoayuda'), ('Crecimiento personal'), ('Ficción contemporánea'), ('Ficción'), ('Thriller psicológico'), 
('Romance'), ('Ciencia ficción'), ('Fantasía'), ('Terror'),  ('Ensayo'), 
('Biografía'), ('Historia'), ('Cómic / Novela gráfica'), ('Juvenil'), ('Clásicos literarios');

INSERT INTO Autor (Nombre_Autor, Apellido_Autor) VALUES
('Jordi', 'Wild'),
('James', 'Clear'),
('Gabriel', 'García Márquez'),
('Joe', 'Dispenza'),
('Sally', 'Rooney'),
('Hanya', 'Yanagihara');

INSERT INTO Libro (Titulo, ISBN, Precio, FK_Detalle_pedido, FK_Detalle_carrito, FK_Editorial, FK_Categoria, FK_Autor)
VALUES
('Anatomía del mal', 9789877804751, 52000, NULL, NULL, 1, 5, 1),
('Hábitos atómicos', 9786077476719, 64000, NULL, NULL, 1, 1, 2),
('En agosto nos vemos', 9788439743088, 70000, NULL, NULL, 2, 4, 3),
('Deja de ser tú', 9786079344085, 72000, NULL, NULL, 1, 1, 4),
('Normal People', 9781984822192, 70000, NULL, NULL, 3, 3, 5),
('A Little Life', 9780385539265, 89000, NULL, NULL, 10, 3, 6);

INSERT INTO Usuario (Nombre, Apellido, Email, Contraseña) VALUES
('Angie', 'González', 'angie.gonzalez@example.com', 'Angie123'),
('Carlos', 'Ramírez', 'carlos.ramirez@example.com', 'Carloz456'),
('Natalia', 'Torres', 'natalia.torres@example.com', 'Natalia789');

INSERT INTO Direccion_Envio (Pais, Ciudad, Direccion, Codigo_postal, FK_User_DIR) VALUES
('Colombia', 'Bogotá', 'Calle 48B Sur #24D-45', '110931', 1),
('Colombia', 'Bogotá', 'Carrera 7 #120-45', '110111', 2),
('Colombia', 'Bogotá', 'Avenida Primero de Mayo #72-30', '110821', 3);

INSERT INTO Carrito_compras (Fecha_creacion, Precio_Total, FK_User_Car) VALUES
('2025-04-06', 116000, 1), -- Carrito de Angie
('2025-04-03', 64000, 2),  -- Carrito de Carlos
('2025-04-07', 159000, 3);  -- Carrito de Natalia

-- Carrito de Angie: Anatomía del mal + Hábitos atómicos
INSERT INTO Detalle_carrito (ID_Libro, cantidad, FK_Carro_ID) VALUES
(1, 1, 1), (2, 1, 1);

-- Carrito de Carlos: solo Hábitos atómicos
INSERT INTO Detalle_carrito (ID_Libro, cantidad, FK_Carro_ID) VALUES
(2, 1, 2);

-- Carrito de Natalia: A Little Life + Normal People
INSERT INTO Detalle_carrito (ID_Libro, cantidad, FK_Carro_ID) VALUES
(6, 1, 3), (5, 1, 3);

INSERT INTO Pedido (Fecha_pedido, Estado, FK_User) VALUES
('2025-05-08', TRUE, 1),   -- Pedido de Angie (activo)
('2025-05-15', FALSE, 2),  -- Pedido de Carlos (cancelado o completado)
('2025-04-28', TRUE, 3);   -- Pedido de Natalia (activo)

-- Pedido de Angie: Anatomía del mal + Hábitos atómicos
INSERT INTO Detalle_pedido (ISBN_Libro, ID_Libro, Cantidad, FK_pedido) VALUES
(9789877804751, 1, 1, 1),
(9786077476719, 2, 1, 1);

-- Pedido de Carlos: solo Hábitos atómicos
INSERT INTO Detalle_pedido (ISBN_Libro, ID_Libro, Cantidad, FK_pedido) VALUES
(9786077476719, 2, 1, 2);

-- Pedido de Natalia: A Little Life + Normal People
INSERT INTO Detalle_pedido (ISBN_Libro, ID_Libro, Cantidad, FK_pedido) VALUES
(9780385539265, 6, 1, 3),
(9781984822192, 5, 1, 3);

