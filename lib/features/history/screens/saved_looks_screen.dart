import 'package:flutter/material.dart';
import 'package:glowai/core/routing/main_shell_scope.dart';
import 'package:glowai/core/theme/app_colors.dart';
import 'package:glowai/features/history/models/saved_look.dart';
import 'package:glowai/features/history/services/saved_looks_service.dart';
import 'package:glowai/features/looks/screens/makeup_look_details_page.dart';

class SavedLooksScreen extends StatefulWidget {
  const SavedLooksScreen({super.key});

  @override
  State<SavedLooksScreen> createState() => _SavedLooksScreenState();
}

class _SavedLooksScreenState extends State<SavedLooksScreen> {
  final SavedLooksService _service = SavedLooksService();

  final List<String> _filters = const [
    'All',
    'Everyday',
    'Party',
    'Natural',
    'Bridal',
  ];

  List<SavedLook> _looks = [];
  String _selectedFilter = 'All';
  String? _errorMessage;
  bool _isLoading = true;

  List<SavedLook> get _visibleLooks {
    if (_selectedFilter == 'All') {
      return _looks;
    }

    return _looks.where((look) => look.occasion == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadLooks();
  }

  /// [silent] refreshes the list in place (no spinner), for when the tab is
  /// shown again after looks may have been saved elsewhere.
  Future<void> _loadLooks({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await _service.fetchSavedLooks();

      if (!mounted) return;

      setState(() {
        _looks = results;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // A failed silent refresh keeps the list the user already sees.
      if (silent && _errorMessage == null && !_isLoading) return;

      setState(() {
        _errorMessage = 'We could not load your saved looks.';
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _removeLook(SavedLook look) async {
    final index = _looks.indexWhere((item) => item.id == look.id);
    if (index == -1) return;
    try {
      await SavedLooksService.removeLook(look);
      if (!mounted) return;
      setState(() => _looks.removeWhere((item) => item.id == look.id));
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${look.title} removed from Saved Looks'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await SavedLooksService.restoreLook(look, index);
                if (mounted) await _loadLooks();
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not restore look.')),
                );
              }
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove saved look.')),
      );
    }
  }

  void _openLookDetails(SavedLook look) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MakeupLookDetailsPage(
          name: look.title,
          description: look.description,
          tag: look.occasion,
          colors: [look.previewColor, AppColors.warmIvory],
          icon: look.previewIcon,
          occasion: look.occasion,
        ),
      ),
    );
  }

  Widget _buildLookCard(SavedLook look) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openLookDetails(look),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [look.previewColor, AppColors.warmIvory],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          look.previewIcon,
                          size: 72,
                          color: AppColors.deepMauve,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          tooltip: 'Remove saved look',
                          onPressed: () => _removeLook(look),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.accent,
                          ),
                          icon: const Icon(Icons.bookmark_rounded),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            look.occasion,
                            style: const TextStyle(
                              color: AppColors.deepMauve,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      look.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      look.savedLabel,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to view details',
                      style: TextStyle(fontSize: 11, color: AppColors.hintText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSavedLooks = _looks.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 68,
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              hasSavedLooks
                  ? 'No looks in this category'
                  : 'No saved looks yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSavedLooks
                  ? 'Try another category to find your saved looks.'
                  : 'Your saved makeup inspirations will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            if (hasSavedLooks) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'All';
                  });
                },
                child: const Text('Show all looks'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadLooks,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_visibleLooks.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 650
            ? 3
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: _visibleLooks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 2 ? 0.70 : 0.82,
          ),
          itemBuilder: (context, index) {
            return _buildLookCard(_visibleLooks[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Standalone: Back pops the route. In the shell: Back goes to the tab the
    // user came from, and is hidden when there is none.
    final back = MainShellScope.backActionOf(context);

    return TabActivationListener(
      tab: MainTab.savedLooks,
      onActivated: () => _loadLooks(silent: true),
      child: Scaffold(
        backgroundColor: AppColors.warmIvory,
        appBar: AppBar(
          backgroundColor: AppColors.warmIvory,
          foregroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: back.visible
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: back.onPressed,
                  icon: const Icon(Icons.arrow_back_ios_new),
                )
              : null,
          title: const Text(
            'GlowAI',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 23,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Looks',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_looks.length} looks saved for your inspiration',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;

                      return ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        selectedColor: AppColors.blushPink,
                        backgroundColor: AppColors.white,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.secondaryText,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
