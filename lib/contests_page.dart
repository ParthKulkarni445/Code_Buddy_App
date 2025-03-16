import 'package:acex/contests_details.dart';
import 'package:acex/services.dart';
import 'package:acex/settings.dart';
import 'package:acex/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';

class ContestsPage extends StatefulWidget {
  const ContestsPage({super.key});

  @override
  State<ContestsPage> createState() => _ContestsPageState();
}

class _ContestsPageState extends State<ContestsPage> {
  late Future<List<dynamic>> contests;
  final Map<String, List<dynamic>> _groupedContests = {};
  final Map<String, int> _currentPage = {};
  final int _pageSize = 50;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<dynamic>> _contestEvents = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final _calendarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    contests = ApiService().getContests();
    contests.then((contestsList) {
      _processContestEvents(contestsList);
    });
  }

  void _processContestEvents(List<dynamic> contestsList) {
    final Map<DateTime, List<dynamic>> events = {};
    
    for (final contest in contestsList) {
      if (contest['phase'] == 'BEFORE') {
        final startTime = DateTime.fromMillisecondsSinceEpoch(contest['startTimeSeconds'] * 1000);
        final dateOnly = DateTime(startTime.year, startTime.month, startTime.day);
        
        if (!events.containsKey(dateOnly)) {
          events[dateOnly] = [];
        }
        events[dateOnly]!.add(contest);
      }
    }
    
    setState(() {
      _contestEvents = events;
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _contestEvents[dateOnly] ?? [];
  }

  void _retryFetchData() {
    setState(() {
      _fetchData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
      _groupedContests.clear();
      _currentPage.clear();
      _contestEvents.clear();
    });
    await Future.wait([contests]);
  }

  Map<String, List<dynamic>> _groupContests(List<dynamic> contests) {
    final grouped = <String, List<dynamic>>{};
    for (final contest in contests) {
      final status = _getContestStatus(contest);
      if (!grouped.containsKey(status)) {
        grouped[status] = [];
      }
      grouped[status]!.add(contest);
    }
    if (grouped.containsKey('Upcoming')) {
      grouped['Upcoming']!.sort((a, b) => a['startTimeSeconds'].compareTo(b['startTimeSeconds']));
    }
    return grouped;
  }

  String _getContestStatus(dynamic contest) {
    switch (contest['phase']) {
      case 'CODING':
        return 'Ongoing';
      case 'BEFORE':
        return 'Upcoming';
      default:
        return 'Finished';
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        centerTitle: true,
        elevation: 15,
        shadowColor: Colors.black,
        title: const Text('Contests', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.yellow[600],
        surfaceTintColor: Colors.yellow[600],
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              } else if (value == 'signout') {
                final authService = AuthService();
                authService.signOut(context);
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
            color: Colors.white, // Dropdown background color
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.black),
                    const SizedBox(width: 8),
                    const Text('Settings', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.black),
                    const SizedBox(width: 8),
                    const Text('Sign Out', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([contests]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingCard(primaryColor: Colors.yellow),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _buildErrorWidget();
          }
          final allContests = snapshot.data![0];
          _groupedContests.addAll(_groupContests(allContests));
          final List<Widget> contestWidgets = [];
          
          // Add calendar widget
          contestWidgets.add(_buildCalendarWidget());
          contestWidgets.add(const SizedBox(height: 24));
          
          for (var entry in _groupedContests.entries) {
            contestWidgets.add(_buildContestGroup(entry.key, entry.value));
            contestWidgets.add(const SizedBox(height: 24));
          }
          contestWidgets.add(const SizedBox(height: 80));
    
          return RefreshIndicator(
            color: Colors.black,
            backgroundColor: Colors.yellow[600],
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: contestWidgets,
              ),
            ),
          );
        }
      )
    );
  }

  Widget _buildCalendarWidget() {
    return Card(
      elevation: 7,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.yellow[600],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12.0),
            width: double.infinity,
            child: const Text(
              'Contest Calendar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          StatefulBuilder(
            key: _calendarKey,
            builder: (context, setCalendarState) {
              return Column(
                children: [
                  TableCalendar(
                    rowHeight: 46,
                    firstDay: DateTime.now().subtract(const Duration(days: 30)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setCalendarState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setCalendarState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 3,
                      markerDecoration: BoxDecoration(
                        color: Colors.yellow[600],
                        shape: BoxShape.circle,
                      ),
                      // Today's date styling
                      todayDecoration: BoxDecoration(
                        border: Border.all(color: Colors.yellow[600]!, width: 1),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      // Selected day styling
                      selectedDecoration: BoxDecoration(
                        color: Colors.yellow[600],
                        shape: BoxShape.circle,
                      ),
                      // Remove the dot indicator
                      isTodayHighlighted: true,
                      markersAutoAligned: true,
                      markersOffset: const PositionedOffset(
                        top: -5,
                        start: 0,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonDecoration: BoxDecoration(
                        color: Colors.yellow[600],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      formatButtonTextStyle: const TextStyle(color: Colors.black),
                      titleCentered: true,
                    ),
                    calendarBuilders: CalendarBuilders(
                      // Custom marker builder to control the appearance of event markers
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            bottom: 7,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.yellow[900],
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  _buildSelectedDayEvents(),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('No contests on this day'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            'Contests on ${DateFormat('MMM d, yyyy').format(_selectedDay)}:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length > 3 ? 3 : events.length,
          itemBuilder: (context, index) {
            final contest = events[index];
            final startTime = DateTime.fromMillisecondsSinceEpoch(contest['startTimeSeconds'] * 1000);
            
            return ListTile(
              leading: Icon(Icons.event, color: Colors.yellow[600]),
              title: Text(contest['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${DateFormat('HH:mm').format(startTime)} (IST)'),
              dense: true,
            );
          },
        ),
        if (events.length > 3)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // Scroll to the Upcoming section
                  // This is a simplified approach - you might want to implement a more sophisticated scrolling mechanism
                },
                child: Text(
                  'See all ${events.length} contests',
                  style: TextStyle(color: Colors.yellow[800]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildContestGroup(String status, List<dynamic> contests) {
    if (!_currentPage.containsKey(status)) {
      _currentPage[status] = 1;
    }

    final int totalPages = (contests.length / _pageSize).ceil();

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final int startIndex = (_currentPage[status]! - 1) * _pageSize;
        final int endIndex = startIndex + _pageSize > contests.length 
            ? contests.length 
            : startIndex + _pageSize;
        final List<dynamic> currentPageContests = contests.sublist(startIndex, endIndex);

        return Card(
          elevation: 7,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.yellow[600],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentPageContests.length,
                itemBuilder: (context, index) => _buildContestTile(currentPageContests[index]),
                separatorBuilder: (context, index) => const Divider(color: Colors.grey, thickness: 2,),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage[status]! > 1 ? () {
                        setState(() {
                          _currentPage[status] = _currentPage[status]! - 1;
                        });
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[600],
                        elevation: 5
                      ),
                      child: const Icon(Icons.chevron_left, size: 25, color: Colors.black),
                    ),
                    Text('Page ${_currentPage[status]} of $totalPages', textAlign: TextAlign.center,),
                    ElevatedButton(
                      onPressed: _currentPage[status]! < totalPages ? () {
                        setState(() {
                          _currentPage[status] = _currentPage[status]! + 1;
                        });
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[600],
                        elevation: 5
                      ),
                      child: const Icon(Icons.chevron_right, size: 25, color: Colors.black,),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContestTile(dynamic contest) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(contest['startTimeSeconds'] * 1000);
    final duration = Duration(seconds: contest['durationSeconds']);
    
    final dateFormat = DateFormat('MMM/dd/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    final formattedDate = dateFormat.format(startTime);
    final formattedTime = timeFormat.format(startTime);
    final formattedDuration = '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}';
    
    return ListTile(
      title: Text(contest['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.calendarDays, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Date: ', style: TextStyle(color: Colors.grey[600])),
                  Text(formattedDate, style: const TextStyle(color: Color.fromARGB(255, 11, 35, 243)),),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.clock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Start Time: ', style: TextStyle(color: Colors.grey[600])),
                  Text('$formattedTime (IST)',  style: const TextStyle(color:Color.fromARGB(255, 11, 35, 243)),)
                ],
              ),
              const SizedBox(height: 6),
               Row(
                children: [
                  FaIcon(FontAwesomeIcons.hourglassHalf, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Duration: ',style: TextStyle(color: Colors.grey[600])),
                  Text('$formattedDuration hrs')
                ],
              ),
              const SizedBox(height: 10),
               (contest['phase']=='BEFORE')?Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final url = 'https://codeforces.com/contestRegistration/${contest['id']}';
                      _launchURL(url);
                    },
                    style: ElevatedButton.styleFrom(
                      side:const BorderSide(color: Colors.black, width: 1.5),
                      backgroundColor: Colors.yellow[600],
                      elevation: 5
                    ),
                    child: const Text('Register', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ):Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContestDetailsPage(contestId: contest['id']),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      side:const BorderSide(color: Colors.black, width: 1.5),
                      backgroundColor: Colors.yellow[600],
                      elevation: 5
                    ),
                    child: const Text('View Details', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 10),
            // Make the card square
            SizedBox(
            width: 80,
            height: 80,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.black, width: 2),
              ),
              color: Colors.yellow[600],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Text(startTime.day.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(DateFormat('MMM').format(startTime), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.signal_wifi_statusbar_connected_no_internet_4_outlined, 
            size: 150
          ),
          const SizedBox(height: 18),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 22, 
              color: Colors.black, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _retryFetchData,
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor: Colors.yellow[600],
            ),
            child: const Text(
              'Retry', 
              style: TextStyle(color: Colors.black)
            ),
          ),
        ],
      ),
    );
  }
}