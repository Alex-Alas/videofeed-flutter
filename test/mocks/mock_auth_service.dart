// mock_auth_service.dart
//
// Doble de prueba de AuthDataSource para las pruebas del repositorio. Permite
// verificar que AuthRepository solo delega en el datasource, sin Firebase.

import 'package:mocktail/mocktail.dart';
import 'package:videofeed/domain/datasources/auth_data_source.dart';

class MockAuthService extends Mock implements AuthDataSource {}
