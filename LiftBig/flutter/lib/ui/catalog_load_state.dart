import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../theme.dart';

/// Loads [LiftBigCatalog] once and shows content, an error, or a retry action.
class CatalogLoadScope extends StatefulWidget {
  const CatalogLoadScope({super.key, required this.builder});

  final Widget Function(BuildContext context, LiftBigCatalog catalog) builder;

  @override
  State<CatalogLoadScope> createState() => _CatalogLoadScopeState();
}

class _CatalogLoadScopeState extends State<CatalogLoadScope> {
  LiftBigCatalog? _catalog;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await LiftBigCatalog.load();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Could not load the LiftBig catalog.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style:  TextStyle(color: context.liftBig.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    final catalog = _catalog;
    if (catalog == null) {
      return const Center(child: Text('Catalog is empty.'));
    }
    return widget.builder(context, catalog);
  }
}
