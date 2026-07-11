import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class GoogleSignInWebView extends StatefulWidget {
  final String baseUrl;

  const GoogleSignInWebView({super.key, required this.baseUrl});

  @override
  State<GoogleSignInWebView> createState() => _GoogleSignInWebViewState();
}

class _GoogleSignInWebViewState extends State<GoogleSignInWebView> {
  double _progress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Clear cookies before initiating Google login to allow selecting a different account
    CookieManager.instance().deleteAllCookies();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);
    final bgColor = const Color(0xFF0F0F1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: const Text(
          'Sign In with Google',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF5A36),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri("${widget.baseUrl}/login"),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              // Use standard mobile Chrome userAgent to bypass "disallowed_useragent" 403 error on Google Login
              userAgent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
              useShouldOverrideUrlLoading: true,
            ),
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
                if (progress == 100) {
                  _isLoading = false;
                }
              });
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url;
              if (url != null) {
                final urlString = url.toString();
                // If Google redirects to localhost:3000, rewrite it to our actual baseUrl (e.g. local IP)
                if (urlString.contains('http://localhost:3000')) {
                  final rewrittenUrl = urlString.replaceFirst('http://localhost:3000', widget.baseUrl);
                  await controller.loadUrl(
                    urlRequest: URLRequest(
                      url: WebUri(rewrittenUrl),
                      headers: navigationAction.request.headers,
                      body: navigationAction.request.body,
                      method: navigationAction.request.method,
                    ),
                  );
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStart: (controller, url) async {
              setState(() {
                _isLoading = true;
              });

              if (url != null) {
                final urlString = url.toString();
                // Fallback check on load start to rewrite localhost redirect URIs
                if (urlString.contains('http://localhost:3000')) {
                  final rewrittenUrl = urlString.replaceFirst('http://localhost:3000', widget.baseUrl);
                  await controller.loadUrl(
                    urlRequest: URLRequest(
                      url: WebUri(rewrittenUrl),
                    ),
                  );
                }
              }
            },
            onLoadStop: (controller, url) async {
              final navigator = Navigator.of(context);
              setState(() {
                _isLoading = false;
              });

              if (url != null) {
                // 1. NextAuth signin flow page auto-submission helper
                if (url.path.contains('/login')) {
                  // Website's login page renders the "Sign In with Google" button
                  // Let's automatically click it to trigger the Google OAuth sign-in flow
                  await controller.evaluateJavascript(source: """
                    (function() {
                      const buttons = Array.from(document.querySelectorAll('button'));
                      const googleBtn = buttons.find(btn => btn.textContent.includes('Sign In with Google') || btn.innerHTML.includes('Sign In with Google'));
                      if (googleBtn) {
                        googleBtn.click();
                      }
                    })();
                  """);
                } else if (url.path.contains('/api/auth/signin/google')) {
                  // NextAuth renders a page with a "Sign in with Google" form/button on GET request
                  // Let's automatically submit it to redirect user directly to Google account selection
                  await controller.evaluateJavascript(source: """
                    (function() {
                      const form = document.querySelector('form');
                      if (form) {
                        form.submit();
                      }
                    })();
                  """);
                }

                // 2. Scan cookies to check if session token is received
                final cookieManager = CookieManager.instance();
                final cookies = await cookieManager.getCookies(url: url);
                
                String? sessionTokenCookie;
                for (var cookie in cookies) {
                  if (cookie.name == 'next-auth.session-token' || cookie.name == '__Secure-next-auth.session-token') {
                    sessionTokenCookie = '${cookie.name}=${cookie.value}';
                    break;
                  }
                }

                if (sessionTokenCookie != null) {
                  if (mounted) {
                    navigator.pop(sessionTokenCookie);
                  }
                }
              }
            },
          ),
          if (_progress < 1.0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: surfaceColor,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
}
