# -----------------------   jenkins secret ----------------------------

data "aws_secretsmanager_secret_version" "jenkins_admin_password_version" {
  secret_id  = aws_secretsmanager_secret.jenkins.id
  depends_on = [aws_secretsmanager_secret_version.jenkins]
}

resource "random_password" "jenkins" {
  length           = 16
  special          = true
  override_special = "@_"
}


resource "aws_secretsmanager_secret" "jenkins" {
  name                    = "${local.prefix}-jenkins-${local.suffix}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "jenkins" {
  secret_id     = aws_secretsmanager_secret.jenkins.id
  secret_string = random_password.jenkins.result
}
