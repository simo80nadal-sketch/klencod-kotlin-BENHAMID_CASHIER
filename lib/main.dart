import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const CashierApp());
}

class CashierApp extends StatelessWidget {
  const CashierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BENHAMID CHOP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0b7a5a)),
        useMaterial3: true,
      ),
      home: const CashierHome(),
    );
  }
}

class CashierHome extends StatefulWidget {
  const CashierHome({super.key});

  @override
  State<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends State<CashierHome> {
  InAppWebViewController? controller;
  double progress = 0;
  bool loadError = false;

  Future<PermissionResponse> _handleWebPermission(
    InAppWebViewController controller,
    PermissionRequest request,
  ) async {
    final resources = request.resources;
    if (resources.contains(PermissionResourceType.CAMERA)) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        return PermissionResponse(
          resources: resources,
          action: PermissionResponseAction.GRANT,
        );
      }
      return PermissionResponse(
        resources: resources,
        action: PermissionResponseAction.DENY,
      );
    }
    return PermissionResponse(
      resources: resources,
      action: PermissionResponseAction.DENY,
    );
  }

  Future<bool> _onBack() async {
    if (controller != null && await controller!.canGoBack()) {
      await controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _onBack() && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialFile: 'assets/cashier.html',
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  supportZoom: true,
                  builtInZoomControls: false,
                  useShouldOverrideUrlLoading: true,
                  allowFileAccess: true,
                  allowContentAccess: true,
                  thirdPartyCookiesEnabled: true,
                  isInspectable: false,
                ),
                onWebViewCreated: (webController) {
                  controller = webController;
                },
                onProgressChanged: (webController, value) {
                  if (mounted) setState(() => progress = value / 100);
                },
                onPermissionRequest: _handleWebPermission,
                onLoadStop: (webController, url) {
                  if (mounted) setState(() => loadError = false);
                },
                onReceivedError: (webController, request, error) {
                  if (request.isForMainFrame == true && mounted) {
                    setState(() => loadError = true);
                  }
                },
              ),
              if (progress < 1)
                LinearProgressIndicator(value: progress),
              if (loadError)
                Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('تعذّر تحميل صفحة الكاشير'),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () {
                              setState(() => loadError = false);
                              controller?.reload();
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}