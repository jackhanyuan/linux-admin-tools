# Linux server mining Trojan virus detection
# @author [jackhanyuan](https://github.com/jackhanyuan)
# https://blog.csdn.net/jackhanyuan/article/details/142785068
# @Date October 10, 2024

#!/bin/bash

# Define keywords (optimized regular expressions)
keywords='mcrond|bcrond|crondr|bprofr|ntpdate|entpdate|lntpdate|initdr|binitd|minitd|msysde|msysdl|bsysde|bsysdl|sysdr|dbused|xmrminer|xmr-rx0\.do-dear\.com|pw\.pwndns\.pw|pwndns|pwnrig.*|do-dear|processhider|root\.sh|reboot\.sh'

# Set maximum scan depth (adjust as needed)
max_scan_depth=2
# If the user provides a scan depth parameter, use it
if [ $# -ge 1 ]; then
    if [[ $1 =~ ^[0-9]+$ ]]; then
        max_scan_depth=$1
    else
        echo "Invalid scan depth parameter. Please provide a positive integer."
        exit 1
    fi
fi
echo "Scan depth set to: $max_scan_depth"

# Get all users' Home directories (as an array)
readarray -t homedirs <<< "$(awk -F: '{print $6}' /etc/passwd | sort -u | grep -Ev '^/$|^/proc$|^/(s?bin)$')"

# Define other directories to scan (do not use quotes to allow globbing)
scandir_patterns=(
    /bin/
    /sbin/
    /etc/cron*/
    /var/spool/cron*/
    /etc/init*/
    /etc/rc*/
    /etc/system*/
    /lib/system*/
    /run/system*
    /var/tmp/.system*/
    /var/tmp/.update/
    /var/log/
)

# Merge and deduplicate directories to scan
dirs_to_scan=($(printf "%s\n" "${homedirs[@]}" "${scandir_patterns[@]}" | awk '!seen[$0]++'))

# Define colors
GREEN='\033[0;32m'  # Green
NC='\033[0m'        # No color

# Start scanning
for dir in "${dirs_to_scan[@]}"; do
    if [ -d "$dir" ]; then
        echo "Scanning directory: $dir"
        
        # Build find command to scan only specific types of files, excluding binary files
        find_cmd=(find -L "$dir" -maxdepth "$max_scan_depth" -type f -size -10M -print0)
    
        # Execute find command
        "${find_cmd[@]}" 2>/dev/null | while IFS= read -r -d '' file; do
            # Check if the filename matches any keyword
            filename=$(basename "$file")
            if echo "$filename" | grep -E -q "$keywords"; then
                echo -e "${GREEN}Found suspicious filename: $file${NC}"
                echo "$file" | sed 's/^/    /'
                echo "-------------------------"
            fi
            
            # echo "Scanning：$file"
            # Search for keywords in file content, excluding binary files
            matches=$(grep --binary-files=without-match -E -H -n -i "$keywords" "$file" 2>/dev/null)
            if [ -n "$matches" ]; then
                echo -e "${GREEN}Found suspicious file content: $file${NC}"
                
                # Indent matched content and limit to first 10 lines with a maximum of 200 characters per line
                echo "$matches" | awk 'NR <= 10 { 
                    if (length($0) > 200) { 
                        print "    " substr($0, 1, 200) " ..."
                    } else { 
                        print "    " $0 
                    } 
                } NR > 10 { 
                    print "    ... (truncated)" 
                    exit 
                }'
                echo "-------------------------"
            fi
        done
    else
        echo "Directory does not exist or is not accessible: $dir"
    fi
done

# Check for SSH authorized_keys
awk -F: '{print $6}' /etc/passwd | xargs -I {} grep -iEH --color=always 'ssh-rsa|ecdsa-sha2-nistp256|ed25519' {}/.ssh/authorized_keys 2>/dev/null | awk -F: '{print "User: " $1 "\nKey: " $2 "\n-------------------------"}' | sed 's/\(ssh-rsa\|ecdsa-sha2-nistp256\|ed25519\)/\x1b[32m\1\x1b[0m/g'

# Check /etc/ld.so.preload with highlighted output if not empty
if [ -s /etc/ld.so.preload ]; then
    echo -e "${GREEN}/etc/ld.so.preload contains the following entries:${NC}"
    cat /etc/ld.so.preload | grep --color=auto '.'
    echo "-------------------------"
else
    echo "/etc/ld.so.preload not exist"
fi

# Check for suspicious cron jobs
crontab -l 2>/dev/null | grep -iE --color=auto "$keywords"

# Check for suspicious services
chkconfig --list 2>/dev/null | grep -iE --color=auto "$keywords"
systemctl list-units --type=service | grep -iE --color=auto "$keywords"

# check environment variables
env 2>/dev/null | grep -iE --color=auto "$keywords"
