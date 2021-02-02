resource "random_string" "random" {
  length = 3
  lower = true
  min_lower = 3
}
resource "aws_s3_bucket" "b" {
  bucket = "${random_string.random.result}-test-bucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}