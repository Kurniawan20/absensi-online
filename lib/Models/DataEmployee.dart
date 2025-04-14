class DataEmployee {
  final int id;
  final String title;
  final String body;
  final String file;
  final String image;
  final String createdAt;
  final String? message;

  DataEmployee(
      {required this.id,
      required this.title,
      required this.body,
      required this.file,
      required this.image,
      required this.createdAt,
      this.message});

  factory DataEmployee.fromJson(Map<String, dynamic> json) {
    return DataEmployee(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      file: json['file'],
      image: json['image'],
      createdAt: json['created_at'],
      message: json['message'],
    );
  }
}
