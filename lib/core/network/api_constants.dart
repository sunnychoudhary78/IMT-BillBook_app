enum Environment { uat, prod }

class ApiConstants {
  static Environment current = Environment.prod; // change only here

  static String get baseUrl {
    switch (current) {
      case Environment.uat:
        return 'http://192.168.1.26:3004/api';
      case Environment.prod:
        return 'https://imt-billbook.immortalgroup.in/api';
    }
  }

  static String get uploadsBaseUrl => '${baseUrl}/uploads';
}
