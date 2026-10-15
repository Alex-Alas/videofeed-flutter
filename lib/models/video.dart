// video.dart
//
// TODO(D-01): modelo Video con fromDoc/toMap.
//
// Campos acordados (documento en la colección `videos`):
//   id           String    id del documento
//   autorUid     String    uid de quien lo subió
//   autorNombre  String    nombre visible del autor
//   titulo       String
//   videoUrl     String    URL de descarga del archivo
//   storagePath  String    ruta del archivo en Storage (videos/{uid}/...)
//   likes        int       contador (FieldValue.increment)
//   creadoEn     DateTime? FieldValue.serverTimestamp()
