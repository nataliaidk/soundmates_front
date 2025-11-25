import 'package:flutter/material.dart';
import 'package:zpi_test/api/api_client.dart';
import 'package:zpi_test/api/token_store.dart';
import 'package:zpi_test/api/event_hub_service.dart';
import 'package:zpi_test/screens/chat_screen.dart';
import 'package:zpi_test/screens/visit_profile/visit_profile_loader.dart';
import 'package:zpi_test/screens/visit_profile/visit_profile_model.dart';
import 'package:zpi_test/theme/app_design_system.dart';

class MatchScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final String userId;
  final DateTime? matchTime;
  final EventHubService? eventHubService;

  const MatchScreen({
    super.key,
    required this.api,
    required this.tokens,
    required this.userId,
    this.matchTime,
    this.eventHubService,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final VisitProfileLoader _loader;
  late Future<VisitProfileViewModel> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loader = VisitProfileLoader(widget.api);
    _dataFuture = _loader.loadData(widget.userId);
  }

  void _navigateToChat(VisitProfileViewModel data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          api: widget.api,
          tokens: widget.tokens,
          userId: widget.userId,
          userName: data.profile.name ?? 'User',
          userImageUrl: data.profileImageUrl,
          eventHubService: widget.eventHubService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDarkGrey,
      body: FutureBuilder<VisitProfileViewModel>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.accentPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading match data',
                style: const TextStyle(color: AppColors.textWhite),
              ),
            );
          }

          final data = snapshot.data!;
          final profile = data.profile;
          final name = profile.name ?? 'User';
          final imageUrl = data.profileImageUrl;

          // Extract top tags (limit to 3 for clean UI)
          final tags = <String>[];
          data.groupedTags.forEach((category, tagList) {
            tags.addAll(tagList);
          });
          final displayTags = tags.take(3).toList();

          return Stack(
            children: [
              // Background circles/waves decoration (simplified)
              Positioned.fill(
                child: CustomPaint(
                  painter: _BackgroundPainter(
                    bottomPadding: MediaQuery.of(context).padding.bottom,
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),

                    // "You connected with"
                    Text(
                      'You connected with',
                      style: AppTextStyles.headingSmall,
                    ),

                    const SizedBox(height: 8),

                    // Name
                    Text(
                      name,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.accentPurpleSoft,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Time (Hardcoded for now as requested)
                    Text('11 mins ago', style: AppTextStyles.timeText),

                    const SizedBox(height: 40),

                    // Avatar with glow
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentPurple.withOpacity(0.5),
                          width: 4,
                        ),
                        boxShadow: AppShadows.purpleGlowShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircleAvatar(
                          backgroundImage: imageUrl != null
                              ? NetworkImage(imageUrl)
                              : null,
                          backgroundColor: Colors.grey.shade800,
                          child: imageUrl == null
                              ? Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: AppTextStyles.avatarInitialLarge,
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Tags
                    if (displayTags.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: displayTags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.radiusMediumAlt,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: AppColors.textBlack87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                    const Spacer(flex: 2),

                    // Bottom Chat FAB (Big button)
                    GestureDetector(
                      onTap: () => _navigateToChat(data),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentPurple.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.textWhite,
                          size: 36,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double bottomPadding;

  _BackgroundPainter({required this.bottomPadding});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Button is 80px height + 40px bottom margin
    // Center is 40px (margin) + 40px (half height) = 80px from bottom of safe area
    final center = Offset(size.width / 2, size.height - bottomPadding - 80);

    // Draw concentric circles
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, i * 80.0, paint);
    }

    // Draw some arcs for "tech/modern" feel
    final arcPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 200),
      -0.5,
      1.0,
      false,
      arcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 280),
      3.5,
      1.5,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.bottomPadding != bottomPadding;
  }
}
