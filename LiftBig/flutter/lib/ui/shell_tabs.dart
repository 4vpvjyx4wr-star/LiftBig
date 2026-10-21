/// Bottom-bar destinations, left to right, matching the Vue app shell.
enum ShellTab {
  home,
  progress,
  lift,
  plans,
  library,
}

extension ShellTabCopy on ShellTab {
  String get label => switch (this) {
    ShellTab.home => 'Home',
    ShellTab.progress => 'Progress',
    ShellTab.lift => 'LIFT',
    ShellTab.plans => 'Plans',
    ShellTab.library => 'Library',
  };

  /// What the control opens. LIFT is today's log, not the calendar.
  String get opens => switch (this) {
    ShellTab.home => 'Calendar',
    ShellTab.progress => 'Progress',
    ShellTab.lift => 'Today',
    ShellTab.plans => 'Plans',
    ShellTab.library => 'Lift library',
  };
}
