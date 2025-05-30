const fs = require('fs');
const path = require('path');

const USERS_FILE = path.join(__dirname, 'usuarios.txt');


const leerUsuarios = () => {
    try {
        const data = fs.readFileSync(USERS_FILE, 'utf8');
        return data ? JSON.parse(data) : [];
    } catch (error) {
        return [];
    }
};


const validarLogin = (req, res) => {
    const { correo, password } = req.body; 

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
