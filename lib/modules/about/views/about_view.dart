import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/widgets/app_logo.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  static final Uri _repositoryUri = Uri.parse(
    'https://github.com/abiodungbenga/EcoVision',
  );

  Future<void> _openRepository() async {
    try {
      final opened = await launchUrl(
        _repositoryUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        SnackbarUtils.showError('Could not open the EcoVision repository.');
      }
    } catch (error) {
      SnackbarUtils.showError(
        'Could not open the EcoVision repository: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About EcoVision')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLogo(showWordmark: true, width: 176, height: 40),
                  const SizedBox(height: 22),
                  Text(
                    'Find the moments\nthat matter in the wild.',
                    style: AppTypography.heading.copyWith(
                      color: palette.onPrimary,
                      fontSize: 27,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'EcoVision helps wildlife and environmental researchers turn field footage into searchable, reviewable observations.',
                    style: AppTypography.body.copyWith(
                      color: palette.onPrimary.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _sectionHeading(
              context,
              'A fieldwork tool, not just a video player',
            ),
            const SizedBox(height: 8),
            Text(
              'Long recordings can hold important evidence of animal behavior, habitat use, and species activity. EcoVision helps researchers find relevant moments without manually scrubbing through every clip.',
              style: AppTypography.body.copyWith(color: palette.secondaryText),
            ),
            const SizedBox(height: 24),
            _sectionHeading(context, 'How it works'),
            const SizedBox(height: 12),
            _workflowStep(
              context,
              number: '01',
              title: 'Add field footage',
              description: 'Choose a wildlife or environmental video stored on your device.',
            ),
            _workflowStep(
              context,
              number: '02',
              title: 'Index with V-Modal',
              description: 'EcoVision uploads the clip to your V-Modal account so its contents can be searched.',
            ),
            _workflowStep(
              context,
              number: '03',
              title: 'Search by text or image',
              description: 'Describe a scene in everyday language or use a reference image to find visually similar moments.',
            ),
            _workflowStep(
              context,
              number: '04',
              title: 'Review and save',
              description: 'Explore timestamped matches and previews, then save useful observations and field notes for later.',
            ),
            const SizedBox(height: 12),
            _sectionHeading(context, 'Made for research workflows'),
            const SizedBox(height: 12),
            _benefitCard(
              context,
              icon: Icons.manage_search_rounded,
              title: 'Spend less time scrubbing',
              description: 'Search large recordings for scenes and behaviors using natural-language prompts.',
            ),
            _benefitCard(
              context,
              icon: Icons.bookmark_add_outlined,
              title: 'Keep findings together',
              description: 'Save notable moments with their video references and timestamps to revisit during research.',
            ),
            _benefitCard(
              context,
              icon: Icons.fact_check_outlined,
              title: 'Keep people in the loop',
              description: 'AI-assisted matches are starting points for review. Researchers should verify observations against the original footage.',
            ),
            const SizedBox(height: 24),
            _sectionHeading(context, 'Your key and your footage'),
            const SizedBox(height: 8),
            Text(
              'Your personal V-Modal API key and saved research data are kept in this device profile for your signed-in account. EcoVision may also offer a shared key managed through Firebase Remote Config; that key is delivered to the app and is not secret. Each account uses its own V-Modal collection. Each uploaded video is associated with the key used for that upload, so changing keys can mean uploading a video again. Revoking a personal key does not delete videos already stored in your V-Modal account.',
              style: AppTypography.body.copyWith(color: palette.secondaryText),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _openRepository,
              icon: const Icon(Icons.code_rounded),
              label: const Text('Explore the project on GitHub'),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Built for people working to understand and protect wildlife.',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: palette.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(BuildContext context, String title) {
    final palette = AppPalette.of(context);
    return Text(
      title,
      style: AppTypography.title.copyWith(color: palette.text),
    );
  }

  Widget _workflowStep(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
  }) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              number,
              style: AppTypography.label.copyWith(color: palette.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final palette = AppPalette.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: palette.secondaryText,
                    ),
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
