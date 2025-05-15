import 'package:image_picker/image_picker.dart';
import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/common/utils/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:permission_handler/permission_handler.dart'; // Adicione permission_handler: ^11.0.0 no pubspec.yaml

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<Either<Failure, XFile>> takePicture() async {
    // 1. Verificar permissão da câmera
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isDenied) {
        return Left(PermissionFailure(cameraPermissionDenied));
      }
    }
    if (status.isPermanentlyDenied) {
       return Left(PermissionFailure(
          "Permissão da câmera negada permanentemente. Abra as configurações do app."));
    }

    // 2. Tentar tirar a foto
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        return Right(photo);
      } else {
        // Usuário cancelou a captura
        return Left(UnknownFailure("Captura de foto cancelada pelo usuário."));
      }
    } catch (e) {
      print("Erro ao tirar foto: $e");
      return Left(UnknownFailure("Erro ao acessar a câmera ou tirar foto: ${e.toString()}"));
    }
  }

  // Opcional: Função para pegar imagem da galeria
  Future<Either<Failure, XFile>> pickImageFromGallery() async {
     // 1. Verificar permissão de acesso à galeria (varia por plataforma)
     // Em Android >= 13, pode não precisar de permissão explícita para o picker
     // Em iOS, a permissão Photos é necessária (geralmente adicionada no Info.plist)
     // Permission_handler pode ser usado para verificar/solicitar se necessário.

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        return Right(image);
      } else {
        // Usuário cancelou a seleção
        return Left(UnknownFailure("Seleção de imagem cancelada pelo usuário."));
      }
    } catch (e) {
      print("Erro ao selecionar imagem da galeria: $e");
      return Left(UnknownFailure("Erro ao acessar a galeria ou selecionar imagem: ${e.toString()}"));
    }
  }
}

