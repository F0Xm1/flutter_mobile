import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/core/supabase_client.dart';
import 'package:test1/src/cubit/auth/auth_cubit.dart';
import 'package:test1/src/cubit/profile/profile_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ProfileCubit();
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _logout() async {
    await context.read<AuthCubit>().signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? '';
    final avatarLetter =
        email.isNotEmpty ? email[0].toUpperCase() : '?';
    final createdAt = user?.createdAt != null
        ? DateTime.parse(user!.createdAt).toLocal()
        : null;

    return BlocProvider<ProfileCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Профіль'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.orange.withValues(alpha: 0.3),
            ),
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgDeep, Color(0xFF140800)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AvatarSection(
                          letter: avatarLetter,
                          email: email,
                          createdAt: createdAt,
                        ),
                        const SizedBox(height: 24),
                        const _SectionLabel('Система'),
                        const SizedBox(height: 8),
                        BlocBuilder<ProfileCubit, ProfileState>(
                          builder: (context, state) {
                            if (state is ProfileLoading) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                    color: AppColors.orange,
                                  ),
                                ),
                              );
                            }
                            if (state is ProfileError) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  state.message,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            if (state is ProfileLoaded) {
                              return Column(
                                children: [
                                  _StatRow(
                                    icon: Icons.location_on_outlined,
                                    label: 'Локації',
                                    value: '${state.locationCount}',
                                  ),
                                  const SizedBox(height: 8),
                                  _StatRow(
                                    icon: Icons.sensors,
                                    label: 'Сенсори',
                                    value: '${state.sensorCount}',
                                  ),
                                  const SizedBox(height: 8),
                                  _StatRow(
                                    icon: Icons.warning_amber_outlined,
                                    label: 'Подій сьогодні',
                                    value: '${state.todayEventCount}',
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.exit_to_app,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Вийти з акаунта',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
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

class _AvatarSection extends StatelessWidget {
  final String letter;
  final String email;
  final DateTime? createdAt;

  const _AvatarSection({
    required this.letter,
    required this.email,
    required this.createdAt,
  });

  String _formatDate(DateTime dt) {
    final months = [
      'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.orange.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.orange, width: 2),
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          email,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (createdAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Учасник з ${_formatDate(createdAt!)}',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.orangeWarm,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orangeWarm, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
