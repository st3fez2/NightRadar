class DriveTimeEstimate {
  const DriveTimeEstimate({
    required this.minutes,
    required this.originCity,
    required this.destinationCity,
  });

  final int minutes;
  final String originCity;
  final String destinationCity;
}

DriveTimeEstimate? estimateDriveTime({
  required String? originCity,
  required String destinationCity,
}) {
  final origin = _normalizeCity(originCity);
  final destination = _normalizeCity(destinationCity);
  if (origin == null || destination == null) {
    return null;
  }

  if (origin == destination) {
    return DriveTimeEstimate(
      minutes: 18,
      originCity: originCity!.trim(),
      destinationCity: destinationCity.trim(),
    );
  }

  final pairKey = _pairKey(origin, destination);
  final mappedMinutes = _knownDriveMinutes[pairKey];
  if (mappedMinutes != null) {
    return DriveTimeEstimate(
      minutes: mappedMinutes,
      originCity: originCity!.trim(),
      destinationCity: destinationCity.trim(),
    );
  }

  final originCluster = _clusterFor(origin);
  final destinationCluster = _clusterFor(destination);
  if (originCluster != null && originCluster == destinationCluster) {
    return DriveTimeEstimate(
      minutes: 35,
      originCity: originCity!.trim(),
      destinationCity: destinationCity.trim(),
    );
  }

  if (originCluster != null && destinationCluster != null) {
    return DriveTimeEstimate(
      minutes: 85,
      originCity: originCity!.trim(),
      destinationCity: destinationCity.trim(),
    );
  }

  return DriveTimeEstimate(
    minutes: 75,
    originCity: originCity!.trim(),
    destinationCity: destinationCity.trim(),
  );
}

String _pairKey(String first, String second) {
  final ordered = [first, second]..sort();
  return '${ordered.first}|${ordered.last}';
}

String? _normalizeCity(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return _cityAliases[normalized] ?? normalized;
}

String? _clusterFor(String city) {
  for (final entry in _metroClusters.entries) {
    if (entry.value.contains(city)) {
      return entry.key;
    }
  }
  return null;
}

const _cityAliases = <String, String>{
  'milan': 'milano',
  'rome': 'roma',
  'turin': 'torino',
  'florence': 'firenze',
  'naples': 'napoli',
};

const _metroClusters = <String, Set<String>>{
  'milano': {
    'milano',
    'monza',
    'sesto san giovanni',
    'cologno monzese',
    'rho',
  },
  'roma': {
    'roma',
    'fiumicino',
    'ciampino',
  },
  'napoli': {
    'napoli',
    'pozzuoli',
    'salerno',
  },
};

const _knownDriveMinutes = <String, int>{
  'bergamo|milano': 55,
  'bologna|milano': 130,
  'brescia|milano': 80,
  'como|milano': 55,
  'firenze|milano': 185,
  'milano|torino': 95,
  'bologna|firenze': 75,
  'bologna|roma': 220,
  'firenze|roma': 170,
  'napoli|roma': 140,
};
