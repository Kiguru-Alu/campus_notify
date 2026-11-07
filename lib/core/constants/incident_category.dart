/// Water and electricity are separate categories rather than "utilities":
/// they are frequent, affect whole blocks at once, and go to different teams.
enum IncidentCategory {
  facilities('facilities', 'Facilities', 'Doors, windows, furniture, fittings'),
  water('water', 'Water', 'Supply cuts, leaks, blocked drains'),
  electricity('electricity', 'Electricity', 'Outages, faulty sockets, lighting'),
  sanitation('sanitation', 'Sanitation', 'Waste, cleaning, washrooms'),
  safety('safety', 'Safety', 'Hazards, security, damaged access control'),
  network('network', 'Network', 'Wi-Fi and connectivity problems');

  const IncidentCategory(this.id, this.label, this.hint);

  final String id;
  final String label;
  final String hint;

  static IncidentCategory fromId(String? id) {
    return IncidentCategory.values.firstWhere(
      (category) => category.id == id,
      orElse: () => IncidentCategory.facilities,
    );
  }
}
