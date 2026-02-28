import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewSlider extends StatelessWidget {
  final String id;
  const WebViewSlider({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // title: const Text('Home',style: TextStyle(fontSize: 18),),
          title: Text("News"),
          backgroundColor: Color.fromRGBO(1, 101, 65, 1),
        ),
        body: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setBackgroundColor(const Color(0x00000000))
              ..setNavigationDelegate(NavigationDelegate(
                onProgress: (int progress) {
                  // Update loading bar.
                },
                onPageStarted: (String url) {},
                onPageFinished: (String url) {},
                onWebResourceError: (WebResourceError error) {},
                onNavigationRequest: (NavigationRequest request) {
                  if (request.url.startsWith('https://www.youtube.com/')) {
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ))
              ..loadRequest(
                  Uri.parse('https://promo.bankaceh.co.id/showpromo/$id')))
        // Expanded(
        //   child: InAppWebView(
        //   initialUrlRequest: URLRequest(url: Uri.parse("https://promo.bankaceh.co.id/showpromo/23")),
        //   // initialHeaders: {},
        //   initialOptions: InAppWebViewGroupOptions(
        //     crossPlatform: InAppWebViewOptions(
        //       // debuggingEnabled: true,
        //     ),
        //   ),
        //   // onWebViewCreated:
        //   //     (InAppWebViewController controller) {
        //   //   webView = controller;
        //   //   print("onWebViewCreated");
        //   //   webView.loadData(
        //   //       data: _htmlForCardsList[0]);
        //   // }
        //   ),
        // // InAppWebView(initialUrlRequest: URLRequest(url: Uri.parse("https://promo.bankaceh.co.id/showpromo/23")),)
        // // WebViewWidget(controller: controller,),
        // // body:WebViewWidget(
        // //   initialUrl: 'https://flutter.dev',
        // // ),
        // )
        );
  }
}
