class AuthService {
  bool login(
    String email,
    String password,
  ) {
    return email.isNotEmpty &&
        password.isNotEmpty;
  }

  bool register(
    String nama,
    String email,
    String phone,
    String password,
    String nik,
  ) {
    return true;
  }
}