import '../models/complaint.dart';
import '../models/technician.dart';
import '../models/triage_result.dart';

class AIService {
  // Stronger, deterministic triage:
  // - keyword + synonym scoring per class
  // - urgency scoring from safety keywords + time words + severity words
  // - returns a stable signature used for dedupe across students/locations
  static TriageResult triage({
    required String description,
    required String block,
    required String room,
  }) {
    final raw = description.trim();
    final t = _normalize(raw);
    final tokens = _tokens(t);

    final reasons = <String>[];

    // Safety / disciplinary override (score >= 4 triggers Counselor routing)
    final safetyHits = _countHits(tokens, const {
      'ragging': 4,
      'harassment': 4,
      'harassing': 3,
      'bully': 3,
      'bullying': 3,
      'assault': 5,
      'threat': 4,
      'abuse': 3,
      'molest': 5,
      'stalk': 4,
    });
    if (safetyHits.score >= 4) {
      reasons.add('Safety/disciplinary keywords detected');
      return TriageResult(
        complaintClass: ComplaintClass.disciplinary,
        priority: ComplaintPriority.urgent,
        urgencyScore: 1.0,
        confidence: 0.92,
        reasons: reasons,
        requiredSkills: const {TechnicianSkill.disciplinary},
        signature: _signature(
          tokens: tokens,
          block: block,
          room: room,
          complaintClass: ComplaintClass.disciplinary,
        ),
      );
    }

    final scoreIt = _countHits(tokens, const {
      'wifi': 3,
      'internet': 3,
      'network': 2,
      'router': 2,
      'lan': 2,
      'server': 2,
      'login': 2,
      'portal': 2,
      'website': 2,
      'app': 1,
    });
    final scoreElectrical = _countHits(tokens, const {
      'electric': 3,
      'electricity': 3,
      'spark': 4,
      'short': 2,
      'circuit': 2,
      'switch': 2,
      'fan': 2,
      'light': 2,
      'bulb': 1,
      'power': 2,
      'socket': 2,
      'plug': 1,
      'shock': 5,
      'burn': 4,
      'smoke': 5,
      'outage': 4,
      'powercut': 4,
      'breaker': 3,
    });
    final scorePlumbing = _countHits(tokens, const {
      'water': 3,
      'leak': 4,
      'leakage': 4,
      'tap': 2,
      'pipe': 3,
      'flush': 2,
      'toilet': 2,
      'washroom': 2,
      'bathroom': 2,
      'drain': 2,
      'sewage': 4,
      'overflow': 3,
      'faucet': 2,
      'faucets': 2,
      'drip': 3,
      'dripping': 3,
    });
    final scoreInfra = _countHits(tokens, const {
      'door': 2,
      'window': 2,
      'ceiling': 2,
      'wall': 2,
      'crack': 3,
      'broken': 2,
      'lift': 4,
      'elevator': 4,
      'stairs': 2,
      'floor': 2,
      'projector': 2,
      'classroom': 1,
      'bench': 1,
      'chair': 1,
      'ac': 2,
      'aircon': 2,
      'air': 1,
    });

    final classScores = <ComplaintClass, _HitScore>{
      ComplaintClass.it: scoreIt,
      ComplaintClass.electrical: scoreElectrical,
      ComplaintClass.plumbing: scorePlumbing,
      ComplaintClass.infrastructure: scoreInfra,
      ComplaintClass.general: _HitScore(0, 0),
    };

    var bestClass = ComplaintClass.general;
    var best = const _HitScore(0, 0);
    for (final entry in classScores.entries) {
      if (entry.value.score > best.score) {
        bestClass = entry.key;
        best = entry.value;
      }
    }

    if (best.score == 0) {
      reasons.add('No strong keywords; routed to general');
    } else {
      reasons.add('Matched ${best.hits} keyword signals for ${bestClass.name}');
    }

    // urgency scoring
    final urgency = _urgencyScore(tokens);
    final priority = _mapPriority(bestClass, urgency, scoreElectrical, scorePlumbing);

    final confidence = _confidence(best, urgency);
    reasons.add('Urgency score ${(urgency * 100).round()}%');

    final skills = switch (bestClass) {
      ComplaintClass.it => {TechnicianSkill.it},
      ComplaintClass.electrical => {TechnicianSkill.electrical},
      ComplaintClass.plumbing => {TechnicianSkill.plumbing},
      ComplaintClass.infrastructure => {TechnicianSkill.infrastructure},
      ComplaintClass.disciplinary => {TechnicianSkill.disciplinary},
      ComplaintClass.general => {TechnicianSkill.general},
    };

    return TriageResult(
      complaintClass: bestClass,
      priority: priority,
      urgencyScore: urgency,
      confidence: confidence,
      reasons: reasons,
      requiredSkills: skills,
      signature: _signature(
        tokens: tokens,
        block: block,
        room: room,
        complaintClass: bestClass,
      ),
    );
  }

