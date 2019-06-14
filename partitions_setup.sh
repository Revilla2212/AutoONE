# Author: Alejandro Revilla
#----------------------------------------------------------------
#!/bin/bash
STATUS_CANCEL=1
STATUS_OK=0

echo -e "\n###################################################"
echo -e "Benvingut a l'script de configuració de particions."
echo -e "###################################################\n"
echo -e "A continuació es mostrarà la seva configuració actual de particions:\n"
lsblk
echo -e "\nInsereixi el disc que vol modificar, aquest no ha de contenir cap partició, en cas contrari el programa podria fallar. Exemple: sda, sdb, etc.\n"
read -p "Disc:" disc

while ! [ -b /dev/$disc ]
do 
    echo -e "Inseriu un disc existent! \n"
    read -p "Disc:" disc
done

echo -e "Has seleccionat el disc $disc \n"
echo -e "A continuació es crearà una partició al disc $disc, vol continuar?\n(y)Yes/(n)No\n"
read -n 1 continue
while [[ $continue != "y" ]] && [[ $continue != "n" ]]
do 
    echo -e "Si us plau, insereixi (y)Yes o (n)No"
    read -n 1 continue
done
if [ $continue == 'n' ]; then echo -e "\nCancel·lant l'operació, tancant el programa... \n"
exit $STATUS_CANCEL;
fi

echo -e "\nSelecciona l'operació desitjada: \n"
echo -e "a - Crear partició de tot el disc amb LVM \n"
echo -e "b - Crear més d'una partició \n"

read -n 1 -p "Operació:" ops

while [[ $ops != "a" ]] && [[ $ops != "b" ]]
do 
    echo -e "\nSi us plau, insereixi a o b"
    read -n 1 ops
done


if [ $ops == "b" ]; then echo -e "Aquesta opció encara no es troba disponible. Tancant el programa... \n"
exit $STATUS_CANCEL;
fi

echo -e "\nHa escollit l'operació $ops \n\nEsta a punt de modificar el disc $disc, esta segur que vol continuar? Per confirmar insereixi el nom del disc un altre cop, per cancelar entri cualsevol altre entrada:"

read -p "Disc a modificar:" discaux

if [[ $discaux != $disc ]];then echo -e "\nCancel·lant l'operació, tancant el programa... \n"
exit $STATUS_CANCEL;
fi

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk ${disc}
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default - end at the end of disk
  p # print the disk information
  w # write the partition table
  q # and we're done
EOF
pvcreate /dev/$disc"1"

##########################################################################
##############################Partició creada#############################
##########################################################################

echo -e "\nPartició creada, insereixi el nom dessitjat pel volume group\n"
correcte=0
while [ $correcte -ne 1 ]
do
    read -p "Volume grup: vg_" vgname
    echo -e "Esteu segur de que voleu que es digui vg_$vgname?\n(y)Yes/(n)No\n"
    read -n 1 continue
    while [[ $continue != "y" ]] && [[ $continue != "n" ]]
    do 
        echo -e "\nSi us plau, insereixi (y)Yes o (n)No"
        read -n 1 continue
    done
    if [ $continue == 'n' ]; then echo -e "\nTorna a entrar nom per al volume group \n";
    else correcte=1;
    fi
done

vgcreate "vg_"$vgname /dev/$disc"1"
lvcreate -l 55%VG -n lv_dades vg_$vgname
lvcreate -l 45%VG -n lv_backup vg_$vgname
mkfs.ext4 /dev/vg_$vgname/lv_dades
mkfs.ext4 /dev/vg_$vgname/lv_backup

echo -e "\nCreat el volume group vg_$vgname i els logical volumes lv_dades(55%) i lv_backup(45%).\nCreats els file systems als lv anteriors.\n"

if ! [ -d /Dades ];then sudo mkdir /Dades; fi
if ! [ -d /backup ];then sudo mkdir /backup; fi

echo -e "\n/dev/vg_$vgname/lv_dades /Dades                 ext4     defaults  0 0\n/dev/vg_$vgname/lv_backup  /backup                  ext4     defaults  0 0" >> /etc/fstab

mount -ai

echo -e "\nCreats els directoris /Dades i /backup en cas de que no existissin prèviament, modificat l'arxiu fstab per afegir els lvm i fet el mount\n"

echo -e "\nConfiguració completada!\nResultat:\n"
lsblk
exit $STATUS_OK
