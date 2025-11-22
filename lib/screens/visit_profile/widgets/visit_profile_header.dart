import 'package:flutter/material.dart';
import '../../../api/models.dart'; // Potrzebne do rzutowania na OtherUserProfileArtistDto
import '../visit_profile_model.dart';

class VisitProfileHeader extends StatelessWidget {
  final VisitProfileViewModel data;
  final VoidCallback onUnmatch;
  final VoidCallback onMessage;

  const VisitProfileHeader({
    super.key,
    required this.data,
    required this.onUnmatch,
    required this.onMessage,
  });

  // Stałe kolory z oryginału
  static const Color _primaryDark = Color(0xFF1A1A1A);
  static const Color _accentPurple = Color(0xFF7B51D3);
  static const Color _accentRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    // Pobieranie URL zdjęcia (można tu dodać base URL jeśli nie jest w modelu)
    final profilePicUrl = data.profileImageUrl;

    return SliverAppBar(
      expandedHeight: 500,
      pinned: true,
      backgroundColor: _primaryDark,
      elevation: 0,
      leading: const SizedBox(), // Ukrywamy domyślną strzałkę, bo mamy customowy przycisk wyżej w Stacku
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Obraz tła
            if (profilePicUrl != null)
              Image.network(
                profilePicUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
              )
            else
              Container(color: Colors.grey[800]),

            // 2. Gradient Overlay (Dla czytelności tekstu)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),

            // 3. Dane Użytkownika (Lewy dolny róg)
            Positioned(
              left: 20,
              right: 130, // Miejsce zostawione na przyciski po prawej
              bottom: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge "Matched"
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentPurple,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _accentPurple.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                        SizedBox(width: 6),
                        Text(
                          "Matched",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Imię i Wiek
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        data.profile.name ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      // Sprawdzenie typu profilu dla wieku (zgodnie z oryginałem)
                      if (data.profile is OtherUserProfileArtistDto) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${(data.profile as OtherUserProfileArtistDto).calculatedAge ?? ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            height: 1.2,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Zielona kropka (Status)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                      )
                    ],
                  ),

                  // Lokalizacja (już sformatowana w modelu)
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.white.withOpacity(0.7), size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          data.locationString.isEmpty
                              ? 'Unknown Location'
                              : data.locationString,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Przyciski Akcji (Prawy dolny róg)
            Positioned(
              bottom: 30,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Unmatch Button
                  _OverlayButton(
                    text: "Unmatch",
                    icon: Icons.close,
                    color: _accentRed,
                    isPrimary: false,
                    onTap: onUnmatch,
                  ),
                  const SizedBox(height: 12),
                  // Message Button
                  _OverlayButton(
                    text: "Message",
                    icon: Icons.chat_bubble_outline,
                    color: _accentPurple,
                    isPrimary: true,
                    onTap: onMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prywatny widget pomocniczy dla przycisków na zdjęciu
class _OverlayButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPrimary ? 20 : 16,
          vertical: isPrimary ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isPrimary ? 20 : 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPrimary ? 14 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}