  static String labelFor(ComplaintClass c) {
    return switch (c) {
      ComplaintClass.infrastructure => 'Infrastructure',
      ComplaintClass.plumbing => 'Plumbing',
      ComplaintClass.electrical => 'Electrical',
      ComplaintClass.it => 'IT / Network',
      ComplaintClass.disciplinary => 'Disciplinary',
      ComplaintClass.general => 'General',
    };
  }

  static String _normalize(String s) {
    final lower = s.toLowerCase();
    return lower
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _tokens(String s) {
    final raw = s.split(' ').where((w) => w.isNotEmpty).toList();
    const stop = {
      'the',
      'a',
      'an',
      'is',
      'are',
      'to',
      'in',
      'on',
      'at',
      'of',
      'for',
      'and',
      'or',
      'with',
      'from',
      'my',
      'our',
      'we',
      'it',
      'this',
      'that',
      'please',
      'since',
      'today',
      'yesterday',
      'room',
      'block',
    };
    return raw.where((w) => !stop.contains(w)).toList();
  }

  static _HitScore _countHits(List<String> tokens, Map<String, int> weights) {
    var hits = 0;
    var score = 0;
    for (final tok in tokens) {
      final w = weights[tok];
      if (w != null) {
        hits += 1;
        score += w;
      }
    }
    return _HitScore(hits, score);
  }

  static double _urgencyScore(List<String> tokens) {
    final u = _countHits(tokens, const {
      'urgent': 4,
      'immediately': 3,
      'asap': 3,
      'danger': 5,
      'hazard': 5,
      'emergency': 5,
      'fire': 5,
      'smoke': 5,
      'shock': 5,
      'flood': 4,
      'burst': 4,
      'broken': 2,
      'not': 1,
      'down': 2,
      'stopped': 2,
      'failed': 2,
      'leak': 3,
      'leakage': 3,
      'overflow': 3,
      'today': 2,
      'now': 2,
      'days': 2,
      'day': 2,
      'hours': 2,
      'hour': 2,
      'weeks': 2,
      'week': 2,
    });
    // clamp 0..1 with diminishing returns
    return (u.score / 10).clamp(0, 1).toDouble();
  }

  static ComplaintPriority _mapPriority(
    ComplaintClass c,
    double urgency,
    _HitScore electrical,
    _HitScore plumbing,
  ) {
    if (c == ComplaintClass.disciplinary) return ComplaintPriority.urgent;

    // hard safety indicators in electrical
    if (c == ComplaintClass.electrical && electrical.score >= 8) {
      return ComplaintPriority.urgent;
    }
    // heavy water leakage / sewage
    if (c == ComplaintClass.plumbing && plumbing.score >= 8) {
      return ComplaintPriority.high;
    }

    if (urgency >= 0.8) return ComplaintPriority.urgent;
    if (urgency >= 0.55) return ComplaintPriority.high;
    if (urgency >= 0.25) return ComplaintPriority.medium;
    return ComplaintPriority.low;
  }

  static double _confidence(_HitScore best, double urgency) {
    // confidence increases with keyword evidence; urgency slightly helps
    final base = (best.score / 10).clamp(0, 1).toDouble();
    return (0.35 + base * 0.55 + urgency * 0.1).clamp(0, 0.98).toDouble();
  }

  static String _signature({
    required List<String> tokens,
    required String block,
    required String room,
    required ComplaintClass complaintClass,
  }) {
    final loc = '${block.trim().toLowerCase()}|${room.trim().toLowerCase()}';
    final canonical = _canonicalClassHits(tokens, complaintClass);
    if (canonical.isNotEmpty) {
      return '${complaintClass.name}|$loc|${canonical.join('+')}';
    }

    // Fallback: stable token signature if we couldn't detect canonical hits.
    final keyTokens = tokens.take(8).toList()..sort();
    return '${complaintClass.name}|$loc|${keyTokens.join(',')}';
  }

  // Used for duplicate clustering (many students may describe the same issue differently).
  static Set<String> canonicalTokensForDedupe(String description) {
    final t = _tokens(_normalize(description));
    final buckets = <String>{};

    for (final tok in t) {
      if (_plumbingKeywords.contains(tok)) buckets.add('plumbing_leak');
      if (_electricalKeywords.contains(tok)) buckets.add('electrical_fault');
      if (_itKeywords.contains(tok)) buckets.add('network_down');
      if (_infrastructureKeywords.contains(tok)) {
        buckets.add('infrastructure_damage');
      }
      if (_disciplinaryKeywords.contains(tok)) buckets.add('discipline_safety');
    }
    return buckets;
  }

  static List<String> _canonicalClassHits(
    List<String> tokens,
    ComplaintClass complaintClass,
  ) {
    bool hasAny(Set<String> keywords) {
      for (final tok in tokens) {
        if (keywords.contains(tok)) return true;
      }
      return false;
    }

    return switch (complaintClass) {
      ComplaintClass.plumbing =>
        hasAny(_plumbingKeywords) ? const ['plumbing_leak'] : const [],
      ComplaintClass.electrical =>
        hasAny(_electricalKeywords) ? const ['electrical_fault'] : const [],
      ComplaintClass.it =>
        hasAny(_itKeywords) ? const ['network_down'] : const [],
      ComplaintClass.infrastructure =>
        hasAny(_infrastructureKeywords)
            ? const ['infrastructure_damage']
            : const [],
      ComplaintClass.disciplinary =>
        hasAny(_disciplinaryKeywords) ? const ['discipline_safety'] : const [],
      ComplaintClass.general =>
        tokens.isNotEmpty ? const ['general_issue'] : const [],
    };
  }
}

class _HitScore {
  final int hits;
  final int score;
  const _HitScore(this.hits, this.score);
}

// Canonical keyword buckets for dedupe + signatures.
const Set<String> _plumbingKeywords = {
  'water',
  'leak',
  'leakage',
  'tap',
  'faucet',
  'pipe',
  'flush',
  'toilet',
  'washroom',
  'bathroom',
  'drain',
  'sewage',
  'overflow',
  'burst',
  'dripping',
};

const Set<String> _electricalKeywords = {
  'electric',
  'electricity',
  'spark',
  'short',
  'circuit',
  'switch',
  'fan',
  'light',
  'bulb',
  'power',
  'socket',
  'plug',
  'shock',
  'burn',
  'smoke',
  'breaker',
  'outage',
};

const Set<String> _itKeywords = {
  'wifi',
  'internet',
  'network',
  'router',
  'lan',
  'server',
  'login',
  'portal',
  'website',
  'app',
};

const Set<String> _infrastructureKeywords = {
  'door',
  'window',
  'ceiling',
  'wall',
  'crack',
  'broken',
  'lift',
  'elevator',
  'stairs',
  'floor',
  'projector',
  'classroom',
  'bench',
  'chair',
  'ac',
  'aircon',
  'air',
};

const Set<String> _disciplinaryKeywords = {
  'ragging',
  'harassment',
  'bully',
  'assault',
  'threat',
  'abuse',
  'molest',
  'stalk',
};
