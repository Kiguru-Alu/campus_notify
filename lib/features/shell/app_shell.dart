import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../auth/providers/auth_providers.dart';
import '../home/screens/home_screen.dart';
import '../incidents/providers/incident_filter.dart';
import '../incidents/screens/incident_list_screen.dart';
import '../incidents/screens/report_incident_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../staff/screens/staff_queue_screen.dart';

/// Holds the four persistent tabs. Reporting is a pushed route rather than
/// a tab: it is a task you finish and leave, not a place you browse.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  /// The campus list and the personal list share one filter provider, so it
  /// is reset on tab change rather than silently carrying over.
  void _select(int value) {
    if (value != _index) {
      ref.read(incidentFilterProvider.notifier).clear();
    }
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(isStaffProvider);

    final pages = <Widget>[
      const HomeScreen(),
      const IncidentListScreen(),
      isStaff ? const StaffQueueScreen() : const IncidentListScreen(mineOnly: true),
      const ProfileScreen(),
    ];

    return Scaffold(
      // IndexedStack keeps each tab's scroll position and its Firestore
      // listeners alive while switching.
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ReportIncidentScreen()),
        ),
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        index: _index,
        isStaff: isStaff,
        onSelect: _select,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.isStaff,
    required this.onSelect,
  });

  final int index;
  final bool isStaff;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      const _NavItem(Icons.layers_outlined, Icons.layers_rounded, 'Campus'),
      isStaff
          ? const _NavItem(Icons.task_alt_outlined, Icons.task_alt, 'Queue')
          : const _NavItem(
              Icons.description_outlined, Icons.description, 'Mine'),
      const _NavItem(Icons.person_outline, Icons.person, 'Profile'),
    ];

    return BottomAppBar(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      height: 64,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 7,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: _NavButton(
                item: items[i],
                selected: index == i,
                onTap: () => onSelect(i),
              ),
            ),
            // Gap for the docked action button.
            if (i == 1) const SizedBox(width: 68),
          ],
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.inkFaint;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: AppType.caption(color: color).copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
