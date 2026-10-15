import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:main/models/post.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  void _showEditNoteDialog(
    BuildContext context,
    Box box,
    Post post,
    String currentNote,
  ) {
    final noteController = TextEditingController(text: currentNote);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_note,
                  color: Colors.amber.shade900,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Personal Note'),
            ],
          ),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Personal Note',
              hintText: 'Enter your thoughts or notes...',
              prefixIcon: Icon(Icons.comment_outlined, size: 20),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newNote = noteController.text.trim();
                Navigator.pop(dialogContext);
                final updatedPost = post.copyWith(note: newNote);
                await box.put(updatedPost.id, updatedPost.toMap());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note updated successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)!.settings.arguments;
    final post = routeArgs is Post
        ? routeArgs
        : (routeArgs is Map
            ? Post.fromMap(routeArgs)
            : const Post(id: 0, title: 'No Title', body: 'No Content'));

    final box = Hive.box('favoritesBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ValueListenableBuilder<Box>(
        valueListenable: box.listenable(keys: [post.id]),
        builder: (context, favBox, _) {
          final isFavorite = favBox.containsKey(post.id);
          final savedRaw = isFavorite ? favBox.get(post.id) : null;
          final savedPost = savedRaw is Map ? Post.fromMap(savedRaw) : post;
          final personalNote = savedPost.note;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Meta Bar
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tag,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Post #${post.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 13,
                                color: Colors.blueGrey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '2 min read',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (isFavorite)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: 13,
                                  color: Color(0xFFE11D48),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Saved in Favorites',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFFBE123C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.35,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Article Content Card
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.article_outlined,
                                    size: 18,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'ARTICLE CONTENT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Color(0xFF4F46E5),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                            ),
                            Text(
                              post.body,
                              style: const TextStyle(
                                height: 1.7,
                                color: Color(0xFF334155),
                                fontSize: 16,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Personal Note Section
                    if (savedPost.hasNote) ...[
                      Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        color: const Color(0xFFFFFBEB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.amber.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    color: Colors.amber.shade900,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Personal Note',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.brown.shade900,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _showEditNoteDialog(
                                      context,
                                      box,
                                      savedPost,
                                      personalNote,
                                    ),
                                    icon: const Icon(Icons.edit, size: 14),
                                    label: const Text('Edit'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: Colors.brown.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                personalNote,
                                style: TextStyle(
                                  color: Colors.brown.shade900,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (isFavorite) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          side: BorderSide(color: Colors.amber.shade300),
                          backgroundColor:
                              Colors.amber.shade50.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showEditNoteDialog(
                          context,
                          box,
                          savedPost,
                          '',
                        ),
                        icon: Icon(
                          Icons.add_comment_outlined,
                          size: 18,
                          color: Colors.amber.shade900,
                        ),
                        label: Text(
                          'Add a personal note to this post',
                          style: TextStyle(
                            color: Colors.brown.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isFavorite
                              ? const Color(0xFF10B981)
                              : const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        label: Text(
                          isFavorite
                              ? 'Saved to Favorites'
                              : 'Save to Favorites',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        onPressed: () async {
                          final postToSave = post.copyWith(note: personalNote);
                          await box.put(postToSave.id, postToSave.toMap());
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavorite
                                    ? 'Post updated in favorites!'
                                    : 'Post saved to favorites!',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
