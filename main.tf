provider "aws" {
  region = "<REGION CODE>" //us-west-1	US West (N. California), sa-east-1	South America (Sao Paulo), ap-south-1	India (Mumbai), af-south-1	Africa (Cape Town), eu-west-2	Europe (London), me-south-1
  //code for other resgion can be found online
}

resource "aws_key_pair" "deployer" {
  key_name   = "aakash-key"
  public_key = "<PUBLIC_KEY>"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "allow_all_ssh" {
  name        = "allow_all_ssh"
  description = "Allow SSH inbound traffic"
//  vpc_id      = aws_vpc.dashboard_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<YOUR PULIC IP /30>"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "quictest" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"  //Free tier machines name may vary based on regions
  key_name = aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
      aws_security_group.allow_all_ssh.id
  ]

  provisioner "file" {
    source      = "LOCATION OF SCRIPT.sh"
    destination = "/home/ubuntu/script.sh"
  }

//  provisioner "file" {
//    source      = "~/.ssh/id_rsa"
//    destination = "/home/ubuntu/.ssh/id_rsa"
//  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "printf 'y\ny\ny\ny\n' | bash /home/ubuntu/script.sh"
    ]
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("<PATH TO KEY IF ALTERNATE KEY IS USED>")
    host = aws_instance.quictest.public_ip
  }

}

output "instace_publice_ip" {
  value = aws_instance.quictest.public_ip
}