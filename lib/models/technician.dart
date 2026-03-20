enum TechnicianSkill {
  infrastructure,
  plumbing,
  electrical,
  it,
  disciplinary,
  general,
}

class Technician {
  final String id;
  final String name;
  final Set<TechnicianSkill> skills;
  final int maxActive;

  const Technician({
    required this.id,
    required this.name,
    required this.skills,
    this.maxActive = 3,
  });
}

