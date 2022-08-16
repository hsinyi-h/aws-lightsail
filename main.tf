#--------------------------------------------------------------
# Lightsail Instance
#--------------------------------------------------------------

resource "aws_lightsail_instance" "lightsail" {
  count		    = length(var.azs)

  name              = element(var.lightsail_names, count.index)
  availability_zone = element(var.azs, count.index)
  blueprint_id      = var.blueprint_id
  bundle_id         = var.bundle_id
  key_pair_name     = aws_lightsail_key_pair.lightsail_key.name
  user_data	    = file("./bootstrap.sh")

  depends_on        = [ aws_lightsail_key_pair.lightsail_key ]

}

#--------------------------------------------------------------
# Lightsail keypair
#--------------------------------------------------------------
resource "aws_lightsail_key_pair" "lightsail_key" {
  name = "lightsail_key"
  public_key = file("lightsail_key.pub")
}

#--------------------------------------------------------------
# Static IP
#--------------------------------------------------------------

resource "aws_lightsail_static_ip" "static_ip" {
  count		= length(var.azs)

  name		= "${var.lightsail_names[count.index]}_static_ip"
}

resource "aws_lightsail_static_ip_attachment" "static_ip_attach" {
  count		= length(var.azs)

  static_ip_name = element(aws_lightsail_static_ip.static_ip.*.id, count.index)
  instance_name  = element(aws_lightsail_instance.lightsail.*.id, count.index)
}

#--------------------------------------------------------------
# Inbound rule
#--------------------------------------------------------------

resource "aws_lightsail_instance_public_ports" "inbound_rule" {
  count		= length(var.azs)

  instance_name = element(aws_lightsail_instance.lightsail.*.name, count.index)

  port_info {
      from_port        = 80
      to_port	       = 80
      protocol         = "tcp"
   }
}

#--------------------------------------------------------------
# Database
#--------------------------------------------------------------

resource "aws_lightsail_database" "db" {
  relational_database_name          = var.db_name
  availability_zone    = var.db_az
  master_database_name = var.db_database_name
  master_password      = data.aws_secretsmanager_secret_version.db-password.secret_string
  master_username      = var.db-user
  blueprint_id         = var.db_blueprint_id
  bundle_id            = var.db_bundle_id
  backup_retention_enabled = true
  skip_final_snapshot  = true

}


#--------------------------------------------------------------
# Secrets Manager
#--------------------------------------------------------------

resource "random_password" "db-password" {
  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "db-password" {
  name = "db-password"
}

resource "aws_secretsmanager_secret_version" "db-password" {
  secret_id     = aws_secretsmanager_secret.db-password.id
  secret_string = random_password.db-password.result
}

data "aws_secretsmanager_secret" "db-password" {
  name       = "db-password"
  depends_on = [aws_secretsmanager_secret.db-password]
}

data "aws_secretsmanager_secret_version" "db-password" {
  secret_id  = data.aws_secretsmanager_secret.db-password.id
  depends_on = [aws_secretsmanager_secret_version.db-password]
}

