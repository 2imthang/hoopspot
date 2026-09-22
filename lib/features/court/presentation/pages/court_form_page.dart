import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../../core/constants/map_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../domain/entities/court_entity.dart';
import '../bloc/court_form_cubit.dart';
import 'court_schedule_page.dart';

/// Sân trung tâm mặc định khi tạo sân mới — Quận 1, TP.HCM, cùng tọa độ
/// dùng làm vị trí "hiện tại" giả lập ở Home (TASK-013/017).
const _defaultCenter = latlong.LatLng(10.7769, 106.7009);

const _amenityOptions = [
  'Đèn sáng',
  'Chỗ để xe',
  'Phòng thay đồ',
  'Wifi',
  'Nước uống',
  'Nhà vệ sinh',
];

/// TASK-031 — dùng chung cho "Thêm sân mới" và "Sửa sân" (`court == null`
/// tức đang tạo mới), khớp bước 1 của flow trong functional-spec 4.10.
class CourtFormPage extends StatelessWidget {
  final CourtEntity? court;

  const CourtFormPage({super.key, this.court});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CourtFormCubit>(param1: court?.imageUrls ?? const <String>[]),
      child: _CourtFormView(court: court),
    );
  }
}

class _CourtFormView extends StatefulWidget {
  final CourtEntity? court;

  const _CourtFormView({required this.court});

  @override
  State<_CourtFormView> createState() => _CourtFormViewState();
}

class _CourtFormViewState extends State<_CourtFormView> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;
  late bool _isOutdoor;
  late Set<String> _selectedAmenities;
  late latlong.LatLng _center;

  bool get _isEditing => widget.court != null;

  @override
  void initState() {
    super.initState();
    final court = widget.court;
    _nameController = TextEditingController(text: court?.name ?? '');
    _addressController = TextEditingController(text: court?.address ?? '');
    _priceController = TextEditingController(
      text: court == null ? '' : court.pricePerSlot.toString(),
    );
    _isOutdoor = court?.isOutdoor ?? false;
    _selectedAmenities = {...?court?.amenities};
    _center = court == null
        ? _defaultCenter
        : latlong.LatLng(court.latitude, court.longitude);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !context.mounted) return;
    context.read<CourtFormCubit>().addImage(File(picked.path));
  }

  Future<void> _searchAddress(BuildContext context) async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    FocusScope.of(context).unfocus();
    final point = await context.read<CourtFormCubit>().searchAddress(address);
    if (point == null || !context.mounted) return;
    final newCenter = latlong.LatLng(point.latitude, point.longitude);
    setState(() => _center = newCenter);
    _mapController.move(newCenter, 16);
  }

  Future<void> _openScheduleConfig(BuildContext context) async {
    final court = widget.court;
    if (court == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourtSchedulePage(court: court)),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await context.read<CourtFormCubit>().submit(
      courtId: widget.court?.id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: _center.latitude,
      longitude: _center.longitude,
      pricePerSlot: int.parse(_priceController.text.trim()),
      amenities: _selectedAmenities.toList(),
      isOutdoor: _isOutdoor,
    );
    if (saved && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa sân' : 'Thêm sân mới')),
      body: BlocConsumer<CourtFormCubit, CourtFormState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Ảnh sân', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _ImagesRow(
                    imageUrls: state.imageUrls,
                    uploading: state.uploadingImage,
                    onAdd: () => _pickImage(context),
                    onRemove: (url) => context.read<CourtFormCubit>().removeImage(url),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Tên sân',
                    hint: 'VD: Sân The Dome Arena',
                    controller: _nameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên sân' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Địa chỉ',
                    hint: 'VD: 12 Nguyễn Huệ, Q1, TP.HCM',
                    controller: _addressController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: state.geocoding ? null : () => _searchAddress(context),
                      icon: state.geocoding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search, size: 18),
                      label: const Text('Tìm vị trí trên bản đồ'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AuthTextField(
                    label: 'Giá mỗi ca (đ/2 tiếng)',
                    hint: 'VD: 250000',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final value = int.tryParse(v?.trim() ?? '');
                      if (value == null || value <= 0) return 'Vui lòng nhập giá hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Vị trí trên bản đồ', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Chạm vào bản đồ để đặt vị trí sân',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LocationPicker(
                    mapController: _mapController,
                    center: _center,
                    onTap: (point) => setState(() => _center = point),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sân ngoài trời'),
                    subtitle: const Text('Cho phép hoàn tiền ngay khi Owner báo hủy do mưa'),
                    value: _isOutdoor,
                    onChanged: (v) => setState(() => _isOutdoor = v),
                  ),
                  const SizedBox(height: 8),
                  Text('Tiện ích', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenityOptions.map((amenity) {
                      final selected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          v ? _selectedAmenities.add(amenity) : _selectedAmenities.remove(amenity);
                        }),
                      );
                    }).toList(),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => _openScheduleConfig(context),
                      icon: const Icon(Icons.schedule_outlined),
                      label: const Text('Cấu hình giờ hoạt động'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.submitting ? null : () => _submit(context),
                    child: state.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Lưu thay đổi' : 'Tạo sân'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImagesRow extends StatelessWidget {
  final List<String> imageUrls;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _ImagesRow({
    required this.imageUrls,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final url in imageUrls)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url, width: 88, height: 88, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onRemove(url),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          InkWell(
            onTap: uploading ? null : onAdd,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: uploading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  final MapController mapController;
  final latlong.LatLng center;
  final ValueChanged<latlong.LatLng> onTap;

  const _LocationPicker({
    required this.mapController,
    required this.center,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            onTap: (_, point) => onTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConstants.osmTileUrlTemplate,
              userAgentPackageName: 'com.example.hoop_spot',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
