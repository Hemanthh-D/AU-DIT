import 'dart:math' as math;
import '../models/complaint.dart';
import '../models/technician.dart';
import '../models/triage_result.dart';

class AIService {
  // ================= STOP WORDS & NEGATIONS =================
  static const Set<String> _negations = {
    'not',
    'no',
    'never',
    'isnt',
    'doesnt',
    'cant',
    'cannot',
    'without',
  };

  // Words that carry zero semantic weight. Filtering these out saves fuzzy-matching CPU cycles.
  static const Set<String> _stopWords = {
    'the',
    'a',
    'an',
    'is',
    'are',
    'am',
    'was',
    'were',
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
    'i',
    'me',
    'us',
    'you',
    'them',
    'has',
    'have',
    'had',
    'been',
    'there',
    'their',
    'they',
    'he',
    'she',
    'him',
    'her',
    'room',
    'block',
    'hostel',
    'sir',
    'maam',
  };

  // ================= MAIN TRIAGE =================
  static TriageResult triage({
    required String description,
    required String block,
    required String room,
  }) {
    final tokens = _tokenize(description);
    final reasons = <String>[];

    // ===== SAFETY OVERRIDE =====
    final safetyHits = _scoreTokens(tokens, _disciplinaryKeywords);

    if (safetyHits.score >= 4) {
      reasons.add(
        'Safety/Disciplinary keywords detected (Score: ${safetyHits.score})',
      );
      return TriageResult(
        complaintClass: ComplaintClass.disciplinary,
        priority: ComplaintPriority.urgent,
        urgencyScore: 1.0,
        confidence: 0.95,
        reasons: reasons,
        requiredSkills: const {TechnicianSkill.disciplinary},
        signature: _signature(tokens, block, room, ComplaintClass.disciplinary),
      );
    }

    // ===== CATEGORY SCORES =====
    final scoreIT = _scoreTokens(tokens, _itKeywords);
    final scoreElectrical = _scoreTokens(tokens, _electricalKeywords);
    final scorePlumbing = _scoreTokens(tokens, _plumbingKeywords);
    final scoreInfra = _scoreTokens(tokens, _infraKeywords);

    final classScores = {
      ComplaintClass.it: scoreIT,
      ComplaintClass.electrical: scoreElectrical,
      ComplaintClass.plumbing: scorePlumbing,
      ComplaintClass.infrastructure: scoreInfra,
      ComplaintClass.general: const _HitScore(0, 0),
    };

    ComplaintClass bestClass = ComplaintClass.general;
    _HitScore best = const _HitScore(0, 0);

    for (final entry in classScores.entries) {
      if (entry.value.score > best.score) {
        bestClass = entry.key;
        best = entry.value;
      }
    }

    if (best.score == 0) {
      reasons.add('No strong keywords detected; routed to General');
    } else {
      reasons.add('Matched ${best.hits} signals for ${bestClass.name}');
    }

    // ===== URGENCY =====
    final urgency = _urgencyScore(tokens);
    final priority = _mapPriority(
      bestClass,
      urgency,
      scoreElectrical,
      scorePlumbing,
    );
    final confidence = _confidence(best, urgency);

    reasons.add('Urgency severity at ${(urgency * 100).round()}%');

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
      signature: _signature(tokens, block, room, bestClass),
    );
  }

  // ================= TOKENIZER =================
  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty && !_stopWords.contains(w))
        .toList();
  }

  // ================= SCORING ENGINE (Sliding Window Fix) =================
  static _HitScore _scoreTokens(List<String> tokens, Map<String, int> dict) {
    int hits = 0;
    int score = 0;
    bool negated = false;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // 1. Check for Negation
      if (_negations.contains(token)) {
        negated = true;
        continue;
      }

      // 2. N-Gram (Bigram) Check via Sliding Window
      if (i < tokens.length - 1) {
        final bigram = '$token ${tokens[i + 1]}';
        if (dict.containsKey(bigram)) {
          hits += 2;
          score += dict[bigram]! + (negated ? 1 : 0);
          negated = false;
          i++; // Consume the next word so we don't double-score it
          continue;
        }
      }

      // 3. Exact Unigram Check
      if (dict.containsKey(token)) {
        hits++;
        score += dict[token]! + (negated ? 1 : 0);
        negated = false;
        continue;
      }

      // 4. Fuzzy Matching (Typo Tolerance)
      if (token.length > 4) {
        bool fuzzyMatched = false;
        for (final entry in dict.entries) {
          if (entry.key.contains(' ')) continue; // Skip bigrams in fuzzy loop

          final distance = _levenshtein(token, entry.key);
          // Strict threshold of 1 to prevent unrelated word mutations
          if (distance <= 1) {
            hits++;
            score += entry.value + (negated ? 1 : 0);
            fuzzyMatched = true;
            break;
          }
        }
        if (fuzzyMatched) {
          negated = false;
          continue;
        }
      }

      // Reset negation if the word didn't match anything in the dictionary
      negated = false;
    }

    return _HitScore(hits, score);
  }

  // ================= LEVENSHTEIN (Fuzzy Match) =================
  static int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var v0 = List.generate(b.length + 1, (i) => i);
    var v1 = List.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(math.min);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[b.length];
  }

  // ================= PRIORITY & UTILS =================
  static double _urgencyScore(List<String> tokens) {
    final score = _scoreTokens(tokens, _urgencyKeywords);
    return (score.score / 10).clamp(0, 1).toDouble();
  }

  static ComplaintPriority _mapPriority(
    ComplaintClass c,
    double urgency,
    _HitScore electrical,
    _HitScore plumbing,
  ) {
    if (c == ComplaintClass.disciplinary) return ComplaintPriority.urgent;
    if (c == ComplaintClass.electrical && electrical.score >= 8) {
      return ComplaintPriority.urgent;
    }
    if (c == ComplaintClass.plumbing && plumbing.score >= 8) {
      return ComplaintPriority.high;
    }
    if (urgency >= 0.8) return ComplaintPriority.urgent;
    if (urgency >= 0.55) return ComplaintPriority.high;
    if (urgency >= 0.25) return ComplaintPriority.medium;
    return ComplaintPriority.low;
  }

  static double _confidence(_HitScore best, double urgency) {
    final base = (best.score / 10).clamp(0, 1).toDouble();
    return (0.35 + base * 0.55 + urgency * 0.1).clamp(0, 0.98);
  }

  static String _signature(
    List<String> tokens,
    String block,
    String room,
    ComplaintClass cls,
  ) {
    final loc = '${block.toLowerCase()}|${room.toLowerCase()}';
    final key = tokens.take(6).toList()..sort();
    return '${cls.name}|$loc|${key.join(',')}';
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

  // Used for duplicate clustering
  static Set<String> canonicalTokensForDedupe(String description) {
    final t = _tokenize(_normalize(description));
    final buckets = <String>{};

    for (final tok in t) {
      if (_plumbingKeywords.containsKey(tok)) buckets.add('plumbing_leak');
      if (_electricalKeywords.containsKey(tok)) buckets.add('electrical_fault');
      if (_itKeywords.containsKey(tok)) buckets.add('network_down');
      if (_infraKeywords.containsKey(tok)) {
        buckets.add('infrastructure_damage');
      }
      if (_disciplinaryKeywords.containsKey(tok)) {
        buckets.add('discipline_safety');
      }
    }
    return buckets;
  }

  static String _normalize(String s) {
    final lower = s.toLowerCase();
    return lower
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _HitScore {
  final int hits;
  final int score;
  const _HitScore(this.hits, this.score);
}

// ================= MASSIVELY EXPANDED DICTIONARIES =================

const Map<String, int> _itKeywords = {
  // Network & Connectivity
  'wifi': 4, 'internet': 4, 'network': 3, 'router': 3, 'lan': 3, 'ethernet': 3,
  'cable': 2, 'vpn': 3, 'firewall': 2, 'bandwidth': 2, 'ping': 2, 'latency': 2,
  'slow': 2,
  'disconnect': 3,
  'disconnected': 3,
  'offline': 3,
  'lag': 2,
  'lagging': 2,
  'no internet': 5, 'wifi down': 5, 'network issue': 3,
  // Accounts & Access
  'login': 3,
  'password': 3,
  'portal': 3,
  'server': 3,
  'account': 3,
  'access': 3,
  'erp': 3, 'lms': 3, 'moodle': 3, 'canvas': 3, 'dashboard': 2, 'website': 2,
  'app': 2, 'email': 2, 'login failed': 4, 'cant login': 4, 'locked out': 4,
  // Hardware & Peripherals
  'printer': 3,
  'printing': 3,
  'scanner': 3,
  'mouse': 2,
  'keyboard': 2,
  'monitor': 3,
  'screen': 3,
  'projector': 3,
  'microphone': 2,
  'mic': 2,
  'camera': 2,
  'webcam': 2,
  'motherboard': 3, 'cpu': 3, 'ram': 2, 'hard drive': 3,
  // Software & General IT
  'software': 2, 'bug': 2, 'glitch': 2, 'error': 3, 'crash': 3, 'crashed': 3,
  'virus': 4,
  'malware': 4,
  'zoom': 2,
  'teams': 2,
  'meet': 2,
  'phishing': 4,
  'hacked': 4,
};

const Map<String, int> _electricalKeywords = {
  // Hazards
  'spark': 5,
  'sparking': 5,
  'shock': 5,
  'smoke': 5,
  'fire': 5,
  'burn': 4,
  'burning': 4,
  'short circuit': 5,
  'bare wire': 5,
  'open wire': 5,
  'smell wire': 4,
  'live wire': 5,
  'current': 4,
  // Power Delivery
  'electric': 4, 'electricity': 4, 'power': 3, 'voltage': 3, 'fluctuation': 3,
  'outage': 5,
  'blackout': 5,
  'power cut': 5,
  'no power': 5,
  'generator': 4,
  'inverter': 4,
  // Components
  'wire': 3, 'wiring': 3, 'switch': 3, 'socket': 3, 'plug': 2, 'switchboard': 3,
  'breaker': 4, 'mcb': 4, 'fuse': 4, 'trip': 3, 'tripped': 3,
  // Appliances
  'light': 3,
  'bulb': 2,
  'tubelight': 2,
  'dim': 2,
  'flicker': 2,
  'flickering': 2,
  'fan': 3, 'regulator': 2, 'heater': 3, 'geyser': 3, 'water heater': 4,
};

const Map<String, int> _plumbingKeywords = {
  // Water & Leaks
  'water': 3, 'leak': 4, 'leaking': 4, 'leakage': 4, 'drip': 3, 'dripping': 3,
  'burst': 5,
  'pipe burst': 5,
  'flood': 5,
  'flooding': 5,
  'puddle': 3,
  'no water': 5,
  // Drainage & Waste
  'drain': 3,
  'drainage': 3,
  'sewage': 5,
  'sewer': 5,
  'gutter': 4,
  'overflow': 4,
  'overflowing': 4,
  'clog': 4,
  'clogged': 4,
  'block': 4,
  'blocked': 4,
  'blockage': 4,
  'choke': 4, 'choked': 4, 'smell': 2, 'stink': 3, 'stinking': 3, 'foul': 3,
  // Fixtures
  'pipe': 4,
  'flush': 3,
  'toilet': 3,
  'commode': 3,
  'washroom': 3,
  'bathroom': 3,
  'sink': 3, 'basin': 3, 'shower': 3, 'jet': 3, 'tap': 3, 'faucet': 3,
  // Drinking Water / Water Quality
  'ro': 3, 'purifier': 3, 'drinking water': 4, 'cooler': 3, 'dispenser': 3,
  'dirty water': 4, 'muddy': 3, 'stagnant': 3,
};

const Map<String, int> _infraKeywords = {
  // Structural
  'wall': 3, 'ceiling': 3, 'floor': 3, 'roof': 3, 'crack': 4, 'cracked': 4,
  'broken': 3,
  'break': 3,
  'seepage': 4,
  'damp': 3,
  'dampness': 3,
  'paint': 1,
  'peeling': 2,
  'tile': 2, 'tiles': 2, 'plaster': 3, 'glass': 3, 'pane': 3,
  // Doors & Windows
  'door': 3,
  'window': 3,
  'lock': 4,
  'key': 3,
  'handle': 2,
  'hinge': 2,
  'latch': 2,
  'door broken': 4, 'stuck inside': 5,
  // Mobility
  'lift': 5,
  'elevator': 5,
  'stairs': 2,
  'staircase': 2,
  'lift stuck': 5,
  'lift not working': 5,
  // Furniture
  'bench': 2,
  'chair': 2,
  'table': 2,
  'desk': 2,
  'bed': 2,
  'cot': 2,
  'mattress': 2,
  'cupboard': 2,
  'almirah': 2,
  'wardrobe': 2,
  'furniture': 2,
  'carpenter': 3,
  'wood': 2,
  // HVAC & Environment
  'ac': 3, 'aircon': 3, 'cooling': 2, 'filter': 2, 'vent': 2, 'exhaust': 2,
  // Pests & Animals (Infra mostly handles pest control)
  'pest': 3,
  'termite': 3,
  'rat': 4,
  'rats': 4,
  'rodent': 4,
  'insect': 3,
  'mosquito': 3,
  'bedbug': 4,
  'bedbugs': 4,
  'cockroach': 3,
  'ants': 2,
  'lizard': 3,
  'mesh': 2,
  'net': 2,
};

const Map<String, int> _disciplinaryKeywords = {
  // Harassment & Bullying
  'ragging': 5,
  'harassment': 5,
  'harass': 5,
  'bully': 5,
  'bullying': 5,
  'tease': 4,
  'teasing': 4,
  'taunt': 4,
  'stalk': 5,
  'creep': 4,
  'abuse': 5,
  'abusive': 5,
  'slur': 5,
  'blackmail': 5, 'extort': 5, 'force': 4, 'forcing': 4,
  // Physical Violence & Actions
  'assault': 5,
  'threat': 5,
  'threaten': 5,
  'violence': 5,
  'fight': 5,
  'fighting': 5,
  'hit': 5, 'hitting': 5, 'attack': 5, 'attacking': 5, 'beat': 5, 'beating': 5,
  'slap': 4, 'punch': 5, 'kick': 4, 'kicking': 4, 'choke': 5, 'choking': 5,
  'throw': 4, 'throwing': 4, 'pelt': 4, 'pelting': 4, 'molest': 5, 'kidnap': 5,
  // Weapons & Projectiles
  'weapon': 5, 'knife': 5, 'blade': 5, 'gun': 5, 'shoot': 5, 'shooting': 5,
  'rock': 4,
  'rocks': 4,
  'stone': 4,
  'stones': 4,
  'stick': 4,
  'bat': 4,
  'rod': 5,
  // Harm & Injury
  'hurt': 4,
  'hurting': 4,
  'injure': 5,
  'injured': 5,
  'blood': 5,
  'bleed': 5,
  'bleeding': 5,
  'kill': 5, 'killing': 5, 'murder': 5,
  // Contraband & Rules
  'drug': 5,
  'drugs': 5,
  'weed': 5,
  'alcohol': 5,
  'drink': 4,
  'drunk': 5,
  'smoking': 4,
  'cigarette': 4,
  'steal': 5,
  'stole': 5,
  'theft': 5,
  'robbed': 5,
  'rule': 2,
  'violation': 3,
  // Disturbance
  'argument': 3,
  'shouting': 3,
  'noise': 3,
  'loud': 2,
  'disturb': 3,
  'curfew': 3,
  // Mental Health
  'suicide': 5,
  'depress': 4,
  'depression': 4,
  'mental': 4,
  'anxiety': 4,
  'stress': 4,
  'panic': 4,
};

const Map<String, int> _urgencyKeywords = {
  'urgent': 5,
  'urgently': 5,
  'immediately': 5,
  'emergency': 5,
  'asap': 5,
  'danger': 5,
  'dangerous': 5,
  'hazard': 5,
  'critical': 5,
  'severe': 5,
  'serious': 5,
  'fast': 3,
  'quick': 3,
  'quickly': 3,
  'now': 4,
  'today': 2,
  'shock': 5,
  'smoke': 5,
  'fire': 5,
  'burst': 5,
  'leak': 3,
  'overflow': 4,
  'stuck': 4,
  'trapped': 5,
  'bleeding': 5,
  'hurt': 5,
  'injury': 5,
  'accident': 5,
  'dead': 5,
  'snake': 5,
};
