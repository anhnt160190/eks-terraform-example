resource "aws_s3_bucket" "s3_backend_bucket" {
  bucket = "example-s3-backend-bucket"
}

resource "aws_s3_bucket_versioning" "s3_backend_bucket_versioning" {
  bucket = aws_s3_bucket.s3_backend_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_backend_bucket_encryption_configuration" {
  bucket = aws_s3_bucket.s3_backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
