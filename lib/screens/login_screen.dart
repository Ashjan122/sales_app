import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jawda_sales/core/network/dio_client.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:jawda_sales/screens/home_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final response = await DioClient.dio.post(
        '/login',
        data: {
          "username": usernameController.text,
          "password": passwordController.text,
        },
      );

      final token = response.data['access_token'];
      final username = response.data['user']['name'];
await AuthService.saveUsername(username);


      // حفظ التوكن (خاص باليوزر)
      await AuthService.saveToken(token);

      // الانتقال للصفحة الرئيسية
      Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => HomeScreen(),
  ),
);

    } on DioException catch (e) {
      print('ERROR STATUS: ${e.response?.statusCode}');
    print('ERROR DATA: ${e.response?.data}');
    print('ERROR MESSAGE: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data['message'] ?? 'فشل تسجيل الدخول')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const BackgroundPainterWidget(),

          Positioned(
            top: screenHeight * 0.12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildTitle(),
                const SizedBox(height: 10),
                _buildSubtitle(),
              ],
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.35),
                      _buildLoginForm(),
                      const Spacer(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() => const Center(
        child: Text(
          "جودة للمبيعات",
          style: TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildSubtitle() => Center(
        child: Text(
          "مرحبا بك في نظام المبيعات",
          style: TextStyle(color: Colors.grey[300], fontSize: 18),
        ),
      );

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          hint: "اسم المستخدم",
          icon: Icons.person,
          obscureText: false,
          controller: usernameController,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          hint: "كلمة المرور",
          icon: Icons.lock,
          obscureText: true,
          controller: passwordController,
        ),
        const SizedBox(height: 30),
        _buildLoginButton(),
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required bool obscureText,
    required TextEditingController controller,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF213D5C)),
          prefixIcon: Icon(icon, color: const Color(0xFF213D5C)),
          filled: true,
          fillColor: Colors.black.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      );

  Widget _buildLoginButton() => ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF213D5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: isLoading ? null : login,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "تسجيل الدخول",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      );
}

class BackgroundPainterWidget extends StatelessWidget {
  const BackgroundPainterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: BackgroundPainter(),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = const Color(0xFF213D5C);

    Path topPath = Path();
    topPath.moveTo(0, 0);
    topPath.lineTo(0, size.height * 0.25);
    topPath.quadraticBezierTo(
        size.width / 2, size.height * 0.35, size.width, size.height * 0.25);
    topPath.lineTo(size.width, 0);
    topPath.close();
    canvas.drawPath(topPath, paint);

    Path bottomPath = Path();
    bottomPath.moveTo(0, size.height);
    bottomPath.lineTo(0, size.height * 0.75);
    bottomPath.quadraticBezierTo(
        size.width / 2, size.height * 0.65, size.width, size.height * 0.75);
    bottomPath.lineTo(size.width, size.height);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
