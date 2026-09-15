// lib/features/earnings/screens/earnings_screen.dart (Driver App)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/core/theme/driver_theme.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(_earningsProvider);

    return Scaffold(
      backgroundColor: DriverColors.background,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: DriverColors.background,
        leading: const BackButton(color: DriverColors.onBackground),
      ),
      body: earningsAsync.when(
        loading: () => _EarningsShimmer(),
        error: (e, _) => Center(child: Text('Failed to load earnings', style: TextStyle(color: DriverColors.error))),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's earnings hero card
              _EarningsHeroCard(
                todayPaise: data.todayPaise,
                weekPaise: data.weekPaise,
                monthPaise: data.monthPaise,
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Weekly bar chart
              Text('This Week', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _WeeklyChart(weeklyData: data.weeklyDailyPaise)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Stats row
              _StatsRow(tripCount: data.weekTripCount, onlineHours: data.weekOnlineHours),
              const SizedBox(height: 24),

              // Recent trips
              Text('Recent Trips', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...data.recentTrips.asMap().entries.map((e) =>
                _TripEarningRow(trip: e.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 300 + e.key * 60))
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsHeroCard extends StatelessWidget {
  final int todayPaise;
  final int weekPaise;
  final int monthPaise;

  const _EarningsHeroCard({required this.todayPaise, required this.weekPaise, required this.monthPaise});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: DriverColors.earningsGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DriverColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Earnings',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(todayPaise / 100),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(label: 'This Week', value: fmt.format(weekPaise / 100)),
              const SizedBox(width: 24),
              _MiniStat(label: 'This Month', value: fmt.format(monthPaise / 100)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white60)),
      Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
    ],
  );
}

class _WeeklyChart extends StatelessWidget {
  final List<int> weeklyData; // 7 values in paise
  const _WeeklyChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final max = weeklyData.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (max / 100 + 100).toDouble(),
          barGroups: weeklyData.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value / 100,
                gradient: const LinearGradient(
                  colors: [DriverColors.primary, DriverColors.secondary],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (max / 100 + 100).toDouble(),
                  color: DriverColors.surfaceElevated,
                ),
              ),
            ],
          )).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  days[v.toInt()],
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: DriverColors.onSurfaceMuted),
                ),
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int tripCount;
  final double onlineHours;
  const _StatsRow({required this.tripCount, required this.onlineHours});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Trips', value: '$tripCount', icon: Icons.route_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Online', value: '${onlineHours.toStringAsFixed(1)}h', icon: Icons.timer_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Accept Rate', value: '94%', icon: Icons.check_circle_outline_rounded)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: DriverColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: DriverColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: DriverColors.onBackground)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: DriverColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _TripEarningRow extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripEarningRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final fare = ((trip['actualFarePaise'] as int? ?? 0) / 100).toStringAsFixed(0);
    final distance = ((trip['distanceMeters'] as int? ?? 0) / 1000).toStringAsFixed(1);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DriverColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DriverColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.route_rounded, color: DriverColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip['dropAddress'] as String? ?? 'Drop', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: DriverColors.onBackground), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$distance km', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: DriverColors.onSurfaceMuted)),
              ],
            ),
          ),
          Text(
            '₹$fare',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: DriverColors.primary),
          ),
        ],
      ),
    );
  }
}

class _EarningsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: DriverColors.surfaceElevated,
      highlightColor: DriverColors.surfaceBorder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(height: 160, decoration: BoxDecoration(color: DriverColors.surface, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 24),
            Container(height: 180, decoration: BoxDecoration(color: DriverColors.surface, borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }
}

// Data model
class EarningsData {
  final int todayPaise;
  final int weekPaise;
  final int monthPaise;
  final List<int> weeklyDailyPaise;
  final int weekTripCount;
  final double weekOnlineHours;
  final List<Map<String, dynamic>> recentTrips;

  const EarningsData({
    required this.todayPaise,
    required this.weekPaise,
    required this.monthPaise,
    required this.weeklyDailyPaise,
    required this.weekTripCount,
    required this.weekOnlineHours,
    required this.recentTrips,
  });
}

// Provider
final _earningsProvider = FutureProvider.autoDispose<EarningsData>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final resp = await dio.get<Map<String, dynamic>>('/v1/drivers/me/earnings');
  final d = resp.data?['data'] as Map<String, dynamic>? ?? {};
  final weekly = (d['weeklyDailyPaise'] as List<dynamic>?)?.map((e) => e as int).toList() ?? List.filled(7, 0);
  return EarningsData(
    todayPaise: d['todayPaise'] as int? ?? 0,
    weekPaise: d['weekPaise'] as int? ?? 0,
    monthPaise: d['monthPaise'] as int? ?? 0,
    weeklyDailyPaise: weekly,
    weekTripCount: d['weekTripCount'] as int? ?? 0,
    weekOnlineHours: (d['weekOnlineHours'] as num?)?.toDouble() ?? 0,
    recentTrips: (d['recentTrips'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
  );
});
