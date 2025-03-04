Create Database LibreriaBD;

Create Table Usuario (
	ID_User Serial Primary key,
	Nombre Varchar(100),
	Apellido Varchar (100),
	Email Varchar (100),
	Contraseña Varchar (50)
);

Create Table Pedido (
	ID_Pedido Serial Primary key,
	FK_User_ID int,
	Fecha_pedido date,
	Estado Boolean,
	CONSTRAINT FK_user FOREIGN KEY (FK_User_ID) REFERENCES Usuario (ID_User)
);

Create Table Pago (
	ID_Pago Serial Primary key,
	FK_Pedido_ID int,
	FechaPago Date,
	Metodo Varchar (50),
	Monto bigint,
	CONSTRAINT FK_pedido FOREIGN KEY (FK_Pedido_ID) REFERENCES Pedido (ID_Pedido)
);

Create Table Direccion_Envio (
	ID_Direccion Serial Primary key,
	FK_User_ID int,
	Pais varchar (100),
	Ciudad Varchar (100),
	Direccion Varchar (100) not null,
	Codigo_postal varchar (50),
	CONSTRAINT FK_user_dir FOREIGN KEY (FK_User_ID) REFERENCES Usuario (ID_User)
);

Create Table Carrito_compras (
	ID_Carrito Serial Primary Key,
	FK_User_ID int not null,
	Fecha_creacion Date,
	CONSTRAINT FK_user_shop FOREIGN KEY (FK_User_ID) REFERENCES Usuario (ID_User)
);

Create Table Detalle_carrito (
	ID_Detalle_carro Serial primary Key,
	FK_Carro_ID int not null,
	ID_Libro Varchar (150),
	cantidad int,
	CONSTRAINT FK_detalle_shop FOREIGN KEY (FK_Carro_ID) REFERENCES Carrito_compras (ID_Carrito)
);

Create Table Editorial (
	ID_Editorial Serial Primary Key,
	Nombre_Editorial Varchar (100)
);

Create Table Categoria_Libro (
	ID_Categoria Serial Primary Key,
	Nombre_Categoria Varchar (100)
);

Create Table Autor (
	ID_Autor Serial Primary Key,
	Nombre_Autor Varchar (100),
	Apellido_Autor Varchar (100)
);

Create Table Libro (
	ID_Libro Serial Primary Key,
	Titulo Varchar (200),
	ISBN Bigint not null,
	Precio int,
	FK_Editorial int,
	FK_Categoria int,
	FK_Autor int,
	CONSTRAINT FK_Edi_Lib FOREIGN KEY (FK_Editorial) REFERENCES Editorial (ID_Editorial),
	CONSTRAINT FK_Cat_Lib FOREIGN KEY (FK_Categoria) REFERENCES Categoria_Libro (ID_Categoria),
	CONSTRAINT FK_Autor_Lib FOREIGN KEY (FK_Autor) REFERENCES Autor (ID_Autor)
);


-- Crear la función que ejecutará la actualización
CREATE OR REPLACE FUNCTION actualizar_estado_pedido()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Pedido
    SET Estado = TRUE
    WHERE ID_Pedido = NEW.FK_Pedido_ID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger que ejecutará la función después de insertar un pago
CREATE TRIGGER trg_actualizar_estado_pedido
AFTER INSERT ON Pago
FOR EACH ROW
EXECUTE FUNCTION actualizar_estado_pedido();

-------------------------------------------------------------------------------------------------------------------------------------------

-- Crear la función que validará el pedido antes de insertarlo
CREATE OR REPLACE FUNCTION validar_pedido()
RETURNS TRIGGER AS $$
DECLARE
    cantidad_items INT;
BEGIN
    -- Contar la cantidad de productos en el carrito del usuario
    SELECT COUNT(*) INTO cantidad_items
    FROM Detalle_carrito dc
    JOIN Carrito_compras cc ON dc.FK_Carro_ID = cc.ID_Carrito
    WHERE cc.FK_User_ID = NEW.FK_User_ID;

    -- Si no hay productos en el carrito, cancelar la inserción del pedido
    IF cantidad_items = 0 THEN
        RAISE EXCEPTION 'No se puede crear un pedido sin artículos en el carrito.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger que ejecutará la función antes de insertar un pedido
