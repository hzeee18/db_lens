import '../../core/enums/source_type.dart';

/// Representasi domain dari satu sumber data yang terdaftar.
class SourceEntity {
  const SourceEntity({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final SourceType type;
}
