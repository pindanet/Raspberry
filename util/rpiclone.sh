#!/bin/bash
# PiClone maakt reservekopieën van Raspberry Pi OS
# en kan deze terugzetten op een opslagapparaat met een andere capaciteit

# backupDir bevat de map waar de reservekopieën bewaard worden
backupDir="$HOME/Documenten/Systeembeheer"

# Zoek alle aangesloten USB opslagapparaten
usbdevices=$(lsblk -o NAME,TRAN,MODEL,SIZE | grep usb)

if [[ ${#usbdevices} -ne 0 ]]; then # Er zijn aangesloten USB apparaten gevonden.
  # Bepaal het aantal regels (USB apparaten)
  totalusbdevices=$(echo "$usbdevices" | wc -l)
  # Initialiseer antwoord op keuzelijst
  answer=$(("0"))
  while (( $answer < 1 || $answer > $totalusbdevices )); do # Tot een aangesloten USB opslagapparaat wordt gekozen
    echo "Please choose an external USB storage device"
    number=0 # Initialiseer gekozen USB apparaat
    while read -u 3 -r line; do # Geef de aangesloten USB opslagapparaten weer
      ((number++))
      echo "${number}) $line"
    done 3<<< "$usbdevices"
    read -p "Your answer: " answer # Gebruiker voert het te gebruiken USB opslagapparaat in
    if (( $answer < 1 || $answer > $totalusbdevices )); then # Ongeldige keuze
      echo "No valid choice. Try again".
    else # Er werd een aangesloten USB opslagapparaat gekozen
      echo "$usbdevices" | head -n $answer | tail -n 1 # Gekozen USB opslagapparaat weergeven
      usbdevice="/dev/$(echo "$(echo "$usbdevices" | head -n $answer | tail -n 1)" | awk '{print $1}')"
      # Om een reservekopie te maken of terug te zetten, mag geen enkele partitie van het USB opslagapparaat gekoppeld zijn
      # Unmount external USB storage device
      if grep -q "${usbdevice}" /proc/mounts; then # Controleer koppelpunten
        mounted=$(echo "$(grep "${usbdevice}" /proc/mounts)" | awk '{print $1}')
        while read -u 4 -r mount; do # Ontkoppel alle gevonden USB opslagapparaat partities
          echo "Unmounting $mount"
          sudo umount "$mount"
        done 4<<< "$mounted"
      fi
      # Kies tussen reservekopie maken of terugzetten
      while [ ! $validChoice ]; do # Tot een geldige keuze werd gemaakt
        read -p "Restore or Backup: " command # Gebruikt geeft keuze in
        case "${command,,}" in
          "restore") # Terugzetten
            # Zoek naar aanwezige reservekopieën
            backups=$(ls ${backupDir}/*.resized.partition.table.txt)
            totalbackups=$(echo "$backups" | wc -l) # Aantal gevonden reservekopieën
            answer=$(("0")) # Initialiseer antwoord op keuzelijst
            while (( $answer < 1 || $answer > $totalbackups )); do # Tot een geldige reservekopie wordt gekozen
              number=0 # Initialiseer gekozen reservekopie
              while read -u 3 -r line; do # Geef de beschikbare reservekopieën weer
                ((number++))
                echo "${number}) ${line%%.*}"
              done 3<<< "$backups"
              read -p "Your answer: " answer # Gebruiker voert de te gebruiken reservekopie in
              answer=${answer:-$(("0"))} # Indien geen invoer ontvangen (gebruiker drukte enkel Enter), gebruiken we het standaard antwoord 0
              if (( $answer < 1 || $answer > $totalbackups )); then # Ongeldige keuze
                echo "No valid choice. Try again".
              else # Er werd een geldige reservekopie gekozen
                # Volledige bestandsnaam van de gekozen reservekopie opzoeken
                backup="$(echo "$(echo "$backups" | head -n $answer | tail -n 1)")"
                # Enkel het eerste deel van bestandsnaam van de gekozen reservekopie gebruiken
                restore=${backup%%.*}
                echo "Restoring backup: $restore" # en weergeven
                # Aanmaken van de partitie structuur op het USB opslagapparaat
                sudo sfdisk $usbdevice < "${restore}.resized.partition.table.txt"
                # Terugzetten van de twee partities naar het USB opslagapparaat
                sudo fsarchiver restfs "${restore}.fsa" id=0,dest=${usbdevice}1 id=1,dest=${usbdevice}2
              fi
            done
            validChoice=true # Dit was een correcte opdracht > beëindig straks de afgewerkte opdracht
            ;;
          "backup") # Reservekopie maken
            read -p "Give your RPI project a name: " rpiproject # Gebruiker voert de naam van de reservekopie in
            rpiproject=${rpiproject:-"rpiproject"} # Indien geen invoer ontvangen (gebruiker drukte enkel Enter), gebruiken we de standaard naam rpiproject
            if [ -f "${backupDir}/${rpiproject}.partition.table.txt" ]; then # De reservekopie bestaat al
              while [ "${userinput,,}" != "y" ] && [ "${userinput,,}" != "n" ]; do # Tot de gebruiker een correct antwoord gaf
                read -p "Overwrite previous backup? (y/n) " userinput # Gebruiker bevestigt of annuleert het overschrijven
                case "${userinput,,}" in # Zet de invoer in kleine letters en beoordeel ze
                  "y") # Overschrijven
                    overwrite=true
                    # Verwijder de vorige reservekopie
                    sudo rm ${backupDir}/${rpiproject}.fsa
                    ;;
                  "n") # Annuleer het overschrijven
                    exit # Breek de opdracht af
                    ;;
                esac
              done
            else # Geen reservekopie met opgegeven naam gevonden
              overwrite=true
            fi
            if [ $overwrite ]; then # Enkel bij toestemming om eventuele reservekopie met dezelfde naam te overschrijven
              echo "Creating a backup..."
              # Schrijf de partitiestructuur van het USB opslagapparaat naar een bestand
              sudo /sbin/sfdisk -d $usbdevice > ${backupDir}/${rpiproject}.partition.table.txt
              # Pas de partitiestructuur aan zodat deze op een USB opslagapparaat met een andere capaciteit kan gebruikt worden
              # Dit bereiken we door de laatste partitie de resterende opslagcapaciteit te laten gebruiken (verwijderen grootte)
              # Zonder de laatste regel met de eigenschappen van de laatste partitie af
              line=$(tail -1  ${backupDir}/${rpiproject}.partition.table.txt)
              # Gebruik tot de eerste komma (naam en start)
              start=${line%%,*}
              # en vanaf de laatste komma (type)
              end=${line##*,}
              # Het eerste deel (tot de laatste regel) van de partitiestructuur blijft behouden
              head=$(head -n -1 ${backupDir}/${rpiproject}.partition.table.txt)
              # Voeg alles samen, het eerste deel
              echo -e "$head" > ${backupDir}/${rpiproject}.resized.partition.table.txt
              # gevolgt door de aangepaste regel bestaande uit start (naam, start) een komma en end (type)
              echo "$start,$end" >> ${backupDir}/${rpiproject}.resized.partition.table.txt

              if [ ! -f "/sbin/fsarchiver" ]; then # Indien de noodzakelijke software niet aanwezig is, installeer deze dan (Debian, Ubuntu)
                sudo apt install fsarchiver
              fi
              # Maak een reservekopie van de inhoud van de twee partities
              sudo /sbin/fsarchiver savefs ${backupDir}/${rpiproject}.fsa ${usbdevice}1 ${usbdevice}2
            fi
            validChoice=true # Dit was een correcte opdracht > beëindig straks de afgewerkte opdracht
            ;;
          *) # Geen correcte keuze
            echo "Try again. Type the full command."
            ;;
        esac
      done
      exit
    fi
  done
else # Er geen aangesloten USB apparaten gevonden.
  echo "No external USB storage device found!"
fi
