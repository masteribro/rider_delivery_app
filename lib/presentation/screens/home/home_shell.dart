import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_cubit.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static int _indexFromLocation(String location) {
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/earnings')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: bottom > 0 ? bottom : 16,
          top: 8,
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.list_alt_rounded,
                label: 'Orders',
                isActive: currentIndex == 1,
                onTap: () => context.go('/orders'),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Earnings',
                isActive: currentIndex == 2,
                onTap: () => context.go('/earnings'),
              ),
              _AccountNavItem(
                isActive: currentIndex == 3,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : const Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AccountNavItem({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : const Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final photoUrl = state is AuthAuthenticated
                    ? state.rider.photoUrl
                    : null;

                if (photoUrl != null) {
                  return Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: 1.5,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }

                return Icon(Icons.person_rounded, size: 22, color: color);
              },
            ),
            const SizedBox(height: 3),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
