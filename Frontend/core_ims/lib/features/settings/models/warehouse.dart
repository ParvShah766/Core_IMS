class Warehouse {
  const Warehouse({required this.code, required this.name});

  final String code;
  final String name;

  Warehouse copyWith({String? code, String? name}) {
    return Warehouse(code: code ?? this.code, name: name ?? this.name);
  }
}
