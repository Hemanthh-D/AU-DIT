import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../core/session/session_provider.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_messenger.dart';
import '../core/ui/app_spacing.dart';
import '../models/app_notification.dart';
import '../providers/complaint_provider.dart';
import '../providers/notification_provider.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _blockController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  String? _extractBlockFromDescription(String description) {
    final match = RegExp(r'(?:block|blk)\s*([a-zA-Z0-9]+)', caseSensitive: false)
        .firstMatch(description);
    if (match == null) return null;
    final val = match.group(1);
    if (val == null) return null;
    final trimmed = val.trim();
    if (trimmed.isEmpty) return null;
    return 'Block $trimmed';
  }

  String? _extractRoomFromDescription(String description) {
    final match =
        RegExp(r'(?:room|rm)\s*([a-zA-Z0-9]+)', caseSensitive: false)
            .firstMatch(description);
    if (match == null) return null;
    final val = match.group(1);
    if (val == null) return null;
    final trimmed = val.trim();
    if (trimmed.isEmpty) return null;
    return 'Room $trimmed';
  }

  void _submitReport() {
    final desc = _controller.text.trim();
    if (desc.isEmpty) {
      AppMessenger.showSnack("Please describe the issue first.");
      return;
    }

    final extractedBlock = _blockController.text.trim().isEmpty
        ? _extractBlockFromDescription(desc)
        : _blockController.text.trim();
    final extractedRoom = _roomController.text.trim().isEmpty
        ? _extractRoomFromDescription(desc)
        : _roomController.text.trim();

    final block =
        (extractedBlock == null || extractedBlock.isEmpty) ? 'Block Unknown' : extractedBlock;
    final room =
        (extractedRoom == null || extractedRoom.isEmpty) ? 'Room Unknown' : extractedRoom;

    if (block == 'Block Unknown' || room == 'Room Unknown') {
      AppMessenger.showSnack(
        "Block/Room not fully provided. Routing is still enabled, but duplicate detection may be less accurate.",
      );
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    // Call the AI Brain in our Provider
    final session = context.read<SessionProvider>();
    final result = Provider.of<ComplaintProvider>(
      context,
      listen: false,
    ).submitComplaint(
      studentId: session.studentId,
      description: desc,
      block: block,
      room: room,
      beforeImagePaths: _selectedImages.map((f) => f.path).toList(),
    );

    // Simulate network delay for a professional feel
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result.outcome != SubmitOutcome.mergedDuplicate) {
          context.read<NotificationProvider>().add(AppNotification(
                id: 'n-${DateTime.now().millisecondsSinceEpoch}',
                complaintId: result.complaint.id,
                type: NotificationType.technicianAssigned,
                title: result.outcome == SubmitOutcome.queued ? 'Queued' : 'Technician assigned',
                body: result.outcome == SubmitOutcome.queued
                    ? 'Your complaint was added to queue for ${result.complaint.assignedTechnicianId}.'
                    : '${result.complaint.assignedTechnicianId} has been assigned to your complaint ${result.complaint.id}.',
                createdAt: DateTime.now(),
                studentId: session.studentId,
              ));
          // Notify the assigned technician
          context.read<NotificationProvider>().add(AppNotification(
                id: 'n-t-${DateTime.now().millisecondsSinceEpoch}',
                complaintId: result.complaint.id,
                type: NotificationType.technicianAssigned,
                title: 'New complaint assigned',
                body: '${result.complaint.categoryLabel} • ${result.complaint.block} ${result.complaint.room} — assigned to you.',
                createdAt: DateTime.now(),
                technicianId: result.complaint.assignedTechnicianId,
              ));
        }
        final msg = switch (result.outcome) {
          SubmitOutcome.assigned =>
            "Submitted! Assigned to ${result.complaint.assignedTechnicianId}.",
          SubmitOutcome.queued =>
            "Submitted! Technician busy — added to queue for ${result.complaint.assignedTechnicianId}.",
          SubmitOutcome.mergedDuplicate =>
            "Already reported in your area — merged into existing ticket ${result.complaint.id}.",
        };
        AppMessenger.showSnack(msg);
        _controller.clear();
        _blockController.clear();
        _roomController.clear();
        _selectedImages.clear();
        context.go('/student/status');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: scheme.surface,
        title: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_chart_rounded, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("New Complaint", style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Describe the issue",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Be specific (location, time, what’s affected). This helps technicians resolve faster.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _blockController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: "Block",
                              hintText: "e.g. Block B",
                              prefixIcon: Icon(Icons.apartment_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: _roomController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: "Room",
                              hintText: "e.g. 204",
                              prefixIcon: Icon(Icons.meeting_room_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _controller,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText:
                            "E.g., WiFi in Block B room 204 has been down since yesterday evening...",
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 72),
                          child: Icon(Icons.description_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Attachments (optional)",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Add photos to make the issue clear.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _pickImage,
                              child: Container(
                                width: 92,
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Add",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final img = _selectedImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  img,
                                  width: 92,
                                  height: 92,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _selectedImages.removeAt(index),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(160),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => context.go('/student/home'),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Submit report"),
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
