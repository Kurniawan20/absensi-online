import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebViewApp extends StatefulWidget {

  var id;
  WebViewApp({Key? key, required this.id}) : super(key: key);

  @override
  State<WebViewApp> createState() => WebViewAppState();
}
class WebViewAppState extends State<WebViewApp> {

  @override
  void initState() {
    super.initState();
  }

  bool isLoading = true;
  late WebViewController _webViewController;
  double webProgress = 0;



  // @override
  // void dispose() {
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {

    var id = widget.id;

    return Scaffold(
        appBar: AppBar(
          // title: const Text('Home',style: TextStyle(fontSize: 18),),
          title: Text("Pengumuman"),
          backgroundColor: Color.fromRGBO(1, 101, 65, 1),
        ),
        body:
            // WillPopScope(
            //   onWillPop: () async {
            //     if(await _webViewController.canGoBack()) {
            //       _webViewController.goBack();
            //       return false;
            //     }else {
            //       return true;
            //     }
            //   },
            //   child:
              Column(
                children: [
                  // webProgress < 1 ? SizedBox(
                  //   height: 5,
                  //   child: LinearProgressIndicator(
                  //     value: webProgress,
                  //     color: Colors.blue,
                  //     backgroundColor: Colors.black87,
                  //   ),
                  // ) : SizedBox(),
                  Expanded(
                      child: WebViewWidget(controller: WebViewController()
                        ..setJavaScriptMode(JavaScriptMode.unrestricted)
                        ..setBackgroundColor(const Color(0x00000000))
                        ..setNavigationDelegate(
                            NavigationDelegate(
                              onProgress: (int progress) {
                                // if (mounted) {
                                //   setState(() {
                                //     this.webProgress = progress / 100;
                                //   });
                                // }
                              },
                              onPageStarted: (String url) { },
                              onPageFinished: (finish) {
                                // if (mounted) {
                                //   setState(() {
                                //     isLoading = false;
                                //     print("aaadddttt");
                                //   });
                                // }
                              },
                              onWebResourceError: (WebResourceError error) {},
                              onNavigationRequest: (NavigationRequest request) {
                                if (request.url.startsWith('https://www.youtube.com/')) {
                                  return NavigationDecision.prevent;
                                }
                                return NavigationDecision.navigate;
                              },
                            )
                        )
                        ..loadRequest(
                            method: LoadRequestMethod.get,
                            Uri.parse('https://promo.bankaceh.co.id/showpromo/39')
                            // Uri.parse('https://abs.basitd.net/api-absensi-mobile/public/api/showblog/${id}')
                        )
                      )
                  )
                ],
              // )
            )
        // Stack(
        //   children: [
        //     WebViewWidget(controller: WebViewController()
        //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
        //   ..setBackgroundColor(const Color(0x00000000))
        //   ..setNavigationDelegate(
        //       NavigationDelegate(
        //         onProgress: (int progress) {
        //           // Update loading bar.
        //         },
        //         onPageStarted: (String url) { },
        //         onPageFinished: (finish) {
        //           if (mounted) {
        //             setState(() {
        //               isLoading = false;
        //               print("aaadddttt");
        //             });
        //           }
        //         },
        //         onWebResourceError: (WebResourceError error) {},
        //         onNavigationRequest: (NavigationRequest request) {
        //           if (request.url.startsWith('https://www.youtube.com/')) {
        //             return NavigationDecision.prevent;
        //           }
        //           return NavigationDecision.navigate;
        //         },
        //       )
        //   )
        //   ..loadRequest(Uri.parse('http://10.140.155.94/mobile-auth-api/public/api/showblog/${id}'))
        //     ),
        //     isLoading ? Center( child: CircularProgressIndicator()) : Stack()
        //   ],
        // )
    );
  }
}
