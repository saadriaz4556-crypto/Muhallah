import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const senderEmail = 'saadriaz4555@gmail.com';
const senderPassword = 'ifqofmmydbnj zokh';

void main() async {
  final smtpServer = gmail(senderEmail, senderPassword);
  const testOtp = '123456';

  final message = Message()
    ..from = const Address(senderEmail, 'Muhallah App')
    ..recipients.add('test@example.com')
    ..subject = 'Test OTP Verification'
    ..text = 'Your test OTP is: $testOtp';

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: $sendReport');

    // Simulate verification
    const enteredOtp = '123456';
    if (enteredOtp == testOtp) {
      print('OTP Verified successfully!');
    } else {
      print('OTP Verification failed.');
    }
  } catch (e) {
    print('Error: $e');
  }
}
