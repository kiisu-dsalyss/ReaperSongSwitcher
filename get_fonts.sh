#!/bin/bash
# Helper script to generate list of system fonts
# Called by Lua scripts to get available fonts

fc-list : family 2>/dev/null | sort -u | while read line; do
    # Split by comma to get all variants
    echo "$line" | tr ',' '\n' | while read font_name; do
        # Clean up whitespace
        font_name=$(echo "$font_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Only include if non-empty and reasonable length
        if [ ! -z "$font_name" ] && [ ${#font_name} -lt 200 ]; then
            echo "$font_name"
        fi
    done
done
