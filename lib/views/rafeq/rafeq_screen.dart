import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/controllers/azkar/azkar_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_cubit.dart';
import 'package:moshaf/views/azkar/one_pray_screen.dart';
import 'package:moshaf/views/azkar/prays_screen.dart';
import 'package:moshaf/views/hadith/hadith_screen.dart';
import 'package:moshaf/views/haj_and_omrah/haj_screen.dart';
import 'package:moshaf/views/mosque_location/mosque_location_screen.dart';
import 'package:moshaf/views/podcasts/podcasts_screen.dart';
import 'package:moshaf/views/pray_teaching/pray_instructions_screen.dart';
import 'package:moshaf/views/prayer_times/prayer_times_screen.dart';
import 'package:moshaf/views/qiblah/qiblah_on_boarding_screen.dart';
import 'package:moshaf/views/quran/all_quran_screen.dart';
import 'package:moshaf/views/quran/audio_screen.dart';
import 'package:moshaf/views/quran/tafseer_search_screen.dart';
import 'package:moshaf/views/quran_radio/quran_radio_screen.dart';
import 'package:moshaf/views/ramadan/ramadan_screen.dart';
import 'package:moshaf/views/recitation/recitation_screen.dart';
import 'package:moshaf/views/search/search_screen.dart';
import 'package:moshaf/views/tasbeeh/tasbeeh_screen.dart';
import 'package:moshaf/views/wodoo_teaching/wodoo_instructions_screen.dart';
import 'package:moshaf/views/zakat_al_mal/zakah_calculator.dart';
import 'package:moshaf/views/azkar/azkar_screen.dart';
import 'package:quran/quran.dart' as quran;

import '../azkar/zekr_screen.dart';
import '../quran/widgets/quran_page.dart';
import '../../constants/azkar.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Data Models
// ──────────────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final _RafeqAction? action;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.action,
  });
}

class _RafeqAction {
  final String type;
  final String label;
  final Map<String, dynamic> params;

  const _RafeqAction({
    required this.type,
    required this.label,
    required this.params,
  });

