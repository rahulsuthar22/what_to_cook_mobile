import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/planner_provider.dart';
import 'recipe_detail_screen.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pageController;
  int _focusedIndex = 0;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeProvider>(context, listen: false).fetchRecipes().then((_) {
        setState(() {
          _isInit = true;
        });
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);

    if (!_isInit || recipeProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5A36)),
        ),
      );
    }

    final recipes = recipeProvider.recipes.where((r) => r.videoUrl.isNotEmpty).toList();

    if (recipes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          title: Text('Food Reels', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'No video recipes available.',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: recipes.length,
        onPageChanged: (index) {
          setState(() {
            _focusedIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final isCurrent = index == _focusedIndex;
          return ReelPlayerCard(
            recipe: recipes[index],
            isActive: isCurrent,
          );
        },
      ),
    );
  }
}

class ReelPlayerCard extends StatefulWidget {
  final RecipeModel recipe;
  final bool isActive;

  const ReelPlayerCard({
    super.key,
    required this.recipe,
    required this.isActive,
  });

  @override
  State<ReelPlayerCard> createState() => _ReelPlayerCardState();
}

class _ReelPlayerCardState extends State<ReelPlayerCard> {
  YoutubePlayerController? _ytController;
  bool _showHeartOverlay = false;
  bool _isLiked = false;
  int _likesCount = 42;

  final List<Map<String, String>> _comments = [];
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.sessionCookie != null) {
          options.headers['Cookie'] = auth.sessionCookie;
        }
        return handler.next(options);
      },
    ));

    _likesCount = 20 + widget.recipe.recipeId * 7; // Seeds mock likes as fallback
    if (widget.isActive) {
      _initPlayer();
      _loadLikesAndComments();
    }
  }

  Future<void> _loadLikesAndComments() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.uid;
    try {
      // 1. Fetch Likes
      String likesUrl = '/api/recipes/${widget.recipe.recipeId}/likes';
      if (userId != null) {
        likesUrl += '?user_id=$userId';
      }
      final likesRes = await _dio.get(likesUrl);
      if (likesRes.statusCode == 200 && likesRes.data['success'] == true) {
        setState(() {
          _likesCount = likesRes.data['likesCount'] ?? 0;
          _isLiked = likesRes.data['liked'] ?? false;
        });
      }

      // 2. Fetch Comments
      final commentsRes = await _dio.get('/api/recipes/${widget.recipe.recipeId}/comments');
      if (commentsRes.statusCode == 200 && commentsRes.data['success'] == true) {
        final List<dynamic> fetched = commentsRes.data['comments'] ?? [];
        setState(() {
          _comments.clear();
          for (var item in fetched) {
            _comments.add({
              'id': item['id']?.toString() ?? '',
              'user': item['user']?.toString() ?? 'Anonymous',
              'text': item['text']?.toString() ?? '',
              'time': item['time']?.toString() ?? 'Just now',
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading likes/comments: $e');
    }
  }

  Future<void> _toggleLikeBackend() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.uid;
    if (userId == null) return;

    try {
      final res = await _dio.post(
        '/api/recipes/${widget.recipe.recipeId}/likes',
        data: {'user_id': userId},
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _isLiked = res.data['liked'] ?? false;
          _likesCount = res.data['likesCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> _postCommentBackend(String text, StateSetter setModalState) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.uid;
    if (userId == null || text.trim().isEmpty) return;

    try {
      final res = await _dio.post(
        '/api/recipes/${widget.recipe.recipeId}/comments',
        data: {
          'user_id': userId,
          'comment': text.trim(),
        },
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final commentData = res.data['comment'];
        final Map<String, String> newComment = {
          'id': commentData['id']?.toString() ?? '',
          'user': commentData['user']?.toString() ?? 'Me',
          'text': commentData['text']?.toString() ?? '',
          'time': commentData['time']?.toString() ?? 'Just now',
        };

        setModalState(() {
          _comments.insert(0, newComment);
        });
        setState(() {}); // updates comments length on parent card
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
    }
  }

  @override
  void didUpdateWidget(covariant ReelPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initPlayer();
      _loadLikesAndComments();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposePlayer();
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _initPlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.recipe.videoUrl);
    if (videoId != null && _ytController == null) {
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: true,
          loop: true,
          hideControls: true,
        ),
      );
      setState(() {});
    }
  }

  void _disposePlayer() {
    _ytController?.dispose();
    _ytController = null;
  }

  void _onDoubleTap() {
    _toggleLikeBackend();
    setState(() {
      _showHeartOverlay = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showHeartOverlay = false;
        });
      }
    });
  }

  void _showCommentsSheet() {
    final primaryColor = const Color(0xFFFF5A36);
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comments',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (context, idx) {
                        final c = _comments[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              c['user']![0].toUpperCase(),
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            c['user']!,
                            style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            c['text']!,
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                          ),
                          trailing: Text(
                            c['time']!,
                            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: primaryColor),
                          onPressed: () {
                            if (textController.text.trim().isNotEmpty) {
                              _postCommentBackend(textController.text.trim(), setModalState);
                              textController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showScheduleModal() {
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);
    String mealType = 'Lunch';
    DateTime selectedDate = DateTime.now();
    bool isScheduling = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Schedule this recipe',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    icon: const Icon(Icons.date_range, color: Colors.white70),
                    label: Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: mealType,
                    dropdownColor: surfaceColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                    items: ['Breakfast', 'Lunch', 'Dinner']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        mealType = val!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: isScheduling
                      ? null
                      : () async {
                          setModalState(() {
                            isScheduling = true;
                          });
                          final planner = Provider.of<PlannerProvider>(context, listen: false);
                          final dateStr =
                              "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                          final success = await planner.scheduleMeal(
                            recipeId: widget.recipe.recipeId,
                            date: dateStr,
                            mealType: mealType,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Meal scheduled successfully!' : 'Scheduling failed.'),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                  child: isScheduling
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF5A36);

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onTap: () {
        if (_ytController != null) {
          if (_ytController!.value.isPlaying) {
            _ytController!.pause();
          } else {
            _ytController!.play();
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Youtube Player
          if (_ytController != null)
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: YoutubePlayer(
                  controller: _ytController!,
                  showVideoProgressIndicator: false,
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5A36)),
            ),

          // Dark Overlay for readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // Double Tap Animation Overlay
          if (_showHeartOverlay)
            Center(
              child: AnimatedOpacity(
                opacity: _showHeartOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.redAccent,
                  size: 100,
                ),
              ),
            ),

          // Right floating toolbar buttons
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                // Like Button
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.redAccent : Colors.white,
                    size: 34,
                  ),
                  onPressed: () {
                    _toggleLikeBackend();
                  },
                ),
                Text(
                  '$_likesCount',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Comments Button
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 32),
                  onPressed: _showCommentsSheet,
                ),
                Text(
                  '${_comments.length}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Schedule Meal
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white, size: 32),
                  onPressed: _showScheduleModal,
                ),
                Text(
                  'Plan',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // View Details
                IconButton(
                  icon: const Icon(Icons.arrow_circle_right_outlined, color: Colors.white, size: 34),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: widget.recipe)),
                    );
                  },
                ),
                Text(
                  'Details',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Left bottom info box
          Positioned(
            left: 20,
            bottom: 40,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.recipe.category,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.recipe.cookingTime} mins • ${widget.recipe.difficultyLevel}',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.recipe.recipeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Double tap to like the reel. Tap once to play/pause.',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
