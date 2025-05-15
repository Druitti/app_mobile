import 'package:geolocator/geolocator.dart';
import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/common/utils/exceptions.dart';
import 'package:app_mobile/common/utils/failures.dart';
import 'package:dartz/dartz.dart'; // Adicione dartz: ^0.10.1 no pubspec.yaml

class LocationService {
  Future<Either<Failure, Position>> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Testa se os serviços de localização estão ativos.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Serviços de localização não estão ativos, não é possível continuar
      return Left(
          PermissionFailure("Serviços de localização estão desativados."));
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissões negadas, próximo passo é informar o usuário.
        return Left(PermissionFailure(locationPermissionDenied));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissões negadas permanentemente, lidar com isso.
      return Left(PermissionFailure(
          "Permissão de localização negada permanentemente. Abra as configurações do app."));
    }

    // Quando temos permissão, obtemos a localização atual.
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return Right(position);
    } catch (e) {
      // Tratar outros erros potenciais
      return Left(UnknownFailure(
          "Não foi possível obter a localização: ${e.toString()}"));
    }
  }

  // Opcional: Stream para atualizações de localização
  Stream<Either<Failure, Position>> getLocationStream() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualiza a cada 10 metros
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => Right<Failure, Position>(position))
        .handleError((error) {
      // Aqui você pode mapear diferentes tipos de erro para Failures específicas
      print("Erro no stream de localização: $error");
      if (error is PermissionDeniedException) {
        return Left<Failure, Position>(
            PermissionFailure(locationPermissionDenied));
      }
      return Left<Failure, Position>(
          UnknownFailure("Erro no stream de localização: ${error.toString()}"));
    });
  }
}
