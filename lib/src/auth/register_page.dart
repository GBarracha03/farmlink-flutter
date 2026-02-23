import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projeto/src/auth/authentication_page.dart';
import 'package:projeto/src/widgets/showSnackbar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  String? _email;
  String? _password;
  String? _userName;
  String? _phoneNumber;
  bool _submitting = false;

  Future<void> _register() async {
    try {
      setState(() => _submitting = true);

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email!.trim(),
            password: _password!,
          );

      final userId = credential.user?.uid;
      if (userId == null) {
        throw Exception("Utilizador nao foi criado corretamente!");
      }

      final profile = {
        "userId": userId,
        "name": _userName,
        "phoneNumber": _phoneNumber,
        "email": _email,
      };
      await FirebaseFirestore.instance
          .collection("profiles")
          .doc(userId)
          .set(profile);

      if (!mounted) return;

      showSnackbar(
        context: context,
        message: 'Conta criada com sucesso!',
        backgroundColor: Colors.green,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthenticationPage()),
      );
    } on FirebaseAuthException catch (e) {
      showSnackbar(
        context: context,
        message: 'Erro ao registar: ${e.message}',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (e) {
      showSnackbar(
        context: context,
        message: 'Erro inesperado: $e',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    form.save();

    await _register();
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
          height: screenHeight * 0.85,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_submitting)
                const Center(child: CircularProgressIndicator())
              else
                _buildRegisterForm(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Criar Nova Conta',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            decoration: InputDecoration(
              labelText: 'Nome de Utilizador',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Insira seu nome';
              if (value.length > 20)
                return 'Nome muito longo (máx. 20 caracteres)';
              return null;
            },
            onSaved: (value) => _userName = value,
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Insira seu e-mail';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'E-mail inválido';
              }
              return null;
            },
            onSaved: (value) => _email = value,
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
            validator: (value) {
              if (value == null || value.isEmpty) return 'Insira sua senha';
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
            onSaved: (value) => _password = value,
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: InputDecoration(
              labelText: 'Número de Telemóvel',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Insira seu número';
              if (value.length > 9) return 'Número inválido';
              return null;
            },
            onSaved: (value) => _phoneNumber = value,
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
                'Registar',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthenticationPage()),
              );
            },
            child: RichText(
              text: TextSpan(
                text: 'Já tem conta? ',
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: 'Iniciar sessão',
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
