class Student {
  final int id;
  final String name;
  final int age;

  Student({
    required this.id,
    required this.name,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'age': this.age,
    };
  }
}
