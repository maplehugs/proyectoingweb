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
    password: ""
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

module.exports = conexion;
