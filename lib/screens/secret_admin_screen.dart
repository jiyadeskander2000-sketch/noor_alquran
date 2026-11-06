import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/audio_manager.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../providers/theme_provider.dart';

class SecretAdminScreen extends StatefulWidget {
  const SecretAdminScreen({super.key});

  @override
  State<SecretAdminScreen> createState() => _SecretAdminScreenState();
}

class _SecretAdminScreenState extends State<SecretAdminScreen> {
  late TextEditingController _reciterNameController;
  Map<int, String> _audioMap = {};
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reciterNameController = TextEditingController(text: StorageService.reciterName);
    _loadAudioMap();
  }

  void _loadAudioMap() {
    setState(() {
      _audioMap = StorageService.getSurahAudioMap();
    });
  }

  @override
  void dispose() {
    _reciterNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioForSurah(Surah surah) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        String pickedPath = result.files.single.path!;

        // 1. Copy file permanently to local offline app storage
        String localSavedPath = await StorageService.copyAudioToLocalStorage(
          pickedPath,
          surah.number,
        );

        // 2. Save mapping
        await StorageService.setAudioForSurah(surah.number, localSavedPath);
        _loadAudioMap();

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0F5132),
              content: Text('تم استيراد وحفظ تسجيل ${surah.name} بنجاح بدون إنترنت!'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('حدث خطأ أثناء استيراد الملف: $e'),
          ),
        );
      }
    }
  }

  Future<void> _removeAudioForSurah(Surah surah) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف التسجيل الصوتي لسورة ${surah.name}؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.removeAudioForSurah(surah.number);
      _loadAudioMap();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف التسجيل الصوتي لسورة ${surah.name}')),
        );
      }
    }
  }

  Future<void> _syncAllToAssetsFolder() async {
    setState(() => _isLoading = true);
    int copiedCount = 0;

    try {
      if (kIsWeb) {
        setState(() => _isLoading = false);
        return;
      }

      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, files are stored permanently in local documents and work 100% offline
        final appDir = await getApplicationDocumentsDirectory();
        final audioDir = Directory(p.join(appDir.path, 'reciter_audio'));
        int filesCount = 0;
        if (await audioDir.exists()) {
          filesCount = (await audioDir.list().toList()).length;
        }

        setState(() => _isLoading = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('التسجيلات محفوظة أوفلاين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'جميع الأصوات التي قمت باستيرادها ($filesCount تسجيل) محفوظة بشكل دائم داخل ذاكرة الهاتف وتعمل 100% بدون إنترنت.\n\nلتضمينها نهائياً داخل ملف الـ APK عند بناء التطبيق من الكمبيوتر لترسله لأي شخص:\nضع ملفات الـ MP3 في المجلد:\nD:\\noor_alquran\\assets\\audio\\\nبأسماء السور (مثال: 1.mp3، 2.mp3 ... إلخ)، وسيقوم فلاتر بدمجها تلقائياً داخل الـ APK!',
                style: GoogleFonts.cairo(height: 1.7),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('فهمت ذلك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      // On Desktop (Windows / macOS / Linux)
      final candidateDirs = [
        Directory('assets/audio'),
        Directory(p.join('D:', 'noor_alquran', 'assets', 'audio')),
      ];

      Directory? targetDir;
      for (var d in candidateDirs) {
        try {
          if (!d.existsSync()) d.createSync(recursive: true);
          targetDir = d;
          break;
        } catch (_) {}
      }

      if (targetDir != null) {
        for (var entry in _audioMap.entries) {
          final surahNum = entry.key;
          final srcPath = entry.value;
          final srcFile = File(srcPath);

          if (srcFile.existsSync()) {
            String ext = p.extension(srcPath);
            if (ext.isEmpty) ext = '.mp3';
            final dest = File(p.join(targetDir.path, '$surahNum$ext'));
            await srcFile.copy(dest.path);
            copiedCount++;
          }
        }
      }

      await StorageService.detectBundledAssetSurahs();
      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green),
                const SizedBox(width: 8),
                Text('تمت المزامنة بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'تم تضمين ($copiedCount) سورة مباشرة في مجلد أصول التطبيق (assets/audio).\n\nالآن عند بناء تطبيق APK عبر الأمر:\nflutter build apk\nستكون جميع هذه الأصوات مدمجة نهائياً داخل ملف الـ APK، بحيث يستمع إليها أي شخص ترسل له التطبيق أوفلاين دون الحاجة لأي إنترنت أو إعدادات!',
              style: GoogleFonts.cairo(height: 1.7),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('حسناً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تنبيه: التسجيلات محفوظة محلياً على الهاتف ($e)')),
        );
      }
    }
  }

  void _changePinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تغيير الرمز السري', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرمز السري الحالي هو: ${StorageService.adminPin}', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'الرمز السري الجديد',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.trim().isNotEmpty) {
                await StorageService.setAdminPin(pinController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث الرمز السري بنجاح')),
                  );
                }
              }
            },
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final goldColor = const Color(0xFFD4AF37);
    final themeProv = Provider.of<ThemeProvider>(context);

    final allSurahs = QuranService.surahs;
    final filteredSurahs = allSurahs.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.contains(_searchQuery) || s.number.toString() == _searchQuery;
    }).toList();

    int totalAdded = _audioMap.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'لوحة إدارة أصوات الشيخ',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _changePinDialog,
            icon: const Icon(Icons.password_rounded),
            tooltip: 'تغيير الرمز السري',
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              // Informative Master Banner
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF152238), const Color(0xFF0F1726)]
                        : [const Color(0xFF0F5132), const Color(0xFF1B4D3E)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: goldColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.security_rounded, color: goldColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'لوحة إدارة أصوات الشيخ محمد وليد الشرعبي',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'تضمين الأصوات وإدارتها لتعمل بدون إنترنت',
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الملفات الصوتية التي تضيفها تُحفظ في التطبيق وتعمل مباشرة أوفلاين. يمكنك أيضاً وضع ملفات الـ MP3 في مجلد assets/audio لتضمينها نهائياً في ملف الـ APK عند بنائه وإرساله لأي شخص.',
                      style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _syncAllToAssetsFolder,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        'مزامنة وحفظ حالة الأصوات (APK Ready)',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'السور المضافة يدوياً: $totalAdded من 114',
                          style: GoogleFonts.cairo(
                            color: goldColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'الرمز السري: ${StorageService.adminPin}',
                          style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Reciter Name Configuration Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D2D) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic_rounded, color: goldColor, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'اسم القارئ المعروض في التطبيق:',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reciterNameController,
                            style: GoogleFonts.cairo(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'أدخل اسم القارئ...',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F1724) : Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            themeProv.updateReciterName(_reciterNameController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حفظ اسم القارئ وتحديثه في التطبيق')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          ),
                          child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Search Box for Surahs
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: GoogleFonts.cairo(),
                decoration: InputDecoration(
                  hintText: 'ابحث عن سورة لإضافة صوتها...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF131D2D) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'قائمة السور (${filteredSurahs.length}):',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

              const SizedBox(height: 12),

              // Surahs Audio Management List
              ...filteredSurahs.map((surah) {
                final isBundled = StorageService.hasBundledAsset(surah.number);
                final hasCustom = _audioMap.containsKey(surah.number);
                final hasAudio = isBundled || hasCustom;
                final audioPath = _audioMap[surah.number];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D2D) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: hasAudio ? goldColor.withValues(alpha: 0.5) : (isDark ? Colors.white10 : Colors.grey.shade200),
                      width: hasAudio ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: hasAudio ? goldColor.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.grey.shade100),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasAudio ? goldColor : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${surah.number}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: hasAudio ? goldColor : null,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            surah.name,
                            style: GoogleFonts.amiri(fontSize: 19, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasAudio ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isBundled ? 'مدمج' : (hasCustom ? 'صوت مضاف' : 'بلا صوت'),
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasAudio ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      hasCustom
                          ? 'ملف: ${p.basename(audioPath!)}'
                          : (isBundled
                              ? 'تلاوة مدمجة للشيخ'
                              : '${surah.typeArabic} • ${surah.numberOfAyahs} آية'),
                      style: GoogleFonts.cairo(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasAudio) ...[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.green, size: 28),
                            tooltip: 'تجربة الصوت',
                            onPressed: () {
                              AudioManager().playSurah(surah);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('جاري تشغيل تسجيل ${surah.name}')),
                              );
                            },
                          ),
                          if (hasCustom)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                              tooltip: 'حذف التسجيل المخصص',
                              onPressed: () => _removeAudioForSurah(surah),
                            ),
                        ],
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          icon: Icon(
                            hasAudio ? Icons.sync_rounded : Icons.add_circle_outline_rounded,
                            color: goldColor,
                            size: 24,
                          ),
                          tooltip: hasAudio ? 'استبدال الصوت' : 'استيراد صوت السورة',
                          onPressed: () => _pickAudioForSurah(surah),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 30),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    const SizedBox(height: 16),
                    Text(
                      'جاري معالجة وحفظ الصوت أوفلاين...',
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
