import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eFootball Tier List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
      ),
      home: const TierListPage(),
    );
  }
}

// ── Models ───────────────────────────────────────────────────
class TierInfo {
  final String id;
  final Color color;
  const TierInfo(this.id, this.color);
}

class Player {
  final String id, name, pos, posGroup, pack, wikiTitle, initials;
  final int ovr;
  const Player({
    required this.id, required this.name, required this.pos,
    required this.posGroup, required this.ovr, required this.pack,
    required this.wikiTitle, required this.initials,
  });
}

// ── Static data ──────────────────────────────────────────────
const kTiers = [
  TierInfo('SS', Color(0xFFFF3355)),
  TierInfo('S',  Color(0xFFFF8800)),
  TierInfo('A',  Color(0xFFCCCC00)),
  TierInfo('B',  Color(0xFF33AA44)),
  TierInfo('C',  Color(0xFF2288DD)),
  TierInfo('D',  Color(0xFF444466)),
];

// อัปเดตรายชื่อนักเตะ 5 คนตามที่ขอ พร้อมคีย์สำหรับการดึงรูปภาพวิกิพีเดียที่ถูกต้อง
const kPlayers = [
  Player(id:'mbappe',  name:'K. Mbappé',    pos:'CF',  posGroup:'FW', ovr:96, pack:'featured', wikiTitle:'Kylian_Mbappé',        initials:'KM'),
  Player(id:'haaland', name:'E. Haaland',   pos:'CF',  posGroup:'FW', ovr:95, pack:'featured', wikiTitle:'Erling_Haaland',       initials:'EH'),
  Player(id:'dembele', name:'O. Dembélé',   pos:'RWF', posGroup:'FW', ovr:91, pack:'featured', wikiTitle:'Ousmane_Dembélé',      initials:'OD'),
  Player(id:'cr7',     name:'C. Ronaldo',   pos:'CF',  posGroup:'FW', ovr:87, pack:'legend',   wikiTitle:'Cristiano_Ronaldo',    initials:'CR'),
  Player(id:'messi',   name:'L. Messi',     pos:'SS',  posGroup:'FW', ovr:87, pack:'legend',   wikiTitle:'Lionel_Messi',         initials:'LM'),
];

// ── Wiki image fetch ─────────────────────────────────────────
Future<String?> fetchWikiImage(String title) async {
  try {
    final uri = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final thumb = data['thumbnail'] as Map<String, dynamic>?;
      return thumb?['source'] as String?;
    }
  } catch (_) {}
  return null;
}

// ── Page ─────────────────────────────────────────────────────
class TierListPage extends StatefulWidget {
  const TierListPage({super.key});
  @override
  State<TierListPage> createState() => _TierListPageState();
}

class _TierListPageState extends State<TierListPage> {
  late Map<String, List<String>> _state;
  String _filter = 'ALL';
  final Map<String, String?> _imgs = {};

  @override
  void initState() {
    super.initState();
    _reset(notify: false);
    _loadImages();
  }

  void _reset({bool notify = true}) {
    _state = {
      'pool': kPlayers.map((p) => p.id).toList(),
      for (final t in kTiers) t.id: <String>[],
    };
    if (notify) setState(() {});
  }

  Future<void> _loadImages() async {
    for (final p in kPlayers) {
      final url = await fetchWikiImage(p.wikiTitle);
      if (mounted) setState(() => _imgs[p.id] = url);
    }
  }

  Player _player(String id) => kPlayers.firstWhere((p) => p.id == id);

  String _zone(String id) {
    for (final e in _state.entries) {
      if (e.value.contains(id)) return e.key;
    }
    return 'pool';
  }

  void _move(String playerId, String to) {
    setState(() {
      final from = _zone(playerId);
      _state[from]?.remove(playerId);
      _state[to] ??= [];
      _state[to]!.add(playerId);
    });
  }

  // ── Pack styling ──
  Color _packBg(String pack) => switch (pack) {
    'legend'   => const Color(0xFF4C1D95),
    'featured' => const Color(0xFF065F46),
    _          => const Color(0xFF1F2937),
  };
  Color _packFg(String pack) => switch (pack) {
    'legend'   => const Color(0xFFA78BFA),
    'featured' => const Color(0xFF6EE7B7),
    _          => const Color(0xFF6B7280),
  };
  String _packLabel(String pack) => switch (pack) {
    'legend'   => 'Legend',
    'featured' => 'Featured',
    _          => 'Standard',
  };

