
let cart = [];

function renderCart() {
    const cartTable = document.getElementById('cart-table').getElementsByTagName('tbody')[0];
    cartTable.innerHTML = '';  
    cart.forEach((book, index) => {
        const row = cartTable.insertRow();
        row.insertCell(0).textContent = book.name;
        row.insertCell(1).textContent = book.author;
        row.insertCell(2).textContent = `$${book.price}`;

        const actionsCell = row.insertCell(3);
        const editButton = document.createElement('button');
        editButton.textContent = 'Editar';
        editButton.classList.add('edit-button');
        editButton.onclick = () => editBook(index);
        actionsCell.appendChild(editButton);

        const deleteButton = document.createElement('button');
        deleteButton.textContent = 'Eliminar';
        deleteButton.onclick = () => deleteBook(index);
        actionsCell.appendChild(deleteButton);
    });
}

// Agregar libro
document.getElementById('add-book-form').addEventListener('submit', (event) => {
    event.preventDefault();

    const name = document.getElementById('book-name').value.trim();
    const author = document.getElementById('book-author').value.trim();
    const price = parseFloat(document.getElementById('book-price').value.trim());

    if (name && author && !isNaN(price)) {
        cart.push({ name, author, price });
        renderCart();
        document.getElementById('add-book-form').reset(); 
    } else {
        alert('Por favor, completa todos los campos correctamente.');
    }
});

// Eliminar
function deleteBook(index) {
    cart.splice(index, 1);
    renderCart();
}

//Editar
function editBook(index) {
    const book = cart[index];

    
    document.getElementById('book-name').value = book.name;
    document.getElementById('book-author').value = book.author;
    document.getElementById('book-price').value = book.price;

    
    const addButton = document.querySelector('.add-button');
    addButton.textContent = 'Actualizar Libro';
    addButton.onclick = () => updateBook(index);
}

// Actualizar libro
function updateBook(index) {
    const name = document.getElementById('book-name').value.trim();
    const author = document.getElementById('book-author').value.trim();
    const price = parseFloat(document.getElementById('book-price').value.trim());

    if (name && author && !isNaN(price)) {
        cart[index] = { name, author, price };
        renderCart();
        document.getElementById('add-book-form').reset();
        const addButton = document.querySelector('.add-button');
        addButton.textContent = 'Agregar Libro';
        addButton.onclick = (event) => {
            event.preventDefault();
           
        };
    } else {
        alert('Por favor, completa todos los campos correctamente.');
    }
}


renderCart();
