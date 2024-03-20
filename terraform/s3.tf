resource "aws_s3_bucket" "bucket" {
  bucket = "${terraform.workspace}-common-crawl-query-${random_pet.one.id}-${random_pet.two.id}"

  tags = {
    environment = terraform.workspace
  }
}

resource "aws_lambda_permission" "lambda_s3_permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.s3update_function.function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.bucket.id}"
}

resource "aws_s3_bucket_notification" "aws_lambda_trigger" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
    lambda_function_arn = module.s3update_function.function.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [
    aws_lambda_permission.lambda_s3_permission
  ]
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "queries/create_ccindex.athena"
  source = "create_ccindex.athena"

  etag = filemd5("create_ccindex.athena")
  depends_on = [
    aws_s3_bucket_notification.aws_lambda_trigger,
    module.s3update_function.function,
  ]
}