CREATE TRIGGER trg_validar_pedido
BEFORE INSERT ON Pedido
FOR EACH ROW
EXECUTE FUNCTION validar_pedido();

-------------------------------------------------------------------------------------------------------------------------------------------

-- Crear la función que eliminará el carrito del usuario después de hacer un pedido
CREATE OR REPLACE FUNCTION eliminar_carrito_despues_pedido()
RETURNS TRIGGER AS $$
DECLARE
    carrito_id INT;
BEGIN
    -- Obtener el ID del carrito del usuario que hizo el pedido
    SELECT ID_Carrito INTO carrito_id
    FROM Carrito_compras
    WHERE FK_User_ID = NEW.FK_User_ID;

    -- Si el usuario tiene un carrito, eliminarlo
    IF carrito_id IS NOT NULL THEN
        DELETE FROM Detalle_carrito WHERE FK_Carro_ID = carrito_id;
        DELETE FROM Carrito_compras WHERE ID_Carrito = carrito_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger que ejecutará la función después de insertar un pedido
CREATE TRIGGER trg_eliminar_carrito
AFTER INSERT ON Pedido
FOR EACH ROW
EXECUTE FUNCTION eliminar_carrito_despues_pedido();

-------------------------------------------------------------------------------------------------------------------------------------------

-- Crear la función que eliminará el carrito del usuario después de hacer un pedido
CREATE OR REPLACE FUNCTION eliminar_carrito_despues_pedido()
RETURNS TRIGGER AS $$
DECLARE
    carrito_id INT;
BEGIN
    -- Obtener el ID del carrito del usuario que hizo el pedido
    SELECT ID_Carrito INTO carrito_id
    FROM Carrito_compras
    WHERE FK_User_ID = NEW.FK_User_ID;

    -- Si el usuario tiene un carrito, eliminarlo
    IF carrito_id IS NOT NULL THEN
        DELETE FROM Detalle_carrito WHERE FK_Carro_ID = carrito_id;
        DELETE FROM Carrito_compras WHERE ID_Carrito = carrito_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger que ejecutará la función después de insertar un pedido
CREATE TRIGGER trg_eliminar_carrito
AFTER INSERT ON Pedido
FOR EACH ROW
EXECUTE FUNCTION eliminar_carrito_despues_pedido();

-------------------------------------------------------------------------------------------------------------------------------------------

-- Crear la función que actualizará el stock de libros
CREATE OR REPLACE FUNCTION actualizar_stock_libros()
RETURNS TRIGGER AS $$
BEGIN
    -- Restar la cantidad de libros comprados al stock
    UPDATE Libro
    SET Precio = Precio - NEW.cantidad
    WHERE ID_Libro = NEW.ID_Libro;

    -- Verificar que el stock no sea negativo
    IF (SELECT Precio FROM Libro WHERE ID_Libro = NEW.ID_Libro) < 0 THEN
        RAISE EXCEPTION 'Stock insuficiente para el libro ID %', NEW.ID_Libro;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger que ejecutará la función después de insertar un pedido
CREATE TRIGGER trg_actualizar_stock
AFTER INSERT ON Detalle_carrito
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_libros();

-------------------------------------------------------------------------------------------------------------------------------------------

-- Crear la función que validará el correo antes de insertar
CREATE OR REPLACE FUNCTION validar_email_unico()
RETURNS TRIGGER AS $$
DECLARE
    existe INT;
BEGIN
    -- Contar si el correo ya existe en la base de datos
    SELECT COUNT(*) INTO existe FROM Usuario WHERE Email = NEW.Email;

    -- Si el correo ya existe, cancelar la inserción
    IF existe > 0 THEN
        RAISE EXCEPTION 'El correo % ya está registrado.', NEW.Email;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger que ejecutará la función antes de insertar un usuario
CREATE TRIGGER trg_validar_email
BEFORE INSERT ON Usuario
FOR EACH ROW
EXECUTE FUNCTION validar_email_unico();

