#!/bin/bash
source ./.env

# Name: scanning_research_Hand.sh
# Author: Landan
# Purpose: Script to automate the scanning process

# code for colored text
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
# Reset the text color to default
NC='\033[0m'

#PASS="" #root password for scans

makeParentDirectory () { # making the file structure
    # Check if an argument is provided
    if [[ ! -z "$1" ]]; then
        mkdir "$1"
        pwd
        echo "Parent Dir :: $1"
        echo -e "${YELLOW}  Making scans Directory ${NC}"
        mkdir "$1"/scans
        echo -e "${YELLOW}  Making Resources Directory ${NC}"
        mkdir "$1"/resources
    else # I know this is redundant
        echo "Usage: $0 <directory_name>"
        exit 1
    fi
}

grabIP () { #Getting the ip information
    # grab the ip schema of the network
    your_ip=$(ifconfig $ADAPTER | grep -oG '\b[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}\b' | head -n 1)
    echo -e "${YELLOW}  Your public IP address is: $your_ip${NC}"

    # Extract the first three octets of the IP address
    first_three_octets=$(echo $your_ip | cut -d. -f1-3)

    # Generate IP addresses in the cider notation
    new_ip="${first_three_octets}.0/24"
    echo -e "${GREEN}[*] IP address: $new_ip${NC}"
}

startfping () { # start the fping scan and save results
    echo -e "${YELLOW}  Starting fping Scan${NC}"
    fping -aqg $new_ip > "$1"/resources/ips
}

startTMUX () { # Starts all of the different tmux sessions
    session_names=("nmap" "mass" "nxc" "landan" "extra") # list of session names
    for session_name in "${session_names[@]}"; do # Start the tmux sessions
      tmux new-session -d -s "$session_name" # makes the tmux sessions
      echo -e "${YELLOW}    Started tmux session: $session_name${NC}"
    done
}

startNXC () { #eventually need to change to NetExec
    echo -e "${YELLOW}  Starting NetExec SMB Scan... ${NC}"
    tmux send-keys -t nxc "nxc smb $new_ip >> ./"$1"/scans/cme.results" ENTER #starts the cme scan
    tmux send-keys -t extra "nxc smb $new_ip --gen-relay-list ~/"$1"/scans/targets.txt" ENTER #might not work tbd
}

startNMAP () { # I bet you wouldn't guess that this function is supposed to start the nmap scans huh
    echo -e "${YELLOW}  Starting NMAP Scan... ${NC}"
    tmux send-keys -t nmap "sudo nmap -O -oX ./"$1"/Scans/nmap --script vulners --script-args mincvss=7.0 -sC -sV -iL ./"$1"/resources/ips" ENTER # start the nmap scan with the list of ips gathered earlier
    tmux send-keys -t nmap "$PASS" ENTER
}

startMASS () {
    echo -e "${YELLOW}  Starting Masscan Scan... ${NC}"
    tmux send-keys -t mass "sudo masscan --include-file ips -p0-65535 -oX masscan.xml --rate=10000" ENTER
    tmux send-keys -t mass "$PASS" ENTER
}

nmaphelp () { # function that will create helper scripts for common findings
    echo -e "${YELLOW}  Creating helper scripts for FTP and Telnet... ${NC}"
    echo -e "#!/bin/bash\nnmap $new_ip -sT -sV -p 21 --open -scripts ftp-anon -oN ftp_anon" >> ./"$1"/scans/FTPANON.sh
    chmod +x ./$1/scans/FTPANON.sh
    echo -e "#!/bin/bash\nnmap $new_ip -sT -sV -p 23 --open -oN telnet" >> ./"$1"/scans/TELNET.sh
    chmod +x ./$1/scans/TELNET.sh
}

finished () { # I wonder what this could possibly be
    echo -e "${GREEN} \n${NC}"
    echo -e "${GREEN}  .dBBBBP   dBBBP dBBBBBBP dBP dBP dBBBBBb     dBBBP  dBBBBP dBBBBBBb dBBBBBb  dBP    dBBBP dBBBBBBP dBBBP ${NC}"
    echo -e "${GREEN}  BP                                   dB'           dBP.BP       dBP     dB' ${NC}"
    echo -e "${GREEN}   BBBBb  dBBP     dBP   dBP dBP   dBBBP'    dBP    dBP.BP dBPdBPdBP  dBBBP' dBP    dBBP     dBP   dBBP ${NC}"
    echo -e "${GREEN}     dBP dBP      dBP   dBP_dBP   dBP       dBP    dBP.BP dBPdBPdBP  dBP    dBP    dBP      dBP   dBP ${NC}"
    echo -e "${GREEN}dBBBBP' dBBBBP   dBP   dBBBBBP   dBP       dBBBBP dBBBBP dBPdBPdBP  dBP    dBBBBP dBBBBP   dBP   dBBBBP \n${NC}"
    echo -e "${YELLOW}[!] Reminder you will have to close the nmap tmux session${NC}"
}

alert () {
    curl -d "Scanning is complete" $NTFY
}

program () { # basically just main
    if [ "$1" == "-h" ] || [ "$1" == "help" ] || ["$1" == ""]; then
        echo -e "${BLUE}Displaying help information...${NC}"
        echo -e "${BLUE}  Usage: $0 <directory_name> \n${NC}"
        echo -e "${YELLOW}  [!] This is a script to automate the scannign process${NC}"
        exit 0
    else
        # maybe add a prompt that will ask the user if they want to add any other arguments before running
        makeParentDirectory "$1"
        grabIP
        startfping "$1"
        startTMUX "$1"
        startNXC "$1"
        startMASSCAN
        startNMAP "$1"
        nmaphelp "$1"
        alert
        finished
    fi
}
# runs the program function... duh
program "$1"
