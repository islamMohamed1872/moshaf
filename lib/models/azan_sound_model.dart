class AzanSoundModel {
  final String name;
  final String path;
  final bool isCustom;

  AzanSoundModel({
    required this.name,
    required this.path,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'isCustom': isCustom,
  };

  factory AzanSoundModel.fromJson(Map<String, dynamic> json) {
    return AzanSoundModel(
      name: json['name'],
      path: json['path'],
      isCustom: json['isCustom'],
    );
  }
}