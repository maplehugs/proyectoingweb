const express = require("express");
const mysql = require("mysql");
const cors = require("cors");
const validarLogin = require('./login');
const bcrypt = require('bcrypt');

const app = express();
app.use(cors());
app.use(express.json());

const conexion = mysql.createConnection({
    host: "localhost",
    database: "libreriabd", 
    user: "root",
    password: "F@rangel18"
});

conexion.connect(function(err) {
    if (err) {
        console.error("❌ Error al conectar a la base de datos:", err);
    } else {
        console.log("✅ Conexión exitosa a la base de datos");
    }
});

app.post('/login', (req, res) => {
    const { correo, password } = req.body;

    const sql = "SELECT * FROM Usuario WHERE correo = ?";

    conexion.query(sql, [correo], (err, result) => {
        if (err) {
            console.error("Error al consultar usuario:", err);
            return res.status(500).json({ error: "Error al consultar usuario" });
        }

        if (result.length === 0) {
            return res.status(401).json({ error: "Correo o contraseña incorrectos" }); 
        }

        const user = result[0];

        
        if (user.Contrasena !== password) {
            return res.status(401).json({ error: "Correo o contraseña incorrectos" }); 
        }

        
        res.status(200).json({
            mensaje: "Inicio de sesión exitoso",
            user: {
                correo: user.correo, 
                nombre: user.nombre, 
            }
        });
    });
});



app.post("/registrar", (req, res) => {
    console.log("Datos recibidos:", req.body);
    const { nombre, apellidos, correo, password, telefono } = req.body;

    if (!nombre || !apellidos || !correo || !password || !telefono) {
        return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    const sql = "INSERT INTO Usuario (Nombre, Apellido, Email, Contrasena, Telefono) VALUES (?, ?, ?, ?, ?)";

    conexion.query(sql, [nombre, apellidos, correo, password, telefono], (err, result) => {
        if (err) {
            console.error("Error al registrar usuario:", err);
            return res.status(500).json({ error: "Error al registrar el usuario" });
        }
        res.json({ mensaje: "Usuario registrado exitosamente" });
    });
});

const PORT = 3300;
app.listen(PORT, () => {
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});

app.get("/carrito", (req, res) => {
    const sql = "SELECT * FROM Carrito";
    conexion.query(sql, (err, results) => {
        if (err) {
            console.error("Error al obtener los libros del carrito:", err);
            return res.status(500).json({ error: "Error en la consulta" });
        }
        res.json(results);
    });
});

app.post("/carrito", (req, res) => {
    const { name, author, price } = req.body;

    if (!name || !author || !price) {
        return res.status(400).json({ error: "Faltan datos del libro" });
    }

    const sql = "INSERT INTO Carrito (name, author, price) VALUES (?, ?, ?)";
    conexion.query(sql, [name, author, price], (err, result) => {
        if (err) {
            console.error("Error al agregar libro al carrito:", err);
            return res.status(500).json({ error: "No se pudo agregar el libro" });
        }
        res.json({ mensaje: "Libro agregado al carrito correctamente", id: result.insertId });
    });
});

app.delete("/carrito/:id", (req, res) => {
    const id = req.params.id;  
    
    if (!id) {
        return res.status(400).json({ error: "ID del libro no proporcionado" });
    }
   
    const sql = "DELETE FROM Carrito WHERE ID = ?";
    conexion.query(sql, [id], (err, result) => {
        if (err) {
            console.error("Error al eliminar libro:", err);
            return res.status(500).json({ error: "No se pudo eliminar el libro" });
        }
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "Libro no encontrado" });
        }
        
        res.json({ mensaje: "Libro eliminado correctamente" });
    });
});

app.put("/carrito/:id", (req, res) => {
    const id = req.params.id;  
    const { name, author, price } = req.body;  

    
    if (!name || !author || !price) {
        return res.status(400).json({ error: "Todos los campos (name, author, price) son obligatorios" });
    }

    
    if (isNaN(price)) {
        return res.status(400).json({ error: "El precio debe ser un número válido" });
    }

    
    const sql = "UPDATE Carrito SET name = ?, author = ?, price = ? WHERE ID = ?";
    conexion.query(sql, [name, author, parseFloat(price), id], (err, result) => {
        if (err) {
            console.error("Error al actualizar libro:", err);
            return res.status(500).json({ error: "Error al actualizar el libro en la base de datos" });
        }

        
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "Libro no encontrado con el ID proporcionado" });
        }

        
        res.json({ mensaje: "Libro actualizado correctamente" });
    });
});


module.exports = conexion;
