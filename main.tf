terraform {
  required_providers {
    yandex = {
        source  = "yandex-cloud/yandex"
        version = "0.77.0"
    }
  }
}

provider "yandex" {
  token     = "<OAuth>"
  cloud_id  = "<идентификатор облака>"
  folder_id = "<идентификатор каталога>"
  zone      = "<зона доступности по умолчанию>"
}

data "yandex_compute_image" "debian_image" {
  family = "debian-11"
}

# Создаём VM 'vm'
resource "yandex_compute_instance" "vm" {        
    name        = "vm"  
    zone        = "ru-central1-a"

    resources {
        cores   = 2                                            
        memory  = 2                                           
    }

    boot_disk {
        initialize_params {
            image_id = data.yandex_compute_image.debian_image.id
            size     = 15 #GB
        }
    }

    network_interface {
        subnet_id   = "e9b9iosa2umis05ld5gu"    # default-ru-central1-a
        nat         = true
    }

    scheduling_policy {
      preemptible = true                        # Прерываемая VM            
    }

    metadata = {
        ssh-keys = "debian:${file("./keys/id_rsa.pub")}"     # debian - логин пользователя
    }
}

# Создание динамического inventory для Ansible для подключения к APP_GW
data "template_file" "inventory" {
    template = file("./_templates/inventory.tpl")
  
    vars = {
        user = "debian"
        host = join("", [yandex_compute_instance.vm.name, " ansible_host=", yandex_compute_instance.vm.network_interface.0.nat_ip_address])
    }
}

resource "local_file" "save_inventory" {
   content  = data.template_file.inventory.rendered
   filename = "./inventory"
}