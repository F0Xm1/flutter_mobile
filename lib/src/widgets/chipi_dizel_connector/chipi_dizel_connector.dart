import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/cubit/station/connection_cubit.dart';

class ChipiDizelConnector extends StatelessWidget {
  final void Function(bool)? onConnectionChanged;
  final bool isOnline;

  const ChipiDizelConnector({
    required this.isOnline,
    this.onConnectionChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const Color accentPurple = Color(0xFF8A2BE2);

    return BlocConsumer<ConnectorCubit, ConnectorState>(
      listener: (context, state) {
        if (state is ConnectorConnected) {
          onConnectionChanged?.call(true);
        } else if (state is ConnectorDisconnected) {
          onConnectionChanged?.call(false);
        }
      },
      builder: (context, state) {
        final isLoading = state is ConnectorLoading;
        final connected = state is ConnectorConnected;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: !isOnline
                  ? const Text(
                      'Немає інтернету',
                      key: ValueKey('no_inet'),
                      style: TextStyle(fontSize: 18, color: Colors.redAccent),
                    )
                  : isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          connected ? 'Підключено' : 'Не підключено',
                          key: ValueKey(connected),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: isLoading || !isOnline
                  ? null
                  : () => context.read<ConnectorCubit>().toggleConnection(
                        isOnline,
                      ),
              child: Text(connected ? 'Відключитись' : 'Підключитись'),
            ),
          ],
        );
      },
    );
  }
}
