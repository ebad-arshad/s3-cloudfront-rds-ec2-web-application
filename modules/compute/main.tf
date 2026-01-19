resource "aws_instance" "backend_instance" {
  ami                    = "ami-02b8269d5e85954ef"
  instance_type          = "t3.micro"
  subnet_id              = var.backend_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.backend_profile.name
  vpc_security_group_ids = [var.backend_sg_id]
  key_name               = "terraform"

  user_data = templatefile("${path.module}/../../scripts/main.sh.tpl", {
    s3_url      = "https://${var.frontend_bucket.bucket_regional_domain_name}"
    s3_host     = var.frontend_bucket.bucket_regional_domain_name
    rds_address = var.rds_address
    db_user     = var.db_user
    db_password = var.db_password
    db_database = var.db_database
  })

  user_data_replace_on_change = true

  tags = {
    Name = "Backend-Instance-${terraform.workspace}"
  }
}

resource "aws_iam_instance_profile" "backend_profile" {
  name = "backend_instance_profile_${terraform.workspace}"
  role = aws_iam_role.backend_role.name

  tags = {
    Name = "Backend-IAM-Profile-${terraform.workspace}"
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AssumeRoleEC2"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backend_role" {
  name               = "backend_role_${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "Backend-Role-${terraform.workspace}"
  }
}

data "aws_iam_policy_document" "backend_permissions" {
  statement {
    sid     = "AllowS3Frontend"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      "${var.frontend_bucket.arn}",
      "${var.frontend_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "backend_policy" {
  name   = "backend-permissions-${terraform.workspace}"
  role   = aws_iam_role.backend_role.name
  policy = data.aws_iam_policy_document.backend_permissions.json
}

resource "aws_iam_role_policy_attachment" "backend_ssm_core" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
