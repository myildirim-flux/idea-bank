import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'APPWRITE_ENDPOINT', obfuscate: true)
  static final String appwriteEndpoint = _Env.appwriteEndpoint;
  @EnviedField(varName: 'APPWRITE_PROJECT_ID', obfuscate: true)
  static final String appwriteProjectId = _Env.appwriteProjectId;
  @EnviedField(varName: 'APPWRITE_DATABASE_ID', obfuscate: true)
  static final String appwriteDatabaseId = _Env.appwriteDatabaseId;
  @EnviedField(varName: 'APPWRITE_TABLE_ID', obfuscate: true)
  static final String appwriteTableId = _Env.appwriteTableId;
  @EnviedField(varName: 'APPWRITE_USER_TABLE_ID', obfuscate: true)
  static final String appwriteUserTableId = _Env.appwriteUserTableId;
  @EnviedField(varName: 'APPWRITE_BUCKET_ID', obfuscate: true)
  static final String appwriteBucketId = _Env.appwriteBucketId;
  @EnviedField(varName: 'APPWRITE_API_KEY', obfuscate: true)
  static final String appwriteApiKey = _Env.appwriteApiKey;
}
