part of 'presence_data_api_service.dart';




class _PresenceDataApiService implements PresenceDataApiService {

  _PresenceDataApiService(this._dio, {this.baseUrl}) {
    baseUrl ??= 'https://newsapi.org/v2';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<HttpResponse<List<DataEmpoyee>>> getPresenceData({String? apiKey, String? country, String? category})  async {
    const _extra = <String,dynamic>{};
    final queryParameters = <String,dynamic>{
      r'apiKey': apiKey,
      r'country': country,
      r'category': category
    };

    queryParameters.removeWhere((k,v) => v == null);
    final _headers = <String,dynamic>{};
    final _data = <String,dynamic>{};
    // final _result = await _dio.fetch<Map<String,dynamic>>(
    //   _setStreamType<T>(RequestOptions requestOptions)<HttpResponse<List<DataEmpoyee>>>(
    //     Options(method: 'GET',headers: _headers,extra: _extra)
    //         .compose(_dio.options, 'top-headlines',
    //             queryParameters: queryParameters,data: _data)
    //         .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));

      // )
    // )
    throw UnimplementedError();
  }

}

RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
  if (T != dynamic &&
    !(requestOptions.responseType == ResponseType.bytes ||
    requestOptions.responseType == ResponseType.stream)) {
    if (T == String) {
      requestOptions.responseType = ResponseType.plain;
    } else {
      requestOptions.responseType = ResponseType.json;
    }
  }
return requestOptions;
}