# flutter-cloud-build
A project which demonstrates using AWS SDK and websockets to create a custom CI/CD pipeline to build flutter projects on cloud


Steps to reproduce custom CI/CD pipeline:

1) First we will create an S3 bucket which will hold a loading page for the time our project gets build.
2) Start a websocket connection to send and receive events happening during the cloud build
3) Create a S3 bucket in the name of the project and copy the contents of the loading screen bucket which we created and access the public url for the bucket
4) Launch the url in the chrome instance with the loading screen on it
5) Create a repository in aws code commit
6) Populate that repo with the project files of your project
7) Create a new build project in the AWS Code Build add the necessary build spec files and build project configurations
8) Now create a pipeline in AWS Code Pipeline
9) Define that pipeline with the required steps i.e. taking the code from code commit, building the project using code build then deploying the project on the s3 bucket which we created on the project's name
10) Fire a lambda at the end of the process which will have ping the web socket sending the message wether the build has failed or succeeded. If failed chrome instance will close and display error according to you and if succeds refresh the chrome instance link and your project is up and running on the cloud.

NOTE: To fire the events on build fail you need to create notification rule for the particular build project which will fire a lambda if the build fails
Steps mentioned are demonstrated in the repo code. This is a part of a bigger project and this feature is designed and integrated by me according to the project. In order for you to create an exact pipeline you need to integrate these according to your project with debugging and research. 
