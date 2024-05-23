import 'aws_code_commit.dart';
import 'aws_s3.dart';

class CloudBuildOperations{

  void startBuildProcess({required projectId}){
    print("Build Process started with project name >> $projectId");

    if(projectId == "No Project Id"){
      return;
    }



    ///Start the webhook to start listening changes for build process completion
    AWSS3Module().startWebhook(projectId: projectId);

    /// Creating S3 bucket, where the user project will be stored
    AWSS3Module().createUserProjectS3Bucket(projectId: projectId);

    /// Committing code to repository and creating build projects and pipelines
    CodeCommitCodeMagic().syncFilesToCloud(projectId: projectId);

  }



}
