// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario de Productos UNACH',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// Modelo de Producto
class Producto {
  final String? id;  // GUID como string
  final String nombre;
  final double precio;
  final int existencia;
  final String? fechaRegistro;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.existencia,
    this.fechaRegistro,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id']?.toString(),
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] ?? 0).toDouble(),
      existencia: json['existencia'] ?? 0,
      fechaRegistro: json['fechaRegistro'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'precio': precio,
      'existencia': existencia,
    };
  }

  // Helper para formatear la fecha
  String get fechaFormateada {
    if (fechaRegistro == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaRegistro!);
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }
}

// Servicio API
class ApiService {
  // IMPORTANTE: Ajusta esta URL según tu API real
  // La ruta correcta es con mayúscula inicial: /Productos
  static const String baseUrl = 'http://miapiunach.somee.com/api';
  
  // GET - Obtener todos los productos
  Future<List<Producto>> getProductos() async {
    final url = '$baseUrl/Productos';  // Con mayúscula
    print('🌐 Intentando conectar a: $url');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          print('✅ Productos cargados: ${data.length}');
          return data.map((json) => Producto.fromJson(json)).toList();
        } else {
          throw Exception('Formato de respuesta inesperado. Se esperaba una lista.');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint no encontrado. Verifica la URL: $url');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      throw Exception('Error de red. Verifica tu conexión a internet.');
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      throw Exception('Error al procesar la respuesta del servidor.');
    } catch (e) {
      print('❌ Error general: $e');
      throw Exception('Error de conexión: $e\n\nVerifica:\n1. URL correcta\n2. API funcionando\n3. Conexión a internet');
    }
  }

  // GET by ID - Obtener un producto específico
  Future<Producto> getProductoById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Productos/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Producto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Producto no encontrado');
      }
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  // POST - Crear nuevo producto
  Future<Producto> createProducto(Producto producto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Productos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(producto.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Producto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al crear: $e');
    }
  }

  // PUT - Actualizar producto
  Future<Producto> updateProducto(String id, Producto producto) async {
    try {
      // Probar sin incluir el ID en el body
      final body = {
        'nombre': producto.nombre,
        'precio': producto.precio,
        'existencia': producto.existencia,
      };
      
      print('🔄 Actualizando producto ID: $id');
      print('📤 Body: ${json.encode(body)}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/Productos/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Si es 204 No Content, retornar el producto con los datos actualizados
        if (response.statusCode == 204 || response.body.isEmpty) {
          return Producto(
            id: id,
            nombre: producto.nombre,
            precio: producto.precio,
            existencia: producto.existencia,
          );
        }
        return Producto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al actualizar: $e');
      throw Exception('Error al actualizar: $e');
    }
  }

  // DELETE - Eliminar producto
  Future<void> deleteProducto(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/Productos/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al eliminar: $e');
    }
  }
}

// Página Principal
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProductos();
    // _loadProductosMock(); // Descomenta para probar con datos mock
  }

  // Método temporal para probar la UI sin API
  void _loadProductosMock() {
    setState(() {
      _productos = [
        Producto(
          id: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
          nombre: 'Laptop HP',
          precio: 15999.99,
          existencia: 5,
          fechaRegistro: '2025-10-29T23:45:19.749Z',
        ),
        Producto(
          id: '2fa85f64-5717-4562-b3fc-2c963f66afa7',
          nombre: 'Mouse Logitech',
          precio: 299.99,
          existencia: 20,
          fechaRegistro: '2025-10-29T23:45:19.749Z',
        ),
        Producto(
          id: '1fa85f64-5717-4562-b3fc-2c963f66afa8',
          nombre: 'Teclado Mecánico',
          precio: 1299.99,
          existencia: 0,
          fechaRegistro: '2025-10-29T23:45:19.749Z',
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productos = await _apiService.getProductos();
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProducto(String id) async {
    try {
      await _apiService.deleteProducto(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProductos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProductoDialog({Producto? producto}) {
    showDialog(
      context: context,
      builder: (context) => ProductoDialog(
        producto: producto,
        onSave: (nuevoProducto) async {
          Navigator.pop(context); // Cerrar el diálogo primero
          
          try {
            if (producto == null) {
              await _apiService.createProducto(nuevoProducto);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto creado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              await _apiService.updateProducto(producto.id!, nuevoProducto);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto actualizado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
            _loadProductos();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProductos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error al cargar productos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadProductos,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _productos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay productos registrados',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _productos.length,
                      itemBuilder: (context, index) {
                        final producto = _productos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: producto.existencia > 0
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              child: Icon(
                                Icons.shopping_bag,
                                color: producto.existencia > 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                            title: Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${producto.precio.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.indigo[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: producto.existencia > 0
                                            ? Colors.green[50]
                                            : Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Existencia: ${producto.existencia}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: producto.existencia > 0
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Colors.blue,
                                  onPressed: () => _showProductoDialog(
                                    producto: producto,
                                  ),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _showDeleteConfirmation(
                                    producto,
                                  ),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                            onTap: () => _showDetalleProducto(producto),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductoDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }

  void _showDeleteConfirmation(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de eliminar "${producto.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProducto(producto.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDetalleProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(producto.nombre),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', producto.id ?? 'N/A'),
              _buildDetailRow(
                'Precio',
                '${producto.precio.toStringAsFixed(2)}',
              ),
              _buildDetailRow('Existencia', producto.existencia.toString()),
              _buildDetailRow('Fecha Registro', producto.fechaFormateada),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showProductoDialog(producto: producto);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// Diálogo para crear/editar producto
class ProductoDialog extends StatefulWidget {
  final Producto? producto;
  final Function(Producto) onSave;

  const ProductoDialog({
    Key? key,
    this.producto,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<ProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _existenciaController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.producto?.nombre ?? '',
    );
    _precioController = TextEditingController(
      text: widget.producto?.precio.toString() ?? '',
    );
    _existenciaController = TextEditingController(
      text: widget.producto?.existencia.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _existenciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.producto == null ? 'Nuevo Producto' : 'Editar Producto',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un precio válido';
                  }
                  if (double.parse(value) < 0) {
                    return 'El precio no puede ser negativo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _existenciaController,
                decoration: const InputDecoration(
                  labelText: 'Existencia *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La existencia es requerida';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingrese una existencia válida';
                  }
                  if (int.parse(value) < 0) {
                    return 'La existencia no puede ser negativa';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final producto = Producto(
                id: widget.producto?.id,
                nombre: _nombreController.text,
                precio: double.parse(_precioController.text),
                existencia: int.parse(_existenciaController.text),
              );
              widget.onSave(producto);
              // Navigator.pop se hace en el callback onSave
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}