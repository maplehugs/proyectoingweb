CREATE DATABASE LibreriaBD;
USE LibreriaBD;

-- Crear las tablas
CREATE TABLE Usuario (
    ID_User INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100),
    Apellido VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Contraseña VARCHAR(50)
);

CREATE TABLE Pedido (
    ID_Pedido INT AUTO_INCREMENT PRIMARY KEY,
    FK_User_ID INT,
    Fecha_pedido DATE,
    Estado BOOLEAN,
    FOREIGN KEY (FK_User_ID) REFERENCES Usuario(ID_User)
);

ALTER TABLE Pedido  
ADD CONSTRAINT fk_pedido_usuario  
FOREIGN KEY (FK_User_ID)  REFERENCES Usuario(ID_User) ;

CREATE TABLE Pago (
    ID_Pago INT AUTO_INCREMENT PRIMARY KEY,
    FK_Pedido_ID INT NOT NULL,
    FechaPago DATE,
    Metodo VARCHAR(50),
    Monto BIGINT
);

ALTER TABLE Pago 
ADD CONSTRAINT fk_pedido_usuario  
FOREIGN KEY (FK_User_ID)  REFERENCES Usuario(ID_User);

CREATE TABLE Direccion_Envio (
    ID_Direccion INT AUTO_INCREMENT PRIMARY KEY,
    FK_User_ID INT,
    Pais VARCHAR(100),
    Ciudad VARCHAR(100),
    Direccion VARCHAR(100) NOT NULL,
    Codigo_postal VARCHAR(50)
);

ALTER TABLE Direccion_Envio_user  
ADD CONSTRAINT fk_User_ID  
FOREIGN KEY (FK_User_ID) REFERENCES Usuario(ID_User);

CREATE TABLE Carrito_compras (
    ID_Carrito INT AUTO_INCREMENT PRIMARY KEY,
    FK_User_ID INT NOT NULL,
    Fecha_creacion DATE,
    FOREIGN KEY (FK_User_ID) REFERENCES Usuario(ID_User)
);

CREATE TABLE Detalle_carrito (
    ID_Detalle_carro INT AUTO_INCREMENT PRIMARY KEY,
    FK_Carro_ID INT NOT NULL,
    ID_Libro VARCHAR(150),
    cantidad INT,
    FOREIGN KEY (FK_Carro_ID) REFERENCES Carrito_compras(ID_Carrito)
);

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
    FK_Editorial INT,
    FK_Categoria INT,
    FK_Autor INT,
    FOREIGN KEY (FK_Editorial) REFERENCES Editorial(ID_Editorial),
    FOREIGN KEY (FK_Categoria) REFERENCES Categoria_Libro(ID_Categoria),
    FOREIGN KEY (FK_Autor) REFERENCES Autor(ID_Autor)
);

-- TRIGGERS

DELIMITER $$
-- Trigger para actualizar estado de pedido
CREATE TRIGGER trg_actualizar_estado_pedido
AFTER INSERT ON Pago
FOR EACH ROW
BEGIN
    UPDATE Pedido SET Estado = TRUE WHERE ID_Pedido = NEW.FK_Pedido_ID;
END $$

-- Trigger para validar pedido antes de insertarlo
CREATE TRIGGER trg_validar_pedido
BEFORE INSERT ON Pedido
FOR EACH ROW
BEGIN
    DECLARE cantidad_items INT;
    SELECT COUNT(*) INTO cantidad_items FROM Detalle_carrito dc
    JOIN Carrito_compras cc ON dc.FK_Carro_ID = cc.ID_Carrito
    WHERE cc.FK_User_ID = NEW.FK_User_ID;
    IF cantidad_items = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede crear un pedido sin artículos en el carrito';
    END IF;
END $$

-- Trigger para eliminar carrito después de hacer un pedido
CREATE TRIGGER trg_eliminar_carrito
AFTER INSERT ON Pedido
FOR EACH ROW
BEGIN
    DECLARE carrito_id INT;
    SELECT ID_Carrito INTO carrito_id FROM Carrito_compras WHERE FK_User_ID = NEW.FK_User_ID;
    IF carrito_id IS NOT NULL THEN
        DELETE FROM Detalle_carrito WHERE FK_Carro_ID = carrito_id;
        DELETE FROM Carrito_compras WHERE ID_Carrito = carrito_id;
    END IF;
END $$

-- Trigger para actualizar stock de libros
CREATE TRIGGER trg_actualizar_stock
AFTER INSERT ON Detalle_carrito
FOR EACH ROW
BEGIN
    UPDATE Libro SET Precio = Precio - NEW.cantidad WHERE ID_Libro = NEW.ID_Libro;
    IF (SELECT Precio FROM Libro WHERE ID_Libro = NEW.ID_Libro) < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para el libro';
    END IF;
END $$

-- Trigger para validar email único antes de insertar usuario
CREATE TRIGGER trg_validar_email
BEFORE INSERT ON Usuario
FOR EACH ROW
BEGIN
    DECLARE existe INT;
    SELECT COUNT(*) INTO existe FROM Usuario WHERE Email = NEW.Email;
    IF existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El correo ya está registrado';
    END IF;
END $$

DELIMITER ;