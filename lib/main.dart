import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _ink = Color(0xFF202638);
const _muted = Color(0xFF737C91);
const _blue = Color(0xFF6579E8);
const _violet = Color(0xFF9B76D8);
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost/api-test/public',
);

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

Future<Map<String, dynamic>> apiRequest(
  String method,
  String path, {
  Map<String, dynamic>? body,
}) async {
  final uri = Uri.parse('$_apiBaseUrl$path');
  final headers = {'Accept': 'application/json'};
  http.Response response;

  if (body != null) headers['Content-Type'] = 'application/json';

  if (method == 'POST') {
    response = await http
        .post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  } else if (method == 'PUT') {
    response = await http
        .put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  } else if (method == 'DELETE') {
    response = await http
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
  } else {
    response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
  }

  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    throw ApiException('Réponse invalide du serveur (${response.statusCode}).');
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      throw ApiException(errors.values.first.toString());
    }
    throw ApiException(
      decoded['message']?.toString() ??
          'Erreur serveur (${response.statusCode}).',
    );
  }

  return decoded;
}

void main() {
  runApp(const CvApp());
}

class CvApp extends StatelessWidget {
  const CvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon CV actualisé',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4FC),
        fontFamily: 'Avenir',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          titleLarge: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleMedium: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(color: _muted, fontSize: 14, height: 1.55),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _isLoading = false;
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await apiRequest(
        'POST',
        _isRegistering ? '/accounts/register' : '/accounts/login',
        body: {
          'email': _usernameController.text.trim(),
          'password': _passwordController.text,
        },
      );
      if (!mounted) return;

      if (_isRegistering) {
        setState(() {
          _isRegistering = false;
          _errorMessage = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Compte créé.'),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const PortfolioShell()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ApiException
            ? error.message
            : 'Impossible de joindre le serveur. Vérifiez votre connexion.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 28),
                    GlassPanel(
                      padding: const EdgeInsets.fromLTRB(26, 30, 26, 25),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bienvenue',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Connectez-vous pour découvrir mon univers.',
                              style: TextStyle(color: _muted, height: 1.5),
                            ),
                            const SizedBox(height: 28),
                            const _FieldLabel('Adresse email'),
                            const SizedBox(height: 9),
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                hint: 'votre@email.com',
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Veuillez saisir votre adresse email.'
                                  : !value.trim().contains('@')
                                  ? 'Veuillez saisir une adresse email valide.'
                                  : null,
                            ),
                            const SizedBox(height: 19),
                            const _FieldLabel('Mot de passe'),
                            const SizedBox(height: 9),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration:
                                  _inputDecoration(
                                    hint: 'Votre mot de passe',
                                    icon: Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _hidePassword
                                          ? 'Afficher le mot de passe'
                                          : 'Masquer le mot de passe',
                                      onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword,
                                      ),
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: _muted,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Veuillez saisir votre mot de passe.'
                                  : value.length < 6
                                  ? 'Le mot de passe doit contenir au moins 6 caractères.'
                                  : null,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB34353),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isLoading)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      Text(
                                        _isRegistering
                                            ? 'Créer mon compte'
                                            : 'Se connecter',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    const SizedBox(width: 9),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 19,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() {
                                        _isRegistering = !_isRegistering;
                                        _errorMessage = null;
                                      }),
                                child: Text(
                                  _isRegistering
                                      ? 'J’ai déjà un compte'
                                      : 'Créer un compte',
                                  style: const TextStyle(
                                    color: _blue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: Text(
                                //'Démo : precious  ·  1234',//'
                                '',
                                style: TextStyle(
                                  color: _muted.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Un CV, tout simplement.',
                      style: TextStyle(
                        color: _ink.withValues(alpha: 0.56),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20, color: _muted),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.55),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
    hintStyle: TextStyle(color: _muted.withValues(alpha: 0.72), fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: _blue, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFCC7180)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFCC7180), width: 1.4),
    ),
  );
}

