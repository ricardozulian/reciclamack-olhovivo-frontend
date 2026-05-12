import 'package:flutter/material.dart';

import '../design_tokens.dart';

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          // Green icon box with shield/check mark
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ReciclaColors.primary,
              borderRadius: BorderRadius.circular(ReciclaRadii.sm),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Recicla',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ReciclaColors.fg1,
                  ),
                ),
                TextSpan(
                  text: 'Mack',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ReciclaColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
