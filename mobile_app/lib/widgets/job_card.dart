import 'package:flutter/material.dart';

class JobCard extends StatelessWidget {
  final dynamic job;

  const JobCard({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          job['job_title'] ?? 'Bilinmeyen Pozisyon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(job['company'] ?? 'Bilinmeyen Şirket'),
        trailing: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            job['match_percentage'] ?? '%0',
            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}