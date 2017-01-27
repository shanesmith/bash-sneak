if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
  echo "sneak.bash requires Bash 4+, you currently have $BASH_VERSION" >&2
fi

declare __sneak_last_search

__sneak() {
  local search

  local direction="$1"

  local prompt="${SNEAK_PROMPT-/ }"

  local num_chars="${SNEAK_NUM_CHARS:-2}"

  local binding_char=$(__sneak_get_bind_char "$direction")

  local num_columns="$(tput cols)"

  local prompt_cursor_col=$(( ${#prompt} + $READLINE_POINT ))

  local prompt_cursor_row=$(( $prompt_cursor_col / $num_columns ))

  prompt_cursor_col=$(( $prompt_cursor_col - ( $prompt_cursor_row * $num_columns ) ))

  if __sneak_bash_version "<=" "4.2"; then
    # move up one line
    tput cuu1
    # erase line
    tput el
  fi

  # save cursor (col 0)
  tput sc

  # re-show the current line
  echo -n "${prompt}${READLINE_LINE}"

  # restore cursor (col 0)
  tput rc

  [[ "$prompt_cursor_row" -gt 0 ]] && tput cud "$prompt_cursor_row"

  [[ "$prompt_cursor_col" -gt 0 ]] && tput cuf "$prompt_cursor_col"

  while true; do

    local save_stty=$(stty -g)

    # disable turning Ctrl-C into SIGINT
    stty intr undef

    # read a single key
    read -rs -n1 key

    local read_success=$?

    stty "$save_stty"

    if [[ "$read_success" -ne 0 ]]; then
      search=""
      break
    fi

    case "$key" in

      $'\e'|$'\cc')
        # escape and ctrl-c quits
        search=""
        break
        ;;

      $binding_char)
        # doubling binding char redoes last search
        search="${__sneak_last_search}"
        break
        ;;

      "")
        # ENTER does search with what we've got so far
        break
        ;;

      [[:print:]])
        # only accept printable characters
        search="$search$key"
        ;;

    esac

    if [[ "${#search}" -eq "${num_chars}" ]]; then
      # we've got what we asked for, let's get down to business
      break
    fi

  done

  # restore cursor (col 0)
  tput rc

  # erase line
  tput el

  if __sneak_bash_version "<=" 4.3; then
    __sneak_old_bash_restore_prompt
  fi

  if [[ -z "${search}" ]]; then
    return
  fi

  # save search
  __sneak_last_search="${search}"

  READLINE_POINT=$(
    echo "$READLINE_LINE" | awk \
      -v point="$READLINE_POINT" \
      -v direction="$direction" \
      -v search="$search" \
      '{
        if (direction == "forward") {
          point += index(substr($0, point+2), search);
        }
        else {
          pos = 0
          str = substr($0, 0, point + 1)
          while (i = index(substr(str, pos+1), search)) {
            pos += i
          }
          if (pos != 0) point = pos - 1
        }

        print point
      }'
  )

}

__sneak_old_bash_restore_prompt() {
  local i

  local numlines=$(echo "$PS1" | grep -o '\\n' | wc -l)

  for (( i = 0; i < "$numlines"; i++ )); do
    # move up one line
    tput cuu1
    # erase line
    tput el
  done
}

__sneak_get_bind_char() {
  local uppercase_direction="$(echo "$1" | tr '[a-z]' '[A-Z]')"
  local option_name="SNEAK_BINDING_${uppercase_direction}"
  local option_value="${!option_name}"

  if [[ ! "$option_value" =~ ^\\C-.$ ]]; then
    return
  fi

  # extract the letter (ie: "x" from "\C-x")
  # make sure it's lowercase
  # get ASCII decimal code
  # compute ASCII for for Ctrl-x
  # convert to octal number
  # print control character
  # ...Bash 4.4 does allow for `qq="\\ct"; echo ${qq@E}` for expanding variables in the same way as $'...'
  echo -n "${option_value:3:1}" \
      | tr '[A-Z]' '[a-z]' \
      | od -An -d \
      | xargs -I'{}' expr '{}' - 96 \
      | xargs printf "%o" \
      | xargs -I'{}' printf "%b" "\0{}"
}

# Compares current BASH_VERSION, succeeds if true
# Usage:  __sneak_bash_version "<" "4.4.5"
__sneak_bash_version() {
  local op="$1"

  if [[ ! $op =~ \<=?|\>=?|!?==? ]]; then
    echo "Invalid operator: $op"
    return 2
  fi

  local comparison=$(echo "$2" | \
    awk -F. \
    -v major="${BASH_VERSINFO[0]}" \
    -v minor="${BASH_VERSINFO[1]}" \
    -v patch="${BASH_VERSINFO[2]}" \
    '{
      comp_version_number = sprintf("%03d%03d%03d", $1, $2, $3)
      bash_version_number = sprintf("%03d%03d%03d", major, minor, patch)

      if (bash_version_number < comp_version_number) print "<"
      else if (bash_version_number > comp_version_number) print ">"
      else print "="
    }'
  )

  case "$comparison" in
    "<") [[ $op =~ \<=?|!= ]]; return $? ;;
    ">") [[ $op =~ \>=?|!= ]]; return $? ;;
    "=") [[ $op =~ == ]]; return $? ;;
  esac
}

__sneak_forward() {
  __sneak "forward"
}

__sneak_backward() {
  __sneak "backward"
}

bind -x "\"${SNEAK_BINDING_FORWARD=\C-g}\": __sneak_forward"

bind -x "\"${SNEAK_BINDING_BACKWARD=\C-t}\": __sneak_backward"

