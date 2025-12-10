import 'package:flutter/material.dart';
import 'package:soundmates/api/api_client.dart';
import 'package:soundmates/api/token_store.dart';
import 'package:soundmates/api/event_hub_service.dart';
import 'package:soundmates/screens/chat_screen.dart';
import 'package:soundmates/screens/visit_profile/visit_profile_loader.dart';
import 'package:soundmates/screens/visit_profile/visit_profile_model.dart';
import 'package:soundmates/theme/app_design_system.dart';

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

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  late final VisitProfileLoader _loader;
  late Future<VisitProfileViewModel> _dataFuture;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _loader = VisitProfileLoader(widget.api);
    _dataFuture = _loader.loadData(widget.userId);

    // Setup rotation animation for background circles
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
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
              // Animated rotating background circles
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _BackgroundPainter(
                        bottomPadding: MediaQuery.of(context).padding.bottom,
                        rotation: _rotationController.value * 2 * 3.14159,
                      ),
                    );
                  },
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
                          backgroundColor: AppTheme.getAdaptiveGrey(context, lightShade: 200, darkShade: 800),
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
  final double rotation;

  _BackgroundPainter({required this.bottomPadding, this.rotation = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - bottomPadding - 80);

    // Save canvas state and rotate around center
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw concentric circles (these stay still visually but rotate with canvas)
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, i * 80.0, paint);
    }

    // Draw rotating arcs for dynamic effect
    final arcPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Multiple arcs at different radii with varying lengths
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 120),
      rotation * 0.5,
      0.8,
      false,
      arcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 200),
      -rotation * 0.7,
      1.2,
      false,
      arcPaint..color = Colors.white.withOpacity(0.06),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 280),
      rotation * 0.3,
      1.5,
      false,
      arcPaint..color = Colors.white.withOpacity(0.05),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 360),
      -rotation * 0.4,
      0.6,
      false,
      arcPaint..color = Colors.white.withOpacity(0.04),
    );

    // Add some accent purple arcs for color
    final purpleArcPaint = Paint()
      ..color = AppColors.accentPurple.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 160),
      rotation * 0.6 + 1.5,
      0.5,
      false,
      purpleArcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 240),
      -rotation * 0.5 + 3.0,
      0.7,
      false,
      purpleArcPaint..color = AppColors.accentPurple.withOpacity(0.08),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 320),
      rotation * 0.8,
      0.4,
      false,
      purpleArcPaint..color = AppColors.accentPurple.withOpacity(0.06),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.bottomPadding != bottomPadding ||
           oldDelegate.rotation != rotation;
  }
}
