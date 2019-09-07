#!/bin/bash
#
# Copyright 2019 Yulio Aleman Jimenez (@yulioaj290)
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions 
# are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in 
# the documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived 
# from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT 
# NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#================================
# Localhost Mirror
#================================
#
# lhmirror                                                      // Show help
#
# lhmirror -h|--help                                            // Show help
#
# lhmirror -p|--publish <origin-url> <local-resource-path>      // Publish local resource in local server as mirror
#
# lhmirror -u|--unpublish <origin-url>                          // Unpublish from local server based on the origin url
#
# lhmirror -a|--unpublish-all                                   // Unpublish all mirrored resources from local server
#
# ================================================
# PROMPT VARIABLES
# ================================================
RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
BLUE=$'\e[0;34m'
NC=$'\e[0m'

# ================================================
# FUNCTIONS
# ================================================
#
# Check if Apache2 is installed
check_apache_func(){
    # Must return "/usr/sbin/apache2"
    local APACHE_INSTALLED="$(echo `systemctl status apache2 | grep -o 'active (running)'`)"
    local NGINX_INSTALLED="$(echo `systemctl status nginx | grep -o 'active (running)'`)"
    if [[ ! -z $APACHE_INSTALLED ]]; then
        echo "true"
    elif [[ ! -z $NGINX_INSTALLED ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Check if given URL is valid
check_url_func(){
    # Removed operator ? -----------------|
    # Removed User and Password Match ----|-----|================|
    # local regex='^(?:(?:(?:https?|ftp):)?\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:[/?#]\S*)?$';
    
    # Regex for URL with NO Optional protocol and without User and Password
    local regex='(https?|ftp)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]';
    
    if [[ $1 =~ $regex ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Check if Domain is in Mirror file
check_domain_in_mirror_func(){
    local EXIST=""
    if [[ ! -e $2 ]]; then
        EXIST="false"
    else
        while read -r DOMAIN_ITEM
        do
            local DOMAIN=$(echo "$DOMAIN_ITEM" | cut -d' ' -f1)

            if [[ "$DOMAIN" == "$1" ]]; then
                EXIST="true"
                break
            else
                EXIST="false"
            fi
        done < "$2"
    fi
    echo "$EXIST"
}

# Check if Origin URL is in Mirror file
check_origin_url_in_mirror_func(){
    local EXIST=""
    if [[ ! -e $2 ]]; then
        EXIST="false"
    else
        while read -r ORIGIN_ITEM
        do
            local ORIGIN=$(echo "$ORIGIN_ITEM" | cut -d' ' -f2)

            if [[ "$ORIGIN" == "$1" ]]; then
                EXIST="true"
                break
            else
                EXIST="false"
            fi
        done < "$2"
    fi
    echo "$EXIST"
}

# Check if Domain is in Hosts file
check_domain_in_hosts_func(){
    local EXIST=""
    if [[ ! -e $2 ]]; then
        EXIST="false"
    else
        while read -r DOMAIN_ITEM
        do
            local DOMAIN=$(echo "$DOMAIN_ITEM" | cut -d' ' -f2)
            
            if [[ "$DOMAIN" == "$1" ]]; then
                EXIST="true"
                break
            else
                EXIST="false"
            fi
        done < "$2"
    fi
    echo "$EXIST"
}

# Extract domain from URL
extract_domain_func(){
    local WEBSITE_DOMAIN="$(echo $1 | awk -F[/:] '{print $4}')"
    echo "$WEBSITE_DOMAIN"
}

# Extract PATH from URL
extract_path_func(){
    local URL_ARGS="$1"
    local CLEAN_PATH=$(echo ${URL_ARGS} | cut -d'/' -f4- | cut -d'?' -f1)
    local COUNT_SLASH="$(echo ${CLEAN_PATH} | grep -Pc '/')"
    if [[ "${COUNT_SLASH}" == "1" ]]; then 
        local FILE_PATH="$(echo ${CLEAN_PATH%\/*})"
    else
        local FILE_PATH=""
    fi

    echo $FILE_PATH
}

# Extract NAME from URL
extract_name_func(){
    local URL_ARGS="$1"
    local CLEAN_PATH=$(echo ${URL_ARGS} | cut -d'/' -f4- | cut -d'?' -f1)
    local COUNT_SLASH="$(echo ${CLEAN_PATH} | grep -Pc '/')"
    if [[ "${COUNT_SLASH}" == "1" ]]; then 
        local FILE_NAME="$(echo ${CLEAN_PATH##*\/})"
    else
        local FILE_NAME="${CLEAN_PATH}"
    fi
    
    echo $FILE_NAME
}

# ================================================
# MAIN PROCESS
# ================================================

# STEP 1: Verify requirements
#   * Apache2 package installed

if [[ $(check_apache_func) == "false" ]]; then
    echo "${RED}[ ERROR ]: Apache2 or NGINX is not installed or maybe is just down.${NC}"
else

    # ================================================
    # STEP 2: Initialize variables
    # ================================================
    OPTION=$1                           # Option passed 
    ORIGIN_URL=$2                       # Origin URL
    LOCAL_RESOURCE=$3                   # Local resource
    HOME_DIR="$(echo ~)/.lhmirror"      # Home directory for temporary files

    # Creating Home directory if not exist
    if [[ ! -e "$HOME_DIR" ]]; then
        mkdir -p "$HOME_DIR"
    fi

    case $OPTION in

        # lhmirror ''|-h|--help                                          // Show help
        ""|"-h"|"--help")
            echo ""
            echo "Usage: $0 [ <command> ]"
            echo ""
            echo "Where <command> is one of:"
            echo "    -p|--publish <origin-url> <local-resource-path>"
            echo "    -u|--unpublish <origin-url>"
            echo "    -a|--unpublish-all"
            echo ""
            echo "Command description:"
            echo "-p|--publish        Set the URL passed in <origin-url>, as local mirror, using the resource(s) passed in <local-resource-path>"
            echo "-u|--unpublish      Remove the local mirror created for the URL passed in <origin-url>"
            echo "-a|--unpublish-all  Remove all local mirrors created before"
            echo ""
            echo "Apache2 or NGINX server is required to use this tool, with default directory server as '/var/www/html'"
            echo ""

            ;;
        
        # lhmirror -p|--publish <origin-url> <local-resource-path>      // Publish local resource in local server as mirror
        "-p"|"--publish")
            VALIDATE_URL="$(check_url_func $ORIGIN_URL)"

            # Check if Local Resource Path is valid File or Directory
            if [[ -d $LOCAL_RESOURCE || -d "$LOCAL_RESOURCE" ]]; then
                VALIDATE_RESOURCE="directory"
            elif [[ -f $LOCAL_RESOURCE || -f "$LOCAL_RESOURCE" ]]; then
                VALIDATE_RESOURCE="file"
            else
                VALIDATE_RESOURCE="false"
            fi

            # Validating Origin URL and Local Resource
            if [[ "$VALIDATE_URL" == "false" ]]; then
                echo "${RED}[ ERROR ]: Invalid argument <origin-url> [$ORIGIN_URL].${NC}"
                exit 128
            elif [[ "$VALIDATE_RESOURCE" == "false" ]]; then
                echo "${RED}[ ERROR ]: Invalid argument <local-resource-path> [$LOCAL_RESOURCE].${NC}"
                exit 128
            fi

            # Getting Domain and Path from the Origin URL
            URL_DOMAIN="$(extract_domain_func $ORIGIN_URL)"
            URL_PATH="$(extract_path_func $ORIGIN_URL)"

            # Making a copy of 'hosts' files into the Home directory
            cp -f "/etc/hosts" "$HOME_DIR"

            # Adding local mirror for the Domain of the Origin URL
            if [[ $(check_domain_in_hosts_func "${URL_DOMAIN}" "${HOME_DIR}/hosts") == "false" ]]; then
                echo "127.0.0.1 ${URL_DOMAIN}" >> "${HOME_DIR}/hosts"
            fi

            # Saving a registry of the Origin URL
            if [[ $(check_origin_url_in_mirror_func "${ORIGIN_URL}" "${HOME_DIR}/mirrors") == "false" ]]; then
                echo "${URL_DOMAIN} ${ORIGIN_URL}" >> "${HOME_DIR}/mirrors"
            fi
            
            URL_MIRROR_PATH="/var/www/html/${URL_PATH}"

            # Creating mirror path sctructure into the Apache server
            mkdir -p "$URL_MIRROR_PATH"
            
            # Determine if copy a single file of all files inside directory
            if [[ "$VALIDATE_RESOURCE" == "directory" ]]; then
                LOCAL_RESOURCE_END="/*"
            else
                LOCAL_RESOURCE_END=""
            fi

            # Copying mirrored files
            cp -Rf "${LOCAL_RESOURCE}"${LOCAL_RESOURCE_END} "$URL_MIRROR_PATH"

            # Copy 'hosts' file to /etc [may require sudo privileges]
            sudo cp -f "${HOME_DIR}/hosts" "/etc/hosts"

            echo "${GREEN}You can access to \"${ORIGIN_URL}\" as local mirror.${NC}"
            ;;
        
        # lhmirror -u|--unpublish <origin-url>                          // Unpublish from local server based on the origin url
        "-u"|"--unpublish")
            VALIDATE_URL="$(check_url_func $ORIGIN_URL)"

            # Validating Origin URL and Local Resource
            if [[ "$VALIDATE_URL" == "false" ]]; then
                echo "${RED}[ ERROR ]: Invalid argument <origin-url> [$ORIGIN_URL].${NC}"
                exit 128
            fi

            # Getting Domain and Path from the Origin URL
            URL_DOMAIN="$(extract_domain_func $ORIGIN_URL)"
            URL_PATH="$(extract_path_func $ORIGIN_URL)"
            URL_NAME="$(extract_name_func $ORIGIN_URL)"

            # Making a copy of 'hosts' files into the Home directory
            cp -f "/etc/hosts" "$HOME_DIR"

            ###### Removing mirrored resource
            # If not exists a mirror for current origin url, then launch error
            if [[ $(check_origin_url_in_mirror_func "${ORIGIN_URL}" "${HOME_DIR}/mirrors") == "false" ]]; then
                echo "${BLUE}[ INFO ]: There is not a mirror for this <origin-url> [$ORIGIN_URL].${NC}"
                exit 128
            else

                # Remove the line of mirrored resource from the 'mirrors' file
                while read -r ORIGIN_ITEM
                do
                    ORIGIN=$(echo "$ORIGIN_ITEM" | cut -d' ' -f2)

                    if [[ "$ORIGIN" != "$ORIGIN_URL" ]]; then
                        echo "$ORIGIN_ITEM" >> "${HOME_DIR}/mirrors.tmp"
                    fi
                done < "${HOME_DIR}/mirrors"

                rm -rf "${HOME_DIR}/mirrors"

                if [[ -e "${HOME_DIR}/mirrors.tmp" ]]; then
                    mv "${HOME_DIR}/mirrors.tmp" "${HOME_DIR}/mirrors"
                fi

                # Remove directory structure of mirrored resource from the Apache server
                ROOT_PATH="/var/www/html"
                URL_MIRROR_PATH="${ROOT_PATH}/${URL_PATH}"
                # URL_MIRROR_PATH="${ROOT_PATH}/${URL_PATH}/${URL_NAME}"
                URL_MIRROR_FILE="${ROOT_PATH}/${URL_PATH}/${URL_NAME}"

                while [[ "$URL_MIRROR_PATH" != "$ROOT_PATH" ]]
                do
                    MIRROR_PATH_CONTENT=$(ls -1qa $URL_MIRROR_PATH | wc -l)
                    if [[ $MIRROR_PATH_CONTENT -gt 3 ]]; then
                        echo "${BLUE}Keeping directory structure due some files in: \"${URL_MIRROR_PATH}\".${NC}"
                        # echo "Keep: "$URL_MIRROR_PATH" with: "$MIRROR_PATH_CONTENT
                        break
                    else
                        # echo "Remove: "$URL_MIRROR_PATH" with: "$MIRROR_PATH_CONTENT
                        rm -rf $URL_MIRROR_PATH
                        URL_MIRROR_PATH="$(echo ${URL_MIRROR_PATH%\/*})"
                    fi
                done

                if [[ -e "$URL_MIRROR_FILE" ]]; then
                    # echo "Residue: "$URL_MIRROR_FILE
                    rm -rf $URL_MIRROR_FILE
                fi

                # If not exists another mirror that belong to the same Domain, then remove the Domain from 'hosts' file
                if [[ $(check_domain_in_mirror_func "${URL_DOMAIN}" "${HOME_DIR}/mirrors") == "false" ]]; then

                    # Remove the line of mirrored Domain from the 'hosts' file
                    while read -r DOMAIN_ITEM
                    do
                        DOMAIN=$(echo "$DOMAIN_ITEM" | cut -d' ' -f2)

                        if [[ "$DOMAIN" != "$URL_DOMAIN" ]]; then
                            echo "$DOMAIN_ITEM" >> "${HOME_DIR}/hosts.tmp"
                        fi
                    done < "${HOME_DIR}/hosts"

                    rm -rf "${HOME_DIR}/hosts"
                    
                    if [[ -e "${HOME_DIR}/hosts.tmp" ]]; then
                        mv "${HOME_DIR}/hosts.tmp" "${HOME_DIR}/hosts"
                    fi
                fi
            fi

            # Copy 'hosts' file to /etc [may require sudo privileges]
            sudo cp -f "${HOME_DIR}/hosts" "/etc/hosts"

            echo "${GREEN}Mirror removed: \"${ORIGIN_URL}\".${NC}"
            ;;
        
        # lhmirror -a|--unpublish-all                                   // Unpublish all mirrored resources from local server
        "-a"|"--unpublish-all")
            # Making a copy of 'hosts' files into the Home directory
            cp -f "/etc/hosts" "$HOME_DIR"

            ###### Removing mirrored resource
            # Remove the line of mirrored resource from the 'mirrors' file
            while read -r ORIGIN_ITEM
            do
                ORIGIN_URL=$(echo "$ORIGIN_ITEM" | cut -d' ' -f2)

                # Getting Domain and Path from the Origin URL
                URL_DOMAIN="$(extract_domain_func $ORIGIN_URL)"
                URL_PATH="$(extract_path_func $ORIGIN_URL)"
                URL_NAME="$(extract_name_func $ORIGIN_URL)"

                # Remove directory structure of mirrored resource from the Apache server
                ROOT_PATH="/var/www/html"
                URL_MIRROR_PATH="${ROOT_PATH}/${URL_PATH}"
                # URL_MIRROR_PATH="${ROOT_PATH}/${URL_PATH}/${URL_NAME}"
                URL_MIRROR_FILE="${ROOT_PATH}/${URL_PATH}/${URL_NAME}"

                while [[ "$URL_MIRROR_PATH" != "$ROOT_PATH" ]]
                do
                    MIRROR_PATH_CONTENT=$(ls -1qa $URL_MIRROR_PATH | wc -l)
                    if [[ $MIRROR_PATH_CONTENT -gt 3 ]]; then
                        echo "${BLUE}Keeping directory structure due some files in: \"${URL_MIRROR_PATH}\".${NC}"
                        # echo "Keep: "$URL_MIRROR_PATH" with: "$MIRROR_PATH_CONTENT
                        break
                    else
                        # echo "Remove: "$URL_MIRROR_PATH" with: "$MIRROR_PATH_CONTENT
                        rm -rf $URL_MIRROR_PATH
                        URL_MIRROR_PATH="$(echo ${URL_MIRROR_PATH%\/*})"
                    fi
                done

                if [[ -e "$URL_MIRROR_FILE" ]]; then
                    # echo "Residue: "$URL_MIRROR_FILE
                    rm -rf $URL_MIRROR_FILE
                fi

                # Remove the line of mirrored Domain from the 'hosts' file
                while read -r DOMAIN_ITEM
                do
                    DOMAIN=$(echo "$DOMAIN_ITEM" | cut -d' ' -f2)

                    if [[ "$DOMAIN" != "$URL_DOMAIN" ]]; then
                        echo "$DOMAIN_ITEM" >> "${HOME_DIR}/hosts.tmp"
                    fi
                done < "${HOME_DIR}/hosts"

                rm -rf "${HOME_DIR}/hosts"
                
                if [[ -e "${HOME_DIR}/hosts.tmp" ]]; then
                    mv "${HOME_DIR}/hosts.tmp" "${HOME_DIR}/hosts"
                fi

                echo "${GREEN}Mirror removed: \"${ORIGIN_URL}\".${NC}"

            done < "${HOME_DIR}/mirrors"

            rm -rf "${HOME_DIR}/mirrors"

            # Copy 'hosts' file to /etc [may require sudo privileges]
            sudo cp -f "${HOME_DIR}/hosts" "/etc/hosts"
            ;;
        
        *)
            echo "${RED}Bad argument!${NC}" 
            echo ""
            echo "Usage: $0 [ <command> ]"
            echo ""
            echo "Where <command> is one of:"
            echo "    -p|--publish <origin-url> <local-resource-path>"
            echo "    -u|--unpublish <origin-url>"
            echo "    -a|--unpublish-all"
            echo ""
            echo "Command description:"
            echo "-p|--publish        Set the URL passed in <origin-url>, as local mirror, using the resource(s) passed in <local-resource-path>"
            echo "-u|--unpublish      Remove the local mirror created for the URL passed in <origin-url>"
            echo "-a|--unpublish-all  Remove all local mirrors created before"
            echo ""
            echo "Apache2 or NGINX server is required to use this tool, with default directory server as '/var/www/html'"
            echo ""
            ;;

    esac

fi
