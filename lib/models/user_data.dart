import 'package:image_picker/image_picker.dart';

class UserData {
  static String nama = "";
  static String email = "";
  static String phone = "";
  static String nik = "";
  static String latitude = "";
  static String longitude = "";
  static String address = "";
  static String ktpImagePath = "";

  // Simpan XFile asli dari image_picker agar bisa ditampilkan di web maupun HP
  static XFile? ktpImageFile;
}
