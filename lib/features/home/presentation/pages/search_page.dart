import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../bloc/search_cubit.dart';
import '../widgets/court_card.dart';

class SearchPage extends StatelessWidget {
  final String initialQuery;

  const SearchPage({super.key, this.initialQuery = ''});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchCubit>()
        ..setQueryImmediate(initialQuery)
        ..load(),
      child: _SearchView(initialQuery: initialQuery),
    );
  }
}

class _SearchView extends StatefulWidget {
  final String initialQuery;

  const _SearchView({required this.initialQuery});

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(context),
              const SizedBox(height: 16),
              _buildFilterChips(context),
              BlocBuilder<SearchCubit, SearchState>(
                buildWhen: (a, b) => a.activePanel != b.activePanel,
                builder: (context, state) => _buildFilterPanel(context, state),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildResults(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: TextField(
            controller: _queryController,
            autocorrect: false,
            onChanged: (value) =>
                context.read<SearchCubit>().updateQuery(value),
            decoration: InputDecoration(
              hintText: 'Tìm sân bóng rổ...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (a, b) => a.activePanel != b.activePanel,
      builder: (context, state) {
        return Row(
          children: [
            _FilterChipButton(
              label: 'Giá',
              selected: state.activePanel == SearchFilterPanel.price,
              onTap: () => context.read<SearchCubit>().togglePanel(
                SearchFilterPanel.price,
              ),
            ),
            const SizedBox(width: 8),
            _FilterChipButton(
              label: 'Khoảng cách',
              selected: state.activePanel == SearchFilterPanel.distance,
              onTap: () => context.read<SearchCubit>().togglePanel(
                SearchFilterPanel.distance,
              ),
            ),
            const SizedBox(width: 8),
            _FilterChipButton(
              label: 'Tiện ích',
              selected: state.activePanel == SearchFilterPanel.amenities,
              onTap: () => context.read<SearchCubit>().togglePanel(
                SearchFilterPanel.amenities,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterPanel(BuildContext context, SearchState state) {
    switch (state.activePanel) {
      case SearchFilterPanel.none:
        return const SizedBox.shrink();
      case SearchFilterPanel.price:
        return _PricePanel();
      case SearchFilterPanel.distance:
        return const _DistancePanel();
      case SearchFilterPanel.amenities:
        return _AmenitiesPanel();
    }
  }

  Widget _buildResults(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.errorMessage!),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.read<SearchCubit>().load(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final results = state.filteredCourts;
        if (results.isEmpty) {
          return const Center(
            child: Text('Không có sân phù hợp, thử nới lỏng bộ lọc'),
          );
        }
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${results.length} kết quả',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...results.map((court) => CourtCard(court: court)),
          ],
        );
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : null,
          border: selected
              ? null
              : Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? theme.colorScheme.onPrimary : null,
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 18,
              color: selected ? theme.colorScheme.onPrimary : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (a, b) =>
          a.priceRange != b.priceRange ||
          a.minPrice != b.minPrice ||
          a.maxPrice != b.maxPrice,
      builder: (context, state) {
        final hasRange = state.maxPrice > state.minPrice;
        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khoảng giá (đ/giờ)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                RangeSlider(
                  values: state.priceRange,
                  min: state.minPrice,
                  max: hasRange ? state.maxPrice : state.minPrice + 1,
                  onChanged: hasRange
                      ? (values) =>
                            context.read<SearchCubit>().updatePriceRange(values)
                      : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatVnd(state.priceRange.start.round())),
                    Text(formatVnd(state.priceRange.end.round())),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DistancePanel extends StatelessWidget {
  const _DistancePanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Lọc theo khoảng cách cần bật định vị GPS — sẽ hỗ trợ khi tích hợp Google Maps.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _AmenitiesPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (a, b) =>
          a.availableAmenities != b.availableAmenities ||
          a.selectedAmenities != b.selectedAmenities,
      builder: (context, state) {
        if (state.availableAmenities.isEmpty) {
          return const Card(
            margin: EdgeInsets.only(top: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chưa có tiện ích nào để lọc'),
            ),
          );
        }
        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.availableAmenities.map((amenity) {
                final selected = state.selectedAmenities.contains(amenity);
                return FilterChip(
                  label: Text(amenity),
                  selected: selected,
                  onSelected: (_) =>
                      context.read<SearchCubit>().toggleAmenity(amenity),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
