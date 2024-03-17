# Pre-Deployment
1. Create separate ECR repository, and push vikunja image to it, this will be used for ecs.
2. Move Frontend files to S3 - uploading them by terraform messes with their content-type which causes the static site to misbehave.

# Post-Deployment
1. Create One pipeline in codepipeline of 4 stages:
   1. stage 1: source
      1. Connect the source to the vikunja source code. will include frontend files, and config files.
   2. stage 2: build
      1. choose the codebuild app created in terraform.
   3. stage 3: deploy
      1. choose the codedeploy app created by terraform
   4. stage 4: deploy
      1. choose deploy to s3, and choose the s3 bucket of the app.