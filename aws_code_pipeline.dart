import 'package:aws_codepipeline_api/codepipeline-2015-07-09.dart';

class CodePipeLineAWS {
  Future<CodePipeline> _codePipeLine() async {
    var value = await awsS3Backend.getCred();

    var cred = AwsClientCredentials(
        accessKey: value.accessKeyId!,
        secretKey: value.secretAccessKey!,
        sessionToken: value.sessionToken);

    return CodePipeline(credentials: cred, region: backendConstants.aws_region);
  }

  void startPipeline({required String name}) async {
    var codePipeLine = await _codePipeLine();
    print("startigng pipeline with name $name");
    codePipeLine.startPipelineExecution(name: name);
  }

  void createNewPipeLine({required String name}) async {
    var codePipeLine = await _codePipeLine();
    print("creating pipeline with name $name");
    // codePipeLine.startPipelineExecution(name: name);

    codePipeLine
        .createPipeline(
      pipeline: PipelineDeclaration(
        // artifactStores: {
        //   "ap-south-1":
        //   ArtifactStore(location: name, type: ArtifactStoreType.s3),
        //   "us-east-1":
        //   ArtifactStore(location: "lambdabucketvirginiaregion", type: ArtifactStoreType.s3)
        // },
        artifactStore:
            ArtifactStore(location: name, type: ArtifactStoreType.s3),
        roleArn: "your role arn",
        stages: [
          /// 1st stage - Source Stage
          StageDeclaration(actions: [
            ActionDeclaration(
                name: "Source",
                roleArn: "your role arn",
                actionTypeId: ActionTypeId(
                    category: ActionCategory.source,
                    owner: ActionOwner.aws,
                    provider: "CodeCommit",
                    version: "1"),
                configuration: {
                  "RepositoryName": name,
                  "BranchName": "master",
                  "PollForSourceChanges": "false"
                },
                outputArtifacts: [OutputArtifact(name: "SourceArtifact")],
                namespace: "SourceVariables"),
          ], name: "SourceStage"),

          /// 2nd Stage - Build Stage
          StageDeclaration(actions: [
            ActionDeclaration(
              name: "Build",
              roleArn: "your role arn",
              actionTypeId: ActionTypeId(
                  category: ActionCategory.build,
                  owner: ActionOwner.aws,
                  provider: "CodeBuild",
                  version: "1"),
              configuration: {
                "BatchEnabled": "false",
                "ProjectName": name,
              },
              namespace: "BuildVariables",
              outputArtifacts: [OutputArtifact(name: "BuildArtifact")],
              inputArtifacts: [InputArtifact(name: "SourceArtifact")],
            ),
          ], name: "BuildStage"),

          /// 3rd Stage - Deploy Stage
          StageDeclaration(actions: [
            ActionDeclaration(
                name: "Deploy",
                roleArn: "your role arn",
                actionTypeId: ActionTypeId(
                    category: ActionCategory.deploy,
                    owner: ActionOwner.aws,
                    provider: "S3",
                    version: "1"),
                configuration: {
                  "BucketName": name,
                  "Extract": "true",
                },
                region: "ap-south-1",
                inputArtifacts: [InputArtifact(name: "BuildArtifact")],
                namespace: "DeployVariables"),
            ActionDeclaration(
                name: "invoke_send_build_function",
                roleArn: "your role arn",
                actionTypeId: ActionTypeId(
                    category: ActionCategory.invoke,
                    owner: ActionOwner.aws,
                    provider: "Lambda",
                    version: "1"),
                configuration: {
                  "FunctionName": "invoke_send_build_function",
                },
                inputArtifacts: [
                  InputArtifact(name: "SourceArtifact"),
                  InputArtifact(name: "BuildArtifact")
                ],
                namespace: "LambdaDeployVariables"),
          ], name: "DeployStage")
        ],
        name: "${name}_pipeline",
        version: 2,
      ),
    )
        .onError((error, stackTrace) {
      print("error in pipeline >>> $error and st >> $stackTrace");
      return CreatePipelineOutput();
    }).then((value) {
      print("created pipeline name is ${value.pipeline?.name}");
    });
  }
}
