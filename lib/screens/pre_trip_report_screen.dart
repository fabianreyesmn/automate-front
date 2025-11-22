import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PreTripReportScreen extends StatefulWidget {
  const PreTripReportScreen({super.key});

  @override
  State<PreTripReportScreen> createState() => _PreTripReportScreenState();
}

class _PreTripReportScreenState extends State<PreTripReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _destination;
  TimeOfDay? _eventTime;
  bool _loading = false;
  bool _smartLoading = false;
  Map<String, dynamic>? _report;
  String? _smartSummary;

  void _generateReport() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _loading = true;
        _report = null;
        _smartSummary = null;
      });
      // Simulate fetching report data
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() {
          _report = {
            'travelTime': 25, // in minutes
            'weather': 'Light rain expected',
            'traffic': 'Moderate',
            'suggestedDeparture': '8:30 AM',
          };
          _loading = false;
        });
      });
    }
  }

  void _generateSmartSummary() {
    if (_report == null) return;
    setState(() => _smartLoading = true);
    // Simulate Gemini API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _smartSummary = "Leave by 8:30 AM to arrive on time for your 9:00 AM meeting at $_destination. Expect light rain, so grab an umbrella. Traffic is moderate.";
        _smartLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Text('Pre-Trip Report', style: theme.textTheme.headlineSmall),
        const Text('Plan your trip with weather and traffic data.'),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Card(
            elevation: 1,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Destination', hintText: 'e.g., Downtown Office', border: OutlineInputBorder()),
                    onSaved: (value) => _destination = value,
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter a destination' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Arrival Time', border: OutlineInputBorder()),
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (time != null) setState(() => _eventTime = time);
                    },
                    controller: TextEditingController(text: _eventTime?.format(context)),
                     validator: (value) => (_eventTime == null) ? 'Please select a time' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      onPressed: _loading ? null : _generateReport,
                      child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate Report'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Analyzing routes and weather...')),
          ),
        if (_report != null)
          Card(
            elevation: 1,
            shadowColor: Colors.black12,
            margin: const EdgeInsets.only(top: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Trip to $_destination', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _ReportInfoTile(icon: LucideIcons.clock, title: 'Depart at:', value: _report!['suggestedDeparture']),
                  _ReportInfoTile(icon: LucideIcons.sun, title: 'Travel Time:', value: '~${_report!['travelTime']} min'),
                  _ReportInfoTile(icon: LucideIcons.cloudRain, title: 'Weather:', value: _report!['weather']),
                  _ReportInfoTile(icon: LucideIcons.car, title: 'Traffic:', value: _report!['traffic']),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _smartLoading ? const SizedBox.shrink() : const Icon(LucideIcons.sparkles, size: 16),
                      label: _smartLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate Smart Summary'),
                      onPressed: _smartLoading ? null : _generateSmartSummary,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (_smartSummary != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withOpacity(0.2)),
                        ),
                        child: Text(_smartSummary!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.purple[900])),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _ReportInfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