class PortfolioShell extends StatefulWidget {
  const PortfolioShell({super.key});

  @override
  State<PortfolioShell> createState() => _PortfolioShellState();
}

class _PortfolioShellState extends State<PortfolioShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[ResumePage(), FamilyPage(), ContactPage()];

  static const _titles = ['Mon CV', 'Ma famille', 'Contact'];

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).maybePop();
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          backgroundColor: const Color(0xFFF5F5FC),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                const _ProfileAvatar(size: 76),
                const SizedBox(height: 13),
                const Text(
                  'Michée KADIMA',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('CV personnel', style: TextStyle(color: _muted)),
                const SizedBox(height: 24),
                const Divider(indent: 22, endIndent: 22),
                for (var index = 0; index < _titles.length; index++)
                  ListTile(
                    selected: _selectedIndex == index,
                    selectedColor: _blue,
                    selectedTileColor: _blue.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Icon(_navIcons[index]),
                    title: Text(_titles[index]),
                    onTap: () => _selectPage(index),
                  ),
                const Spacer(),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Se déconnecter'),
                  onTap: _logout,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 4,
          title: Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 17),
              child: GestureDetector(
                onTap: () => _selectPage(2),
                child: const _ProfileAvatar(size: 38),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              radius: 25,
              child: Row(
                children: List.generate(_titles.length, (index) {
                  final selected = _selectedIndex == index;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => _selectPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? _blue.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _navIcons[index],
                              size: 20,
                              color: selected ? _blue : _muted,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _titles[index],
                              style: TextStyle(
                                color: selected ? _blue : _muted,
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _navIcons = [
  Icons.person_outline_rounded,
  Icons.groups_2_outlined,
  Icons.mail_outline_rounded,
];

class ResumePage extends StatelessWidget {
  const ResumePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(21),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const _ProfileAvatar(size: 112),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF63BD91),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Michée KADIMA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Étudiant · Développeur en devenir',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Curieux et motivé, je m’intéresse à la création '
                'd’expériences numériques utiles et accessibles. '
                'J’aime apprendre, construire et relever de nouveaux défis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, height: 1.55, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Tag(label: 'Disponible', color: Color(0xFF56A982)),
                  _Tag(label: 'Goma, Congo KINSHASA', color: _blue),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const _SectionTitle(
          title: 'Formation',
          subtitle: 'Mon parcours académique',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 10),
        const _TimelineCard(
          title: 'Études en informatique',
          organization: 'Établissement à compléter',
          period: 'En cours',
          description:
              'Formation orientée vers la programmation, les systèmes '
              'informatiques et la conception de solutions numériques.',
          icon: Icons.school_rounded,
        ),
        const SizedBox(height: 17),
        const _SectionTitle(
          title: 'Expériences & projets',
          subtitle: 'Ce que je construis',
          icon: Icons.work_outline_rounded,
        ),
        const SizedBox(height: 10),
        const _TimelineCard(
          title: 'Application mobile CV',
          organization: 'Projet personnel · Flutter',
          period: '2025 — 2026',
          description:
              'Conception d’une application responsive avec navigation, '
              'composants réutilisables et interface inspirée du verre liquide.',
          icon: Icons.phone_iphone_rounded,
        ),
        const SizedBox(height: 10),
        const _TimelineCard(
          title: 'Projets académiques',
          organization: 'Travaux pratiques',
          period: 'En cours',
          description:
              'Réalisation de petits projets pour mettre en pratique '
              'les bases du développement et du travail en équipe.',
          icon: Icons.code_rounded,
        ),
        const SizedBox(height: 17),
        const _SectionTitle(
          title: 'Compétences',
          subtitle: 'Techniques & langues',
          icon: Icons.auto_awesome_outlined,
        ),
        const SizedBox(height: 10),
        GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Techniques',
                style: TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 11),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SkillChip('Flutter'),
                  _SkillChip('Dart'),
                  _SkillChip('HTML & CSS'),
                  _SkillChip('Git'),
                  _SkillChip('UI / UX'),
                  _SkillChip('Esprit d’équipe'),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Langues',
                style: TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const _LanguageBar(
                name: 'Français',
                level: 'Courant',
                value: 0.9,
              ),
              const SizedBox(height: 12),
              const _LanguageBar(
                name: 'Anglais',
                level: 'Intermédiaire',
                value: 0.70,
              ),
              const SizedBox(height: 12),
              const _LanguageBar(
                name: 'Swahili',
                level: 'Courant',
                value: 0.85,
              ),
              const SizedBox(height: 12),
              const _LanguageBar(
                name: 'Lingala',
                level: 'Intermédiaire',
                value: 0.65,
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const _SectionTitle(
          title: 'Centres d’intérêt',
          subtitle: 'En dehors du code',
          icon: Icons.favorite_border_rounded,
        ),
        const SizedBox(height: 10),
        GlassPanel(
          padding: const EdgeInsets.all(17),
          child: Wrap(
            spacing: 9,
            runSpacing: 9,
            children: const [
              _InterestChip(icon: Icons.menu_book_rounded, label: 'Lecture'),
              _InterestChip(
                icon: Icons.sports_basketball_rounded,
                label: 'Sport',
              ),
              _InterestChip(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Innovation',
              ),
              _InterestChip(
                icon: Icons.travel_explore_rounded,
                label: 'Découverte',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _EditableNote(),
      ],
    );
  }
}

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  List<_FamilyMember> _members = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await apiRequest('GET', '/famille-membres');
      final data = response['data'];
      final list = data is List
          ? data
          : data is Map
          ? (data['data'] as List? ?? const [])
          : const [];
      if (!mounted) return;
      setState(() {
        _members = list
            .whereType<Map>()
            .map(
              (item) => _FamilyMember.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ApiException
            ? error.message
            : 'Impossible de charger les membres.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMember(_FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce membre'),
        content: Text('Voulez-vous supprimer ${member.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB34353),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await apiRequest('DELETE', '/famille-membres/${member.id}');
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Membre supprimé')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Impossible de supprimer le membre.',
          ),
        ),
      );
    }
  }

  Future<void> _showMemberForm({_FamilyMember? member}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _FamilyMemberForm(member: member, onSaved: () => _loadMembers()),
    );
    if (saved == true) await _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Les personnes qui comptent',
            style: TextStyle(
              color: _ink,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Ma famille est enregistrée dynamiquement dans la base de données.',
            style: TextStyle(color: _muted, height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _showMemberForm(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Ajouter un membre'),
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            GlassPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_rounded, color: _muted, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loadMembers,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (_members.isEmpty)
            const GlassPanel(
              padding: EdgeInsets.all(18),
              child: Text(
                'Aucun membre enregistré pour le moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            )
          else
            for (final member in _members) ...[
              _FamilyCard(
                member: member,
                onEdit: () => _showMemberForm(member: member),
                onDelete: () => _deleteMember(member),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _FamilyMember {
  const _FamilyMember({
    required this.id,
    required this.nom,
    required this.postnom,
    required this.prenom,
    required this.lieuNaissance,
    required this.dateNaissance,
    required this.relationship,
    required this.imageUrl,
  });

  factory _FamilyMember.fromJson(Map<String, dynamic> json) {
    return _FamilyMember(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nom: json['nom']?.toString() ?? '',
      postnom: json['postnom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      lieuNaissance: json['lieu_naissance']?.toString() ?? '',
      dateNaissance: json['date_naissance']?.toString() ?? '',
      relationship: json['parente']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
    );
  }

  final int id;
  final String nom;
  final String postnom;
  final String prenom;
  final String lieuNaissance;
  final String dateNaissance;
  final String relationship;
  final String? imageUrl;

  String get fullName => '$prenom $postnom $nom'.replaceAll('  ', ' ').trim();
  String get initials => prenom.isNotEmpty ? prenom[0].toUpperCase() : '?';
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  final _FamilyMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: member.imageUrl == null || member.imageUrl!.isEmpty
                ? Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    color: const Color(0xFFE7EAFE),
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 25,
                      ),
                    ),
                  )
                : Image.network(
                    _normalizeImageUrl(member.imageUrl!),
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      color: const Color(0xFFE7EAFE),
                      child: Text(
                        member.initials,
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.relationship.toUpperCase(),
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  member.fullName,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${member.lieuNaissance} · ${member.dateNaissance}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Modifier',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: _blue),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB34353),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _normalizeImageUrl(String url) {
  final imageUri = Uri.tryParse(url);
  final apiUri = Uri.tryParse(_apiBaseUrl);
  if (imageUri == null || apiUri == null) return url;
  if (imageUri.host == 'localhost' || imageUri.host == '127.0.0.1') {
    return imageUri
        .replace(host: apiUri.host, port: apiUri.hasPort ? apiUri.port : null)
        .toString();
  }
  return url;
}

class _FamilyMemberForm extends StatefulWidget {
  const _FamilyMemberForm({required this.onSaved, this.member});

  final _FamilyMember? member;
  final Future<void> Function() onSaved;

  @override
  State<_FamilyMemberForm> createState() => _FamilyMemberFormState();
}

class _FamilyMemberFormState extends State<_FamilyMemberForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _postnom;
  late final TextEditingController _prenom;
  late final TextEditingController _lieu;
  late final TextEditingController _date;
  late final TextEditingController _parente;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _nom = TextEditingController(text: member?.nom);
    _postnom = TextEditingController(text: member?.postnom);
    _prenom = TextEditingController(text: member?.prenom);
    _lieu = TextEditingController(text: member?.lieuNaissance);
    _date = TextEditingController(text: member?.dateNaissance);
    _parente = TextEditingController(text: member?.relationship);
  }

  @override
  void dispose() {
    _nom.dispose();
    _postnom.dispose();
    _prenom.dispose();
    _lieu.dispose();
    _date.dispose();
    _parente.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final initial = DateTime.tryParse(_date.text) ?? DateTime(2000);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      _date.text =
          '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final body = {
      'nom': _nom.text.trim(),
      'postnom': _postnom.text.trim(),
      'prenom': _prenom.text.trim(),
      'lieu_naissance': _lieu.text.trim(),
      'date_naissance': _date.text.trim(),
      'parente': _parente.text.trim(),
    };

    try {
      if (widget.member == null) {
        await apiRequest('POST', '/famille-membres', body: body);
      } else {
        await apiRequest(
          'PUT',
          '/famille-membres/${widget.member!.id}',
          body: body,
        );
      }
      await widget.onSaved();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Impossible d’enregistrer le membre.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    IconData icon = Icons.person_outline_rounded,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(hint: label, icon: icon),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Ce champ est obligatoire.'
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.member != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        radius: 24,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        editing ? 'Modifier le membre' : 'Ajouter un membre',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field('Nom', _nom),
                const SizedBox(height: 10),
                _field('Postnom', _postnom),
                const SizedBox(height: 10),
                _field('Prénom', _prenom),
                const SizedBox(height: 10),
                _field(
                  'Lieu de naissance',
                  _lieu,
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _date,
                  readOnly: true,
                  onTap: _chooseDate,
                  decoration: _inputDecoration(
                    hint: 'Date de naissance',
                    icon: Icons.calendar_today_outlined,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Choisissez une date.'
                      : null,
                ),
                const SizedBox(height: 10),
                _field(
                  'Parenté (Père, Mère, Frère…)',
                  _parente,
                  icon: Icons.family_restroom_rounded,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(editing ? 'Enregistrer' : 'Ajouter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const _email = 'preciousmuhido18@gmail.com';
  static const _phone = '+243 970 529 536';
  static const _address = 'Goma, Congo KINSHASA';
  static const _linkedin = 'https://www.linkedin.com/';
  static const _github = 'https://github.com/';

  Future<void> _open(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir cette application.')),
      );
    }
  }

  Future<void> _copyAddress(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _address));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresse copiée dans le presse-papiers.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const Text(
          'Restons en contact',
          style: TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Une idée, une opportunité ou simplement envie d’échanger ?',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 19),
        GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _ContactTile(
                icon: Icons.phone_rounded,
                label: 'Téléphone',
                value: _phone,
                tint: const Color(0xFFE6F4ED),
                onTap: () =>
                    _open(context, Uri(scheme: 'tel', path: '+243970529536')),
              ),
              const _ContactDivider(),
              _ContactTile(
                icon: Icons.mail_rounded,
                label: 'E-mail',
                value: _email,
                tint: const Color(0xFFE9ECFF),
                onTap: () =>
                    _open(context, Uri(scheme: 'mailto', path: _email)),
              ),
              const _ContactDivider(),
              _ContactTile(
                icon: Icons.location_on_rounded,
                label: 'Adresse',
                value: _address,
                tint: const Color(0xFFFFEFE7),
                onTap: () => _copyAddress(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const _SectionTitle(
          title: 'Réseaux sociaux',
          subtitle: 'Retrouvez-moi en ligne',
          icon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 10),
        GlassPanel(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _SocialTile(
                icon: Icons.work_outline_rounded,
                label: 'LinkedIn',
                value: 'linkedin.com/in/Precious-Muhindo',
                onTap: () => _open(context, Uri.parse(_linkedin)),
              ),
              const Divider(height: 20, color: Color(0x26737C91)),
              _SocialTile(
                icon: Icons.code_rounded,
                label: 'GitHub',
                value: 'github.com/precious1811-prec',
                onTap: () => _open(context, Uri.parse(_github)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAFF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: _blue),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponible pour échanger',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Réponse sous 1 à 2 jours',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.circle, size: 9, color: Color(0xFF63BD91)),
            ],
          ),
        ),
        const SizedBox(height: 11),
        const _EditableNote(),
      ],
    );
  }
}

class _ContactDivider extends StatelessWidget {
  const _ContactDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 21, color: Color(0x26737C91));
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _blue, size: 19),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_outward_rounded, size: 16, color: _muted),
          ],
        ),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: _blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.north_east_rounded, size: 17, color: _muted),
          ],
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.88),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C67A5).withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F5FD),
                  Color(0xFFEEF1FC),
                  Color(0xFFF8F3F8),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          top: -90,
          right: -85,
          child: _GlowOrb(size: 250, color: Color(0x77B4C4FF)),
        ),
        const Positioned(
          left: -100,
          top: 270,
          child: _GlowOrb(size: 240, color: Color(0x66F4C8DC)),
        ),
        const Positioned(
          right: -80,
          bottom: -100,
          child: _GlowOrb(size: 270, color: Color(0x668DCECF)),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_blue, _violet],
            ),
            borderRadius: BorderRadius.circular(23),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.27),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'MICHÉE',
          style: TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'PORTFOLIO PERSONNEL',
          style: TextStyle(
            color: _muted.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [_blue, _violet]),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/profile_photo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFE9EBFF),
            alignment: Alignment.center,
            child: Text(
              'PM',
              style: TextStyle(
                color: _blue,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _ink,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, color: _blue, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.title,
    required this.organization,
    required this.period,
    required this.description,
    required this.icon,
  });

  final String title;
  final String organization;
  final String period;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      period,
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  organization,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 7),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEFF).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _blue,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LanguageBar extends StatelessWidget {
  const _LanguageBar({
    required this.name,
    required this.level,
    required this.value,
  });

  final String name;
  final String level;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(level, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: const Color(0xFFE8EAF3),
            valueColor: const AlwaysStoppedAnimation<Color>(_blue),
          ),
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _violet),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableNote extends StatelessWidget {
  const _EditableNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Pensez à remplacer les informations d’exemple par les vôtres.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _muted.withValues(alpha: 0.9),
        fontSize: 11,
        height: 1.4,
      ),
    );
  }
}
