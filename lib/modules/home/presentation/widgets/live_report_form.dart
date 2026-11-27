part of '../home_screen.dart';

void _openReportForm(
  BuildContext context,
  LiveHomeActions actions,
  String id,
  String date,
) {
  final routine = actions.routine(id);
  designSheet<void>(
    context,
    title: context.tr('home.log_todays_report'),
    builder: (context) => FutureBuilder(
      future: routine,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return DesignLabel(_dashboardError(context, snapshot.error!));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _LiveReportForm(
          fields: dashboardRows(snapshot.data!['fields']),
          save: (answers) => actions.submitReport(id, date, answers),
        );
      },
    ),
  );
}

class _LiveReportForm extends StatefulWidget {
  const _LiveReportForm({required this.fields, required this.save});

  final List<DashboardJson> fields;
  final Future<bool> Function(Map<String, Object>) save;

  @override
  State<_LiveReportForm> createState() => _LiveReportFormState();
}

class _LiveReportFormState extends State<_LiveReportForm> {
  final _form = GlobalKey<FormState>();
  final _answers = <String, Object>{};
  bool _saving = false;
  Object? _error;

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.save(Map.unmodifiable(_answers));
      if (mounted && saved) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.fields.where((field) => field['id'] is String);
    if (fields.isEmpty) {
      return DesignLabel(context.tr('network.errors.invalidResponse'));
    }
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          for (final field in fields) _field(field),
          if (_error case final error?)
            DesignLabel(_dashboardError(context, error)),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Text(context.tr('tasks.submit')),
          ),
        ],
      ),
    );
  }

  Widget _field(DashboardJson field) {
    final id = field['id'] as String;
    final type = field['field_type'];
    final required = field['required'] == true;
    final decoration = InputDecoration(
      labelText: dashboardText(field['label']),
    );
    final format = NumberFormat.decimalPattern(context.locale.toString());

    String? requiredError(String? value) =>
        required && (value == null || value.trim().isEmpty)
        ? context.tr('home.live_report_required')
        : null;

    if (type == 'choice' || type == 'rating') {
      final options = type == 'rating'
          ? List.generate(5, (index) => '${index + 1}')
          : (field['options'] as List? ?? const [])
                .whereType<String>()
                .toList();
      return DropdownButtonFormField<String>(
        decoration: decoration,
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: _saving ? null : (_) {},
        validator: requiredError,
        onSaved: (value) {
          if (value != null) {
            _answers[id] = type == 'rating' ? int.parse(value) : value;
          }
        },
      );
    }

    return TextFormField(
      enabled: !_saving,
      decoration: decoration,
      maxLines: type == 'long' ? 3 : 1,
      keyboardType: type == 'number'
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      validator: (value) =>
          requiredError(value) ??
          (type == 'number' &&
                  (value?.trim().isNotEmpty ?? false) &&
                  format.tryParse(value!) == null
              ? context.tr('home.live_report_number')
              : null),
      onSaved: (raw) {
        final value = raw?.trim() ?? '';
        if (value.isEmpty) {
          _answers.remove(id);
        } else {
          _answers[id] = type == 'number' ? format.parse(value) : value;
        }
      },
    );
  }
}
