// login_screen.dart
//
// Formulario de inicio de sesion y registro. Habla solo con AuthRepository (via
// el factory). Al autenticarse no navega: AuthGate reacciona al cambio de sesion
// y muestra la app automaticamente.

import 'package:flutter/material.dart';

import '../../../infrastructure/repositories/auth_repository.dart';
import '../../../infrastructure/repositories/auth_repository_factory.dart';
import '../../../domain/datasources/auth_data_source.dart';

class LoginScreen extends StatefulWidget {
  /// Repositorio inyectable; si es null se crea con el factory (Firebase).
  final AuthRepository? repositorio;

  const LoginScreen({super.key, this.repositorio});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _nombreController = TextEditingController();

  late final AuthRepository _repositorio;
  bool _esRegistro = false;
  bool _cargando = false;
  bool _verContrasena = false;

  @override
  void initState() {
    super.initState();
    // La pantalla usa el factory para obtener el repositorio del backend.
    _repositorio =
        widget.repositorio ?? AuthRepositoryFactory.crear(AuthBackend.firebase);
  }

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      if (_esRegistro) {
        await _repositorio.registrarse(
          correo: _correoController.text,
          contrasena: _contrasenaController.text,
          nombre: _nombreController.text,
        );
      } else {
        await _repositorio.iniciarSesion(
          correo: _correoController.text,
          contrasena: _contrasenaController.text,
        );
      }
      // No se navega: AuthGate detecta la sesion y muestra la app.
    } on AuthFailure catch (e) {
      if (mounted) _mostrarError(e.mensaje);
    } catch (_) {
      if (mounted) {
        _mostrarError('Ocurrio un error inesperado. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _alternarModo() {
    setState(() {
      _esRegistro = !_esRegistro;
      _formKey.currentState?.reset();
    });
  }

  String? _validarCorreo(String? valor) {
    final correo = valor?.trim() ?? '';
    if (correo.isEmpty) return 'Ingresa tu correo.';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(correo)) return 'Correo con formato invalido.';
    return null;
  }

  String? _validarContrasena(String? valor) {
    final contrasena = valor ?? '';
    if (contrasena.isEmpty) return 'Ingresa tu contrasena.';
    if (contrasena.length < 6) return 'Minimo 6 caracteres.';
    return null;
  }

  String? _validarNombre(String? valor) {
    final nombre = (valor ?? '').trim();
    if (nombre.isEmpty) return 'Ingresa tu nombre.';
    // Mismo limite que firestore.rules para users/{uid}.nombre.
    if (nombre.length > 100) return 'Maximo 100 caracteres.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // ConstrainedBox + SingleChildScrollView evitan overflow cuando el
            // teclado reduce el alto disponible o en pantallas pequenas.
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Encabezado(colorScheme: colorScheme),
                        const SizedBox(height: 32),
                        if (_esRegistro) ...[
                          TextFormField(
                            key: const Key('campo-nombre'),
                            controller: _nombreController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: _decoracion('Nombre', Icons.person_outline),
                            validator: _validarNombre,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          key: const Key('campo-correo'),
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: _decoracion('Correo', Icons.mail_outline),
                          validator: _validarCorreo,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('campo-contrasena'),
                          controller: _contrasenaController,
                          obscureText: !_verContrasena,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _enviar(),
                          decoration: _decoracion(
                            'Contrasena',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _verContrasena
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                () => _verContrasena = !_verContrasena,
                              ),
                            ),
                          ),
                          validator: _validarContrasena,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('boton-enviar'),
                          onPressed: _cargando ? null : _enviar,
                          child: _cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _esRegistro ? 'Crear cuenta' : 'Iniciar sesion',
                                ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('boton-alternar'),
                          onPressed: _cargando ? null : _alternarModo,
                          child: Text(
                            _esRegistro
                                ? 'Ya tengo cuenta. Iniciar sesion'
                                : 'Crear una cuenta nueva',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _decoracion(String label, IconData icono) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    );
  }
}

/// Encabezado llamativo con el nombre de la app y el modo actual.
class _Encabezado extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Encabezado({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_circle_fill,
            size: 56,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'VideoFeed',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Comparte y descubre videos',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
