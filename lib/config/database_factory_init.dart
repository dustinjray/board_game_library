import 'database_factory_init_stub.dart'
    if (dart.library.io) 'database_factory_init_native.dart';

Future<void> initializeDatabaseFactory() => initializeDatabaseFactoryImpl();