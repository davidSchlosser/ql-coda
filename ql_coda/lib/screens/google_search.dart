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
  late final WebViewController _controller;
  static String initialUrl = '';
  late final String defaultUrl;

  @override
  void initState() {
    super.initState();
    defaultUrl = 'https://google.com/search?q=${widget.artists}~${widget.title}';
    _controller = WebViewController()
      ..loadRequest(Uri.parse(initialUrl.isNotEmpty ? initialUrl : defaultUrl))
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        // if there's a current url, save it to be used when by default when we come back
        String? aUrl = await _controller.currentUrl();
        initialUrl = aUrl ?? '';
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Googling..'),
          actions: [
            NavigationControls(controller: _controller),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.personRunning),
              onPressed: () {
                initialUrl = Uri.encodeFull(defaultUrl);
                _logger.d('initial url: $initialUrl');
                _controller.loadRequest(Uri.parse(initialUrl));
              },
            )
          ],
        ),

        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls({required this.controller, super.key});

  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            if (await controller.canGoBack()) {
              await controller.goBack();
            } else {
              messenger.showSnackBar(
                const SnackBar(content: Text('No back history item')),
              );
              return;
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            if (await controller.canGoForward()) {
              await controller.goForward();
            } else {
              messenger.showSnackBar(
                const SnackBar(content: Text('No forward history item')),
              );
              return;
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: () {
            controller.reload();
          },
        ),
      ],
    );
  }
}
