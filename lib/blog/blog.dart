import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() =>
      _CommunityPageState();
}

class _CommunityPageState
    extends State<CommunityPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController postController =
      TextEditingController();

  final TextEditingController commentController =
      TextEditingController();

  final picker = ImagePicker();

  List<dynamic> posts = [];

  bool isLoading = true;
  bool isPosting = false;

  File? selectedImage;

  String selectedCategory =
      "General Discussion";

  bool isAnonymous = false;

  final List<String> categories = [
    "General Discussion",
    "Health Question",
    "Mental Health",
    "Fitness",
    "Nutrition",
    "Medication",
    "Recommendations",
    "Emergency",
  ];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .order(
            'created_at',
            ascending: false,
          );

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

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage() async {
    if (selectedImage == null) return null;

    try {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}.jpg";

      await supabase.storage
          .from('community-images')
          .upload(
            fileName,
            selectedImage!,
          );

      final imageUrl = supabase.storage
          .from('community-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      debugPrint("IMAGE UPLOAD ERROR: $e");
      return null;
    }
  }

  Future<void> createPost() async {
    if (postController.text.trim().isEmpty) {
      return;
    }

    try {
      setState(() {
        isPosting = true;
      });

      final user =
          supabase.auth.currentUser;

      if (user == null) return;

      final patient = await supabase
          .from('patients')
          .select()
          .eq('id', user.id)
          .single();

      String? imageUrl;

      if (selectedImage != null) {
        imageUrl = await uploadImage();
      }

      await supabase.from('posts').insert({
        'user_id': user.id,

        'user_role': 'patient',

        'full_name':
            patient['full_name'] ??
                'Unknown User',

        'profile_image_url':
            patient['profile_image_url'],

        'content':
            postController.text.trim(),

        'image_url': imageUrl,

        'category': selectedCategory,

        'is_anonymous': isAnonymous,

        'is_verified_doctor': false,
      });

      postController.clear();

      setState(() {
        selectedImage = null;
        isAnonymous = false;
        selectedCategory =
            "General Discussion";
      });

      fetchPosts();
    } catch (e) {
      debugPrint("CREATE POST ERROR: $e");
    }

    setState(() {
      isPosting = false;
    });
  }

  Future<void> toggleLike(
    String postId,
  ) async {
    try {
      final user =
          supabase.auth.currentUser;

      if (user == null) return;

      final existingLike = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        await supabase
            .from('post_likes')
            .delete()
            .eq('id', existingLike['id']);

        await supabase.rpc(
          'decrement_likes',
          params: {
            'post_id_input': postId,
          },
        );
      } else {
        await supabase
            .from('post_likes')
            .insert({
          'post_id': postId,
          'user_id': user.id,
        });

        await supabase.rpc(
          'increment_likes',
          params: {
            'post_id_input': postId,
          },
        );
      }

      fetchPosts();
    } catch (e) {
      debugPrint("LIKE ERROR: $e");
    }
  }

  Future<void> addComment(
    String postId,
  ) async {
    if (commentController.text
        .trim()
        .isEmpty) {
      return;
    }

    try {
      final user =
          supabase.auth.currentUser;

      if (user == null) return;

      final patient = await supabase
          .from('patients')
          .select()
          .eq('id', user.id)
          .single();

      await supabase
          .from('comments')
          .insert({
        'post_id': postId,

        'user_id': user.id,

        'user_role': 'patient',

        'full_name':
            patient['full_name'],

        'content':
            commentController.text
                .trim(),
      });

      await supabase.rpc(
        'increment_comments',
        params: {
          'post_id_input': postId,
        },
      );

      commentController.clear();

      fetchPosts();
    } catch (e) {
      debugPrint("COMMENT ERROR: $e");
    }
  }

  Future<List<dynamic>> fetchComments(
    String postId,
  ) async {
    return await supabase
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order(
          'created_at',
          ascending: true,
        );
  }

  Future<void> deletePost(
    String postId,
  ) async {
    try {
      await supabase
          .from('posts')
          .delete()
          .eq('id', postId);

      fetchPosts();
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
    }
  }

  String formatDate(String date) {
    final parsed = DateTime.parse(date);

    return DateFormat(
      'dd MMM yyyy • hh:mm a',
    ).format(parsed);
  }

  Widget roleBadge(
    String role,
    bool verified,
  ) {
    if (role == 'doctor') {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),

        decoration: BoxDecoration(
          color: Colors.blue.shade100,

          borderRadius:
              BorderRadius.circular(12),
        ),

        child: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.verified,
              size: 14,
              color: Colors.blue,
            ),

            const SizedBox(width: 4),

            Text(
              verified
                  ? "Verified Doctor"
                  : "Doctor",

              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (role == 'admin') {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),

        decoration: BoxDecoration(
          color: Colors.purple.shade100,

          borderRadius:
              BorderRadius.circular(12),
        ),

        child: const Text(
          "Admin",

          style: TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: Colors.green.shade100,

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: const Text(
        "Patient",

        style: TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9FF),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchPosts,

          child: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : ListView(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  children: [
                    Card(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        child: Column(
                          children: [
                            TextField(
                              controller:
                                  postController,

                              maxLines: 4,

                              decoration:
                                  InputDecoration(
                                hintText:
                                    "Share something with the community...",

                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            DropdownButtonFormField(
                              value:
                                  selectedCategory,

                              items: categories
                                  .map(
                                    (e) =>
                                        DropdownMenuItem(
                                      value:
                                          e,

                                      child:
                                          Text(
                                        e,
                                      ),
                                    ),
                                  )
                                  .toList(),

                              onChanged: (
                                value,
                              ) {
                                setState(() {
                                  selectedCategory =
                                      value!;
                                });
                              },

                              decoration:
                                  InputDecoration(
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            Row(
                              children: [
                                Checkbox(
                                  value:
                                      isAnonymous,

                                  onChanged:
                                      (
                                        value,
                                      ) {
                                    setState(
                                      () {
                                        isAnonymous =
                                            value!;
                                      },
                                    );
                                  },
                                ),

                                const Text(
                                  "Post anonymously",
                                ),
                              ],
                            ),

                            if (selectedImage !=
                                null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                  top: 10,
                                ),

                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),

                                  child: Image.file(
                                    selectedImage!,
                                    height:
                                        180,
                                    width:
                                        double
                                            .infinity,
                                    fit:
                                        BoxFit
                                            .cover,
                                  ),
                                ),
                              ),

                            const SizedBox(
                              height: 10,
                            ),

                            SizedBox(
  width: double.infinity,

  child: Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: pickImage,
          icon: const Icon(Icons.image),
          label: const Text("Image", style: TextStyle(color: Colors.white)),
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: ElevatedButton(
          onPressed:
              isPosting ? null : createPost,

          style:
              ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),

          child: isPosting
              ? const SizedBox(
                  width: 18,
                  height: 18,

                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  "Post",

                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    ],
  ),
)
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ...posts.map((post) {
                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 20,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,

                                    backgroundImage:
                                        post['profile_image_url'] !=
                                                null
                                            ? NetworkImage(
                                                post[
                                                    'profile_image_url'],
                                              )
                                            : null,

                                    child:
                                        post['profile_image_url'] ==
                                                null
                                            ? const Icon(
                                                Icons.person,
                                              )
                                            : null,
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [
                                        Text(
                                          post['is_anonymous'] ==
                                                  true
                                              ? "Anonymous Patient"
                                              : post[
                                                      'full_name'] ??
                                                  '',

                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,

                                            fontSize:
                                                16,
                                          ),
                                        ),

                                        const SizedBox(
                                          height:
                                              4,
                                        ),

                                        Row(
                                          children: [
                                            roleBadge(
                                              post[
                                                  'user_role'],

                                              post[
                                                      'is_verified_doctor'] ??
                                                  false,
                                            ),

                                            const SizedBox(
                                              width:
                                                  8,
                                            ),

                                            Text(
                                              formatDate(
                                                post[
                                                    'created_at'],
                                              ),

                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.grey.shade600,

                                                fontSize:
                                                    12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (supabase
                                          .auth
                                          .currentUser
                                          ?.id ==
                                      post['user_id'])
                                    PopupMenuButton(
                                      itemBuilder:
                                          (
                                            context,
                                          ) =>
                                              [
                                        PopupMenuItem(
                                          onTap:
                                              () {
                                            deletePost(
                                              post[
                                                  'id'],
                                            );
                                          },

                                          child:
                                              const Text(
                                            "Delete",
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              Text(
                                post['content'],
                                style:
                                    const TextStyle(
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              if (post['image_url'] !=
                                  null)
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),

                                  child: Image.network(
                                    post['image_url'],

                                    width:
                                        double
                                            .infinity,

                                    fit:
                                        BoxFit
                                            .cover,
                                  ),
                                ),

                              const SizedBox(
                                height: 16,
                              ),

                              Row(
                                children: [
                                  IconButton(
                                    onPressed:
                                        () {
                                      toggleLike(
                                        post[
                                            'id'],
                                      );
                                    },

                                    icon:
                                        const Icon(
                                      Icons
                                          .favorite_border,
                                    ),
                                  ),

                                  Text(
                                    post[
                                            'likes_count']
                                        .toString(),
                                  ),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  const Icon(
                                    Icons.comment,
                                  ),

                                  const SizedBox(
                                    width: 6,
                                  ),

                                  Text(
                                    post[
                                            'comments_count']
                                        .toString(),
                                  ),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  const Icon(
                                    Icons.repeat,
                                  ),

                                  const SizedBox(
                                    width: 6,
                                  ),

                                  Text(
                                    post[
                                            'reposts_count']
                                        .toString(),
                                  ),
                                ],
                              ),

                              const Divider(),

                              FutureBuilder(
                                future:
                                    fetchComments(
                                  post['id'],
                                ),

                                builder: (
                                  context,
                                  snapshot,
                                ) {
                                  if (!snapshot
                                      .hasData) {
                                    return const SizedBox();
                                  }

                                  final comments =
                                      snapshot
                                          .data!;

                                  return Column(
                                    children: [
                                      ...comments.map(
                                        (
                                          comment,
                                        ) {
                                          return Container(
                                            margin:
                                                const EdgeInsets.only(
                                              bottom:
                                                  10,
                                            ),

                                            padding:
                                                const EdgeInsets.all(
                                              10,
                                            ),

                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  Colors.grey.shade100,

                                              borderRadius:
                                                  BorderRadius.circular(
                                                12,
                                              ),
                                            ),

                                            child:
                                                Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,

                                              children: [
                                                Text(
                                                  comment[
                                                      'full_name'],

                                                  style:
                                                      const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),

                                                const SizedBox(
                                                  height:
                                                      4,
                                                ),

                                                Text(
                                                  comment[
                                                      'content'],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),

                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                TextField(
                                              controller:
                                                  commentController,

                                              decoration:
                                                  InputDecoration(
                                                hintText:
                                                    "Write a comment...",

                                                border:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(
                                            width:
                                                8,
                                          ),

                                          IconButton(
                                            onPressed:
                                                () {
                                              addComment(
                                                post[
                                                    'id'],
                                              );
                                            },

                                            icon:
                                                const Icon(
                                              Icons
                                                  .send,
                                              color:
                                                  Colors.blue,
                                            ),
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
                    }),
                  ],
                ),
        ),
      ),
    );
  }
}