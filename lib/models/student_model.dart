class Student {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String className;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.className,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      className: json['class_name'],
    );
  }
}
