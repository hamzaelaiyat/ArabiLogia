import 'dart:io';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/constants/test_keys.dart';
import 'package:arabilogia/core/services/update_service.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/features/auth/update_confirm/widgets/update_header.dart';
import 'package:arabilogia/features/auth/update_confirm/widgets/release_notes_card.dart';
import 'package:arabilogia/features/auth/update_confirm/widgets/mandatory_update_banner.dart';
import 'package:arabilogia/features/auth/update_confirm/widgets/download_progress_section.dart';
import 'package:arabilogia/features/auth/update_confirm/widgets/update_action_buttons.dart';
import 'package:arabilogia/features/auth/update_confirm/widgets/download_error_dialog.dart';
import 'package:arabilogia/features/auth/update_confirm/services/android_update_handler.dart';
import 'package:arabilogia/features/auth/update_confirm/services/windows_update_handler.dart';
import 'package:arabilogia/features/auth/update_confirm/services/linux_update_handler.dart';

class UpdateConfirmPage extends StatefulWidget {
  final AppUpdate update;
  const UpdateConfirmPage({super.key, required this.update});
  @override
  State<UpdateConfirmPage> createState() => _UpdateConfirmPageState();
}

class _UpdateConfirmPageState extends State<UpdateConfirmPage> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _status = '';
  dynamic _activeHandler;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: TestKeys.updateConfirmScreen,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.update.isMandatory ? 'تحديث إلزامي' : 'يتوفر تحديث جديد',
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UpdateHeader(
              version: widget.update.version,
              fileSize: widget.update.fileSize,
            ),
            const SizedBox(height: AppTokens.spacing24),
            if (widget.update.releaseNotes.isNotEmpty) ...[
              ReleaseNotesCard(releaseNotes: widget.update.releaseNotes),
              const SizedBox(height: AppTokens.spacing24),
            ],
            if (widget.update.isMandatory) const MandatoryUpdateBanner(),
            const SizedBox(height: AppTokens.spacing32),
            if (_isDownloading)
              DownloadProgressSection(
                progress: _downloadProgress,
                status: _status,
              ),
            if (!_isDownloading)
              UpdateActionButtons(
                onUpdateNow: _startUpdate,
                onRemindLater: _remindLater,
                onSkip: _skipUpdate,
              ),
          ],
        ),
      ),
    );
  }

  void _onProgress(double progress, String status) {
    if (!mounted) return;
    setState(() { _downloadProgress = progress; _status = status; });
  }

  void _onComplete() {
    if (!mounted) return;
    setState(() => _isDownloading = false);
  }

  void _onError(String error) {
    if (!mounted) return;
    setState(() { _isDownloading = false; _status = error; });
  }

  void _startUpdate() {
    setState(() { _isDownloading = true; _downloadProgress = 0; _status = ''; });

    _activeHandler?.dispose();
    final u = widget.update;
    if (Platform.isAndroid) {
      _activeHandler = AndroidUpdateHandler(
        downloadUrl: u.downloadUrl, fileName: u.fileName, fileSize: u.fileSize,
        version: u.version, releaseNotes: u.releaseNotes,
        onProgressUpdate: _onProgress, onComplete: _onComplete, onError: _onError,
        onFallbackToBrowser: (url) {
          setState(() => _isDownloading = false);
          showBrowserFallbackDialog(context, url);
        },
      );
      _activeHandler!.startUpdate(context);
    } else if (Platform.isWindows) {
      _activeHandler = WindowsUpdateHandler(
        downloadUrl: u.downloadUrl, fileName: u.fileName, fileSize: u.fileSize,
        version: u.version, releaseNotes: u.releaseNotes,
        onProgressUpdate: _onProgress, onComplete: _onComplete, onError: _onError,
        onShowDownloadError: (msg) =>
            showDownloadErrorDialog(context, msg, _startUpdate),
      );
      _activeHandler!.startUpdate(context);
    } else if (Platform.isLinux) {
      _activeHandler = LinuxUpdateHandler(
        downloadUrl: u.downloadUrl, fileName: u.fileName, fileSize: u.fileSize,
        version: u.version, releaseNotes: u.releaseNotes,
        onProgressUpdate: _onProgress, onComplete: _onComplete, onError: _onError,
        onShowDownloadError: (msg) =>
            showDownloadErrorDialog(context, msg, _startUpdate),
      );
      _activeHandler!.startUpdate(context);
    }
  }

  void _remindLater() async {
    await UpdateService.remindLater();
    if (mounted) Navigator.pop(context);
  }

  void _skipUpdate() async {
    await UpdateService.skipVersion(widget.update.version);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _activeHandler?.dispose();
    super.dispose();
  }
}
