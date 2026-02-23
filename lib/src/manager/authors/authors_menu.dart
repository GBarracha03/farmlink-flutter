import 'package:flutter/material.dart';

class AuthorsMenu extends StatelessWidget {
  const AuthorsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.jpeg'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Autores do Projeto',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildAuthorCard(
                      context,
                      initial: "G",
                      name: "Gonçalo Barracha",
                      email: "202200187@estudantes.ips.pt",
                    ),
                    const SizedBox(height: 25),
                    _buildAuthorCard(
                      context,
                      initial: "F",
                      name: "Francisco Paz",
                      email: "202200186@estudantes.ips.pt",
                    ),
                    const SizedBox(height: 25),
                    _buildAuthorCard(
                      context,
                      initial: "M",
                      name: "Marco Gomes",
                      email: "202200965@estudantes.ips.pt",
                    ),
                    const SizedBox(height: 25),
                    _buildAuthorCard(
                      context,
                      initial: "R",
                      name: "Rodrigo Cardoso",
                      email: "202200197@estudantes.ips.pt",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorCard(
    BuildContext context, {
    required String initial,
    required String name,
    required String email,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
