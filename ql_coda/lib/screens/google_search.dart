import 'dart:async';

import 'package:coda/logger.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logger/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

Logger _logger = getLogger('GoogleSearch', Level.debug);

class GoogleSearch extends StatefulWidget {
  final String artists, title;

  const GoogleSearch({super.key, required this.artists, required this.title});

  @override
  GoogleSearchState createState() => GoogleSearchState();
}

/* defaults to again displaying the last url used, or else to a google search of artist & title
 */
class GoogleSearchState extends State<GoogleSearch> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();
  static String initialUrl = '';

  WebViewController webViewController = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);

  @override
  Widget build(BuildContext context) {
    final String defaultUrl = 'https://google.com/search?q=${widget.artists}~${widget.title}';
    String url = initialUrl.isNotEmpty ?
      initialUrl :
      Uri.encodeFull(defaultUrl);

    _logger.d('url: $url');

    return WillPopScope(
      onWillPop: () async {
        // if there's a current url, save it to be used when by default when we come back
        String? aUrl = await webViewController.currentUrl();
        initialUrl = aUrl ?? '';
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Googling..'),
          actions: [
            NavigationControls(_controller.future),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.personRunning),
              onPressed: () {
                initialUrl = Uri.encodeFull(defaultUrl);
                _logger.d('initial url: $initialUrl');
                webViewController.loadRequest(Uri.parse(initialUrl));
              },
            )
          ],
        ),
       body: WebViewWidget(controller: webViewController),
       /* body: WebView(
          initialUrl: url,
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController _webViewController) {
            webViewController = _webViewController;
            _controller.complete(webViewController);
          },
        ),*/
      ),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture, {super.key});

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController? controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady
                  ? null
                  : () => navigate(context, controller!, goBack: true),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady
                  ? null
                  : () => navigate(context, controller!, goBack: false),
            ),
          ],
        );
      },
    );
  }

  navigate(BuildContext context, WebViewController controller,
      {bool goBack = false}) async {
    bool canNavigate =
        goBack ? await controller.canGoBack() : await controller.canGoForward();
    if (canNavigate) {
      goBack ? controller.goBack() : controller.goForward();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("No ${goBack ? 'back' : 'forward'} history item")),
      );
    }
  }
}
