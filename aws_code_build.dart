import 'package:aws_codebuild_api/codebuild-2016-10-06.dart';

class CodeBuildAWS {
  Future<CodeBuild> _codeBuild() async {
    var value = await awsS3Backend.getCred();

    var cred = AwsClientCredentials(
        accessKey: value.accessKeyId!,
        secretKey: value.secretAccessKey!,
        sessionToken: value.sessionToken);

    return CodeBuild(credentials: cred, region: backendConstants.aws_region);
  }

  /// For test, create a void function
  void createNewBuildProject({required String projectId}) async {
    var codeBuild = await _codeBuild();
    codeBuild
        .createProject(
            artifacts: ProjectArtifacts(type: ArtifactsType.codepipeline),
            environment: ProjectEnvironment(
                computeType: ComputeType.buildGeneral1Large,
                image: "aws/codebuild/standard:7.0",
                type: EnvironmentType.linuxContainer),
            name: projectId,
            serviceRole: "your role arnS",
            source: ProjectSource(type: SourceType.codepipeline, buildspec: '''
          version: 0.2
          run-as: root
          phases:
            install:
              commands:
                - echo \$CODEBUILD_SRC_DIR
              
            pre_build:
              commands:
                - echo Installing flutter dependencies
                - export FLUTTER_SDK=\$CODEBUILD_SRC_DIR/flutter-sdk
                - mkdir \$FLUTTER_SDK
                - git clone https://github.com/flutter/flutter.git \$FLUTTER_SDK -b stable
                - export PATH="\$PATH:\$FLUTTER_SDK/bin"
                # - flutter precache --force
                # - flutter doctor
            build:
              commands:
                - echo Build started
                - flutter build web
          post_build:
              commands:
                - echo Build completed
          artifacts:
            files:
              - '**/*'
            discard-paths: no  
            base-directory: 'build/web'       
          '''),
            timeoutInMinutes: 5)
        .onError((error, stackTrace) {
      print("error in code build >> $error st>> $stackTrace");
      return CreateProjectOutput();
    }).then((value) {
      print("project build");
      print("value>> ${value.project?.name}");
      AWSNotifications().createNotification(projectId: projectId);
      CodePipeLineAWS()
          .createNewPipeLine(name: value.project?.name ?? projectId);
    });
  }
}
