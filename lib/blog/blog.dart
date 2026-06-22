import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityPage extends StatefulWidget {
  final VoidCallback? onPostUpdated; 
  final bool isPinnedInShell; 

  const CommunityPage({
    this.onPostUpdated, 
    this.isPinnedInShell = false, 
    super.key,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController postController = TextEditingController();

  List<dynamic> posts = [];
  bool isLoading = true;
  bool isPosting = false;
  String selectedCategory = "General Discussion";
  bool isAnonymous = false;
  String? currentUserRole;

  final List<String> categories = [
    "General Discussion",
    "Health Question",
    "Mental Health",
    "Fitness",
    "Nutrition",
    "Medication",
    "Recommendations",
    "Emergency",
    "Notice"
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        posts = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("FETCH POSTS ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentUserRole() async {
  final user = supabase.auth.currentUser;
  if (user != null) {
    final profile = await _getUserProfile(user.id);
    if (mounted) {
      setState(() {
        currentUserRole = profile?['role'];
      });
    }
  }
}

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final docCheck = await supabase.from('doctors').select().eq('id', userId).maybeSingle();
      if (docCheck != null) {
        return {
          'role': 'doctor',
          'full_name': docCheck['full_name'] ?? 'Doctor',
          'profile_image_url': docCheck['profile_image_url'],
          'is_verified': docCheck['is_verified'] ?? true, 
        };
      }

      final patientCheck = await supabase.from('patients').select().eq('id', userId).maybeSingle();
      if (patientCheck != null) {
        return {
          'role': 'patient',
          'full_name': patientCheck['full_name'] ?? 'Patient',
          'profile_image_url': patientCheck['profile_image_url'],
          'is_verified': false,
        };
      }

      final adminCheck = await supabase.from('admins').select().eq('id', userId).maybeSingle();
      if (adminCheck != null) {
        return {
          'role': 'admin',
         'full_name': adminCheck['full_name'] ?? 'Admin',
          'profile_image_url': adminCheck['profile_image_url'],
          'is_verified': false,
        };
      }

      return {'role': 'user', 'full_name': 'Community Member', 'profile_image_url': null, 'is_verified': false};
    } catch (e) {
      debugPrint("Metadata extraction error: $e");
      return null;
    }
  }
Future<void> createPost() async {
  if (postController.text.trim().isEmpty) return;

  try {
    setState(() {
      isPosting = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _getUserProfile(user.id);
    
    final String confirmedRole = profile?['role'] ?? 'patient';
    final String confirmedName = profile?['full_name'] ?? 'Community Member';
    final bool verifiedDoctorStatus = profile?['is_verified'] ?? false;

    await supabase.from('posts').insert({
      'user_id': user.id,
      'user_role': confirmedRole, 
      'full_name': confirmedName,
      'profile_image_url': profile?['profile_image_url'],
      'content': postController.text.trim(),
      'category': selectedCategory,
      'is_anonymous': confirmedRole == 'patient' ? isAnonymous : false, //this is where we make sure only patients can post anonymously
      'is_verified_doctor': confirmedRole == 'doctor' ? verifiedDoctorStatus : false,
    });

    postController.clear();
    setState(() {
      isAnonymous = false;
      selectedCategory = "General Discussion";
    });

    fetchPosts();
  } catch (e) {
    debugPrint("CREATE POST ERROR: $e");
  } finally {
    if (mounted) {
      setState(() {
        isPosting = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final Widget mainBody = SafeArea(
      child: RefreshIndicator(
        onRefresh: fetchPosts,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: postController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "Share something with the community...",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            items: categories
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value!;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Select Category",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ).toInputDecoration(),
                          ),
                          const SizedBox(height: 10),
                          
                          if (currentUserRole == 'patient') ...[ 
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              "Post anonymously",
                               style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                            value: isAnonymous,
                            onChanged: (value) {
                            setState(() {
                           isAnonymous = value;
                             });
                             },
                           ),
                           const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isPosting ? null : createPost,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: isPosting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      "Create Post",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...posts.map((post) => PostCard(
                        key: ValueKey(post['id']),
                        post: post,
                        onPostUpdated: fetchPosts,
                      )),
                ],
              ),
      ),
    );


    if (widget.isPinnedInShell) {
      return Container(
        color: const Color(0xFFF5F9FF),
        child: mainBody,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: mainBody,
    );
  }
}


extension on InputDecoration {
  InputDecoration toInputDecoration() => this;
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onPostUpdated;

  const PostCard({
    required this.post,
    required this.onPostUpdated,
    super.key,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final supabase = Supabase.instance.client;
  
  late final TextEditingController _commentController; 
  late Future<List<dynamic>> _commentsFuture;
  
  int localLikesCount = 0;
  int localCommentsCount = 0;
  bool isLikedByMe = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _syncPostData();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post['id'] != oldWidget.post['id']) {
      _syncPostData();
    } else {
      final serverLikes = widget.post['likes_count'] ?? 0;
      final serverComments = widget.post['comments_count'] ?? 0;
      
      if (serverLikes > 0 && serverLikes != localLikesCount) {
        setState(() => localLikesCount = serverLikes);
      }
      if (serverComments > 0 && serverComments != localCommentsCount) {
        setState(() => localCommentsCount = serverComments);
      }
    }
  }

  void _syncPostData() {
    setState(() {
      localLikesCount = widget.post['likes_count'] ?? 0;
      localCommentsCount = widget.post['comments_count'] ?? 0;
      _loadComments();
      _checkIfLikedByMe();
    });
  }

  void _loadComments() {
    setState(() {
      _commentsFuture = supabase
          .from('comments')
          .select()
          .eq('post_id', widget.post['id'])
          .order('created_at', ascending: true);
    });
  }

  Future<void> _checkIfLikedByMe() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final List<dynamic> existingLikes = await supabase
        .from('post_likes')
        .select()
        .eq('post_id', widget.post['id'])
        .eq('user_id', user.id);

    if (mounted) {
      setState(() {
        isLikedByMe = existingLikes.isNotEmpty;
      });
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      setState(() {
        if (isLikedByMe) {
          isLikedByMe = false;
          localLikesCount = (localLikesCount > 0) ? localLikesCount - 1 : 0;
        } else {
          isLikedByMe = true;
          localLikesCount += 1;
        }
      });

      final List<dynamic> existingLikes = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id);

      if (existingLikes.isNotEmpty) {
        await supabase.from('post_likes').delete().eq('post_id', postId).eq('user_id', user.id);
        await supabase.rpc('decrement_likes', params: {'post_id_input': postId});
      } else {
        await supabase.from('post_likes').insert({'post_id': postId, 'user_id': user.id});
        await supabase.rpc('increment_likes', params: {'post_id_input': postId, 'user_id_input': user.id});
      }
      
      widget.onPostUpdated.call();
    } catch (e) {
      debugPrint("LIKE ERROR: $e");
    }
  }

  Future<Map<String, dynamic>> _getCommenterMetadata(String userId) async {
    final doc = await supabase.from('doctors').select('full_name').eq('id', userId).maybeSingle();
    if (doc != null) return {'role': 'doctor', 'name': doc['full_name']};

    final pat = await supabase.from('patients').select('full_name').eq('id', userId).maybeSingle();
    if (pat != null) return {'role': 'patient', 'name': pat['full_name']};

    return {'role': 'user', 'name': 'User'};
  }

  Future<void> addComment(String postId) async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final meta = await _getCommenterMetadata(user.id);
      _commentController.clear();

      await supabase.from('comments').insert({
        'post_id': postId,
        'user_id': user.id,
        'user_role': meta['role'],
        'full_name': meta['name'],
        'content': commentText,
      });

      await supabase.rpc('increment_comments', params: {
        'post_id_input': postId,
        'user_id_input': user.id,
        'comment_content': commentText,
      });

      setState(() {
        localCommentsCount += 1;
      });
      
      _loadComments();
      widget.onPostUpdated.call();
    } catch (e) {
      debugPrint("COMMENT ERROR: $e");
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await supabase.from('comments').delete().eq('id', commentId);
      try {
        await supabase.rpc('decrement_comments', params: {'post_id_input': widget.post['id']});
      } catch (_) {}

      setState(() {
        localCommentsCount = (localCommentsCount > 0) ? localCommentsCount - 1 : 0;
      });

      _loadComments();
      widget.onPostUpdated.call();
    } catch (e) {
      debugPrint("DELETE COMMENT ERROR: $e");
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);
      widget.onPostUpdated.call();
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
    }
  }

  String formatDate(String date) {
  final parsed = DateTime.parse(date);
  
  final localDateTime = parsed.toLocal(); 

  return DateFormat('dd MMM yyyy • hh:mm a').format(localDateTime);
}

  Widget roleBadge(String role, bool verified) {
    Color bg = Colors.green.shade100;
    String text = "Patient";

    if (role == 'doctor') {
      bg = Colors.blue.shade100;
      text = verified ? "Verified Doctor" : "Doctor";
    } else if (role == 'admin') {
      bg = Colors.purple.shade100;
      text = "Admin";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (role == 'doctor') ...[
            const Icon(Icons.verified, size: 14, color: Colors.blue),
            const SizedBox(width: 4),
          ],
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUserId = supabase.auth.currentUser?.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: (post['is_anonymous'] != true && post['profile_image_url'] != null) 
      ? NetworkImage(post['profile_image_url']) 
      : null,
                  child: post['profile_image_url'] == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        post['is_anonymous'] == true ? "Anonymous Patient" : post['full_name'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,                   
        overflow: TextOverflow.ellipsis, 
      ),
      const SizedBox(height: 4),
      Row(
        children: [

          roleBadge(post['user_role'] ?? 'patient', post['is_verified_doctor'] ?? false),
          const SizedBox(width: 6),
          
          
          Expanded(
            child: Text(
              formatDate(post['created_at']), 
              style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  ),
),
                if (currentUserId == post['user_id'])
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') deletePost(post['id']);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text("Delete Post", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(post['content'] ?? '', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
              child: Text(
                post['category'] ?? '',
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => toggleLike(post['id']),
                  icon: Icon(isLikedByMe ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                  label: Text(localLikesCount.toString()),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.comment, color: Colors.grey),
                const SizedBox(width: 6),
                Text(localCommentsCount.toString()),
              ],
            ),
            const Divider(),
            FutureBuilder<List<dynamic>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final comments = snapshot.data!;

                return Column(
                  children: [
                    ...comments.map((comment) {
                      final isMyComment = currentUserId == comment['user_id'];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(comment['content'] ?? ''),
                                ],
                              ),
                            ),
                            if (isMyComment)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete Comment"),
                                      content: const Text("Are you sure you want to remove this comment?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            deleteComment(comment['id']);
                                          },
                                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: "Write a comment...",
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => addComment(post['id']),
                          icon: const Icon(Icons.send, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
