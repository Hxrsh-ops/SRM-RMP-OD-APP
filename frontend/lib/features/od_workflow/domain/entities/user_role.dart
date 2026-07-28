enum UserRole {
  student,
  facultyAdvisor,
  coordinator;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.facultyAdvisor:
        return 'Faculty Advisor';
      case UserRole.coordinator:
        return 'Coordinator';
    }
  }
}
