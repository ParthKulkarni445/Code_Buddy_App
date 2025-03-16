import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:math';

class MomentumCard extends StatelessWidget {
  final List<dynamic> ratingHistory;
  final List<dynamic> submissions;

  const MomentumCard({
    Key? key,
    required this.ratingHistory,
    required this.submissions,
  }) : super(key: key);

  double _calculateMomentum() {
    double momentum = 0;
    
    // Calculate contest performance (60% of momentum)
    if (ratingHistory.isNotEmpty) {
      // Get last 3 contests
      final recentContests = ratingHistory.length >= 5 
          ? ratingHistory.sublist(ratingHistory.length - 5) 
          : ratingHistory;
      
      int totalDelta = 0;
      int positiveContests = 0;
      
      for (var contest in recentContests) {
        int delta = contest['newRating'] - contest['oldRating'];
        totalDelta += delta;
        if (delta > 0) positiveContests++;
      }
      
      // Calculate contest score (0-3)
      double contestScore = 0;
      if (recentContests.isNotEmpty) {
        // Average delta impact
        double avgDelta = totalDelta.toDouble();
        contestScore += (avgDelta>0)?2.5*(1-exp(-avgDelta/300)):-2.5*(1-exp(avgDelta/300));
        
        // Consistency impact
        contestScore += (positiveContests / recentContests.length) * 0.5;
      }
      
      momentum += contestScore.toDouble();
    }
    
    // Calculate recent practice (40% of momentum)
    if (submissions.isNotEmpty) {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      
      int acceptedSubmissions = 0;
      int totalSubmissions = 0;
      Set<String> uniqueProblems = {};
      
      for (var submission in submissions) {
        final submissionTime = DateTime.fromMillisecondsSinceEpoch(
            submission['creationTimeSeconds'] * 1000);
        
        if (submissionTime.isAfter(oneWeekAgo)) {
          totalSubmissions++;
          
          if (submission['verdict'] == 'OK') {
            acceptedSubmissions++;
            uniqueProblems.add('${submission['problem']['contestId']}${submission['problem']['index']}');
          }
        }
      }
      
      // Calculate practice score (0-2)
      double practiceScore = 0;
      
      // Unique problems solved impact
      practiceScore += min(uniqueProblems.length / 5, 1.2);
      
      // Acceptance rate impact
      if (totalSubmissions > 0) {
        double acceptanceRate = acceptedSubmissions / totalSubmissions;
        practiceScore += acceptanceRate * 0.8;
      }
      
      momentum += practiceScore; // 40% weight
    }
    
    // Ensure momentum is between 0 and 5
    return momentum.clamp(0, 5);
  }

  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;

  String _getMomentumDescription(double momentum) {
    if (momentum >= 4.5) return "Exceptional! You're on fire!";
    if (momentum >= 3.5) return "Great momentum! Keep it up!";
    if (momentum >= 2.5) return "Good progress, Stay consistent!";
    if (momentum >= 1.5) return "Steady pace, Try to push harder!";
    if (momentum >= 0.5) return "Building momentum, More practice needed";
    return "Time to get back on track!";
  }

  Color _getMomentumColor(double momentum) {
    if (momentum >= 4) return Colors.red;
    if (momentum >= 3) return Colors.orange;
    if (momentum >= 2) return Colors.blue;
    if (momentum >= 1) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final momentum = _calculateMomentum();
    
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Momentum',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildMomentumMeter(momentum),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getMomentumDescription(momentum),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _getMomentumColor(momentum),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMomentumStats(),
            ],
          ),
        ),
      ),
    );
  }

  // Using Syncfusion Gauge package instead of custom paint
  Widget _buildMomentumMeter(double momentum) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        return Container(
          width: availableWidth,
          height: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Syncfusion Radial Gauge
              Expanded(
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 5,
                      startAngle: 180,
                      endAngle: 0,
                      showLabels: true,
                      showLastLabel: true,
                      showTicks: true,
                      radiusFactor: 1,
                      canScaleToFit: true,
                      axisLineStyle: AxisLineStyle(
                        thickness: 0.2,
                        color: Colors.grey[300],
                        cornerStyle: CornerStyle.bothCurve,
                        thicknessUnit: GaugeSizeUnit.factor,
                      ),
                      pointers: <GaugePointer>[
                        RangePointer(
                          value: momentum,
                          width: 0.2,
                          cornerStyle: CornerStyle.startCurve,
                          sizeUnit: GaugeSizeUnit.factor,
                          color: _getMomentumColor(momentum),
                          enableAnimation: true,
                          animationDuration: 2000,
                          animationType: AnimationType.easeInCirc,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Text(
                            momentum.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                              color: _getMomentumColor(momentum),
                            ),
                          ),
                          angle: 90,
                          positionFactor: 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMomentumStats() {
    // Calculate stats for display
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    
    // Contest stats
    num contestDelta = 0;
    if (ratingHistory.isNotEmpty && ratingHistory.length >= 5) {
      final recentContests = ratingHistory.sublist(ratingHistory.length - 5);
      for (var contest in recentContests) {
        contestDelta += contest['newRating'] - contest['oldRating'];
      }
    }
    
    // Submission stats
    int weeklySubmissions = 0;
    int acceptedSubmissions = 0;
    Set<String> uniqueProblems = {};
    
    for (var submission in submissions) {
      final submissionTime = DateTime.fromMillisecondsSinceEpoch(
          submission['creationTimeSeconds'] * 1000);
      
      if (submissionTime.isAfter(oneWeekAgo)) {
        weeklySubmissions++;
        
        if (submission['verdict'] == 'OK') {
          acceptedSubmissions++;
          uniqueProblems.add('${submission['problem']['contestId']}${submission['problem']['index']}');
        }
      }
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        _buildStatItem(
          FontAwesomeIcons.trophy, 
          'Last 5 Contests', 
          contestDelta >= 0 ? '+$contestDelta' : '$contestDelta',
          contestDelta >= 0 ? Colors.green : Colors.red,
        ),
        _buildStatItem(
          FontAwesomeIcons.code, 
          'Problems Solved (7d)', 
          uniqueProblems.length.toString(),Colors.black
        ),
        _buildStatItem(
          FontAwesomeIcons.check, 
          'Acceptance Rate (7d)', 
          weeklySubmissions > 0 
              ? '${(acceptedSubmissions / weeklySubmissions * 100).toStringAsFixed(1)}%' 
              : 'N/A',Colors.black
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return LayoutBuilder(
      builder: (context,constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FaIcon(icon, size: constraints.maxWidth*0.07, color: Colors.grey[600]),
              SizedBox(
                width: constraints.maxWidth * 0.88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[600])),
                    Text(value.length > 19 ? '${value.substring(0, 19)}...' : value,
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      maxLines: 1,),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}