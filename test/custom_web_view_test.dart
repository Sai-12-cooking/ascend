import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ascend_app/views/custom_web_view.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return MockPlatformWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return MockPlatformNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockPlatformWebViewWidget(params);
  }
}

class MockPlatformWebViewController extends PlatformWebViewController {
  MockPlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}
  
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  
  @override
  Future<void> setBackgroundColor(Color color) async {}
  
  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}
}

class MockPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MockPlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageStarted(void Function(String url) onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(void Function(String url) onPageFinished) async {}

  @override
  Future<void> setOnWebResourceError(void Function(WebResourceError error) onWebResourceError) async {}
}

class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('mock_webview'));
  }
}


void main() {
  setUpAll(() {
    WebViewPlatform.instance = MockWebViewPlatform();
  });

  testWidgets('CustomWebView renders correctly and displays title', (WidgetTester tester) async {
    const testUrl = 'https://example.com';
    const testTitle = 'Test Web View';

    await tester.pumpWidget(
      const MaterialApp(
        home: CustomWebView(
          url: testUrl,
          title: testTitle,
        ),
      ),
    );

    // Verify the title is displayed
    expect(find.text(testTitle), findsOneWidget);
    
    // Verify a WebViewWidget (or our mock) is in the tree
    expect(find.byType(WebViewWidget), findsOneWidget);
    
    // Verify AppBar refresh icon is present
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    
    // Verify CircularProgressIndicator is present initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
