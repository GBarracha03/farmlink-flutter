import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projeto/src/home/home_menu.dart';
import 'package:projeto/src/widgets/showSnackbar.dart';
import 'register_page.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();

  bool _submitting = false;
  String? _fieldEmail;
  String? _fieldPassword;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _firebaseSignin({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      showSnackbar(
        context: context,
        message: 'Utilizador autenticado com sucesso.',
        backgroundColor: Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showSnackbar(
          context: context,
          message: 'Nenhum utilizador encontrado com o e-mail indicado.',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      } else if (e.code == 'wrong-password') {
        showSnackbar(
          context: context,
          message: 'A palavra-passe introduzida está incorreta.',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      } else {
        showSnackbar(
          context: context,
          message: 'Erro: ${e.message}',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> _checkCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeMenu(userId: user.uid)),
      );
    }
  }

  void _onSubmit() async {
    setState(() {
      _submitting = true;
    });

    _formKey.currentState?.save();
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _submitting = false;
      });
      showSnackbar(
        context: context,
        message: 'Por favor corrija os erros apresentados antes de avançar',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    log('Email: $_fieldEmail');
    log('Password: $_fieldPassword');

    await _firebaseSignin(
      email: _fieldEmail.toString(),
      password: _fieldPassword.toString(),
    );

    setState(() {
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.jpeg'),
        backgroundColor: theme.primaryColor,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: screenHeight * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_submitting)
                const Center(child: CircularProgressIndicator())
              else
                _buildAuthForm(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bem-vindo',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            decoration: InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Introduza o seu e-mail';
              if (!RegExp(
                r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
              ).hasMatch(value!)) {
                return 'Introduza um e-mail válido';
              }
              return null;
            },
            onSaved: (value) => _fieldEmail = value,
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: InputDecoration(
              labelText: 'Palavra-passe',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value?.isEmpty ?? true)
                return 'Introduza a sua palavra-passe';
              return null;
            },
            onSaved: (value) => _fieldPassword = value,
            onFieldSubmitted: (_) => _onSubmit(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              );
            },
            child: RichText(
              text: TextSpan(
                text: 'Não tem conta? ',
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: 'Registe-se aqui',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
