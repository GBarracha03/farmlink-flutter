import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projeto/src/profile/user_profile.dart';
import 'package:projeto/src/profile/profile_edit.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key, required this.userId});

  final String userId;

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  late Future<UserProfile> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _fetchUserProfile();
  }

  Future<UserProfile> _fetchUserProfile() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.userId)
            .get();

    if (!doc.exists) {
      return UserProfile(userId: widget.userId);
    }

    return UserProfile.fromMap(doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.jpeg'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: FutureBuilder<UserProfile>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar perfil'));
          }

          final userProfile = snapshot.data!;

          return _buildProfileContent(userProfile);
        },
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Perfil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 100,
              backgroundColor: Theme.of(context).primaryColor,
              child:
                  profile.profileImageUrl != null
                      ? ClipOval(
                        child: Image.network(
                          profile.profileImageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                      : Text(
                        profile.name?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                        ),
                      ),
            ),
            const SizedBox(height: 40),
            _infoRow('Nome de utilizador:', profile.name ?? 'Desconhecido'),
            _infoRow(
              'Número de Contacto:',
              profile.phoneNumber ?? 'Desconhecido',
            ),
            _infoRow('Avaliação:', '4.99 ★'),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mercados Habituais:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '- Mercado de Azeitão',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Text(
                    '- Mercado de Palmela',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Text(
                    '- Mercado de Setúbal',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProfileEdit(
                            userId: widget.userId,
                            initialProfile: profile,
                          ),
                    ),
                  ).then((_) {
                    setState(() {
                      _userProfileFuture = _fetchUserProfile();
                    });
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Editar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
