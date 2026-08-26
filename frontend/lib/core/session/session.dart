import '../../features/auth/data/user_model.dart';

class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();

  UserModel? currentUser;
}
