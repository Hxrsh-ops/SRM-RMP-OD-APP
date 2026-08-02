abstract class EmailService {
  Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String body,
    String? templateId,
    Map<String, dynamic>? templateParams,
  });
}

class ResendEmailProvider implements EmailService {
  final String apiKey;

  const ResendEmailProvider({required this.apiKey});

  @override
  Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String body,
    String? templateId,
    Map<String, dynamic>? templateParams,
  }) async {
    // Disabled in pilot development - future integration point
    return true;
  }
}

class BrevoEmailProvider implements EmailService {
  final String apiKey;

  const BrevoEmailProvider({required this.apiKey});

  @override
  Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String body,
    String? templateId,
    Map<String, dynamic>? templateParams,
  }) async {
    // Disabled in pilot development - future integration point
    return true;
  }
}

class SmtpEmailProvider implements EmailService {
  final String host;
  final int port;
  final String username;
  final String password;

  const SmtpEmailProvider({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  @override
  Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String body,
    String? templateId,
    Map<String, dynamic>? templateParams,
  }) async {
    // Disabled in pilot development - future integration point
    return true;
  }
}
