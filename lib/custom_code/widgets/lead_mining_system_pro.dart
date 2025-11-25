// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class LeadMiningSystemPRO extends StatefulWidget {
  const LeadMiningSystemPRO({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<LeadMiningSystemPRO> createState() => _LeadMiningSystemPROState();
}

class _LeadMiningSystemPROState extends State<LeadMiningSystemPRO> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Center(
        child: Text(
          'Lead Mining System PRO',
          style: FlutterFlowTheme.of(context).headlineMedium,
        ),
      ),
    );
  }
}
