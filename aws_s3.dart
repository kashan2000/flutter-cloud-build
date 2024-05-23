import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:aws_s3_api/s3-2006-03-01.dart';

import 'package:ide/business_logic/data/aws/aws_s3.dart';
import 'package:path/path.dart' as path;
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'launch_chrome.dart';

class AWSS3Module {
  UserConnect? _userConnect;
  bool hasWebsocketReceivedMessage = false;

  Future<S3> _AWSS3() async {
    var value = await awsS3Backend.getCred();

    var cred = AwsClientCredentials(
        accessKey: "your access key", secretKey: "your secret key");

    return S3(credentials: cred, region: backendConstants.aws_region);
  }

  Future<void> createUserProjectS3Bucket({required String projectId}) async {
    var AWSS3 = await _AWSS3();
    print("creaitng s3 bucket with name ${projectId}");

    AWSS3
        .createBucket(
            bucket: projectId,
            createBucketConfiguration: CreateBucketConfiguration(
                locationConstraint: BucketLocationConstraint.apSouth_1))
        .onError((error, stackTrace) {
      print("Error on creating s3 bucker >>>> ${error}");
      return CreateBucketOutput();
    }).then((value) async {
      print("s3 bucket created with path ${value.location}");
      print("putting bucket website");
      await AWSS3.putBucketWebsite(
          bucket: projectId,
          websiteConfiguration: WebsiteConfiguration(
              indexDocument: IndexDocument(suffix: 'index.html')));
      print("putting public access");
      await AWSS3
          .putPublicAccessBlock(
              bucket: projectId,
              publicAccessBlockConfiguration: PublicAccessBlockConfiguration(
                  blockPublicAcls: false,
                  blockPublicPolicy: false,
                  ignorePublicAcls: false,
                  restrictPublicBuckets: false))
          .onError((error, stackTrace) {
        print("error puvlic>> $error");
      });
      print("put bucket policy");
      await AWSS3.putBucketPolicy(bucket: projectId, policy: '''{
    "Version": "2012-10-17",
    "Id": "PolicyForPublicWebsiteContent",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$projectId/*"
        }
    ]
}''').onError((error, stackTrace) {
        print("cannot uploda policy >> ${error}");
      }).then((value) {
        print("uplodased");
      });
      copyDefaultS3Project(projectId: projectId);
    });
  }

  void copyDefaultS3Project({required String projectId}) async {
    var AWSS3 = await _AWSS3();
    final listObjectsResponse =
        await AWSS3.listObjects(bucket: "testloadingbucket");

    if (listObjectsResponse.contents != null) {
      // Iterate through the objects and copy each one to the destination bucket
      for (final object in listObjectsResponse.contents!) {
        final sourceKey = object.key!;
        final destinationKey =
            sourceKey; // Keep the same key in the destination bucket

        try {
          final copyObjectResponse = await AWSS3.copyObject(
            bucket: projectId,
            key: destinationKey,
            copySource: 'testloadingbucket/$sourceKey',
          );

          print(
              'Successfully copied $sourceKey: ${copyObjectResponse.copyObjectResult}');
        } catch (e) {
          print('Error copying $sourceKey: $e');
        }
      }
      print("stating chromiusm");
      BuildChromePup.instance.start(url: "http://$projectId.yours3bucketurl");
      Future.delayed(const Duration(seconds: 240), () {
        if (!hasWebsocketReceivedMessage) {
          BuildChromePup.instance
              .reload(url: "http://$projectId.yours3bucketurl")
              .onError((_, __) {
            print("err-reload>> $_ | $__");
          });
        }
      });
    } else {
      print('No objects found in the source bucket.');
    }
  }

  void startWebhook({required String projectId}) {
    print("starting webhook");
    _userConnect = UserConnect(onClose: (_, __) {
      print("channel is closed>> $_ and $__");
    }, onMessage: (_) {
      String result = _.toString();
      print("Result>>>> $_");

      if (result.contains('Echo: {"buildStatus":"Successfull"}')) {
        print(
            "build successfull, refresh the link >>> ${"http://$projectId.yours3bucketurl"}");
        Future.delayed(const Duration(seconds: 2), () {
          hasWebsocketReceivedMessage = true;

          BuildChromePup.instance
              .reload(url: "http://$projectId.yours3bucketurl")
              .onError((_, __) {
            print("err-reload>> $_ | $__");
          });
        });

        /// Failed to build
      } else if (result.contains('Build Failed')) {
        print("Build Failed");
        try {
          var outputMap = json.decode(result);
          String errorLog;
          errorLog = (outputMap["Build Failed"]) ??
              "Unable to generate logs, kindly build your project again";
          var errorLogList = json.decode(errorLog);

          // Convert the filtered list back to a string
          // var filteredErrorLog = json.encode(filteredErrorLogList);

          // print("error log : $filteredErrorLog");
          BuildChromePup.instance.close();
        } catch (er) {
          print("Error in decoding>> $er");
        }
      }
    }, onOpen: () {
      print("webhook is opened with project id send >> $projectId");
      hasWebsocketReceivedMessage = false;

      // Timer? _timer;
      // _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      //   try {
      //     _userConnect?.send("Hello from flutter");
      //     // print("Message sent");
      //   }catch(er){
      //     print("error sending message >> $er");
      //   }
      // });

      /// Do something on open
    });
    _userConnect?.connect(projectId: projectId);
  }
}
