const String appName = 'Dubsmash';
String appTempDirectoryPath;

class Strings {
  static const String default_profile_image = 'assets/images/default_profile.png';
  static const String default_bg = 'assets/images/piano_bg.jpg';
  static const String default_melody_image = 'assets/images/default_melody.jpg';
  static const String default_melody_page_bg = 'assets/images/default_record_bg.jpg';
  static const String headphones_alert_bg = 'assets/images/headphones_alert.jpg';
  static const String splash = 'assets/images/splash.jpg';

  //Admin ID
  static const String starId = 'PKckiJkH1KbDnik1f4EqrWCMmNr2';

  //Melodies categories
  static const List<String> melodyCategories = ['do', 're', 'mi', 'fa', 'sol', 'la', 'si'];

  //Stripe Payment
  static const String paymentPublishableKey =
      "pk_test_51HeoJlKcQzB5OdSOSFKB5rf0v6micyHbExBXYogHRcSbqoMP0LUWuPjs3ojQz9mQBMnLyY6S5ZIpWKsNwxGc43l800htm1GfEw";
  static const String paymentSecret =
      'sk_test_51HeoJlKcQzB5OdSOt6U9dHeE0AycFD0go3mogovD0SDtBWNIxesy5p5R414Z8dPiIDkPS88ecWhtIKqibOiyW9XA00em5I6n1c';
  // static const merchantId = "05674331101508648233";
  static const merchantId = "Test";

  //File encryption key
  static const encryption_key = 'Zjssy8Zsn38cjDSldzZDamfJ381xDgPm';

  //Icons
  static const String person_remove = 'assets/icons/person_remove.png';

  //Translations
  static const en_edit_image = 'Edit Image';
  static const ar_edit_image = 'تعديل الصورة';

  static const en_edit_lyrics = 'Edit lyrics';
  static const ar_edit_lyrics = 'تعديل الكلمات';

  static const en_edit_name = 'Edit Name';
  static const ar_edit_name = 'تعديل الإسم';

  static const en_delete = 'Delete';
  static const ar_delete = 'حذف';
}
