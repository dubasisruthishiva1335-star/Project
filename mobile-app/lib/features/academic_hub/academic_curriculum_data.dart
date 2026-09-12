// lib/features/academic_hub/academic_curriculum_data.dart
// Academic curriculum metadata for Engineering branches and semesters

class AcademicCurriculumData {
  static List<Map<String, dynamic>> getSubjects(String branch, int semester) {
    final b = branch.toUpperCase().trim();
    final s = semester;

    if (s == 1) {
      if (b == 'ECE') {
        return [
          {
            'id': 'ece_sem1_ec101',
            'code': 'EC101',
            'name': 'Basic Electronics Engineering',
            'branch': 'ECE',
            'semester': 1,
            'contents': [],
          },
          {
            'id': 'ece_sem1_ma101',
            'code': 'MA101',
            'name': 'Engineering Mathematics I (Linear Algebra & Calculus)',
            'branch': 'ECE',
            'semester': 1,
            'contents': [],
          },
          {
            'id': 'ece_sem1_ph101',
            'code': 'PH101',
            'name': 'Engineering Physics & Quantum Mechanics',
            'branch': 'ECE',
            'semester': 1,
            'contents': [],
          },
          {
            'id': 'ece_sem1_ee101',
            'code': 'EE101',
            'name': 'Basic Electrical Engineering',
            'branch': 'ECE',
            'semester': 1,
            'contents': [],
          },
          {
            'id': 'ece_sem1_ec102l',
            'code': 'EC102L',
            'name': 'Basic Electronics & Devices Laboratory',
            'branch': 'ECE',
            'semester': 1,
            'contents': [],
          },
        ];
      }

      if (b == 'CSE' || b == 'AI_ML') {
        return [
          {
            'id': 'cse_sem1_cs101',
            'code': 'CS101',
            'name': 'Problem Solving & Programming in C/Python',
            'branch': b,
            'semester': 1,
            'contents': [],
          },
          {
            'id': 'cse_sem1_ma101',
            'code': 'MA101',
            'name': 'Engineering Mathematics I (Linear Algebra & Calculus)',
            'branch': b,
            'semester': 1,
            'contents': [],
          },
          {
            'id': 'cse_sem1_ec101',
            'code': 'EC101',
            'name': 'Digital Electronics & Logic Design',
            'branch': b,
            'semester': 1,
            'contents': [],
          },
        ];
      }
    }

    // Default Schema for any other Branch & Semester
    return [
      {
        'id': '${b.toLowerCase()}_sem${s}_core1',
        'code': '$b${s}01',
        'name': '$b Core Engineering Theory $s',
        'branch': b,
        'semester': s,
        'contents': [],
      },
      {
        'id': '${b.toLowerCase()}_sem${s}_core2',
        'code': '$b${s}02',
        'name': 'Applied $b Systems & Computing ($s)',
        'branch': b,
        'semester': s,
        'contents': [],
      },
      {
        'id': '${b.toLowerCase()}_sem${s}_lab',
        'code': '$b${s}03L',
        'name': '$b Laboratory Practicum',
        'branch': b,
        'semester': s,
        'contents': [],
      },
    ];
  }
}
