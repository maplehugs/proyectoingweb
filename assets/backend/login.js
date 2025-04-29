const fs = require('fs');
const path = require('path');

const USERS_FILE = path.join(__dirname, 'usuarios.txt');

// Función para leer usuarios desde el archivo
const leerUsuarios = () => {
    try {
        const data = fs.readFileSync(USERS_FILE, 'utf8');
        return data ? JSON.parse(data) : [];
    } catch (error) {
        return [];
    }
};

// Función que maneja la lógica de inicio de sesión
const validarLogin = (req, res) => {
    const { correo, password } = req.body; // Asegurar que el backend reciba "correo"

    if (!correo || !password) {
        return res.status(400).json({ error: 'Correo y contraseña requeridos' });
    }

    const usuarios = leerUsuarios();
    const usuarioEncontrado = usuarios.find(user => user.correo === correo && user.password === password);

    if (usuarioEncontrado) {
        res.json({ mensaje: '✅ Inicio de sesión exitoso', usuario: usuarioEncontrado });
    } else {
        res.status(401).json({ error: '❌ Credenciales incorrectas' });
    }
};

module.exports = validarLogin;
