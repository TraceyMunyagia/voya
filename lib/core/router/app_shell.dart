import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, required this.location, super.key});
  final Widget child;
  final String location;
  static const destinations = <({String label, IconData icon, String path})>[
    (label: 'Home', icon: Icons.home_outlined, path: '/home'),
    (label: 'Explore', icon: Icons.explore_outlined, path: '/explore'),
    (label: 'Create', icon: Icons.add_circle_outline, path: '/create'),
    (label: 'Saved', icon: Icons.bookmark_border, path: '/saved'),
    (label: 'Profile', icon: Icons.person_outline, path: '/profile'),
  ];
  @override
  Widget build(BuildContext context) {
    final selected = destinations.indexWhere(
      (item) => location.startsWith(item.path),
    );
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (index) => context.go(destinations[index].path),
        destinations: [
          for (final item in destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(_selectedIcon(item.icon)),
              label: item.label,
            ),
        ],
      ),
    );
  }

  static IconData _selectedIcon(IconData icon) {
    switch (icon) {
      case Icons.home_outlined:
        return Icons.home;
      case Icons.explore_outlined:
        return Icons.explore;
      case Icons.add_circle_outline:
        return Icons.add_circle;
      case Icons.bookmark_border:
        return Icons.bookmark;
      case Icons.person_outline:
        return Icons.person;
      default:
        return icon;
    }
  }
}
