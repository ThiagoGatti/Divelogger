import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../auth/presentation/login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE9F8FB),
              Color(0xFFD2F0F4),
              Color(0xFFB5E2E9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(context),
              ),
              _buildBottomInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DiverrTheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.water,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          const Text(
            'DIVERR',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: DiverrTheme.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 45),

            _buildDiverIllustration(),

            const SizedBox(height: 35),

            const Text(
              'Seu diário de\nmergulhos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 38,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: DiverrTheme.dark,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Registre suas experiências, descubra novos '
                  'pontos de mergulho e explore o mundo subaquático.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 35),

            _buildLoginButton(context),

            const SizedBox(height: 12),

            _buildRegisterButton(context),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDiverIllustration() {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.65),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 25,
            right: 35,
            child: _buildBubble(12),
          ),
          Positioned(
            top: 55,
            left: 30,
            child: _buildBubble(8),
          ),
          Positioned(
            bottom: 45,
            right: 25,
            child: _buildBubble(6),
          ),

          const Icon(
            Icons.scuba_diving,
            size: 100,
            color: DiverrTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: DiverrTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Entrar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () {
          // Futuramente: Navigator.push para RegisterPage
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: DiverrTheme.primary,
          side: const BorderSide(
            color: DiverrTheme.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Criar minha conta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInfoItem(
            Icons.location_on_outlined,
            'Explore',
          ),
          _buildSeparator(),
          _buildInfoItem(
            Icons.scuba_diving_outlined,
            'Registre',
          ),
          _buildSeparator(),
          _buildInfoItem(
            Icons.public,
            'Descubra',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      IconData icon,
      String text,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: DiverrTheme.primary,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        '•',
        style: TextStyle(
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}