import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/app_colors.dart';
import 'package:test1/presentation/cubits/dashboard_cubit.dart';
import 'package:test1/src/bloc/connection/connection_bloc.dart';
import 'package:test1/src/bloc/connection/connection_state.dart' as connection;
import 'package:test1/src/cubit/auth/auth_cubit.dart';
import 'package:test1/src/screens/home_page/home_content.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final DashboardCubit _dashboardCubit;

  @override
  void initState() {
    super.initState();
    final connectionBloc = context.read<ConnectionBloc>();
    _dashboardCubit = DashboardCubit(connectionBloc);
    _dashboardCubit.startWatching();
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthCubit>().signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>.value(
      value: _dashboardCubit,
      child: BlocListener<ConnectionBloc, connection.ConnectionState>(
        listener: (context, state) {
          if (state is connection.ConnectionConnected) {
            ScaffoldMessenger.of(context).clearSnackBars();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.bgSurface,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.orange.withValues(alpha: 0.3),
              ),
            ),
            title: BlocBuilder<DashboardCubit, DashboardState>(
              buildWhen: (prev, next) =>
                  prev.runtimeType != next.runtimeType ||
                  (next is DashboardLoaded &&
                      (prev is! DashboardLoaded ||
                          prev.activeLocationId != next.activeLocationId ||
                          prev.locations.length != next.locations.length)),
              builder: (context, state) {
                if (state is DashboardLoaded && state.locations.isNotEmpty) {
                  return _LocationSelector(
                    locations: state.locations,
                    activeId: state.activeLocationId,
                    onSelected: _dashboardCubit.switchLocation,
                  );
                }
                return const Text(
                  'Чіпідізєль',
                  style: TextStyle(color: Colors.white),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.white54),
                tooltip: 'Вийти',
                onPressed: () => _logout(context),
              ),
            ],
          ),
          body: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.bgDeep, Color(0xFF140800)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(child: HomeContent()),
          ),
        ),
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final List<Map<String, dynamic>> locations;
  final String? activeId;
  final ValueChanged<String> onSelected;

  const _LocationSelector({
    required this.locations,
    required this.activeId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.length == 1) {
      return Text(
        locations.first['name'] as String,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      );
    }
    return DropdownButton<String>(
      value: activeId,
      dropdownColor: AppColors.bgElevated,
      iconEnabledColor: AppColors.orangeWarm,
      underline: const SizedBox.shrink(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      items: locations.map((loc) {
        return DropdownMenuItem<String>(
          value: loc['id'] as String,
          child: Text(
            loc['name'] as String,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (id) {
        if (id != null) onSelected(id);
      },
    );
  }
}
