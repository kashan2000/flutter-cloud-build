import 'package:aws_sns_api/sns-2010-03-31.dart';
import 'package:aws_codestar_notifications_api/codestar-notifications-2019-10-15.dart';

class AWSNotifications {
  Future<CodeStarNotifications> _Notifications() async {
    var value = await awsS3Backend.getCred();

    var cred = AwsClientCredentials(
        accessKey: value.accessKeyId!,
        secretKey: value.secretAccessKey!,
        sessionToken: value.sessionToken);
    // print("credentials : accesskey : ${value.accessKeyId}, secret key : ${value.secretAccessKey} and session token : ${value.sessionToken}");

    return CodeStarNotifications(
        credentials: cred, region: backendConstants.aws_region);
  }

  void createNotification({required projectId}) async {
    var notification = await _Notifications();
    print("adding notification");
    notification
        .createNotificationRule(
            detailType: DetailType.full,
            eventTypeIds: ["codebuild-project-build-state-failed"],
            name: "Build-Failed",
            resource:
                "arn:aws:codebuild:ap-south-1:454502939428:project/$projectId",
            targets: [
              Target(targetType: "SNS", targetAddress: "your topic address")
            ])
        .then((value) {
      print("notification rule done>> $value");
    });
  }
}

class AWSSNSModule {
  Future<SNS> _awsSNS() async {
    var value = await awsS3Backend.getCred();

    var cred = AwsClientCredentials(
        accessKey: value.accessKeyId!,
        secretKey: value.secretAccessKey!,
        sessionToken: value.sessionToken);
    // print("credentials : accesskey : ${value.accessKeyId}, secret key : ${value.secretAccessKey} and session token : ${value.sessionToken}");

    return SNS(credentials: cred, region: backendConstants.aws_region);
  }
}
