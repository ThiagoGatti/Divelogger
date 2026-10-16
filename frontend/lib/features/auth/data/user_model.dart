/// Quem pode ver os mergulhos do usuário.
const Map<String, String> kVisibilityLabels = {
  'PRIVATE': 'Somente eu',
  'FRIENDS': 'Meus amigos',
  'FOLLOWERS': 'Meus seguidores',
  'PUBLIC': 'Qualquer usuário',
};

class UserModel {
  final int id;
  final String nomeCompleto;
  final String email;
  final String? telefone;
  final String? dataNascimento;
  final bool verificado;
  final String plano;
  final String role;
  final String? planExpiresAt;
  final String? username;
  final String? bio;
  final String diveVisibility; // PRIVATE | FOLLOWERS | PUBLIC

  const UserModel({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.telefone,
    this.dataNascimento,
    required this.verificado,
    required this.plano,
    this.role = 'USER',
    this.planExpiresAt,
    this.username,
    this.bio,
    this.diveVisibility = 'FOLLOWERS',
  });

  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num).toInt(),
        nomeCompleto: json['nomeCompleto'] as String? ?? '',
        email: json['email'] as String? ?? '',
        telefone: json['telefone'] as String?,
        dataNascimento: json['dataNascimento'] as String?,
        verificado: json['verificado'] as bool? ?? false,
        plano: json['plano'] as String? ?? 'FREE',
        role: json['role'] as String? ?? 'USER',
        planExpiresAt: json['planExpiresAt'] as String?,
        username: json['username'] as String?,
        bio: json['bio'] as String?,
        diveVisibility: json['diveVisibility'] as String? ?? 'FOLLOWERS',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomeCompleto': nomeCompleto,
        'email': email,
        'telefone': telefone,
        'dataNascimento': dataNascimento,
        'verificado': verificado,
        'plano': plano,
        'role': role,
        'planExpiresAt': planExpiresAt,
        'username': username,
        'bio': bio,
        'diveVisibility': diveVisibility,
      };
}
