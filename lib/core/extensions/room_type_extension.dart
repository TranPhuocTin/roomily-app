extension RoomTypeExtension on String {
  String get toDisplayText {
    switch (this) {
      case 'ROOM':
        return 'Phòng trọ';
      case 'APARTMENT':
        return 'Chung cư';
      case 'HOUSE':
        return 'Nhà nguyên căn';
      default:
        return this;
    }
  }
} 