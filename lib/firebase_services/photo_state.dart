import 'package:diplom/firebase_services/photo_entity.dart';

abstract class PhotoState {}

class PhotoLoading extends PhotoState {}

class PhotoLoaded extends PhotoState {
  final List<PhotoEntity> photos;

  PhotoLoaded({required this.photos});
}

class PhotoLoadFailure extends PhotoState {}
