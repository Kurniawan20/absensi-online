class DataEmpoyee {
  final int id;
  final String title;
  final String body;
  final String file;
  final String image;
  final String createdAt;

  DataEmpoyee(
      {required this.id,
        required this.title,
        required this.body,
        required this.file,
        required this.image,
        required this.createdAt});

  factory DataEmpoyee.fromJson(Map<String, dynamic> json) {
    return DataEmpoyee(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      file: json['file'],
      image: json['image'],
      createdAt: json['created_at'],
    );
  }
}