import 'dart:io' as io;

import 'package:aws_codecommit_api/codecommit-2015-04-13.dart';

import 'package:ide/business_logic/data/aws/aws_s3.dart';
import 'package:path/path.dart' as path;

import 'aws_code_build.dart';

class CodeCommitCodeMagic {
  Future<CodeCommit> _codeCommit() async {
    var value = await awsS3Backend.getCred();

    var cred = AwsClientCredentials(
        accessKey: value.accessKeyId!,
        secretKey: value.secretAccessKey!,
        sessionToken: value.sessionToken);
    // print("credentials : accesskey : ${value.accessKeyId}, secret key : ${value.secretAccessKey} and session token : ${value.sessionToken}");

    return CodeCommit(credentials: cred, region: backendConstants.aws_region);
  }

  Future<CommitStatus> syncFilesToCloud({required String projectId}) async {
    print("creating repo named $projectId");
    var codeCommit = await _codeCommit();
    try {
      /// This will Create Repo.
      await codeCommit.createRepository(repositoryName: projectId);
      String dirPath = "your dir path";
      var dir = io.Directory(dirPath).listSync(recursive: true);
      List<PutFileEntry> putFiles = [];
      for (var value in dir) {
        if (value.runtimeType.toString() == "_File") {
          String filePath = "ypur file path";

          var file = io.File(value.path);
          if (addFileOrNot(filePath)) {
            // print("adding file with path >> $filePath");
            var putFile = PutFileEntry(
                fileContent: file.readAsBytesSync(),
                fileMode: FileModeTypeEnum.normal,
                filePath: filePath);
            putFiles.add(putFile);
          }
        }
      }
      int firstIndex = 0;
      int lastIndex = 0;
      String? parentCommitId;
      CommitStatus status;
      int i = 0;
      try {
        codeCommit.createBranch(
            branchName: 'master',
            commitId: 'Creating Branch',
            repositoryName: projectId);
      } catch (ex, st) {
        print("DaDS>>> $ex $st");
      }
      while (putFiles.isNotEmpty) {
        List<PutFileEntry> commitFiles = [];
        if (putFiles.length < 99) {
          lastIndex = putFiles.length;
        } else {
          lastIndex = 99;
        }
        commitFiles = putFiles.sublist(firstIndex, lastIndex);

        CreateCommitOutput result;
        if (i == 0) {
          try {
            result = await codeCommit.createCommit(
                branchName: 'master',
                repositoryName: projectId,
                putFiles: commitFiles,
                commitMessage: "$i Commit");
          } catch (ex, st) {
            print("exception>> $ex $st");
            return CommitStatus("fail", true);
          }
        } else {
          result = await codeCommit.createCommit(
              branchName: 'master',
              repositoryName: projectId,
              putFiles: commitFiles,
              parentCommitId: parentCommitId,
              commitMessage: "$i Commit");
        }
        putFiles = putFiles.sublist(lastIndex);
        // codeCommit.putFile(branchName: 'master', fileContent: fileContent, filePath: filePath, repositoryName: repoId);
        parentCommitId = result.commitId;
        status = CommitStatus(result.commitId, false);
        i++;
      }
      print("final commit >> $parentCommitId");

      /// Creating new project
      CodeBuildAWS().createNewBuildProject(projectId: projectId);
      return CommitStatus(parentCommitId, false);

      /// Create Code Build Project

      /// Create Code Pipeline connecting all these
      /// Whenever any code is commited, will start the pipeline.
    } catch (exception, st) {
      print("CodeCommitCodeMagic > syncFilesToCloud > error $exception >> $st");

      if (exception is RepositoryNameExistsException) {
        var branchDetails = await codeCommit.getBranch(
            branchName: "master", repositoryName: projectId);
        var parentCommitId = branchDetails.branch!.commitId;

        List<PutFileEntry> putFiles = [];

        try {
          int firstIndex = 0;
          int lastIndex = 0;
          // String parentCommitId;
          CommitStatus status;
          int i = 0;
          while (putFiles.isNotEmpty) {
            List<PutFileEntry> commitFiles = [];
            if (putFiles.length < 99) {
              lastIndex = putFiles.length;
            } else {
              lastIndex = 99;
            }
            commitFiles = putFiles.sublist(firstIndex, lastIndex);

            late CreateCommitOutput result;
            // if (i == 0) {
            //   result = await codeCommit.createCommit(
            //       branchName: 'master', repositoryName: repoId, putFiles: commitFiles, commitMessage: "$i Commit",
            //   parentCommitId: parentCommitId);
            // } else {
            try {
              print("trying code comiiiit");
              result = await codeCommit.createCommit(
                  branchName: 'master',
                  repositoryName: projectId,
                  putFiles: commitFiles,
                  parentCommitId: parentCommitId,
                  commitMessage: "$i Commit");
            } catch (ex, st) {
              print("ex>> $ex $st");
            }
            putFiles = putFiles.sublist(lastIndex);
            //codeCommit.putFile(branchName: branchName, fileContent: fileContent, filePath: filePath, repositoryName: repositoryName);
            parentCommitId = result.commitId;
            status = CommitStatus(result.commitId, false);
            print("commit status>>> $status");
            i++;
          }
        } catch (ex, st) {
          print("exx>> $ex, $st");
        }
      } // return CommitStatus(null, true);

      print("starting pipelin eexecution");
      CodePipeLineAWS().startPipeline(name: "${projectId}_pipeline");
      return CommitStatus(null, false);
    }
  }

  bool addFileOrNot(String filePath) {
    var fileNames = path.split(filePath);
    String fileName = fileNames.isNotEmpty ? fileNames[0] : "";

    switch (fileName) {
      case 'Java':
      case 'flutter':
      case 'defaults':
      case 'build':
      case '.dart_tool':
      case 'bats':
      case '.flutter-plugins':
      case '.flutter-plugins-dependencies':
      case '.packages':
      case 'android':
      case 'example':
      // case 'web':
      case 'test':
      case 'macos':
      case 'windows':
      case 'gradle':
        return false;
      case 'ios':
        filePath = filePath.substring(4);
        var iosFileNames = path.split(filePath);
        String iosFileName = iosFileNames.isNotEmpty ? iosFileNames[0] : "";
        switch (iosFileName) {
          case ".symlinks":
          // case "Pods":
          case "Podfile.lock":
            return false;
          default:
            return true;
        }
        break;
      // case "android":
      //   filePath = filePath.substring(8);
      //   print("fil Path android  $filePath");
      //   String androidFileName = filePath.contains('/') ? filePath.substring(0, filePath.indexOf('/')) : filePath;
      //   print("androidFileName   $androidFileName");
      //   switch(androidFileName){
      //     case "sdk":
      //     case ".gradle":
      //       return false;
      //     default:
      //       return true;
      //   }
      //   break;
      default:
        return true;
    }
  }
}

class CommitStatus {
  final String? commitId;
  final bool failed;

  CommitStatus(this.commitId, this.failed);
}