  factory _RafeqAction.fromJson(Map<String, dynamic> json) => _RafeqAction(
    type: json['type'] ?? 'answer',
    label: json['label'] ?? '',
    params: json['params'] is Map
        ? Map<String, dynamic>.from(json['params'])
        : {},
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────────────────────

class RafeqScreen extends StatefulWidget {
  const RafeqScreen({super.key});

  @override
  State<RafeqScreen> createState() => _RafeqScreenState();
}

class _RafeqScreenState extends State<RafeqScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _history = [];
  bool _loading = false;
  final List<String> _models = [
    "deepseek/deepseek-v4-flash:free",
    "google/gemma-4-31b-it:free",
    "arcee-ai/trinity-large-thinking:free",
    "google/gemma-4-26b-a4b-it:free",
    "nvidia/nemotron-3-super-120b-a12b:free",
    "openrouter/owl-alpha",
    "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
    "qwen/qwen3-coder:free",
    "poolside/laguna-m.1:free",
    "nvidia/nemotron-3-nano-30b-a3b:free",
    "poolside/laguna-xs.2:free",
    "liquid/lfm-2.5-1.2b-thinking:free",
    "liquid/lfm-2.5-1.2b-instruct:free",
    "baidu/cobuddy:free",
  ];
  static const _quickSuggestions = [
    ('اقرأ سورة يس', 'assets/images/quran.png'),
    ('أذكار الصباح', 'assets/images/prays.png'),
    ('أوقات الصلاة', 'assets/images/prayer_times.png'),
    ('اتجاه القبلة', 'assets/images/qiblah.png'),
    ('استمع للقرآن', 'assets/images/radio.png'),
    ('ورد يومي', 'assets/images/holy.png'),
    ('تفسير الآيات', 'assets/images/quran.png'),
    ('أحاديث نبوية', 'assets/images/hadith2.png'),
    ('مواقع المساجد', 'assets/images/masjed.png'),
    ('حساب الزكاة', 'assets/images/zakah.png'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // SYSTEM PROMPT — covers every feature in the app
  // ─────────────────────────────────────────────────────────────────────────
  static const _systemPrompt = '''
أنت رفيق، مساعد إسلامي ذكي مدمج في تطبيق مستقيم. تحدث بالعربية دائماً وكن ودوداً ومختصراً.

عندما يطلب المستخدم شيئاً، أرجع JSON فقط بهذا الشكل بدون أي نص إضافي:
{
  "response": "الرد للمستخدم (جملة أو جملتان فقط)",
  "action": {
    "type": "<نوع الإجراء من القائمة أدناه>",
    "label": "نص زر التنقل بالعربية مع إيموجي",
    "params": { ... }
  }
}

═══ أنواع الإجراءات المتاحة ═══

1.  navigate_quran          → قراءة القرآن الكريم (يفتح قائمة السور)
    params: { "surah_number": رقم, "surah_name": "اسم" }

2.  navigate_audio_quran    → الاستماع للقرآن بصوت القراء
    params: { "surah_number": رقم }

3.  navigate_radio          → إذاعة القرآن الكريم المصرية/السعودية

4.  navigate_tafseer        → تفسير الآيات (بحث وتفسير)
    params: { "surah_number": رقم }

5.  navigate_search         → البحث/التدوير في القرآن الكريم
    params: { "query": "نص البحث" }

6.  navigate_azkar          → الأذكار والأدعية (الرئيسية)
    params: { "category": "sabah|masaa|nawm|istiqaz|baad_salah|motafareqa|adhan|masjid|taam|wudu|hajj|manzil" }

7.  navigate_prays          → أدعية وأدعية نبوية

8.  navigate_prayer_times   → مواقيت الصلوات الخمس

9.  navigate_qiblah         → تحديد اتجاه القبلة

10. navigate_tasbeeh        → السبحة الإلكترونية

11. navigate_hadith         → الأحاديث النبوية الشريفة

12. navigate_recitation     → الوِرد اليومي / خطة ختم القرآن

13. navigate_wodoo          → تعليم الوضوء (للأطفال والمبتدئين)

14. navigate_pray_teaching  → تعليم كيفية الصلاة

15. navigate_qiblah         → تحديد اتجاه القبلة بالبوصلة

16. navigate_mosque         → البحث عن أقرب مسجد بالخريطة

17. navigate_ramadan        → خصائص شهر رمضان المبارك

18. navigate_haj            → مناسك الحج والعمرة

19. navigate_zakat          → حساب زكاة المال

20. navigate_podcast        → مقاطع الفيديو والبودكاست الإسلامي

21. navigate_nabawi_prays   → أدعية نبوية مختارة

22. answer                  → سؤال عام أو معلومة بدون تنقل

═══ أرقام السور المهمة ═══
الفاتحة=1, البقرة=2, آل عمران=3, النساء=4, المائدة=5,
يوسف=12, الكهف=18, مريم=19, طه=20, يس=36,
الرحمن=55, الملك=67, الإخلاص=112, الفلق=113, الناس=114.

═══ قواعد ═══
- إذا طلب المستخدم سوراً بالاسم → navigate_quran مع surah_number
- إذا طلب المستخدم نوع ذكر محدد مثل أذكار الصباح أو المساء أو النوم أو بعد الصلاة → استخدم navigate_azkar مع category المناسبة ولا تفتح شاشة الأذكار العامة
- category mapping:
  أذكار الصباح = sabah
  أذكار المساء = masaa
  أذكار النوم = nawm
  أذكار الاستيقاظ = istiqaz
  أذكار بعد الصلاة = baad_salah
  أذكار متفرقة = motafareqa
  أذكار الأذان = adhan
  أذكار المسجد = masjid
  أذكار الطعام = taam
  أذكار الوضوء = wudu
  أذكار الحج والعمرة = hajj
  أذكار المنزل = manzil
- إذا لم يكن هناك تنقل مناسب → استخدم "answer"
-اذا طلب احاديث او ادعية لحالته النفسية اظهرها دون توجيهه لأي صفحة
- أرجع JSON نظيف فقط بدون ماركداون أو backticks
''';


  void _navigateToAzkarCategory(String? category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final normalized = (category ?? '').trim().toLowerCase();

    final Map<String, ({String title, Map items})> azkarRoutes = {
      'sabah': (
      title: 'اذكار الصباح',
      items: AzkarConstants.azkarSabah,
      ),
      'masaa': (
      title: 'اذكار المساء',
      items: AzkarConstants.azkarMasaa,
      ),
      'nawm': (
      title: 'اذكار النوم',
      items: AzkarConstants.azkarAlNawm,
      ),
      'istiqaz': (
      title: 'اذكار الاستيقاظ',
      items: AzkarConstants.azkarAlIstiqaz,
      ),
      'baad_salah': (
      title: 'اذكار بعد الصلاة',
      items: AzkarConstants.azkarBaadAlsalah,
      ),
      'motafareqa': (
      title: 'اذكار متفرقة',
      items: AzkarConstants.azkarMotafareqa,
      ),
      'adhan': (
      title: 'اذكار الاذان',
      items: AzkarConstants.azkarAlAdhan,
      ),
      'masjid': (
      title: 'اذكار المسجد',
      items: AzkarConstants.azkarAlMasjid,
      ),
      'taam': (
      title: 'اذكار الطعام',
      items: AzkarConstants.azkarAlTaam,
      ),
      'wudu': (
      title: 'اذكار الوضوء',
      items: AzkarConstants.azkarAlWudu,
      ),
      'hajj': (
      title: 'اذكار الحج والعمرة',
      items: AzkarConstants.azkarAlHajjWalUmrah,
      ),
      'manzil': (
      title: 'اذكار المنزل',
      items: AzkarConstants.azkarAlManzil,
      ),
    };

    final route = azkarRoutes[normalized];

    if (route == null) {
      AzkarCubit.get(context).getZekrBasedOnTime(context);
      navigateTo(context, const AzkarScreen());
      return;
    }

    navigateTo(
      context,
      ZekrScreen(
        title: route.title,
        items: route.items,
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      text:
      'السلام عليكم ورحمة الله! 🌙\nأنا رفيق، مساعدك الإسلامي الشخصي\n\n'
          'يمكنني مساعدتك في:\n'
          '• قراءة أي سورة أو الاستماع إليها\n'
          '• أوقات الصلاة والأذان والقبلة\n'
          '• الأذكار والأدعية والتفسير\n'
          '• الأحاديث النبوية والوِرد اليومي\n'
          '• الحج والعمرة وحساب الزكاة\nوأكثر من ذلك! 🤲',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _loading) return;

    final userText = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(
        _ChatMessage(
          text: userText,
          isUser: true,
        ),
      );
      _loading = true;
    });

    _history.add({
      'role': 'user',
      'content': userText,
    });

    _scrollToBottom();

    try {

      http.Response? response;

      /// TRY MODELS ONE BY ONE
      for (final model in _models) {
        final apiKey = dotenv.env['OPENROUTER_API_KEY'];
        try {

          response = await http.post(
            Uri.parse(
              'https://openrouter.ai/api/v1/chat/completions',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization':
              'Bearer $apiKey',
              'HTTP-Referer': 'https://yourapp.com',
              'X-Title': 'Mostakeem App',
            },
            body: jsonEncode({
              "model": model,
              "messages": [
                {
                  "role": "system",
                  "content": _systemPrompt,
                },

                ..._history,
              ],
              "temperature": 0.6,
            }),
          );

          print("Using model: $model");
          print(response.body);

          /// SUCCESS
          if (response.statusCode == 200) {
            break;
          }

          /// RATE LIMIT
          if (response.statusCode == 429) {
            print("Rate limit reached for $model");
            // _models.remove(model);
            continue;
          }

          /// OTHER ERROR
          print(
            "Model failed: ${response.statusCode}",
          );

        } catch (e) {

          print("Model exception: $e");
          continue;
        }
      }

      /// ALL MODELS FAILED
      if (response == null || response.statusCode != 200) {
        _addError();
        return;
      }

      /// PARSE RESPONSE
      /// PARSE RESPONSE
      final data = jsonDecode(response.body);

      String rawText = data['choices'][0]['message']['content']
          .toString()
          .replaceAll(RegExp(r'```json\n?|\n?```'), '')
          .trim();

      Map<String, dynamic> parsed;

      try {

        /// Extract only JSON object
        final start = rawText.indexOf('{');
        final end = rawText.lastIndexOf('}');

        if (start != -1 && end != -1) {
          rawText = rawText.substring(start, end + 1);
        }

        parsed = jsonDecode(rawText);

      } catch (e) {

        print("JSON PARSE ERROR: $e");
        print(rawText);

        parsed = {
          'response': rawText,
          'action': null,
        };
      }

      _history.add({
        'role': 'assistant',
        'content': rawText,
      });

      _RafeqAction? action;

      if (parsed['action'] != null) {

        action = _RafeqAction.fromJson(
          Map<String, dynamic>.from(
            parsed['action'],
          ),
        );

        if (action.type == 'answer') {
          action = null;
        }
      }

      setState(() {

        _messages.add(
          _ChatMessage(
            text: parsed['response'] ??
                'حدث خطأ في الفهم.',
            isUser: false,
            action: action,
          ),
        );
      });

    } catch (e) {

      print(e);

      _addError();

    } finally {

      setState(() {
        _loading = false;
      });

      _scrollToBottom();
    }
  }
  void _addError() {
    setState(() {
      _messages.add(const _ChatMessage(
        text: 'عذراً، حدث خطأ. يرجى التحقق من الاتصال والمحاولة مجدداً.',
        isUser: false,
      ));
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Action handler — covers ALL navigate_ types
  // ─────────────────────────────────────────────────────────────────────────
  void _handleAction(_RafeqAction action) {
    try {
      final isDark =
          Theme.of(context).brightness == Brightness.dark;

      switch (action.type) {
      // ── Quran reading ──────────────────────────────────────────────
        case 'navigate_quran':
          final cubit = TextQuranCubit.get(context);
          if (cubit.suraJsonData == null) return;

          int surahNum = 1;
          final value = action.params['surah_number'];
          if (value is int) {
            surahNum = value;
          } else if (value is String) {
            surahNum = int.tryParse(value) ?? 1;
          }
          cubit.soraNumber = surahNum;
          navigateTo(
            context,
            QuranViewPage(
              navigatedFromRecitation: false,
              shouldHighlightText: false,
              highlightVerse: '',
              jsonData: cubit.suraJsonData!,
              pageNumber: quran.getPageNumber(surahNum, 1),
            ),
          );
          break;

      // ── Audio Quran ────────────────────────────────────────────────
        case 'navigate_audio_quran':
          int surahNum = 1;
          final value = action.params['surah_number'];
          if (value is int) surahNum = value;
          if (value is String) surahNum = int.tryParse(value) ?? 1;
          AudioQuranCubit.get(context).sorahNumber = surahNum;
          TextQuranCubit.get(context).soraNumber = surahNum;
          navigateTo(context, AudioScreen());
          break;

      // ── Radio ──────────────────────────────────────────────────────
        case 'navigate_radio':
          navigateTo(context, QuranRadioScreen());
          break;

      // ── Tafseer ────────────────────────────────────────────────────
        case 'navigate_tafseer':
          navigateTo(context, const TafseerSearchScreen());
          break;

      // ── Quran search ───────────────────────────────────────────────
        case 'navigate_search':
          navigateTo(context, const SearchScreen());
          break;

      // ── Azkar (with optional category) ────────────────────────────
        case 'navigate_azkar':
          _navigateToAzkarCategory(action.params['category']?.toString());
          break;

      // ── Prays (أدعية) ──────────────────────────────────────────────
        case 'navigate_prays':
          AzkarCubit.get(context).getRandomDuaa();
          navigateTo(context, const PraysScreen());
          break;

      // ── Nabawi prays ───────────────────────────────────────────────
        case 'navigate_nabawi_prays':
          navigateTo(
            context,
            OnePrayScreen(
              title: 'أدعية نبوية',
              items: AzkarConstants.adeyahNabaweyah,
              // isDark: isDark,
            ),
          );
          break;

      // ── Prayer times ───────────────────────────────────────────────
        case 'navigate_prayer_times':
          navigateTo(context, PrayerTimesScreen());
          break;

      // ── Qiblah ────────────────────────────────────────────────────
        case 'navigate_qiblah':
          navigateTo(context, QiblahOnBoardingScreen());
          break;

      // ── Tasbeeh ───────────────────────────────────────────────────
        case 'navigate_tasbeeh':
          navigateTo(context, TasbeehScreen());
          break;

      // ── Hadith ────────────────────────────────────────────────────
        case 'navigate_hadith':
          navigateTo(context, HadithScreen());
          break;

      // ── Recitation / Ward ─────────────────────────────────────────
        case 'navigate_recitation':
          navigateTo(context, RecitationScreen());
          break;

      // ── Wudoo teaching ────────────────────────────────────────────
        case 'navigate_wodoo':
          navigateTo(context, WodooInstructionsScreen());
          break;

      // ── Prayer teaching ───────────────────────────────────────────
        case 'navigate_pray_teaching':
          navigateTo(context, PrayInstructionsScreen());
          break;

      // ── Mosque locator ────────────────────────────────────────────
        case 'navigate_mosque':
          navigateTo(context, MosqueLocationScreen());
          break;

      // ── Ramadan ───────────────────────────────────────────────────
        case 'navigate_ramadan':
          navigateTo(context, RamadanScreen());
          break;

      // ── Haj & Umrah ───────────────────────────────────────────────
        case 'navigate_haj':
          navigateTo(context, HajScreen(isDark: isDark));
          break;

      // ── Zakat calculator ──────────────────────────────────────────
        case 'navigate_zakat':
          navigateTo(context, ZakahCalculator());
          break;

      // ── Podcast / videos ──────────────────────────────────────────
        case 'navigate_podcast':
          navigateTo(context, PodcastsScreen());
          break;

        default:
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تنفيذ العملية')),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.isGoldMode;

    final green = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    return Scaffold(
      // ── no scaffold background — we use the background image ──────────
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ─────────────────────────────────────────
          Image.asset(
            'assets/images/chatbot_bg.png',
            fit: BoxFit.cover,
          ),

          // ── Scrim so text is readable ────────────────────────────────
          Container(
            color: isDark
                ? Colors.black.withOpacity(0.65)
                : Colors.black.withOpacity(0.35),
          ),

          // ── Content ──────────────────────────────────────────────────
          Column(
            children: [
              _buildHeader(green, isDark, gold),
              Expanded(
                  child: _buildMessageList(isDark, gold, green, textClr, borderClr)),
              if (_messages.length == 1)
                _buildQuickSuggestions(green, isDark, gold),
              _buildInputArea(green, isDark, gold, borderClr),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(Color green, bool isDark, bool gold) {
    return Container(
      color: green.withOpacity(0.90),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/images/rafeq_hi.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رفيق',
                        style: AppTextStyles.madB18(context,
                            color: Colors.white)),
                    Row(
                      children: [
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: BoxDecoration(
                            color: _loading
                                ? Colors.orange
                                : Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          _loading ? 'يفكر...' : 'مساعدك الإسلامي الشخصي',
                          style: AppTextStyles.madReg12(context,
                              color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
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

  // ── Message list ─────────────────────────────────────────────────────────
  Widget _buildMessageList(
      bool isDark, bool gold, Color green, Color textClr, Color borderClr) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _buildTypingIndicator(green);
        return _buildMessageBubble(
            _messages[i], isDark, gold, green, textClr);
      },
    );
  }

  // ── Single bubble ────────────────────────────────────────────────────────
  Widget _buildMessageBubble(
      _ChatMessage msg,
      bool isDark,
      bool gold,
      Color green,
      Color textClr,
      ) {
    final isUser = msg.isUser;

    // User bubbles: solid green
    // Bot bubbles: semi-transparent dark glass
    final bubbleBg = isUser
        ? green
        : Colors.black.withOpacity(isDark ? 0.60 : 0.45);

    final bubbleTextClr = isUser ? Colors.white : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18.r,
              backgroundColor: green,
              backgroundImage:
              const AssetImage('assets/images/rafeq_hi.png'),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 10.h),
                  constraints: BoxConstraints(maxWidth: 0.75.sw),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.r),
                      topRight: Radius.circular(18.r),
                      bottomLeft:
                      Radius.circular(isUser ? 18.r : 4.r),
                      bottomRight:
                      Radius.circular(isUser ? 4.r : 18.r),
                    ),
                    border: !isUser
                        ? Border.all(
                        color: Colors.white.withOpacity(0.15))
                        : null,
                  ),
                  child: Text(
                    msg.text,
                    style: AppTextStyles.madReg14(context,
                        color: bubbleTextClr),
                    textAlign: TextAlign.right,
                  ),
                ),

                // ── Action button ────────────────────────────────────
                if (msg.action != null) ...[
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () => _handleAction(msg.action!),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 9.h),
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: green.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.action!.label,
                            style: AppTextStyles.madB14(context,
                                color: Colors.white),
                          ),
                          SizedBox(width: 6.w),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) SizedBox(width: 8.w),
        ],
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────────────────────
  Widget _buildTypingIndicator(Color green) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: green,
            backgroundImage:
            const AssetImage('assets/images/rafeq_hi.png'),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(18.r),
                bottomRight: Radius.circular(18.r),
                bottomLeft: Radius.circular(4.r),
              ),
              border:
              Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  3, (i) => _TypingDot(delay: i * 200, color: green)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick suggestions ─────────────────────────────────────────────────────
  Widget _buildQuickSuggestions(
      Color green, bool isDark, bool gold) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('اقتراحات سريعة',
              style: AppTextStyles.madReg12(context,
                  color: Colors.white70)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.start,
            children: _quickSuggestions.map((q) {
              return GestureDetector(
                onTap: () => _sendMessage(q.$1),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.40),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(q.$1,
                      style: AppTextStyles.madReg12(context,
                          color: Colors.white)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Input area ────────────────────────────────────────────────────────────
  Widget _buildInputArea(
      Color green, bool isDark, bool gold, Color borderClr) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(isDark ? 0.75 : 0.55),
          border: Border(
              top: BorderSide(
                  color: Colors.white.withOpacity(0.15))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 46.h),
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.20)),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.madReg14(context,
                      color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اكتب هنا... مثلاً: اقرأ سورة الكهف',
                    hintStyle: AppTextStyles.madReg14(context,
                        color: Colors.white38),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: _loading ? Colors.grey : green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: green.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Typing dot animation
// ──────────────────────────────────────────────────────────────────────────────

class _TypingDot extends StatefulWidget {
  final int delay;
  final Color color;
  const _TypingDot({required this.delay, required this.color});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: -6.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
              color: widget.color, shape: BoxShape.circle),
        ),
      ),
    ),
  );
}