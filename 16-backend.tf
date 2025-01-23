provider "aws" {
  region = "ap-northeast-1"
}
resource "aws_s3_bucket" "armageddon2" {
  bucket = "mattress-avengers-armageddon-bucket232"
 
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "armageddon2" {
  bucket = "${aws_s3_bucket.armageddon2.id}"

  block_public_acls   = true
  block_public_policy = true
}

# terraform {
#     backend "s3" {
#         bucket = "mattress-avengers-armageddon-2"
#         key = "tokyo-key-pair"
#         region = "ap-northeast-1"      
# }
# }