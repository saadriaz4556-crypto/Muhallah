import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const senderEmail = 'saadriaz4555@gmail.com';
const senderPassword = 'ifqofmmydbnj zokh';

void main() async {
  final smtpServer = gmail(senderEmail, senderPassword);

  final message = Message()
    ..from = const Address(senderEmail, 'Muhallah App')
    ..recipients.add('test@example.com')
    ..subject = 'Test OTP'
    ..text = 'Your test OTP is: 123456';

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: $sendReport');
  } catch (e) {
    print('Message not sent. \n$e');
  }
}
