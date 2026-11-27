class SchoolItem {
  const SchoolItem(
    this.id,
    this.type,
    this.title,
    this.child,
    this.when,
    this.group, {
    this.subject = '',
    this.note = '',
    this.done = false,
  });
  final String id, type, title, child, when, group, subject, note;
  final bool done;
  SchoolItem toggle() => SchoolItem(
    id,
    type,
    title,
    child,
    when,
    group,
    subject: subject,
    note: note,
    done: !done,
  );
}

const schoolExamples = [
  SchoolItem(
    '1',
    'hw',
    'Draw the water cycle',
    'Tobi',
    'school.yesterday',
    'od',
    subject: 'school.science',
  ),
  SchoolItem(
    '2',
    'hw',
    'Spelling list — 20 words',
    'Ada',
    'common.today',
    'wk',
    subject: 'school.english',
    note: 'school.redo_note',
  ),
  SchoolItem(
    '3',
    'hw',
    'Read chapter 3 and write a summary',
    'Ada',
    'school.nov27',
    'wk',
    subject: 'school.english',
  ),
  SchoolItem(
    '4',
    'form',
    'Excursion consent form',
    'Tobi',
    'school.nov27',
    'wk',
  ),
  SchoolItem('5', 'pta', 'PTA meeting', '', 'school.nov28', 'wk'),
  SchoolItem(
    '6',
    'buy',
    'Cardboard and glue for the craft project',
    'Ada',
    'school.nov29',
    'wk',
  ),
  SchoolItem(
    '7',
    'test',
    'Maths test — chapters 4 and 5',
    'Tobi',
    'school.nov30',
    'wk',
    subject: 'school.maths',
  ),
  SchoolItem(
    '8',
    'event',
    'Inter-house sports — wear house colour',
    'Ada',
    'school.dec4',
    'later',
  ),
  SchoolItem('9', 'fees', 'Second term fees', '', 'school.dec7', 'later'),
];
