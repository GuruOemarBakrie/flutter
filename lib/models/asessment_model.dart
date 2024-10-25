class Assessment {
  final int id;
  final String namaAsesmen;
  final String? tanggalUjian;
  final String? waktuMulai;
  final int alokasiWaktu;
  final String? statusKehadiran;
  final List<Question> questions;

  Assessment({
    required this.id,
    required this.namaAsesmen,
    this.tanggalUjian,
    this.waktuMulai,
    required this.alokasiWaktu,
    this.statusKehadiran,
    required this.questions,
  });

  factory Assessment.fromJson(
      Map<String, dynamic> assessmentData, List<dynamic> soalData) {
    // Handle alokasi_waktu conversion
    int parseAlokasiWaktu(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Assessment(
      id: assessmentData['id'] ?? 0,
      namaAsesmen: assessmentData['namaasesmen'] ?? '',
      tanggalUjian: assessmentData['tanggal_ujian'],
      waktuMulai: assessmentData['waktu_mulai'],
      alokasiWaktu: parseAlokasiWaktu(assessmentData['alokasi_waktu']),
      statusKehadiran: assessmentData['status_kehadiran'],
      questions: soalData.map((q) => Question.fromJson(q)).toList(),
    );
  }
}

class Question {
  final int id;
  final String steamSoal;
  final String? bahanBacaan;
  final String jenisPg;
  final List<Choice> choices;

  Question({
    required this.id,
    required this.steamSoal,
    this.bahanBacaan,
    required this.jenisPg,
    required this.choices,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<Choice> parseChoices(dynamic pilihanpg) {
      if (pilihanpg is List) {
        return pilihanpg.map((c) => Choice.fromJson(c)).toList();
      } else if (pilihanpg is Map) {
        return pilihanpg.values.map((c) => Choice.fromJson(c)).toList();
      }
      return [];
    }

    return Question(
      id: json['id'] ?? 0,
      steamSoal: json['steamsoal'] ?? '',
      bahanBacaan: json['bahanbacaan'],
      jenisPg: json['jenispg'] ?? 'Pilihan Ganda',
      choices: parseChoices(json['pilihanpg']),
    );
  }
}

class Choice {
  final int id;
  final String text;

  Choice({
    required this.id,
    required this.text,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
    );
  }
}
