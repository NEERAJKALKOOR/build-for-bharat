// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_verification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OtpVerificationAdapter extends TypeAdapter<OtpVerification> {
  @override
  final int typeId = 5;

  @override
  OtpVerification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OtpVerification(
      email: fields[0] as String,
      otp: fields[1] as String,
      createdAt: fields[2] as DateTime,
      expiresAt: fields[3] as DateTime,
      isUsed: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OtpVerification obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.otp)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.expiresAt)
      ..writeByte(4)
      ..write(obj.isUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OtpVerificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
