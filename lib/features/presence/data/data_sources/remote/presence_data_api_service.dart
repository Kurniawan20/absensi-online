import 'package:dio/dio.dart';
import 'package:monitoring_project/core/constants/constants.dart';
import 'package:monitoring_project/features/presence/data/models/DataEmployee.dart';
import 'package:retrofit/http.dart';
import 'package:retrofit/retrofit.dart';
part 'presence_data_api_service.g.dart';

@RestApi(baseUrl:baseUrlPresence)
abstract class PresenceDataApiService {
  factory PresenceDataApiService (Dio dio) = _PresenceDataApiService;

  @GET('/top-headlines')
  Future<HttpResponse<List<DataEmpoyee>>> getPresenceData({
    @Query("apiKey") String ? apiKey,
    @Query("country") String ? country,
    @Query("category") String ? category,
  });
}