const express = require('express');
const router = express.Router();
const db = require('../Data_Base/db');



router.post('/register', async (req, res) => {
  const { nombre, email, contraseña } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO usuarios (nombre, email, contraseña) VALUES ($1, $2, $3) RETURNING *',
      [nombre, email, contraseña]
    );

    res.json({ message: 'Usuario registrado', usuario: result.rows[0] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al registrar usuario' });
  }
});

module.exports = router;
