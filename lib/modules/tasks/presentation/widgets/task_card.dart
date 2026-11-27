import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../domain/task.dart';

Color taskStatusTone(TaskStatus status) => switch (status) {
  TaskStatus.completed => DesignColor.green,
  TaskStatus.submitted => DesignColor.amber,
  TaskStatus.returned => DesignColor.rose,
  TaskStatus.inProgress => DesignColor.blue,
  TaskStatus.notStarted => DesignColor.purple,
};

Color taskStatusColor(String status) => switch (status) {
  'Completed' => DesignColor.green,
  'Submitted' => DesignColor.amber,
  'Returned' => DesignColor.rose,
  'In progress' => DesignColor.blue,
  _ => DesignColor.purple,
};