  // ── Player card ──
  Widget _card(String id) {
    final p = _player(id);
    
    // แก้ไข: ถ้าไม่ตรงกับ Filter ให้ส่งคืน Widget เปล่าเพื่อไม่ให้กินพื้นที่ใน Wrap
    if (_filter != 'ALL' && p.posGroup != _filter) return const SizedBox.shrink();

    final imgUrl = _imgs[id];

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2A2A38), width: 1.5),
            color: const Color(0xFF1A1A24),
          ),
          clipBehavior: Clip.antiAlias,
          child: imgUrl != null
              ? Image.network(imgUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(p.initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
                  ))
              : Center(
                  child: Text(p.initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
                ),
        ),
        const SizedBox(height: 3),
        Text(p.name, style: const TextStyle(fontSize: 9, color: Color(0xFFAAAAAA)), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(p.pos,  style: const TextStyle(fontSize: 8, color: Color(0xFF555555))),
        Text('${p.ovr}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF00C896))),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _packBg(p.pack),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(_packLabel(p.pack), style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: _packFg(p.pack))),
        ),
      ],
    );

    return SizedBox(
      width: 64,
      child: Draggable<String>(
        data: id,
        feedback: Material(color: Colors.transparent, child: Opacity(opacity: 0.9, child: SizedBox(width: 64, child: body))),
        childWhenDragging: Opacity(opacity: 0.3, child: body),
        child: body,
      ),
    );
  }

  // ── Drop zone ──
  Widget _dropZone(String zoneId) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => _zone(d.data) != zoneId,
      onAcceptWithDetails: (d) => _move(d.data, zoneId),
      builder: (ctx, candidates, _) {
        final over = candidates.isNotEmpty;
        final ids = _state[zoneId] ?? [];
        
        // เช็คว่าในโซนนี้มีตัวที่ผ่านฟิลเตอร์เหลืออยู่จริงไหม
        final visibleIds = ids.where((id) {
          if (_filter == 'ALL') return true;
          return _player(id).posGroup == _filter;
        }).toList();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 85),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: over ? const Color(0xFF1C1C2E) : const Color(0xFF16161E),
            border: Border.all(
              color: over ? const Color(0xFF00C896) : const Color(0xFF1E1E28),
            ),
          ),
          child: visibleIds.isEmpty
              ? const Center(child: Text('วางที่นี่', style: TextStyle(fontSize: 10, color: Color(0xFF2A2A3A))))
              : Wrap(spacing: 6, runSpacing: 6, children: ids.map(_card).toList()),
        );
      },
    );
  }

  // ── Tier row ──
  Widget _tierRow(TierInfo t) {
    final textColor = t.color.computeLuminance() > 0.35 ? Colors.black : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 44,
                color: t.color,
                alignment: Alignment.center,
                child: Text(t.id, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -1)),
              ),
              Expanded(child: _dropZone(t.id)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter chip ──
  Widget _chip(String label) {
    final on = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: on ? const Color(0xFF00C896) : Colors.transparent,
          border: Border.all(color: on ? const Color(0xFF00C896) : const Color(0xFF2A2A38)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w700 : FontWeight.w400, color: on ? Colors.black : const Color(0xFF888888))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E1E28)))),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF0077FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: const Text('eF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('eFootball Tier List', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('eFHUB • Jun 2026', style: TextStyle(fontSize: 9, color: Color(0xFF555555))),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2A2A38)), borderRadius: BorderRadius.circular(20)),
                      child: const Text('↺ รีเซ็ต', style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
                    ),
                  ),
                ],
              ),
            ),
            // Filter bar
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E1E28)))),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: ['ALL','GK','CB','MF','FW'].map(_chip).toList()),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('↕ ลาก & วางเพื่อจัดอันดับ', style: TextStyle(fontSize: 10, color: Color(0xFF444444))),
                    const SizedBox(height: 8),
                    ...kTiers.map(_tierRow),
                    const SizedBox(height: 14),
                    const Text('ยังไม่ได้จัดอันดับ', style: TextStyle(fontSize: 10, color: Color(0xFF444444))),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _dropZone('pool'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}