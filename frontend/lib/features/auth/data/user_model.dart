class UserModel {
  final int id;
  final String nomeCompleto;
  final String email;
  final String? telefone;
  final String? dataNascimento;
  final bool verificado;
  final String plano;

  const UserModel({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.telefone,
    this.dataNascimento,
    required this.verificado,
    required this.plano,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num).toInt(),
        nomeCompleto: json['nomeCompleto'] as String? ?? '',
        email: json['email'] as String? ?? '',
        telefone: json['telefone'] as String?,
        dataNascimento: json['dataNascimento'] as String?,
        verificado: json['verificado'] as bool? ?? false,
        plano: json['plano'] as String? ?? 'FREE',
      );
}
