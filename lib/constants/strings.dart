const String appName_ar = 'ألحاني';
const String appName = 'Alhany';
String appTempDirectoryPath;

class Strings {
  static const String default_profile_image =
      'assets/images/default_profile.png';
  static const String default_cover_image = 'assets/images/default_cover.jpg';
  static const String default_bg = 'assets/images/piano_bg.jpg';
  static const String default_melody_image = 'assets/images/default_melody.jpg';
  static const String default_melody_page_bg =
      'assets/images/default_record_bg.jpg';
  static const String headphones_alert_bg =
      'assets/images/headphones_alert.jpg';
  static const String splash = 'assets/images/splash.jpg';
  static const String splash_icon = 'assets/images/splash_icon.png';

  //App
  static const String packageName = 'com.devyat.alhani.app';

  //Admin ID
  static const String starId = 'PKckiJkH1KbDnik1f4EqrWCMmNr2';

  //Melodies categories
  static const List<String> melodyCategories = [
    'do',
    're',
    'mi',
    'fa',
    'sol',
    'la',
    'si'
  ];

  //Stripe Payment
  static const String stripePublishableKey =
      "pk_live_5FXfeoysTRHWhu3PV2mRLVSi00JgLi7Zyt";
  static const String stripeSecret =
      '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';
  // static const merchantId = "05674331101508648233";
  static const merchantId = "Live";

  //File encryption key
  static const encryption_key = 'Zjssy8Zsn38cjDSldzZDamfJ381xDgPm';

  //Icons
  static const String person_remove = 'assets/icons/person_remove.png';
  static const String reply = 'assets/icons/reply.png';
  static const String send = 'assets/icons/send.png';
  static const String send_ar = 'assets/icons/send_ar.png';
  static const String app_icon = 'assets/icons/app_icon.png';
  static const String app_bar = 'assets/icons/app_bar.png';
  static const String apple = 'assets/icons/apple.png';
  static const String google = 'assets/icons/google.png';

  //Translations
  static const en_edit_image = 'Edit Image';
  static const ar_edit_image = 'تعديل الصورة';

  static const en_edit_lyrics = 'Edit lyrics';
  static const ar_edit_lyrics = 'تعديل الكلمات';

  static const en_edit_name = 'Edit Name';
  static const ar_edit_name = 'تعديل الإسم';

  static const en_delete = 'Delete';
  static const ar_delete = 'حذف';

  static const en_forgot_password = "Forgot Password?";
  static const ar_forgot_password = 'نسيت كلمة المرور؟';

  static const en_melody_uploaded = 'Melody uploaded!';
  static const ar_melody_uploaded = 'تم رفع اللحن';

  static const en_choose_melody = 'Choose Melody';
  static const ar_choose_melody = 'اختيار اللحن';

  static const en_choose_melodies = 'Choose Melodies';
  static const ar_choose_melodies = 'اختيار الألحان';

  static const en_update = 'Update';
  static const ar_update = 'تعديل';

  static const en_add = 'Add';
  static const ar_add = 'إضافة';

  static const en_updated = 'Updated!';
  static const ar_updated = 'تم التعديل';

  static const en_leave_comment = 'Leave a comment...';
  static const ar_leave_comment = '...اترك تعليقا';

  static const en_leave_reply = 'Leave a reply...';
  static const ar_leave_reply = '...اترك ردا';
}
