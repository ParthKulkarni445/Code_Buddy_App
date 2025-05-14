import 'package:flutter/material.dart';
import 'package:acex/services.dart';
import 'package:acex/utils/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:acex/providers/user_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class ClubDetailPage extends StatefulWidget {
  final String clubId;
  final String clubName;
  
  const ClubDetailPage({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  final ClubService _clubService = ClubService();
  Club? _club;
  List<ClubDiscussion> _discussions = [];
  List<ClubProblem> _problems = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoadingDiscussions = true;
  bool _isLoadingProblems = true;
  bool _isLoadingLeaderboard = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClubDetails();
  }
  
  Future<void> _fetchClubDetails() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final club = await _clubService.getClubById(widget.clubId);
      
      setState(() {
        _club = club;
        isLoading = false;
      });
      
      // Fetch tab data
      _fetchDiscussions();
      _fetchProblems();
      _fetchLeaderboard();
    } catch (e) {
      print('Error fetching club details: $e');
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load club details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _fetchDiscussions() async {
    setState(() {
      _isLoadingDiscussions = true;
    });
    
    try {
      final discussions = await _clubService.getClubDiscussions(widget.clubId);
      
      setState(() {
        _discussions = discussions;
        _isLoadingDiscussions = false;
      });
    } catch (e) {
      print('Error fetching discussions: $e');
      setState(() {
        _isLoadingDiscussions = false;
      });
    }
  }
  
  Future<void> _fetchProblems() async {
    setState(() {
      _isLoadingProblems = true;
    });
    
    try {
      final problems = await _clubService.getClubProblems(widget.clubId);
      
      setState(() {
        _problems = problems;
        _isLoadingProblems = false;
      });
    } catch (e) {
      print('Error fetching problems: $e');
      setState(() {
        _isLoadingProblems = false;
      });
    }
  }
  
  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoadingLeaderboard = true;
    });
    
    try {
      final leaderboard = await _clubService.getClubLeaderboard(widget.clubId);
      
      setState(() {
        _leaderboard = leaderboard;
        _isLoadingLeaderboard = false;
      });
    } catch (e) {
      print('Error fetching leaderboard: $e');
      setState(() {
        _isLoadingLeaderboard = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color clubColor = _getClubColor(widget.clubName);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: LoadingCard(primaryColor: Colors.purple))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 200.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: clubColor,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        _club?.name ?? widget.clubName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black38,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          _club?.bannerUrl != null
                              ? Image.network(
                                  _club!.bannerUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            clubColor.withOpacity(0.7),
                                            clubColor,
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        clubColor.withOpacity(0.7),
                                        clubColor,
                                      ],
                                    ),
                                  ),
                                ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                          if (_club != null)
                            Positioned(
                              bottom: 60,
                              left: 16,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_club!.memberCount} members',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _club!.isPublic ? Icons.public : Icons.lock,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _club!.isPublic ? 'Public' : 'Private',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    actions: [
                      if (_club != null && _isUserAdmin())
                        IconButton(
                          icon: const Icon(Icons.settings),
                          color: Colors.white,
                          onPressed: () {
                            // Club settings
                            _showClubSettingsDialog();
                          },
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'leave' && _club != null) {
                            _showLeaveClubDialog();
                          } else if (value == 'share') {
                            // Share club
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon'),
                              ),
                            );
                          } else if (value == 'report') {
                            // Report club
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report feature coming soon'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          if (_club != null && _isUserMember() && !_isUserCreator())
                            const PopupMenuItem(
                              value: 'leave',
                              child: Row(
                                children: [
                                  Icon(Icons.exit_to_app, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Leave Club', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share),
                                SizedBox(width: 8),
                                Text('Share'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag),
                                SizedBox(width: 8),
                                Text('Report'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: clubColor,
                        labelColor: clubColor,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: 'Discussions'),
                          Tab(text: 'Problems'),
                          Tab(text: 'Leaderboard'),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiscussionsTab(),
                  _buildProblemsTab(),
                  _buildLeaderboardTab(),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildDiscussionsTab() {
    if (_isLoadingDiscussions) {
      return _buildLoadingShimmer();
    }
    
    if (_discussions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.forum,
        title: 'No discussions yet',
        message: 'Be the first to start a discussion in this club!',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchDiscussions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _discussions.length,
        itemBuilder: (context, index) {
          final discussion = _discussions[index];
          return _buildDiscussionCard(discussion);
        },
      ),
    );
  }

  Widget _buildDiscussionCard(ClubDiscussion discussion) {
    final Color clubColor = _getClubColor(widget.clubName);
    final formattedDate = DateFormat.yMMMd().format(discussion.createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Open discussion detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Discussion detail coming soon'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: clubColor.withOpacity(0.2),
                    radius: 20,
                    child: Text(
                      discussion.authorName.substring(0, min(2, discussion.authorName.length)).toUpperCase(),
                      style: TextStyle(
                        color: clubColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discussion.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                discussion.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                discussion.content,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${discussion.commentCount} comments',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${discussion.likeCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemsTab() {
    if (_isLoadingProblems) {
      return _buildLoadingShimmer();
    }
    
    if (_problems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.code,
        title: 'No problems yet',
        message: 'Add coding problems for club members to solve!',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchProblems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _problems.length,
        itemBuilder: (context, index) {
          final problem = _problems[index];
          return _buildProblemCard(problem);
        },
      ),
    );
  }

  Widget _buildProblemCard(ClubProblem problem) {
    final Color difficultyColor = _getDifficultyColor(problem.difficulty);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Open problem detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Problem detail coming soon'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      problem.difficulty.capitalize(),
                      style: TextStyle(
                        color: difficultyColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.purple,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${problem.points} pts',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                problem.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                problem.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${problem.solvedCount} solved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.yMMMd().format(problem.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLoadingLeaderboard) {
      return _buildLoadingShimmer();
    }
    
    if (_leaderboard.isEmpty) {
      return _buildEmptyState(
        icon: Icons.leaderboard,
        title: 'No leaderboard data yet',
        message: 'Solve problems to appear on the leaderboard!',
      );
    }
    
    final userId = Provider.of<UserProvider>(context, listen: false).user.id;
    
    return RefreshIndicator(
      onRefresh: _fetchLeaderboard,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Problems',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Points',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final entry = _leaderboard[index];
                final isCurrentUser = entry['userId'] == userId;
                final clubColor = _getClubColor(widget.clubName);
                
                return Container(
                  color: isCurrentUser 
                      ? clubColor.withOpacity(0.1) 
                      : (index % 2 == 0 ? Colors.grey[100] : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                            color: index < 3 ? clubColor : null,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: clubColor.withOpacity(0.2),
                              child: Text(
                                entry['username'].substring(0, min(1, entry['username'].length)).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: clubColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry['username'],
                              style: TextStyle(
                                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  '(You)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: clubColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${entry['problemsSolved']}',
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${entry['points']}',
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final Color clubColor = _getClubColor(widget.clubName);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: clubColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_club == null) return const SizedBox.shrink();
    
    final Color clubColor = _getClubColor(widget.clubName);
    
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        // Show different FAB based on selected tab and user permissions
        if (!_isUserMember()) {
          return FloatingActionButton(
            onPressed: () => _joinClub(),
            backgroundColor: clubColor,
            child: const Icon(Icons.person_add, color: Colors.white),
          );
        }
        
        switch (_tabController.index) {
          case 0: // Discussions
            return FloatingActionButton(
              onPressed: () {
                _showNewDiscussionDialog();
              },
              backgroundColor: clubColor,
              child: const Icon(Icons.add_comment, color: Colors.white),
            );
          case 1: // Problems
            if (_isUserAdmin()) {
              return FloatingActionButton(
                onPressed: () {
                  _showAddProblemDialog();
                },
                backgroundColor: clubColor,
                child: const Icon(Icons.add, color: Colors.white),
              );
            }
            return const SizedBox.shrink();
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  void _showNewDiscussionDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Discussion'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a title'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              _addDiscussion(
                titleController.text.trim(),
                contentController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getClubColor(widget.clubName),
              foregroundColor: Colors.white,
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _addDiscussion(String title, String content) async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      await _clubService.addDiscussion(
        clubId: widget.clubId,
        title: title,
        content: content,
        authorId: user.id,
        authorName: user.handle,
      );
      
      // Hide loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discussion posted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _fetchDiscussions();
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post discussion: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddProblemDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String difficulty = 'medium';
    int points = 100;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Problem'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Problem Title',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    value: difficulty,
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      DropdownMenuItem(value: 'expert', child: Text('Expert')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          difficulty = value;
                          // Set default points based on difficulty
                          switch (value) {
                            case 'easy':
                              points = 50;
                              break;
                            case 'medium':
                              points = 100;
                              break;
                            case 'hard':
                              points = 150;
                              break;
                            case 'expert':
                              points = 200;
                              break;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Points: '),
                      Expanded(
                        child: Slider(
                          value: points.toDouble(),
                          min: 10,
                          max: 300,
                          divisions: 29,
                          label: points.toString(),
                          activeColor: _getClubColor(widget.clubName),
                          onChanged: (value) {
                            setState(() {
                              points = value.toInt();
                            });
                          },
                        ),
                      ),
                      Text(
                        points.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Problem Statement',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a problem title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  _addProblem(
                    titleController.text.trim(),
                    descriptionController.text.trim(),
                    difficulty,
                    points,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getClubColor(widget.clubName),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addProblem(String title, String description, String difficulty, int points) async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      await _clubService.addProblem(
        clubId: widget.clubId,
        title: title,
        description: description,
        difficulty: difficulty,
        points: points,
        authorId: user.id,
      );
      
      // Hide loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _fetchProblems();
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add problem: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClubSettingsDialog() {
    if (_club == null) return;
    
    final nameController = TextEditingController(text: _club!.name);
    final descriptionController = TextEditingController(text: _club!.description);
    bool isPublic = _club!.isPublic;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Club Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Club Name',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Public Club'),
                    subtitle: const Text('Anyone can join a public club'),
                    value: isPublic,
                    activeColor: _getClubColor(widget.clubName),
                    onChanged: (value) {
                      setState(() {
                        isPublic = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a club name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  // Update club settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Club settings updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getClubColor(widget.clubName),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLeaveClubDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Club'),
        content: const Text('Are you sure you want to leave this club?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveClub();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinClub() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      await _clubService.joinClub(widget.clubId, user.id);
      
      // Hide loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the club'),
          backgroundColor: Colors.green,
        ),
      );
      
      _fetchClubDetails();
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join club: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveClub() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      await _clubService.leaveClub(widget.clubId, user.id);
      
      // Hide loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully left the club'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Go back to social page
      Navigator.pop(context);
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave club: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isUserMember() {
    if (_club == null) return false;
    
    final userId = Provider.of<UserProvider>(context, listen: false).user.id;
    return _club!.members.contains(userId);
  }

  bool _isUserAdmin() {
    if (_club == null) return false;
    
    final userId = Provider.of<UserProvider>(context, listen: false).user.id;
    return _club!.admins.contains(userId);
  }

  bool _isUserCreator() {
    if (_club == null) return false;
    
    final userId = Provider.of<UserProvider>(context, listen: false).user.id;
    return _club!.createdBy == userId;
  }

  Color _getClubColor(String clubName) {
    final List<Color> colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    
    // Use hash of club name to determine color
    final int hash = clubName.hashCode.abs();
    return colors[hash % colors.length];
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'hard':
        return Colors.orange;
      case 'expert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}